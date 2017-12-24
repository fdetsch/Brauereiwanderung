### environment -----

## clean-up workspace
rm(list = ls(all = TRUE))

## load packages
library(mapview)
library(raster)
library(jsonlite)

if (!require(Orcs)) {
  devtools::install_github("fdetsch/Orcs", local = FALSE)
  library(Orcs)
}


### digital elevation model -----

## spatial bounding box of registered breweries, required as shapefile input for 
## USGS Earth Explorer (https://earthexplorer.usgs.gov/)
ext = as(extent(breweries), "SpatialPolygons")
proj4string(ext) = "+init=epsg:4326"
ext = SpatialPolygonsDataFrame(ext, data = data.frame(x = "breweries"))

if (!file.exists("data/breweries.shp")) {
  writeOGR(ext, "data", "breweries", "ESRI Shapefile")
}

fls = list.files("data", pattern = "^breweries", full.names = TRUE)
zip("data/breweries.zip", fls)

## after manual data download, extract and merge tiled elevation data
zps = list.files("inst/extdata", pattern = "^ASTGTM.*.zip", full.names = TRUE)
dms = lapply(zps, function(i) {
  ifl = unzip(i, list = TRUE)$Name
  ids = grep("dem.tif$", ifl)
  ofl = unzip(i, files = ifl[ids], exdir = "inst/extdata")
  rst = raster(ofl)
  
  return(rst)
})

dem = merge(dms)
dem = crop(dem, ext, snap = "out", filename = "data/ASTGTM2_NxxE0xx_dem.tif", 
           datatype = "INT2U", overwrite = TRUE)

# ## visualize data (optional)
# spplot(dem, scales = list(draw = TRUE, y = list(rot = 90)), 
#        sp.layout = list("sp.points", as(breweries, "Spatial"), pch = 20, col = "black"), 
#        col.regions = terrain.colors(111), at = seq(0, 1100, 10))

## calculate slope and aspect
slp = ifMissing("data/ASTGTM2_NxxE0xx_slp.tif", raster
                , terrain, "filename", x = dem, unit = "degrees")
asp = ifMissing("data/ASTGTM2_NxxE0xx_asp.tif", raster
                , terrain, "filename", x = dem, unit = "degrees", opt = "aspect")


### openstreetmap data -----

srv = "http://download.geofabrik.de/europe/germany/bayern/"
zps = sapply(c("ober", "mittel", "unter"), function(region) {
  onl = paste0(srv, region, "franken-latest-free.shp.zip")
  ofl = gsub(srv, "inst/extdata/", onl)
  
  ifMissing(ofl, invisible, download.file, "destfile", url = onl)
})

library(parallel)
cl = makePSOCKcluster(3L)

shp = parLapply(cl, zps, function(i) {
  ifl = unzip(i, list = TRUE)$Name
  ids = grep("roads", ifl)
  ofl = unzip(i, files = ifl[ids], exdir = gsub(".shp.zip$", "", i)
              , overwrite = FALSE)
  
  raster::shapefile(ofl[grep(".shp$", ofl)])
})

rds = do.call("rbind", shp)

cds = data.frame(code = unique(rds@data$code), fclass = unique(rds@data$fclass))
cds = cds[order(cds$code), ]
row.names(cds) = as.character(1:nrow(cds))
saveRDS(cds, file = "inst/extdata/fclass-codes.rds")

rds@data = rds@data[, c("osm_id", "code", "name", "ref", "maxspeed")]
saveRDS(rds, file = "inst/extdata/franken-roads.rds")

## http://download.geofabrik.de/europe/germany/bayern.html
osm = dir("inst/extdata", pattern = "franken$", full.names = TRUE)
ids = sapply(c("ober", "mittel", "unter"), function(i) grep(i, osm))
osm = osm[ids]


### spatial analysis -----

brw = as(breweries, "Spatial")
brw = spTransform(brw, CRS("+init=epsg:32632"))

brw = brw[-which(duplicated(brw$brewery)), ]

## breweries with a neighboring brewery in a 2-km radius
ids = sapply(seq_along(brw), function(i) {
  bff = rgeos::gBuffer(brw[i, ], width = 2e3, quadsegs = 25)
  xtr = over(brw, bff)
  length(which(!is.na(xtr))) > 1
})

brw = brw[ids, ]

## breweries with at least 4 neighboring breweries in a 10-km radius
ids = sapply(seq_along(brw), function(i) {
  bff = rgeos::gBuffer(brw[i, ], width = 1e4, quadsegs = 50)
  xtr = over(brw, bff)
  length(which(!is.na(xtr))) >= 4
})

brw = brw[ids, ]

## path length
brw = spTransform(brw, CRS("+init=epsg:4326"))
crd = coordinates(brw)

source("R/getRoutes.R")

library(parallel)
cl = makePSOCKcluster(detectCores() - 1)
clusterExport(cl, c("brw", "crd", "getRoutes"))
jnk = clusterEvalQ(cl, library(raster))

rts = parLapply(cl, seq_along(brw), function(i) {
  lst = lapply(seq_along(brw), function(j) {
    # geodist(crd[i, 2], crd[i, 1]
    #         , crd[j, 2], crd[j, 1], units = "km") * 1e3
    getRoutes(crd[i, ], crd[j, ], ID = brw$brewery[j]
              , proj4string = CRS("+init=epsg:4326"))
  })
  
  bnd = do.call("rbind", lst)
  bnd = spTransform(bnd, CRS("+init=epsg:32632"))
  
  return(bnd)
})

names(rts) = brw$brewery

#' @param i Start index
#' @param js Remaining indices
#' @param segments Route segments
go = function(x, id, js, len = 0, segments = NULL) {
  
  if (len > 12000 | length(js) == 0) {
    return(list(len, segments))
  } else {
    lns = sapply(1:length(x[[id]]), function(z) {
      if (z == id | !(z %in% js)) {
        return(1e6) 
      } else {
        return(gLength(x[[id]][z, ], byid = TRUE))
      }        
    })

    new_id = which.min(lns)
    
    new_segments = if (is.null(segments)) {
      x[[id]][new_id, ]
    } else {
      rbind(segments, x[[id]][new_id, ])
    }
    
    new_len = len + lns[[new_id]]
    
    new_js = js[js != new_id]
    # new_x = x[-new_id]
    
    go(x, new_id, new_js, new_len, new_segments)
  }
}

jnk = clusterEvalQ(cl, { library(raster); library(rgeos) })
clusterExport(cl, c("rts", "go"))
tracks = parLapply(cl, seq_along(brw), function(id) {
  go(rts, id = id, js = seq_along(rts)[-id])
})

no_breweries = sapply(sapply(tracks, "[[", 2), length)
ids = which(no_breweries == max(no_breweries))

best = sapply(tracks[ids], "[[", 1)

shp = do.call("rbind", sapply(tracks, "[[", 2))
m = mapview(shp)
mapshot(m, url = file.path(getwd(), "index.html")
        , file = file.path(getwd(), "index.png"))

### environment -----

## clean-up workspace
rm(list = ls(all = TRUE))

## load packages
library(mapview)
library(raster)

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
slp = terrain(dem, unit = "degrees", filename = "data/ASTGTM2_NxxE0xx_slp.tif")
asp = terrain(dem, opt = 'aspect',unit = "degrees", 
              filename = "data/ASTGTM2_NxxE0xx_asp.tif")


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

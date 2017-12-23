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

spplot(dem, scales = list(draw = TRUE, y = list(rot = 90)), 
       sp.layout = list("sp.points", as(breweries, "Spatial"), pch = 20, col = "black"), 
       col.regions = terrain.colors(111), at = seq(0, 1100, 10))

# Calculate slopes
slp = terrain(dem,unit = "degrees", filename = "data/ASTGTM2_NxxE0xx_slp.tif")
asp = terrain(dem,opt='aspect',unit = "degrees", filename = "data/ASTGTM2_NxxE0xx_asp.tif")


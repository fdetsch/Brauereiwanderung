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

dem = merge(dms, filename = "data/ASTGTM2_NxxE0xx.tif", datatype = "INT2U")


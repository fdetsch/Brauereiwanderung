### . osmdata (https://cran.r-project.org/web/packages/osmdata/vignettes/osmdata.html) ----

## load packages
library(osmdata)
library(sf)
library(mapview)

## find brewing specific key-value pairs
q = opq(bbox = c(9.462785, 48.900742, 11.935392, 50.441619)) %>% 
  add_osm_feature("craft", "brewery") %>%
  add_osm_feature("microbrewery", "yes") %>% 
  osmdata_sf()

## eliminate joint point/polygon venues in favor of polygons
dpl = st_intersects(q$osm_points, q$osm_polygons)
dpl = sapply(dpl, function(x) length(x) > 0)

mapview(q$osm_points[, dpl]) + q$osm_polygons

pts1 = q$osm_points[!dpl, ]
pts2 = st_centroid(pts2)

## display data
m = mapview(pts1) + pts2
m

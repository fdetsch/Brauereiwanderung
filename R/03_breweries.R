### . osmdata (https://cran.r-project.org/web/packages/osmdata/vignettes/osmdata.html) ----

### ENVIRONMENT ====

## load packages
library(osmdata)
library(mapview)

## define functions
rbindsflist = function(x) {
  dat = data.table::rbindlist(
    x
    , fill = TRUE
  )
  
  sf::st_set_geometry(dat, "geometry")
}


### DATA RETRIEVAL ====

## find brewing specific key-value pairs
q = mapply(
  function(key, value) {
    opq(
      bbox = c(9.462785, 48.900742, 11.935392, 50.441619)
      , timeout = 90
    ) %>% 
      add_osm_feature(
        key = key
        , value = value
      ) %>%
      osmdata_sf()
  }
  , key = c("craft", "microbrewery")
  , value = c("brewery", "yes")
  , SIMPLIFY = FALSE
)

## bind point geometries
pts = rbindsflist(
  lapply(
    seq(q)
    , function(i) {
      q[[i]]$osm_points
    }
  )
)

## bind polygon geometries
pys = rbindsflist(
  lapply(
    seq(q)
    , function(i) {
      q[[i]]$osm_polygons
    }
  )
)

## eliminate joint point/polygon venues in favor of polygons
dpl = suppressMessages(
  sf::st_intersects(
    pts
    , pys
  )
) %>% lengths > 0

# mapview(pts[dpl, ]) + pys # duplicate points and polygons

## display data
m = mapview(pts[!dpl, ]) + pys + suppressWarnings(sf::st_centroid(pys))
m

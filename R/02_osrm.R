### ENVIRONMENT ====

## packages
library(rjson)
library(mapview)


### ROUTING ====

## decode() function (available online: https://cmhh.github.io/post/routing/)
decode <- function(str, multiplier=1e5){
  
  if (!require(bitops)) stop("Package: bitops required.")
  if (!require(sp)) stop("Package: sp required.")
  
  truck <- 0
  trucks <- c()
  carriage_q <- 0
  
  for (i in 0:(nchar(str)-1)){
    ch <- substr(str, (i+1), (i+1))
    x <- as.numeric(charToRaw(ch)) - 63
    x5 <- bitShiftR(bitShiftL(x, 32-5), 32-5)
    truck <- bitOr(truck, bitShiftL(x5, carriage_q))
    carriage_q <- carriage_q + 5
    islast <- bitAnd(x, 32) == 0
    if (islast){
      negative <- bitAnd(truck, 1) == 1
      if (negative) truck <- -bitShiftR(-bitFlip(truck), 1)/multiplier
      else truck <- bitShiftR(truck, 1)/multiplier
      trucks <- c(trucks, truck)
      carriage_q <- 0
      truck <- 0
    }
  }
  lat <- trucks[c(T,F)][-1]
  lng <- trucks[c(F,T)][-1]
  res <- data.frame(lat=c(trucks[1],cumsum(lat)+trucks[1]), 
                    lng=c(trucks[2],cumsum(lng)+trucks[2]))
  
  coordinates(res) <- ~lng+lat
  proj4string(res) <- CRS("+init=epsg:4326")
  return(SpatialLines(list(Lines(Line(res), 1)), CRS("+init=epsg:4326")))
}


### . manual online retrieval ----
### (available online: https://cmhh.github.io/post/routing/)

brwrs = subset(breweries, grepl("Trunk|Uetzing", brewery))

origin = brwrs[tmp <- brwrs$brewery == "Brauerei Trunk", ]
destination = brwrs[!tmp, ]

o <- sf::st_coordinates(origin)
d <- sf::st_coordinates(destination)

profile = c("driving", "walking") # 2nd doesn't seem to work for some reason
(url <- paste0("http://router.project-osrm.org/route/v1/", profile[1], "/", 
               o[1],",",o[2],";",d[1],",",d[2],"?overview=full"))

route_car = try(log("e"), silent = TRUE)
system.time({
  while (inherits(route_car, "try-error")) {
    route_car = try(suppressWarnings(fromJSON(file = url)), silent = TRUE)
    Sys.sleep(.2) # go to sleep for .2 seconds
  }
})

#create a basic map
path_car <- decode(route_car$routes[[1]]$geometry)
m1 = mapview(brwrs, alpha.regions = 1) + path_car
m1


### . manual offline analog ----
### (available online: https://github.com/MeganBeckett/presentations/blob/master/useR_2019/useR_2019_osrm.pdf)

crd = paste0(o[1], ",", o[2], ";", d[1], ",", d[2])
stdout = system(paste0('curl -s "http://127.0.0.1:5000/route/v1/walking/', crd, '"')
                , intern = TRUE)

route_foot = fromJSON(stdout)
path_foot = decode(route_foot$routes[[1]]$geometry, multiplier = 1e5)

m2 = m1 + mapview(path_foot, color = "orange")
m2


### . r osrm pkg retrieval ----

# remotes::install_github("rCarto/osrm")
library(osrm)

## set server and profile
options(osrm.server = "http://127.0.0.1:5000/", osrm.profile = "walking")

path_foot2 = osrmRoute(origin, destination, returnclass = "sf")
m3 = m2 + mapview(path_foot2, color = "cornflowerblue")
m3

## get shortest travel geometry
trips <- osrmTrip(loc = breweries[1:100, ], returnclass = "sf")

mapview(trips[[1]]$trip) + breweries[1:100, ]

## 
options("osrm.profile" = "walk")
lst = lapply(1:10, function(i) {
  cat(i)
  osrmIsochrone(breweries[i, ], returnclass = "sf"
                , breaks = seq(from = 0, to = 60, length.out = 13))
})

mapview(iso)

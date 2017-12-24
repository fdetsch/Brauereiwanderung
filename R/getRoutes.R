getRoutes = function(start, end, host = "http://localhost:11111", ...) {
  txt = paste0(host, "/route?point=", start[2], "%2C", start[1]
               , "&point=", end[2], "%2C", end[1]
               , "&vehicle=hike&points_encoded=false")
  jsn = jsonlite::fromJSON(txt)
  
  crd = jsn$paths$points$coordinates[[1]]
  sln = mapview::coords2Lines(crd, ...)
  
  return(sln)
}

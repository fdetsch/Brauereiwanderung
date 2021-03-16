#
# This is the server logic of a Shiny web application. You can run the
# application by clicking 'Run App' above.
#
# Find out more about building applications with Shiny here:
#
#    http://shiny.rstudio.com/
#

library(shiny)
library(mapview)
library(leaflet)

# Define server logic required to draw a histogram
shinyServer(function(input, output) {
  
  cid = "HZLZB54PSOERBSI4D3GHAIQQDYGOMFXUTMCNECEC0XB4GRYA"
  
  # aoi = sf::st_as_sf(
  #   data.frame(
  #     lat = 50.11248629959232
  #     , lng = 11.0092276814799
  #     , name = "bad staffelstein"
  #   )
  #   , coords = c("lng", "lat")
  #   , crs = 4326
  # )
  # 
  loc = reactive({
    input$location
  })
  
  output$entered = renderPrint({
    loc()
  })
  
  hereR::set_key(
    keyring::key_get(
      "here"
    )
  )
  
  ## https://cran.r-project.org/web/packages/hereR/vignettes/geocoder.html
  aoi = reactive({
    hereR::geocode(
      loc()
    )
  })
  
  output$text = renderPrint({
    aoi()
  })
  
  m = reactive({
    mapview(
      aoi()
      , legend = FALSE
    )
  })

  # qry = reactive({
  #   paste0(
  #     "https://api.foursquare.com/v2/venues/search"
  #     , "?client_id=", cid
  #     , "&client_secret=", keyring::key_get("foursquare", cid)
  #     , "&v=20200501&near=", input$location
  #     , "&intent=browse"
  #     , "&radius=20000"
  #     , "&limit=50"
  #     , "&categoryId=50327c8591d4c4b30a586d5d"
  #   )
  # })
  # 
  # tmp = tempfile(fileext = ".json")
  # jnk = utils::download.file(
  #   qry()
  #   , tmp
  # )
  # 
  # jsn = jsonlite::fromJSON(
  #   tmp
  # )$response$venues
  # 
  # loc = sf::st_as_sf(
  #   data.frame(
  #     jsn$name
  #     , jsn$location
  #   )
  #   , coords = c("lng", "lat")
  #   , crs = 4326
  # )
  # 
  # })
  
  # tmp = "file4bec41a011e8.json"
  # 
  output$map <- renderLeaflet({

    # m = mapview(
    #   aoi
    #   , color = "transparent"
    #   , col.regions = "transparent"
    #   , legend = FALSE
    # )
    #
    # crd = sf::st_coordinates(aoi)
    # l = m@map %>%
    #   addMarkers(
    #     crd[, 1]
    #     , crd[, 2]
    #     # , icon = list(
    #     #   iconUrl = "inst/extdata/beer.jpg"
    #     #   , iconSize = c(60, 60)
    #     # )
    #   )

    # draw the histogram with the specified number of bins
    # m = mapview(
    #   aoi()
    #   , legend = FALSE
    # )

    m()@map
  })
})

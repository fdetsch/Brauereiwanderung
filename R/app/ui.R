#
# This is the user-interface definition of a Shiny web application. You can
# run the application by clicking 'Run App' above.
#
# Find out more about building applications with Shiny here:
#
#    http://shiny.rstudio.com/
#

library(shiny)

# Define UI for application that draws a histogram
shinyUI(fluidPage(
    
    # Application title
    titlePanel("St. Louis Brews"),
    
    # Sidebar with a slider input for number of bins
    sidebarLayout(
        sidebarPanel(
            textInput(
                "location"
                , "Search near:"
                , value = "Bad Staffelstein"
            )
            , fluidRow(
                column(
                    12
                    , verbatimTextOutput("entered")
                )
            )
        )
        
        , mainPanel(
            verbatimTextOutput("text")
            , leaflet::leafletOutput(
                "map"
                , height = 800
            )
        )
    )
    
))

library('shiny')
library('DT')

source('prepare_app_data.R')

ui <- fluidPage(
  
  titlePanel(
    h1("PKMN Similarity Tool", align="center")
    ),
  
  fluidRow(column(12, h1(""))),

  fluidRow(
    column(3, offset=1,
           selectizeInput("pokemon1", "Pokemon 1:", table$Name, selected="Charizard")),
    column(4,
           h1(textOutput(outputId = 'similarity'), align="center")),
    column(3,
           selectizeInput("pokemon2", "Pokemon 2:", table$Name, selected="Blastoise"))
  ),
  
  fluidRow(column(3, align="center",
                  imageOutput(outputId = 'image1')),
           column(6, align="center",
                  #DT::dataTableOutput(outputId = 'grid')),
                  tableOutput(outputId = 'grid')),
           column(3, align="center",
                  imageOutput(outputId = 'image2'))
  ),

  fluidRow(
    column(12, h3(""))
  ),
  
  renderImage(img("3.png")),
)

server <- function(input, output, session) {
  
  get_index1 <- reactive({ which(table$Name == input$pokemon1) })
  get_index2 <- reactive({ which(table$Name == input$pokemon2) })
  
  get_grid <- reactive({
    grid[,1] <- grid_data[get_index1(),]
    grid[,3] <- grid_data[get_index2(),]
    grid
  })

  output$image1 <- renderImage({
    list(src = as.character(table[get_index1(), "Image.Name"]))
  }, deleteFile=FALSE)

  output$image2 <- renderImage({
    list(src = as.character(table[get_index2(), "Image.Name"]))
  }, deleteFile=FALSE)
  
  output$similarity <- renderText({ paste0(100*round(cosine_scores[get_index1(), get_index2()], digits=2), "%") })
  output$grid <- renderTable({ get_grid() })
}

shinyApp(ui, server)
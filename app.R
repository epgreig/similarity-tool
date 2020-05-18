library('shiny')
library('DT')

source('conditional_formatting.R')
source('prepare_app_data.R')

ui <- fluidPage(
  
  titlePanel(
    h1("PKMN Similarity Tool", align="center")
    ),
  
  br(),

  fluidRow(
    column(4, align="center",
           selectizeInput("pokemon1", "Pokemon 1:", table$Name, selected="Charizard")),
    column(4,
           h1(textOutput(outputId = 'similarity'), align="center")),
    column(4, align="center",
           selectizeInput("pokemon2", "Pokemon 2:", table$Name, selected="Blastoise"))
  ),
  fluidRow(
    column(2, align="center",
           actionButton("find_match1", "Find Most Similar")),
    column(2, align="center",
           actionButton("find_mismatch1", "Find Most Different")),
    column(4),
    column(2, align="center",
           actionButton("find_match2", "Find Most Similar")),
    column(2, align="center",
           actionButton("find_mismatch2", "Find Most Different"))
  ),
  br(),
  
  fluidRow(column(4, align="center",
                  imageOutput(outputId = 'image1')),
           column(4,align="center",
                  div(dataTableOutput(outputId = 'grid'), style="text-align:center"),
                  tags$head(tags$style(type = "text/css", "#grid th {display:none;}"))),
           column(4, align="center",
                  imageOutput(outputId = 'image2'))
  ),
  
  br()
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
    list(src = as.character(table[get_index1(), "Image.Name"]),
         width="300px",
         height="300px")
  }, deleteFile=FALSE)

  output$image2 <- renderImage({
    list(src = as.character(table[get_index2(), "Image.Name"]),
         width="300px",
         height="300px")
  }, deleteFile=FALSE)
  
  output$similarity <- renderText({ paste0(100*round(cosine_scores[get_index1(), get_index2()], digits=2), "%") })
  output$grid <- renderDataTable(
    DT::datatable(
      get_grid(),
      class='cell-border',
      options = list(
        dom='t',
        pageLength = 14,
        rowCallback = JS(rowCallback),
        headerCallback = JS(headerCallback)
        )
    ) %>% formatStyle(
      columns = 2,
      width='10px',
      fontSize='10pt',
    ) %>% formatStyle(
      columns = c(1,3),
      width='60px',
      fontSize="11pt",
      fontWeight = 'bold'
    )
  )
  
  observeEvent(input$find_match1, {
    updateTextInput(session, 'pokemon2', value=table$Name[table$most_similar[get_index1()]])
  })
  
  observeEvent(input$find_match2, {
    updateTextInput(session, 'pokemon1', value=table$Name[table$most_similar[get_index2()]])
  })
  
  observeEvent(input$find_mismatch1, {
    updateTextInput(session, 'pokemon2', value=table$Name[table$most_dissimilar[get_index1()]])
  })
  
  observeEvent(input$find_mismatch2, {
    updateTextInput(session, 'pokemon1', value=table$Name[table$most_dissimilar[get_index2()]])
  })
}

shinyApp(ui, server)
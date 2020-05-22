library('shiny')
library('DT')

source('conditional_formatting.R')
source('prepare_app_data.R')

ui <- fluidPage(
  
  tags$head(HTML("<title>PKMN Similarity Tool</title>")),
  
  fluidRow(
    column(3),
    column(6,
           titlePanel(h2("PKMN Similarity Tool", align="center"))),
    column(3, align="right",
           checkboxInput("scale_images", "Scale Images by Height", value = FALSE, width = NULL))
    ),

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
                  tags$head(tags$style(type = "text/css", "#grid th {display:none;}")),
                  tags$head(tags$style(type = "text/css", "#grid th {border-width: 5px;}"))),
           column(4, align="center",
                  imageOutput(outputId = 'image2'))
  ),
  
  br()
)

server <- function(input, output, session) {

  get_index1 <- reactive({ which(table$Name == input$pokemon1) })
  get_index2 <- reactive({ which(table$Name == input$pokemon2) })
  
  output$similarity <- renderText({ paste0(100*round(cosine_scores[get_index1(), get_index2()], digits=2), "%") })

  ratio <- reactive({
    as.numeric(grid_data[get_index1(),"Height"]) / as.numeric(grid_data[get_index2(),"Height"])
  })
  
  padding1 <- reactive({
    if (ratio() >= 1 | input$scale_images == FALSE) { 0 }
    else { 300*(1 - ratio()) }
  })
  padding2 <- reactive({
    if (ratio() <= 1 | input$scale_images == FALSE) { 0 }
    else { 300*(1 - 1/ratio()) }
  })

  output$image1 <- renderImage({
    list(src = as.character(table[get_index1(), "Image.Name"]),
         width="300px",
         height="300px",
         style=paste0(
           "padding-top:", padding1(), "px;",
           "padding-left:", padding1()/2, "px;",
           "padding-right:", padding1()/2, "px;"))
  }, deleteFile=FALSE)

  output$image2 <- renderImage({
    list(src = as.character(table[get_index2(), "Image.Name"]),
         width="300px",
         height="300px",
         style=paste0(
           "padding-top:", padding2(), "px;",
           "padding-left:", padding2()/2, "px;",
           "padding-right:", padding2()/2, "px;"))
  }, deleteFile=FALSE)
  
  get_grid <- reactive({
    grid[,1] <- grid_data[get_index1(),]
    grid[,3] <- grid_data[get_index2(),]
    grid
  })

  output$grid <- renderDataTable(
    DT::datatable(
      get_grid(),
      class='row-border compact',
      escape=FALSE,
      callback = JS("$('table.dataTable.no-footer').css('border-bottom', 'none');"),
      options = list(
        dom='t',
        pageLength = 14,
        rowCallback = JS(rowCallback)
        )
    ) %>% formatStyle(
      columns = 2,
      width='50px',
      fontSize='9pt'
    ) %>% formatStyle(
      columns = c(1,3),
      width='55px',
      fontWeight = 'bold'
    )
  )
  
  observeEvent(input$find_match1, {
    match_id <- table$V1[get_index1()]
    if (match_id == get_index1()) {
      match_id <- table$V2[get_index1()]
    }

    updateTextInput(session, 'pokemon2', value=table$Name[match_id])
  })
  
  observeEvent(input$find_match2, {
    match_id <- table$V1[get_index2()]
    if (match_id == get_index2()) {
      match_id <- table$V2[get_index2()]
    }

    updateTextInput(session, 'pokemon1', value=table$Name[match_id])
  })
  
  mismatch_column <- paste0("V", nrow(table))

  observeEvent(input$find_mismatch1, {
    mismatch_id <- as.numeric(table[get_index1(), mismatch_column, with=FALSE])
    updateTextInput(session, 'pokemon2', value=table$Name[mismatch_id])
  })
  
  observeEvent(input$find_mismatch2, {
    mismatch_id <- as.numeric(table[get_index2(), mismatch_column, with=FALSE])
    updateTextInput(session, 'pokemon1', value=table$Name[mismatch_id])
  })
}

shinyApp(ui, server)
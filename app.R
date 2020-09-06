library('shiny')
library('shinyBS')
library('DT')

source('conditional_formatting.R')
source('prepare_app_data.R')

ui <- fluidPage(
  
  tags$head(HTML("<title>PKMN Similarity Tool</title>")),
  
  fluidRow(
    column(3),
    column(6,
           titlePanel(h3("PKMN Similarity Tool", align="center"))),
    column(3, align="right",
           checkboxInput("scale_images", "Scale Images by Height", value = FALSE, width = NULL))
  ),
  br(),

  fluidRow(
    column(4, align="center",
           selectizeInput("pokemon1", "PKMN 1:", table$Name, selected="Charizard"),
           actionButton("randomize1", "", icon=icon("random"), 
                        style='font-size:9pt; padding-left:20px; padding-right:20px; padding-top:3px; padding-bottom:3px; margin-top:-18px; color:white; background-color:rgb(51,183,122); border-color:white'),
           bsTooltip("randomize1", "Randomize")),
    column(1, style='padding:2px',
           actionButton("most_similar1",
                        "", icon=icon("angle-double-up"), width='100%',
                        style='font-size:10pt; padding:2px; margin:0px; color:white; background-color:rgb(51,122,183); border-color:white'),
           bsTooltip("most_similar1", "Find Most Similar", placement = "left"),
           br(),
           actionButton("next_similar1",
                        "", icon=icon("angle-up"), width='100%',
                        style='font-size:10pt; padding:0px; margin-top:-4px; color:white; background-color:rgb(120, 180, 240); border-color:white'),
           bsTooltip("next_similar1", "Find More Similar", placement = "left"),
           br(),
           actionButton("next_dissimilar1",
                        "", icon=icon("angle-down"), width='100%',
                        style='font-size:10pt; padding:0px; margin-top:-6px; color:white; background-color:rgb(120, 180, 240); border-color:white'),
           bsTooltip("next_dissimilar1", "Find Less Similar", placement = "left"),
           br(),
           actionButton("most_dissimilar1",
                        "", icon=icon("angle-double-down"), width='100%',
                        style='font-size:10pt; padding:2px; margin-top:-4px; color:white; background-color:rgb(51,122,183); border-color:white'),
           bsTooltip("most_dissimilar1", "Find Least Similar", placement = "left")
    ),
    column(2,
           h1(textOutput(outputId = 'similarity'), align="center")),
    column(1, style='padding:2px',
           actionButton("most_similar2",
                        "", icon=icon("angle-double-up"), width='100%',
                        style='font-size:10pt; padding:2px; margin:0px; color:white; background-color:rgb(51,122,183); border-color:white'),
           bsTooltip("most_similar2", "Find Most Similar", placement = "right"),
           br(),
           actionButton("next_similar2",
                        "", icon=icon("angle-up"), width='100%',
                        style='font-size:10pt; padding:0px; margin-top:-4px; color:white; background-color:rgb(120, 180, 240); border-color:white'),
           bsTooltip("next_similar2", "Find More Similar", placement = "right"),
           br(),
           actionButton("next_dissimilar2",
                        "", icon=icon("angle-down"), width='100%',
                        style='font-size:10pt; padding:0px; margin-top:-6px; color:white; background-color:rgb(120, 180, 240); border-color:white'),
           bsTooltip("next_dissimilar2", "Find Less Similar", placement = "right"),
           br(),
           actionButton("most_dissimilar2",
                        "", icon=icon("angle-double-down"), width='100%',
                        style='font-size:10pt; padding:2px; margin-top:-4px; color:white; background-color:rgb(51,122,183); border-color:white'),
           bsTooltip("most_dissimilar2", "Find Least Similar", placement = "right")
    ),
    column(4, align="center",
           selectizeInput("pokemon2", "PKMN 2:", table$Name, selected="Blastoise"),
           actionButton("randomize2", "", icon=icon("random"), 
                        style='font-size:9pt; padding-left:20px; padding-right:20px; padding-top:3px; padding-bottom:3px; margin-top:-18px; color:white; background-color:rgb(51,183,122); border-color:white'),
           bsTooltip("randomize2", "Randomize"))
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
  )
  
)

server <- function(input, output, session) {

  get_index1 <- reactive({ which(table$Name == input$pokemon1) })
  get_index2 <- reactive({ which(table$Name == input$pokemon2) })
  
  output$similarity <- renderText({ paste0(100*round(cosine_scores[get_index1(), get_index2()], digits=2), "%") })

  # Images

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
  
  # Grid
  
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
  
  # Buttons
  
  observeEvent(input$randomize1, {
    random_pkmn <- sample(table$Name, 1)
    updateTextInput(session, 'pokemon1', value=random_pkmn)
  })
  
  observeEvent(input$randomize2, {
    random_pkmn <- sample(table$Name, 1)
    updateTextInput(session, 'pokemon2', value=random_pkmn)
  })
  
  V_columns <- paste0("V",1:nrow(table))
  mismatch_column <- V_columns[nrow(table)]
  
  observeEvent(input$most_similar1, {
    match_id <- table$V1[get_index1()]
    if (match_id == get_index1()) {
      match_id <- table$V2[get_index1()]
    }
    updateTextInput(session, 'pokemon2', value=table$Name[match_id])
  })
  
  observeEvent(input$next_similar1, {
    current_rank <- match(get_index2(),table[get_index1(),V_columns,with=FALSE])
    next_rank <- max(current_rank-1, 1)
    V_next_rank <- paste0("V", next_rank)
    next_similar_id <- as.numeric(table[get_index1(),V_next_rank,with=FALSE])
    updateTextInput(session, 'pokemon2', value=table$Name[next_similar_id])
  })
  
  observeEvent(input$next_dissimilar1, {
    current_rank <- match(get_index2(),table[get_index1(),V_columns,with=FALSE])
    next_rank <- min(current_rank+1, nrow(table))
    V_next_rank <- paste0("V", next_rank)
    next_dissimilar_id <- as.numeric(table[get_index1(),V_next_rank,with=FALSE])
    updateTextInput(session, 'pokemon2', value=table$Name[next_dissimilar_id])
  })
  
  observeEvent(input$most_dissimilar1, {
    mismatch_id <- as.numeric(table[get_index1(), mismatch_column,with=FALSE])
    updateTextInput(session, 'pokemon2', value=table$Name[mismatch_id])
  })
  
  observeEvent(input$most_similar2, {
    match_id <- table$V1[get_index2()]
    if (match_id == get_index2()) {
      match_id <- table$V2[get_index2()]
    }
    updateTextInput(session, 'pokemon1', value=table$Name[match_id])
  })
  
  observeEvent(input$next_similar2, {
    current_rank <- match(get_index1(),table[get_index2(),V_columns,with=FALSE])
    next_rank <- max(current_rank-1, 1)
    V_next_rank <- paste0("V", next_rank)
    next_similar_id <- as.numeric(table[get_index2(),V_next_rank,with=FALSE])
    updateTextInput(session, 'pokemon1', value=table$Name[next_similar_id])
  })
  
  observeEvent(input$next_dissimilar2, {
    current_rank <- match(get_index1(),table[get_index2(),V_columns,with=FALSE])
    next_rank <- min(current_rank+1, nrow(table))
    V_next_rank <- paste0("V", next_rank)
    next_dissimilar_id <- as.numeric(table[get_index2(),V_next_rank,with=FALSE])
    updateTextInput(session, 'pokemon1', value=table$Name[next_dissimilar_id])
  })
  
  observeEvent(input$most_dissimilar2, {
    mismatch_id <- as.numeric(table[get_index2(), mismatch_column,with=FALSE])
    updateTextInput(session, 'pokemon1', value=table$Name[mismatch_id])
  })
}

shinyApp(ui, server)
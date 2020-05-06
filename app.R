library(shiny)

source('generate_pokemon_similarity.R')
table <- table_with_scores

ui <- pageWithSidebar(
  headerPanel("PKMN Similarity Tool"),
  sidebarPanel(
    # Input: Selector for variable to plot against mpg ----
    selectizeInput("pokemon1", "Pokemon 1:", table$Name, selected="Charizard"),
    selectizeInput("pokemon2", "Pokemon 2:", table$Name, selected="Blastoise"),
    
    # Input: Checkbox for whether outliers should be included ----
    checkboxInput("outliers", "Show outliers", TRUE)
  ),
  
  # Main panel for displaying outputs ----
  mainPanel(),

  tabPanel("Live Images", 
           lapply(X = seq_len(10), FUN = function(i) {
             conditionalPanel(condition = paste0("input.image_type == 'img_type", i, "'"),
                              img(src = paste0("img_type", i, ".jpeg"))
             )
           })
  )
)

server <- function(input, output) {
  refresh_input1 <- reactive({
    table_index1 <- which(table$Name == input$pokemon1)
    image_index1 <- table[table_index1, "Pokedex"]
    #image_file1 <- get_image_file(image_index1)
  })
  
  refresh_input2 <- reactive({
    table_index2 <- which(table$Name == input$pokemon1)
    image_index2 <- table[table_index2, "Pokedex"]
    #image_file2 <- get_image_file(image_index2)
  })
  
  #output$Health1 <- table[table_index1,"Health"]
  # Return the formula text for printing as a caption ----
  # output$caption <- renderText({
  #   formulaText()
  # })
  # 
  # # Generate a plot of the requested variable against mpg ----
  # # and only exclude outliers if requested
  # output$mpgPlot <- renderPlot({
  #   boxplot(as.formula(formulaText()),
  #           data = mpgData,
  #           outline = input$outliers,
  #           col = "#75AADB", pch = 19)
  # })
}

shinyApp(ui, server)
library(shiny)

table <- table_with_scores

ui <- pageWithSidebar(
  headerPanel("PKMN Similarity Tool"),
  sidebarPanel(
    # Input: Selector for variable to plot against mpg ----
    selectizeInput("pokemon1", "Pokemon 1:", table$Name),
    selectizeInput("pokemon2", "Pokemon 2:", table$Name),
    
    # Input: Checkbox for whether outliers should be included ----
    checkboxInput("outliers", "Show outliers", TRUE)
  ),
  
  # Main panel for displaying outputs ----
  mainPanel()
)

server <- function(input, output) {
  # Compute the formula text ----
  # This is in a reactive expression since it is shared by the
  # output$caption and output$mpgPlot functions
  formulaText <- reactive({
    paste("mpg ~", input$variable)
  })
  
  # Return the formula text for printing as a caption ----
  output$caption <- renderText({
    formulaText()
  })
  
  # Generate a plot of the requested variable against mpg ----
  # and only exclude outliers if requested
  output$mpgPlot <- renderPlot({
    boxplot(as.formula(formulaText()),
            data = mpgData,
            outline = input$outliers,
            col = "#75AADB", pch = 19)
  })
}

shinyApp(ui, server)
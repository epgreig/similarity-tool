library('shiny')
library('shinyBS')
library('DT')

source('conditional_formatting.R')
source('prepare_app_data.R')

# Build JS lookups for Pokedex numbers and generation
safe_names <- gsub('"', '\\"', table$Name, fixed=TRUE)
pokedex_js <- paste0("window.pokedex_lookup={",
  paste0('"', safe_names, '":', table$Pokedex, collapse=","),
  "};")

region_to_gen <- c(Kanto=1, Johto=2, Hoenn=3, Sinnoh=4, Unova=5, Kalos=6, Alola=7, Galar=8, Hisui=8, Paldea=9)
gens <- region_to_gen[data$Region.of.Origin]
gen_js <- paste0("window.gen_lookup={",
  paste0('"', safe_names, '":', gens, collapse=","),
  "};")

# Custom selectize render: Pokedex # on left, Gen on right, name only when selected
dropdown_render <- I(paste0('{',
  'option: function(item, escape) {',
  '  var num = window.pokedex_lookup[item.value];',
  '  var gen = window.gen_lookup[item.value];',
  '  var roman = ["","I","II","III","IV","V","VI","VII","VIII","IX"];',
  '  if (!num) return "<div>" + escape(item.label) + "</div>";',
  '  return "<div style=\\"display:flex;align-items:center\\">"',
  '    + "<span style=\\"color:#aaa;font-size:8.5pt;width:38px;text-align:right;margin-right:10px;flex-shrink:0\\">#" + num + "</span>"',
  '    + "<span style=\\"flex:1;text-align:center\\">" + escape(item.label) + "</span>"',
  '    + "<span style=\\"color:#aaa;font-size:8pt;width:38px;text-align:center;margin-left:10px;flex-shrink:0\\">" + (gen ? roman[gen] : "") + "</span>"',
  '    + "</div>";',
  '},',
  'item: function(item, escape) {',
  '  return "<div>" + escape(item.label) + "</div>";',
  '}',
  '}'))

ui <- fluidPage(

  tags$head(
    HTML("<title>Pokémon Similarity Tool</title>"),
    tags$link(href="https://fonts.googleapis.com/css2?family=Inter:wght@400;600;700&display=swap", rel="stylesheet"),
    tags$script(HTML(pokedex_js)),
    tags$script(HTML(gen_js)),
    tags$script(HTML("
      Shiny.addCustomMessageHandler('setTooltip', function(data) {
        var el = $('#' + data.id);
        if (el.data('bs.tooltip')) {
          el.tooltip('hide').tooltip('destroy');
        }
        el.attr('title', data.title)
          .attr('data-toggle', 'tooltip')
          .attr('data-placement', data.placement || 'bottom');
        el.tooltip({container: 'body'});
      });
      $(document).on('click', '.btn', function() {
        $(this).tooltip('hide');
      });
      $(document).on('mouseleave', '[data-toggle=\"tooltip\"]', function() {
        $(this).tooltip('hide');
      });

      // Bind raw target_score input to Shiny
      var targetScoreBinding = new Shiny.InputBinding();
      $.extend(targetScoreBinding, {
        find: function(scope) { return $(scope).find('#target_score'); },
        getValue: function(el) { return $(el).val(); },
        subscribe: function(el, callback) {
          $(el).on('change.targetScore keyup.targetScore', function() { callback(); });
        },
        unsubscribe: function(el) { $(el).off('.targetScore'); }
      });
      Shiny.inputBindings.register(targetScoreBinding, 'targetScore');

      // Similarity edit mode
      $(document).on('click', '#similarity-display', function(e) {
        e.stopPropagation();
        $('#similarity-display').hide();
        $('#similarity-edit').show();
        $('#target_score').val('').focus();
      });
      $(document).on('keydown', '#target_score', function(e) {
        if (e.key === 'Enter') {
          e.preventDefault();
          // Force Shiny to pick up current value before triggering click
          $(this).trigger('change');
          setTimeout(function() { $('#find_match').click(); }, 50);
        } else if (e.key === 'Escape') {
          e.preventDefault();
          $('#similarity-edit').hide();
          $('#similarity-display').show();
        }
      });
      $(document).on('click', function(e) {
        if ($('#similarity-edit').is(':visible') &&
            !$(e.target).closest('#similarity-edit').length) {
          $('#similarity-edit').hide();
          $('#similarity-display').show();
        }
      });
      Shiny.addCustomMessageHandler('setFixedSide', function(side) {
        if (side === 1) {
          $('#fix_left').addClass('fix-active');
          $('#fix_right').removeClass('fix-active');
        } else {
          $('#fix_right').addClass('fix-active');
          $('#fix_left').removeClass('fix-active');
        }
      });
      Shiny.addCustomMessageHandler('showSimilarity', function(data) {
        $('#similarity-edit').hide();
        $('#similarity-display').show();
      });
    ")),
    tags$style(HTML("
      body {
        font-family: 'Inter', -apple-system, BlinkMacSystemFont, sans-serif;
        background-color: #f0f2f5;
      }
      .container-fluid {
        max-width: 1100px;
      }
      h3 {
        font-weight: 700;
        letter-spacing: -0.5px;
        color: #2c3e50;
        margin-bottom: 0;
      }
      .similarity-badge {
        font-size: 28pt;
        font-weight: 700;
        color: #2c3e50;
        background: white;
        border-radius: 16px;
        padding: 8px 20px;
        box-shadow: 0 2px 8px rgba(0,0,0,0.08);
        display: inline-block;
        margin-top: 10px;
      }
      #similarity-display {
        cursor: pointer;
        position: relative;
        transition: background 0.15s ease;
      }
      #similarity-display:hover {
        background: #f8f9fa;
        border-radius: 16px;
      }
      #similarity-display::after {
        content: '\\1F50D';
        position: absolute;
        top: 4px;
        right: 6px;
        font-size: 14px;
        color: #aaa;
        opacity: 0;
        transition: opacity 0.15s ease;
      }
      #similarity-display:hover::after {
        opacity: 1;
      }
      #similarity-edit .score-input {
        font-size: 28pt;
        font-weight: 700;
        color: #2c3e50;
        background: transparent;
        border: none;
        border-bottom: 3px solid #3498db;
        outline: none;
        width: 80px;
        text-align: center;
        padding: 0;
        margin: 0;
      }
      #similarity-edit .score-suffix {
        font-size: 28pt;
        font-weight: 700;
        color: #2c3e50;
      }
      .fix-toggle {
        font-size: 9pt !important;
        padding: 3px 10px !important;
        color: #888 !important;
        background-color: #e9ecef !important;
        border-radius: 20px !important;
        margin-top: 6px !important;
        transition: all 0.15s ease !important;
      }
      .fix-toggle.fix-active {
        color: white !important;
        background-color: #3498db !important;
      }
      .fix-label {
        font-size: 8pt;
        color: #aaa;
        margin-top: 8px;
        margin-bottom: 2px;
      }
      #find_match {
        font-size: 9pt !important;
        padding: 3px 14px !important;
        color: white !important;
        background-color: #3498db !important;
        border-radius: 20px !important;
        margin-top: 6px !important;
        margin-left: 4px !important;
      }
      .pokemon-image {
        background: white;
        border-radius: 16px;
        padding: 12px;
        box-shadow: 0 2px 8px rgba(0,0,0,0.08);
        display: inline-block;
      }
      .btn {
        border-radius: 8px !important;
        transition: opacity 0.15s ease;
        border: none !important;
      }
      .btn:hover {
        opacity: 0.85;
      }
      .selectize-input {
        border-radius: 10px !important;
        border: 2px solid #e0e0e0 !important;
        padding: 6px 12px !important;
        font-size: 11pt !important;
      }
      .selectize-input.focus {
        border-color: #3498db !important;
        box-shadow: 0 0 0 3px rgba(52,152,219,0.15) !important;
      }
      .selectize-dropdown {
        border-radius: 10px !important;
        border: 2px solid #e0e0e0 !important;
        box-shadow: 0 4px 12px rgba(0,0,0,0.1) !important;
      }
      table.dataTable {
        background: white;
        border-radius: 12px !important;
        overflow: hidden;
        box-shadow: 0 2px 8px rgba(0,0,0,0.08);
      }
      table.dataTable td {
        font-family: 'Inter', sans-serif !important;
      }
      .checkbox label {
        font-size: 11pt;
        color: #2c3e50;
        font-weight: 600;
      }
      .tooltip .tooltip-arrow {
        display: none !important;
      }
    "))
  ),

  fluidRow(
    column(3),
    column(6,
           titlePanel(h3("Pokémon Similarity Tool", align="center"))),
    column(3)
  ),
  br(),

  fluidRow(
    column(4, align="center",
           selectizeInput("pokemon1", NULL, table$Name, selected="Charizard",
                          options=list(render=dropdown_render)),
           actionButton("randomize1", "", icon=icon("random"),
                        style='font-size:9pt; padding-left:20px; padding-right:20px; padding-top:3px; padding-bottom:3px; margin-top:-18px; color:white; background-color:rgb(51,183,122); border-color:white'),
           bsTooltip("randomize1", "Randomize")),
    column(1, style='padding:2px',
           actionButton("most_similar1",
                        "", icon=icon("angle-double-up"), width='100%',
                        style='font-size:10pt; padding:2px; margin:0px; color:white; background-color:rgb(51,122,183); border-color:white'),
           br(),
           actionButton("next_similar1",
                        "", icon=icon("angle-up"), width='100%',
                        style='font-size:10pt; padding:0px; margin-top:-4px; color:white; background-color:rgb(120, 180, 240); border-color:white'),
           br(),
           actionButton("next_dissimilar1",
                        "", icon=icon("angle-down"), width='100%',
                        style='font-size:10pt; padding:0px; margin-top:-6px; color:white; background-color:rgb(120, 180, 240); border-color:white'),
           br(),
           actionButton("most_dissimilar1",
                        "", icon=icon("angle-double-down"), width='100%',
                        style='font-size:10pt; padding:2px; margin-top:-4px; color:white; background-color:rgb(51,122,183); border-color:white')),
    column(2, align="center",
           div(id="similarity-display", class="similarity-badge",
               textOutput(outputId = 'similarity', inline=TRUE)),
           div(id="similarity-edit", style="display:none; text-align:center; margin-top:10px",
               div(class="similarity-badge", style="padding:8px 12px",
                   tags$input(id="target_score", type="text", class="score-input",
                              placeholder="85", maxlength="4"),
                   tags$span("%", class="score-suffix")),
               div(class="fix-label", "Find match for:"),
               div(actionButton("fix_left", "Charizard", class="fix-toggle fix-active"),
                   actionButton("fix_right", "Blastoise", class="fix-toggle")),
               div(actionButton("find_match", "Go")))),
    column(1, style='padding:2px',
           actionButton("most_similar2",
                        "", icon=icon("angle-double-up"), width='100%',
                        style='font-size:10pt; padding:2px; margin:0px; color:white; background-color:rgb(51,122,183); border-color:white'),
           br(),
           actionButton("next_similar2",
                        "", icon=icon("angle-up"), width='100%',
                        style='font-size:10pt; padding:0px; margin-top:-4px; color:white; background-color:rgb(120, 180, 240); border-color:white'),
           br(),
           actionButton("next_dissimilar2",
                        "", icon=icon("angle-down"), width='100%',
                        style='font-size:10pt; padding:0px; margin-top:-6px; color:white; background-color:rgb(120, 180, 240); border-color:white'),
           br(),
           actionButton("most_dissimilar2",
                        "", icon=icon("angle-double-down"), width='100%',
                        style='font-size:10pt; padding:2px; margin-top:-4px; color:white; background-color:rgb(51,122,183); border-color:white')),
    column(4, align="center",
           selectizeInput("pokemon2", NULL, table$Name, selected="Blastoise",
                          options=list(render=dropdown_render)),
           actionButton("randomize2", "", icon=icon("random"),
                        style='font-size:9pt; padding-left:20px; padding-right:20px; padding-top:3px; padding-bottom:3px; margin-top:-18px; color:white; background-color:rgb(51,183,122); border-color:white'),
           bsTooltip("randomize2", "Randomize"))
  ),
  br(),

  fluidRow(column(4, align="center",
                  div(class="pokemon-image", imageOutput(outputId = 'image1', height="auto"))),
           column(4,align="center",
                  div(dataTableOutput(outputId = 'grid'), style="text-align:center"),
                  tags$head(tags$style(type = "text/css", "#grid th {display:none;}")),
                  tags$head(tags$style(type = "text/css", "#grid th {border-width: 5px;}"))),
           column(4, align="center",
                  div(class="pokemon-image", imageOutput(outputId = 'image2', height="auto")))
  ),
  br(),

  fluidRow(
    column(4),
    column(4, align="center",
           checkboxInput("scale_images", "Scale Images by Height", value = FALSE, width = NULL)),
    column(4)
  )

)

server <- function(input, output, session) {

  # Dynamic tooltips that include the Pokemon name
  setTooltip <- function(id, title, placement="bottom") {
    session$sendCustomMessage('setTooltip', list(id=id, title=title, placement=placement))
  }

  observe({
    name1 <- input$pokemon1
    if (!is.null(name1) && name1 != "") {
      setTooltip("most_similar1", paste("Most Similar to", name1), "left")
      setTooltip("next_similar1", paste("More Similar to", name1), "left")
      setTooltip("next_dissimilar1", paste("Less Similar to", name1), "left")
      setTooltip("most_dissimilar1", paste("Least Similar to", name1), "left")
    }
  })
  observe({
    name2 <- input$pokemon2
    if (!is.null(name2) && name2 != "") {
      setTooltip("most_similar2", paste("Most Similar to", name2), "right")
      setTooltip("next_similar2", paste("More Similar to", name2), "right")
      setTooltip("next_dissimilar2", paste("Less Similar to", name2), "right")
      setTooltip("most_dissimilar2", paste("Least Similar to", name2), "right")
    }
  })

  # Editable similarity: which side is fixed
  fixed_side <- reactiveVal(1)

  observeEvent(input$fix_left, { fixed_side(1) })
  observeEvent(input$fix_right, { fixed_side(2) })

  observe({
    name1 <- input$pokemon1
    name2 <- input$pokemon2
    if (!is.null(name1) && name1 != "") updateActionButton(session, "fix_left", label = name1)
    if (!is.null(name2) && name2 != "") updateActionButton(session, "fix_right", label = name2)
    session$sendCustomMessage('setFixedSide', fixed_side())
  })

  observeEvent(input$find_match, {
    target <- as.numeric(gsub("[^0-9.\\-]", "", input$target_score)) / 100
    if (is.na(target)) return()

    fixed_idx <- if (fixed_side() == 1) get_index1() else get_index2()
    scores <- cosine_scores[fixed_idx, ]
    scores[fixed_idx] <- NA  # exclude self
    match_idx <- which.min(abs(scores - target))

    if (fixed_side() == 1) {
      updateSelectizeInput(session, 'pokemon2', selected = table$Name[match_idx])
    } else {
      updateSelectizeInput(session, 'pokemon1', selected = table$Name[match_idx])
    }
    session$sendCustomMessage('showSimilarity', list())
  })

  get_index1 <- reactive({
    id <- which(table$Name == input$pokemon1)
    if (length(id) == 0) { id <- 3 }
    return(id)
    })
  get_index2 <- reactive({
    id <- which(table$Name == input$pokemon2)
    if (length(id) == 0) { id <- 6 }
    return(id)})

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
    updateSelectizeInput(session, 'pokemon1', selected=random_pkmn)
  })

  observeEvent(input$randomize2, {
    random_pkmn <- sample(table$Name, 1)
    updateSelectizeInput(session, 'pokemon2', selected=random_pkmn)
  })

  V_columns <- paste0("V",1:nrow(table))
  mismatch_column <- V_columns[nrow(table)]

  observeEvent(input$most_similar1, {
    match_id <- table$V1[get_index1()]
    if (match_id == get_index1()) {
      match_id <- table$V2[get_index1()]
    }
    updateSelectizeInput(session, 'pokemon2', selected=table$Name[match_id])
  })

  observeEvent(input$next_similar1, {
    current_rank <- match(get_index2(),table[get_index1(),V_columns,with=FALSE])
    next_rank <- max(current_rank-1, 1)
    V_next_rank <- paste0("V", next_rank)
    next_similar_id <- as.numeric(table[get_index1(),V_next_rank,with=FALSE])
    updateSelectizeInput(session, 'pokemon2', selected=table$Name[next_similar_id])
  })

  observeEvent(input$next_dissimilar1, {
    current_rank <- match(get_index2(),table[get_index1(),V_columns,with=FALSE])
    next_rank <- min(current_rank+1, nrow(table))
    V_next_rank <- paste0("V", next_rank)
    next_dissimilar_id <- as.numeric(table[get_index1(),V_next_rank,with=FALSE])
    updateSelectizeInput(session, 'pokemon2', selected=table$Name[next_dissimilar_id])
  })

  observeEvent(input$most_dissimilar1, {
    mismatch_id <- as.numeric(table[get_index1(), mismatch_column,with=FALSE])
    updateSelectizeInput(session, 'pokemon2', selected=table$Name[mismatch_id])
  })

  observeEvent(input$most_similar2, {
    match_id <- table$V1[get_index2()]
    if (match_id == get_index2()) {
      match_id <- table$V2[get_index2()]
    }
    updateSelectizeInput(session, 'pokemon1', selected=table$Name[match_id])
  })

  observeEvent(input$next_similar2, {
    current_rank <- match(get_index1(),table[get_index2(),V_columns,with=FALSE])
    next_rank <- max(current_rank-1, 1)
    V_next_rank <- paste0("V", next_rank)
    next_similar_id <- as.numeric(table[get_index2(),V_next_rank,with=FALSE])
    updateSelectizeInput(session, 'pokemon1', selected=table$Name[next_similar_id])
  })

  observeEvent(input$next_dissimilar2, {
    current_rank <- match(get_index1(),table[get_index2(),V_columns,with=FALSE])
    next_rank <- min(current_rank+1, nrow(table))
    V_next_rank <- paste0("V", next_rank)
    next_dissimilar_id <- as.numeric(table[get_index2(),V_next_rank,with=FALSE])
    updateSelectizeInput(session, 'pokemon1', selected=table$Name[next_dissimilar_id])
  })

  observeEvent(input$most_dissimilar2, {
    mismatch_id <- as.numeric(table[get_index2(), mismatch_column,with=FALSE])
    updateSelectizeInput(session, 'pokemon1', selected=table$Name[mismatch_id])
  })
}

shinyApp(ui, server)

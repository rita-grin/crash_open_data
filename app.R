library(shiny)
library(leaflet)
library(sf)
library(ggplot2)

library(dplyr)
library(stringr)

crashes_interactive <- readRDS("Outputs/crashes_interactive.rds")

crashes_interactive <- crashes_interactive %>%
  mutate(region = str_to_title(region)) %>% 
  filter(crashYear < 2025)

region_choices <- sort(unique(crashes_interactive$region))

# UI 
ui <- fluidPage(
  titlePanel("Crashes by region – map and severity"),
  sidebarLayout(
    sidebarPanel(
      selectInput(
        "region",
        "Region:",
        choices = region_choices,
        selected = region_choices[1]
      ),
      selectInput(
        "tla",
        "Territorial local authority (optional):",
        
        # update in server
        choices = c("All TLAs" = ""),   
        selected = ""
      ),
      sliderInput(
        "yearRange",
        "Crash year range:",
        min = min(crashes_interactive$crashYear, na.rm = TRUE),
        max = max(crashes_interactive$crashYear, na.rm = TRUE),
        value = c(2018, 2024),
        step = 1,
        sep = ""
      )
    ),
    mainPanel(
      leafletOutput("map", height = "600px"),
      br(),
      h4("Severe crashes (fatal/serious)"),
      plotOutput("plot_severe", height = "300px"),
      br(),
      h4("Non-severe crashes"),
      plotOutput("plot_nonsevere", height = "300px"),
      br(),
      h4("Crashes by TLA in selected region"),
      plotOutput("plot_tla_counts", height = "300px")
    )
  )
)

# SERVER
server <- function(input, output, session) {
  
  # ---------- filtered crashes for selected region + years ----------
  filtered_data <- reactive({
    df <- crashes_interactive %>%
      filter(
        region == input$region,
        crashYear >= input$yearRange[1],
        crashYear <= input$yearRange[2]
      )
    
    # If a specific TLA is chosen, filter further
    if (!is.null(input$tla) && nzchar(input$tla)) {
      df <- df %>% filter(tlaName == input$tla)
    }
    
    df
  })
  
  observeEvent(input$region, {
    tla_choices <- crashes_interactive %>%
      filter(region == input$region) %>%
      distinct(tlaName) %>%
      arrange(tlaName) %>%
      pull(tlaName)
    
    updateSelectInput(
      session,
      "tla",
      choices  = c("All TLAs" = "", tla_choices),
      selected = ""
    )
  })
  
  summary_by_tla <- reactive({
    df <- filtered_data()
    if (nrow(df) == 0) return(NULL)
    
    df %>%
      group_by(tlaName) %>%
      summarise(
        total_crashes = n(),
        severe_crashes = sum(severity_cat == "Severe (fatal/serious)"),
        .groups = "drop"
      )
  })
  
  summary_by_period <- reactive({
    df <- filtered_data()
    
    if (nrow(df) == 0) return(NULL)
    
    df <- df %>%
      mutate(period = factor(period, levels = c("Pre", "Covid", "Post")))
    
    df %>%
      count(tlaName, period, severity_cat, name = "n") %>%
      group_by(tlaName, period) %>%
      mutate(prop = n / sum(n)) %>%
      ungroup()
  })
  
  summary_counts <- reactive({
    df <- filtered_data()
    if (nrow(df) == 0) return(NULL)
    
    df <- df %>%
      mutate(period = factor(period, levels = c("Pre", "Covid", "Post")))
    
    df %>%
      group_by(period) %>%
      summarise(
        # crashes
        crash_count = n(),
        severe_crash_count = sum(severity_bin == 1L, na.rm = TRUE),
        
        # persons: adjust column names if yours differ
        fatal_persons = sum(fatalCount,   na.rm = TRUE),
        serious_persons = sum(seriousCount, na.rm = TRUE),  
        # total persons involved (optional)
        total_persons = fatal_persons + serious_persons,
        
        severe_persons = fatal_persons + serious_persons,
        .groups = "drop"
      )
  })
  
  # ---------- map: crashes only  ----------
  output$map <- renderLeaflet({
    df <- filtered_data()
    
    if (nrow(df) == 0) {
      leaflet() %>%
        addTiles() %>%
        addPopups(0, 0, "No data for selected filters")
    } else {
      sf_4326 <- st_transform(df, 4326)
      
      pal <- colorFactor(
        palette = c("red", "grey40"),
        domain = c("Severe (fatal/serious)", "Non-severe")
      )
      
      leaflet(sf_4326) %>%
        addTiles() %>%
        addCircleMarkers(
          radius = 5,
          color = ~pal(severity_cat),
          stroke = FALSE,
          fillOpacity = 0.9,
          popup = ~paste(
            "Year:", crashYear, "<br>",
            "Severity:", crashSeverity
          )
        ) %>%
        addLegend(
          "bottomright",
          pal = pal,
          values = c("Severe (fatal/serious)", "Non-severe"),
          title = "Crash severity",
          opacity = 1
        )
    }
  })
  
  # ---------- plot: severe vs non-severe by period ----------
  output$plot_tla_counts <- renderPlot({
    s <- summary_by_tla()
    if (is.null(s)) {
      plot.new()
      text(0.5, 0.5, "No data for selected filters")
      return(invisible())
    }
    
    ggplot(s, aes(x = reorder(tlaName, total_crashes),
                  y = total_crashes)) +
      geom_col(fill = "steelblue") +
      coord_flip() +
      theme_minimal() +
      labs(
        title = paste("Crashes by TLA –", input$region),
        x = "TLA",
        y = "Number of crashes"
      )
  })
  
  output$plot_severe <- renderPlot({
    summary_df <- summary_by_period()
    
    if (is.null(summary_df)) {
      plot.new()
      text(0.5, 0.5, "No data for selected filters")
      return(invisible())
    }
    
    # only severe
    severe_df <- summary_df %>%
      filter(severity_cat == "Severe (fatal/serious)") %>%
      mutate(period = factor(period, levels = c("Pre", "Covid", "Post")))
    
    if (!is.null(input$tla) && nzchar(input$tla)) {
      severe_df <- severe_df %>% filter(tlaName == input$tla)
      
      ggplot(severe_df, aes(x = period, y = prop, group = 1)) +
        geom_line(linewidth = 1.2, colour = "red") +
        geom_point(size = 3, colour = "red") +
        theme_minimal() +
        labs(
          title = paste(
            "Severe crashes (proportion of all crashes) –",
            input$region, "/", input$tla
          ),
          x = "Period",
          y = "Severe crashes per crash"
        )
      
    } else {
      # ---- All TLAs: multiple lines, one per TLA ----
      ggplot(severe_df, aes(x = period, y = prop,
                            group = tlaName, colour = tlaName)) +
        geom_line(linewidth = 1.2) +
        geom_point(size = 2) +
        theme_minimal() +
        labs(
          title = paste(
            "Severe crashes (proportion of all crashes) –", input$region,
            "(all TLAs)"
          ),
          x = "Period",
          y = "Severe crashes per crash",
          colour = "TLA"
        )
    }
  })
  
  output$plot_nonsevere <- renderPlot({
    summary_df <- summary_by_period()
    
    if (is.null(summary_df)) {
      plot.new()
      text(0.5, 0.5, "No data for selected filters")
      return(invisible())
    }
    
    nonsev_df <- summary_df %>%
      filter(severity_cat == "Non-severe") %>%
      mutate(period = factor(period, levels = c("Pre", "Covid", "Post")))
    
    if (!is.null(input$tla) && nzchar(input$tla)) {
      # specific TLA
      nonsev_df <- nonsev_df %>% filter(tlaName == input$tla)
      
      ggplot(nonsev_df, aes(x = period, y = prop, group = 1)) +
        geom_line(linewidth = 1.2, colour = "grey30") +
        geom_point(size = 3, colour = "grey30") +
        theme_minimal() +
        labs(
          title = paste(
            "Non-severe crashes (proportion of all crashes) –",
            input$region, "/", input$tla
          ),
          x = "Period",
          y = "Non-severe crashes per crash"
        )
      
    } else {
      # all TLAs
      ggplot(nonsev_df, aes(x = period, y = prop,
                            group = tlaName, colour = tlaName)) +
        geom_line(linewidth = 1.2) +
        geom_point(size = 2) +
        theme_minimal() +
        labs(
          title = paste(
            "Non-severe crashes (proportion of all crashes) –",
            input$region, "(all TLAs)"
          ),
          x = "Period",
          y = "Non-severe crashes per crash",
          colour = "TLA"
        )
    }
  })
}

shinyApp(ui = ui, server = server)
library(shiny)
library(ggplot2)
library(dplyr)
library(splines)
library(babynames)

babynames <- babynames::babynames

ui <- fluidPage(
  sidebarLayout(
    sidebarPanel(
      p("Enter your favorite name:"),
      textInput("name", "")
    ),
    mainPanel(
      plotOutput("pop")
    )
  )
)



server <- function(input, output, session){
  
  data <- reactive({
    babynames %>%
      filter(tolower(name) == tolower(input$name)) %>% 
      group_by(year) %>% 
      summarize(n = sum(n))
  })
  
  output$pop <- renderPlot({
    data() %>% 
      ggplot(aes(x = year, y = n)) +
      geom_point(alpha = 0.4) +
      stat_smooth(method = glm, method.args = list(family = "quasipoisson"), 
                  formula = y ~ ns(x, 3)) + 
      labs(
        title = paste0("Popularity of ", input$name), 
        y = paste0("# of People Named ", input$name),
        x = "Year"
      ) +
      theme_minimal()
  })
} 

shinyApp(ui, server)


library(shiny)
library(ggplot2)
library(babynames)
library(dplyr)
library(readr)
library(splines)
# library(repoman)

# local({
#   repoman::list_packages()
# })

babynames <- read_csv('../babynames.csv', col_types = "iiccid")

ui <- fluidPage(
  sidebarLayout(
    sidebarPanel(
      p('Enter your favorite name:'),
      textInput('name', '')
    ),
    mainPanel(
      plotOutput('pop')
    )
  )
)

server <- function(input, output, session){
  
  data <- reactive({
    babynames %>%
      filter(tolower(name) == tolower(input$name)) %>% 
      select(year, n) %>% 
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
        y = paste0('# of People Named ', input$name),
        x = 'Year'
      ) +
      theme_minimal()
  })
} 

shinyApp(ui, server)


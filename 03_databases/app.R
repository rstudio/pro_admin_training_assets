library(shinydashboard)
library(dplyr)
library(dbplyr)
library(purrr)
library(shiny)
library(highcharter)
library(DT)
library(htmltools)

con <- DBI::dbConnect(odbc::odbc(), "Postgres Dev")

DBI::dbExecute(con,"SET search_path TO datawarehouse;")


# Use purrr's split() and map() function to create the list
# needed to display the name of the airline but pass its
# Carrier code as the value

airline_list <- tbl(con, "carrier") %>%
  collect()  %>%
  split(.$carriername) %>%
  map(~.$carrier)



ui <- dashboardPage(
  dashboardHeader(title = "Flights Dashboard",
                  titleWidth = 200),
  dashboardSidebar(
     selectInput(
        inputId = "airline",
        label = "Airline:", 
        choices = airline_list, 
        selectize = FALSE),
     sidebarMenu(
       selectInput(
         "month",
         label = "Month:", 
         choices = list(
           "All Year" = 99,
           "January" = 1,
           "February" = 2,
           "March" = 3,
           "April" = 4,
           "May" = 5,
           "June" = 6,
           "July" = 7,
           "August" = 8,
           "September" = 9,
           "October" = 10,
           "November" = 11,
           "December" = 12
         ) , 
         selected =  "All Year", 
         selectize = FALSE),
       actionLink("remove", "Remove detail tabs")
    )
  ),
  dashboardBody(
    tabsetPanel(id = "tabs",
                  tabPanel(
                    title = "Main Dashboard",
                    value = "page1",
                    fluidRow(
                      valueBoxOutput("total_flights"),
                      valueBoxOutput("per_day"),
                      valueBoxOutput("percent_delayed")
                    ),
                    fluidRow(
                      column(width = 7,
                             p(textOutput("monthly")),
                             highchartOutput("group_totals")),
                      column(width = 5,
                             p("Click on an airport in the plot to see the details"),
                             highchartOutput("top_airports"))
                    )
                  )
      )
  )
)


# helper functions --------------------------------------------------------

db_flights <-
  tbl(con, "flight") %>%
  left_join(tbl(con, "carrier"), by = c(uniquecarrier = "carrier")) %>% 
  rename(carrier = uniquecarrier) %>% 
  left_join(tbl(con, "airport"), by = c("origin" = "airport")) %>% 
  rename(origin_name = origin) %>% 
  select(-lat, -long) %>% 
  left_join(tbl(con, "airport"), by = c("dest" = "airport")) %>% 
  rename(
    dest_name = origin_name,
    day = dayofmonth) 

                      

total_flights <- function(db_flights, airline, month){
  result <- db_flights %>%
    filter(carrier == !!airline)
  
  if(month != 99) result <- filter(result, month == !!month)
  
  result %>%
    tally() %>%
    pull() %>% 
    as.integer()
}                  

flights_per_day <- function(db_flights, airline, month){
  result <- db_flights %>%
    filter(carrier == !!airline)
  
  if(month != 99) result <- filter(result, month == !!month)
  
  result %>%
    group_by(day) %>%
    tally() %>%
    summarise(avg = mean(n)) %>%
    pull(avg) %>% 
    round(0)
}


fraction_delayed <- function(db_flights, airline, month){
  result <- db_flights %>%
    filter(carrier == !!airline)
  
  if(month != 99) result <- filter(result, month == !!month)
  
  result %>%
    mutate(delayed = if_else(depdelay >= 15, 1, 0)) %>%
    summarise(delays = sum(delayed),
              total = n()) %>%
    mutate(percent = delays / total) %>%
    pull()
}


# shiny server code -------------------------------------------------------



server <- function(input, output, session) { 
  
  tab_list <- NULL

  # Preparing the data by pre-joining flights to other
  # tables and doing some name clean-up

  output$monthly <- renderText({
    if(input$month == "99")"Click on a month in the plot to see the daily counts"
  })
  
  output$total_flights <- renderValueBox({
    # The following code runs inside the database
    result <- total_flights(db_flights, input$airline, input$month)
    valueBox(value = prettyNum(result, big.mark = ","),
             subtitle = "Number of Flights")
  })
  
  
  output$per_day <- renderValueBox({
    
    # The following code runs inside the database
    result <- flights_per_day(db_flights, input$airline, input$month)
    
    valueBox(prettyNum(result, big.mark = ","),
             subtitle = "Average flights per day",
             color = "blue")
  })
  
  
  
  output$percent_delayed <- renderValueBox({
    
    # The following code runs inside the database
    result <- fraction_delayed(db_flights, input$airline, input$month)
    
    valueBox(paste0(round(result * 100), "%"),
             subtitle = "Flights delayed",
             color = "teal")
  })
  
  # Events in Highcharts can be tracked using a JavaScript. For data points in a plot, the 
  # event.point.category returns the value that is used for an additional filter, in this case
  # the month that was clicked on.  A paired observeEvent() command is activated when
  # this java script is executed
  js_click_line <- JS("function(event) {Shiny.onInputChange('line_clicked', [event.point.category]);}")
  
  output$group_totals <- renderHighchart({
    
  if(input$month != 99) {
      result <- db_flights %>%
        filter(month == !!input$month,
               carrier == !!input$airline) %>%
        group_by(day) %>%
        tally() %>%
        collect()
      group_name <- "Daily"
    } else {
      result <- db_flights %>%
        filter(carrier == !!input$airline) %>%
        group_by(month) %>%
        tally() %>%
        collect()    
      group_name <- "Monthly"
    } 
    
    highchart() %>%
      hc_add_series(
        data = result$n, 
        type = "line",
        name = paste(group_name, " total flights"),
        events = list(click = js_click_line)) 
    
    
  })
  
  # Tracks the JavaScript event created by `js_click_line`
  observeEvent(input$line_clicked != "",
               if(input$month == 99)
                 updateSelectInput(session, "month", selected = input$line_clicked),
                 ignoreInit = TRUE)
  
  js_bar_clicked <- JS("function(event) {Shiny.onInputChange('bar_clicked', [event.point.category]);}")
  
  output$top_airports <- renderHighchart({
    # The following code runs inside the database
    result <- db_flights %>%
      filter(carrier == !!input$airline) 
    
    if(input$month != 99) result <- filter(result, month == !!input$month) 
    
    result <- result %>%
      group_by(dest_name) %>%
      tally() %>%
      arrange(desc(n)) %>%
      collect() %>%
      head(10)
    
    highchart() %>%
      hc_add_series(
        data = result$n, 
        type = "bar",
        name = paste("No. of Flights"),
        events = list(click = js_bar_clicked)) %>%
      hc_xAxis(
        categories = result$dest_name,
        tickmarkPlacement="on")
    
    
})
  
  observeEvent(input$bar_clicked,
               {
                 airport <- input$bar_clicked[1]
                 message(airport)
                 tab_title <- paste(input$airline, 
                                    "-", airport , 
                                    if(input$month != 99) paste("-" , month.name[as.integer(input$month)]))
                 
                 if(tab_title %in% tab_list == FALSE){
                   details <- db_flights %>%
                     filter(dest_name == !!airport,
                            carrier == !!input$airline)
                   
                   if(input$month != 99) details <- filter(details, month == !!input$month) 
                   
                   details <- details %>%
                     head(100) %>% 
                     select(month,
                            day,
                            flightid,
                            tailnum,
                            deptime,
                            arrtime,
                            dest_name,
                            distance) %>%
                     collect() %>%
                     mutate(month = month.name[as.integer(month)])
                   
                   
                   appendTab(inputId = "tabs",
                             tabPanel(
                               tab_title,
                               DT::renderDataTable(details)
                             ))
                   
                   tab_list <<- c(tab_list, tab_title)
                                      
                 }

                 updateTabsetPanel(session, "tabs", selected = tab_title)
                 
               })
  
  observeEvent(input$remove,{
    # Use purrr's walk command to cycle through each
    # panel tabs and remove them
    tab_list %>%
      walk(~removeTab("tabs", .x))
    tab_list <<- NULL
  })
  
}



shinyApp(ui, server)

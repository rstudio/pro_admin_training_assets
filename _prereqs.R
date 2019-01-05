pkgs <- c(
  "tidyverse",
  "babynames",
  "splines",
  
  "repoman", 
  "shiny",
  "shinydashboard",
  "dbplyr",
  "highcharter",
  "DT",
  "htmltools",
  
  "quantmod",
  "dygraphs",
  "forecast",
  "highcharter",
  
  "odbc",
  
  "plumber"
)

not_installed <- setdiff(pkgs, as.data.frame(installed.packages())$Package)
install.packages(not_installed)

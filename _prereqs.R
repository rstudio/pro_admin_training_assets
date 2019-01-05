# Install pre-reqs

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

for (pkg in pkgs) {
  if (!requireNamespace(pkg, quietly = TRUE)) install.packages(pkg)
}
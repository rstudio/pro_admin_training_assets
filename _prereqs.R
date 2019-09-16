# Use RStudio Package Manager binary package installation
# https://docs.rstudio.com/rspm/1.0.12/admin/binaries.html#binary-user-agents

options(repos = RSPM)
RSPM <- c(CRAN = "http://cluster.rstudiopm.com/cran/__linux__/bionic/latest")

# Set the default HTTP user agent
options(HTTPUserAgent = sprintf("R/%s R (%s)", getRversion(), 
                                paste(getRversion(), R.version$platform, R.version$arch, R.version$os)))

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

#Fix Windows UTF‑8 locale issue
#check required data file, 
#then launch Shiny dashboard locally.

if (.Platform$OS.type=="windows" && !l10n_info()[["UTF-8"]]) {
  candidate <- suppressWarnings(Sys.setlocale("LC_CTYPE","Chinese (Simplified)_China.utf8"))
  if (is.na(candidate)||candidate=="") {
    suppressWarnings(Sys.setlocale("LC_CTYPE","English_United States.utf8"))
  }
}
if (!file.exists("outputs/dashboard_data.rds")) stop("Run source('render.R') first.")
shiny::runApp(".",host="127.0.0.1",port=getOption("fuelwatch.port"),launch.browser=interactive())


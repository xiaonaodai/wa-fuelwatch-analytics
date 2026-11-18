#Check required R packages.
#Install pandoc if unavailable.

packages <- c("data.table","ggplot2","e1071","pROC","ROCR","lime","gridExtra","cluster","knitr",
              "rmarkdown","shiny","DT","pandoc")
missing <- packages[!vapply(packages,requireNamespace,logical(1),quietly=TRUE)]
if (length(missing)) install.packages(missing,repos="https://cloud.r-project.org")
if (!rmarkdown::pandoc_available()) {
  versions <- pandoc::pandoc_installed_versions()
  if (!length(versions)) {
    if (!requireNamespace("gh",quietly=TRUE)) install.packages("gh",repos="https://cloud.r-project.org")
    pandoc::pandoc_install()
  }
}
message("Dependencies ready. Run source('render.R').")


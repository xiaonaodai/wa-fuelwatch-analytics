#Check if project file exists and pandoc is ready. 
#Render Rmd to HTML. If pandoc not found, throw error and tell user to run setup script.
if (!file.exists("project.Rmd")) stop("Set working directory to the project folder.")
if (!requireNamespace("rmarkdown",quietly=TRUE)) stop("Run source('setup.R') first.")
render_project <- function() {
  rmarkdown::render("project.Rmd",output_file="FuelWatch_Analysis_Report.html",
                    envir=new.env(parent=globalenv()),quiet=FALSE)
}
if (rmarkdown::pandoc_available()) {
  render_project()
} else if (requireNamespace("pandoc",quietly=TRUE) &&
           length(pandoc::pandoc_installed_versions())) {
  pandoc::with_pandoc_version(tail(pandoc::pandoc_installed_versions(),1),render_project())
} else stop("Pandoc is missing. Run source('setup.R') or render from RStudio.")



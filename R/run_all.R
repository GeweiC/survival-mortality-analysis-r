# Run this from the project root in RStudio or the R terminal:
# source("R/run_all.R")
required_data <- c(file.path("data", "heart.csv"), file.path("data", "mortality.csv"))
missing_data <- required_data[!file.exists(required_data)]
if (length(missing_data)) {
  stop("Add the two locally supplied CSVs before running: ", paste(missing_data, collapse = ", "),
       "\nRead data/README.md for instructions.")
}
if (!requireNamespace("survival", quietly = TRUE)) stop("Install: install.packages('survival')")
for (script in c("01_heart_survival.R", "02_lung_survival.R", "03_mortality_life_tables.R")) {
  cat("\n== Running ", script, " ==\n", sep = "")
  source(file.path("R", script), local = new.env(parent = globalenv()))
}
cat("\nDone: inspect results/ and figures/.\n")

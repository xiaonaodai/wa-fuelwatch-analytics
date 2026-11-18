# Dataset Guide: Western Australia FuelWatch Historical Data

## Data Source
The raw monthly fuel price records are published as open data by the Western Australian Government:
- Portal: [FuelWatch Historical Data](https://www.fuelwatch.wa.gov.au/retail/historic)
- Time Window Covered: January 2023 to August 2026 (44 consecutive months)

## Why Raw CSVs Are Excluded from Git
Each monthly CSV is approximately 8–11 MB, resulting in over 380 MB of raw tabular data across the 44-month study period. To keep this repository lightweight and fast to clone, raw `.csv` files are ignored by git (`datasets/*.csv`).

## Instant Demo (No Download Needed)
If you only wish to explore the interactive Shiny dashboard, you do **not** need the raw CSV files! 
The repository includes preprocessed summaries in `outputs/dashboard_data.rds` (~1.2 MB). You can immediately launch the application via:
```R
source("run_app.R")
```

## Reproducing Full Pipeline from Raw Data
To re-run the full end-to-end data pipeline (`project.Rmd` / `render.R`):
1. Download the historical monthly files (`FuelWatchRetail-MM-YYYY.csv`) for `01-2023` through `08-2026` from the official portal.
2. Place the CSV files directly inside this `datasets/` folder.
3. Execute `source("render.R")` in R or RStudio.

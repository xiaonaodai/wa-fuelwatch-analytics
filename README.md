# Western Australia Fuel Price Analytics & Prediction

An end-to-end computational data analysis study and interactive Shiny dashboard examining over 3.7 million retail fuel price records across Western Australia (January 2023 – August 2026).

---

## Highlights

- **Large-Scale Data Pipeline**: Ingested, validated, and harmonized 44 consecutive months of retail price notifications from open government records using `data.table`.
- **Predictive Classification**: Built and compared Naive Bayes and Support Vector Machine (SVM) models to identify relatively cheap Regular Unleaded Petrol (ULP) sites without observing contemporaneous prices.
- **Leakage Prevention**: Engineered station history features using out-of-fold Laplace-smoothed target encoding across date folds.
- **Temporal Stability (YoY vs. MoM)**: Evaluated performance differences between year-over-year (seasonal) and month-over-month (recent trend) training partitions.
- **Model Explainability**: Leveraged LIME (Local Interpretable Model-agnostic Explanations) to interpret individual classification boundaries.
- **Station Profiling via Clustering**: Clustered service stations by pricing behavior and evaluated stability across distinct time windows using Adjusted Rand Index (ARI) and silhouette validation.
- **Interactive Shiny Dashboard**: Self-contained web interface with custom styling, multi-filter exploration, and station clustering views.

---

## Repository Structure

```text
wa-fuelwatch-analytics/
├── app.R                         # Shiny dashboard application
├── run_app.R                     # One-click Shiny launcher
├── project.Rmd                   # Comprehensive end-to-end analysis script
├── render.R                      # Script to render project.Rmd into HTML
├── setup.R                       # Dependency check and installer
├── FuelWatch_Analysis_Report.html# Pre-rendered full analysis report
├── outputs/
│   └── dashboard_data.rds        # Preprocessed data powering the dashboard (~1.2 MB)
├── datasets/
│   └── README.md                 # Data provenance and download instructions
├── .gitignore                    # Excludes temporary files and raw large CSVs
└── README.md
```

---

## Quick Start: Launch Dashboard in 10 Seconds

You do **not** need to download the 380+ MB raw CSV files to experience the project. The preprocessed analytical summaries are bundled in `outputs/dashboard_data.rds`.

### Prerequisites
Make sure R is installed. Install required packages:
```r
source("setup.R")
```

### Launch Interactive App
Run the following in R or your terminal:
```r
source("run_app.R")
```
The browser will automatically open with the dashboard at `http://127.0.0.1:port`.

---

## Reproducing the Full Pipeline

If you want to re-run the complete data cleaning, modeling, and HTML report generation:
1. Refer to [datasets/README.md](datasets/README.md) to download the historical monthly CSV files (`01-2023` to `08-2026`).
2. Place the CSV files inside the `datasets/` folder.
3. Run:
```r
source("render.R")
```
This produces `FuelWatch_Analysis_Report.html` containing all code, tables, and ggplot2 visualizations.

---

## Core Findings

1. **Station Track Record Dominates**: Historical station-level cheap frequency is the single most predictive feature for identifying low prices.
2. **Recent Trends Beat Seasonal History**: Models trained on recent continuous months (MoM) consistently outperform year-over-year (YoY) models on test data, as pricing cycles and station dynamics evolve quickly.
3. **Regional vs. Metro Divergence**: Metropolitan fuel prices exhibit high volatility with pronounced cycle swings, whereas regional stations exhibit slower, stickier price adjustments.

---

## License

This project is licensed under the MIT License.

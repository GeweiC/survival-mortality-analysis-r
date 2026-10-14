# Generated results

Run `source("R/run_all.R")` from the project root to create CSV files here:

- `heart_km_100day.csv` — Kaplan–Meier estimates, Greenwood log-scale variance and 95% intervals at day 100.
- `heart_cox_full.csv`, `heart_cox_reduced.csv`, `heart_cox_final.csv` — Cox coefficients and hazard ratios.
- `heart_cox_ph_diagnostics.csv` — Schoenfeld proportional-hazards checks.
- `lung_tie_counts.csv`, `lung_cox_ties_comparison.csv` — tied-event summary and exact vs Efron comparison.
- `lung_aft_final.csv` (+ `lung_aft_log_scale.csv` when available) — Weibull AFT model estimates and confidence intervals.
- `pension_mortality_full.csv`, `pension_life_table_5yr.csv` — central death rates, annual death probabilities and life tables.

No derived output tables are pre-shipped because the R scripts have not been executed in this packaging environment. Publicly sharing pension-scheme outputs should be considered separately from sharing the code.

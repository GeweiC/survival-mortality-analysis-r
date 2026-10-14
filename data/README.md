# Input data (not redistributed)

The two CSV inputs were supplied for university coursework. **They are intentionally omitted from this public-ready archive.** Redistribution rights have not been established, and the heart cohort contains individual-level health records.

To reproduce the full project, place your own authorised copies here with exactly these names:

- `data/heart.csv` — the original MATH3085 `heart.csv` cohort (299 rows, 13 columns); the previously supplied file was named `heart(1).csv`, so rename it locally.
- `data/mortality.csv` — the original MATH3085 pension-scheme age-specific deaths and exposure table (ages 60–102 in the supplied file).

The R package `survival` includes `survival::lung`, so no separate `lung.csv` is needed.

## Expected heart.csv fields

`TIME`, `Event`, `Gender`, `Smoking`, `Diabetes`, `BP`, `Anaemia`, `Age`, `Ejection.Fraction`, `Sodium`, `Creatinine`, `Pletelets`, `CPK`.

The supplied heart file spells `Pletelets` with this exact spelling. The scripts retain the name to remain compatible with the original file.

**Non-standard event convention:** Coursework instructions specify that death (`Event=1`) is *censored* and a record coded `Event=0` is considered an observed transition. Thus the heart workflow explicitly fits `Surv(TIME, Event==0)` (represented in code by a new `transition_observed` column). It does **not** estimate conventional mortality survival. This is a specific coursework assumption, not a general recommendation for heart-failure clinical analyses.

## Expected mortality.csv fields

`Age (x)`, `Female exposed`, `Female deaths`, `Male exposed`, `Male deaths`.

The mortality table was supplied as a pension-scheme dataset, so check its redistribution rights separately before sharing.

## Missing data

The main scripts will stop with a clear error if the necessary private CSV files have not been added to `data/`. The `02_lung_survival.R` analysis can run independently after installing `survival`.

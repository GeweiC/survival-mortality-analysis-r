# Methodological notes and careful interpretation

This portfolio adapts a completed MATH3085 university data-analysis assignment. The original question paper, full coursework report, and participant-level/pension-scheme data are deliberately not included.

## Heart cohort: unusually defined event

The assignment explicitly instructs analysts to treat patient deaths as non-informative censoring and the alternative outcome as the observed transition. Hence `Event == 0` is used as the event indicator for `Surv()`. This is an exercise-specific coding convention and can be inappropriate for a real-world mortality analysis or for competing-risk clinical research.

The 100-day Kaplan–Meier survival estimates in the original report were 0.7606 (non-smoking) and 0.7842 (smoking), calculated under that assignment convention. **Overlapping confidence intervals alone are not a hypothesis test of group equality.** Without a formal group comparison, do not claim that smoking definitively has no association with transition time.

The original report selected BP and Anaemia in a reduced Cox model and reported HRs of approximately 1.7464 and 1.4349, respectively, for the *defined transition event*. Those HRs should not be described as relative hazards of death. The Schoenfeld diagnostic global p-value was approximately 0.40; this is a failure to find strong evidence against proportionality, not proof that it holds perfectly.

## Lung analysis

The original analysis compared exact partial likelihood with Efron handling for tied failure times, and evaluated a Weibull accelerated failure-time model. Its selected AFT model uses `sex + ph.ecog`. All estimation is performed using the publicly bundled `survival::lung` data provided by the R `survival` package.

## Pension life tables

Crude central death rates use `m_x = deaths_x / central_exposure_x` (unscaled). Constant force assumes `q_x = 1 - exp(-m_x)` and uniform distribution of deaths (UDD) assumes `q_x = m_x / (1 + m_x/2)`.

A transcription / column-label alignment issue was found in the original report's 5-year life table: the data-derived columns actually correspond to male constant-force, female constant-force, male UDD and female UDD, whereas the report interleaves labels differently. The restructured script outputs all four columns with explicit names and consistent ordering. It does not silently copy the labelled report table.

## Reproducibility status

Source CSV shapes and the 100-day heart Kaplan–Meier estimates were independently checked while preparing the portfolio. An R runtime was unavailable in the packaging environment; therefore **the R scripts are not claimed to have been executed or fully validated here**. Run them in RStudio locally and compare the output against your coursework report before publishing generated outputs.

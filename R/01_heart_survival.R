# Heart-failure cohort: Kaplan-Meier and Cox proportional hazards models.
# IMPORTANT: coursework defines death (Event = 1) as censoring and Event = 0
# as the observed transition. This is not conventional death-event analysis.

if (!requireNamespace("survival", quietly = TRUE)) {
  stop("Install the survival package: install.packages('survival')")
}
if (!file.exists(file.path("data", "heart.csv"))) {
  stop("Missing data/heart.csv; see data/README.md")
}
dir.create("results", showWarnings = FALSE, recursive = TRUE)
dir.create("figures", showWarnings = FALSE, recursive = TRUE)

heart <- read.csv(file.path("data", "heart.csv"), check.names = TRUE)
required <- c("TIME", "Event", "Smoking", "BP", "Anaemia", "Ejection.Fraction")
if (!all(required %in% names(heart))) stop("Missing heart columns: ", paste(setdiff(required, names(heart)), collapse = ", "))
if (anyNA(heart) || any(heart$TIME <= 0) ||
    !all(heart$Event %in% 0:1) || !all(heart$Smoking %in% 0:1)) {
  stop("Heart data contain missing or invalid values")
}

# The coursework-defined transition indicator; 1 = transition observed.
heart$transition_observed <- as.integer(heart$Event == 0L)
km_fit <- survival::survfit(
  survival::Surv(TIME, transition_observed) ~ Smoking, data = heart
)

png(file.path("figures", "heart_kaplan_meier_smoking.png"), width = 1200, height = 800, res = 140)
plot(km_fit, col = c("#1E7497", "#D97742"), lwd = 2.5,
     xlab = "Follow-up time (days)", ylab = "Estimated probability of no transition",
     main = "Kaplan-Meier estimates by smoking status", mark.time = TRUE)
legend("topright", legend = c("Non-smoking", "Smoking"),
       col = c("#1E7497", "#D97742"), lty = 1, lwd = 2.5, bty = "n")
mtext("Coursework convention: death (Event = 1) is censored", side = 1, line = 4, cex = 0.75)
dev.off()

# The 95% interval below uses the log-scale Greenwood formula from the report.
km_at_day <- function(df, day = 100L) {
  fit <- survival::survfit(survival::Surv(TIME, transition_observed) ~ 1, data = df)
  estimate <- as.numeric(summary(fit, times = day, extend = TRUE)$surv[1])
  selected <- fit$time <= day
  at_risk <- fit$n.risk[selected]
  n_events <- fit$n.event[selected]
  if (any(at_risk <= n_events)) stop("Greenwood log variance undefined for a zero risk set")
  greenwood_log_var <- sum(n_events / (at_risk * (at_risk - n_events)))
  margin <- qnorm(0.975) * sqrt(greenwood_log_var)
  c(estimate = estimate,
    lower_95 = max(0, estimate * exp(-margin)),
    upper_95 = min(1, estimate * exp(margin)),
    greenwood_log_variance = greenwood_log_var)
}
km_results <- rbind(
  data.frame(group = "Non-smoking", t(km_at_day(subset(heart, Smoking == 0L)))),
  data.frame(group = "Smoking", t(km_at_day(subset(heart, Smoking == 1L))))
)
write.csv(km_results, file.path("results", "heart_km_100day.csv"), row.names = FALSE)

# Explicitly specify explanatory variables to avoid accidentally including an
# outcome indicator as a predictor.
explanatory <- setdiff(names(heart), c("TIME", "Event", "transition_observed"))
full_formula <- reformulate(explanatory, response = "survival::Surv(TIME, transition_observed)")
cox_full <- survival::coxph(full_formula, data = heart)
cox_reduced <- survival::coxph(
  survival::Surv(TIME, transition_observed) ~ BP + Anaemia + Ejection.Fraction,
  data = heart
)
cox_final <- survival::coxph(
  survival::Surv(TIME, transition_observed) ~ BP + Anaemia, data = heart
)

cox_summary <- function(fit) {
  b <- coef(fit)
  se <- sqrt(diag(vcov(fit)))
  z <- qnorm(0.975)
  data.frame(term = names(b), estimate = as.numeric(b),
             hazard_ratio = as.numeric(exp(b)),
             ci_95_lower = as.numeric(exp(b - z * se)),
             ci_95_upper = as.numeric(exp(b + z * se)),
             p_value = as.numeric(summary(fit)$coefficients[, "Pr(>|z|)"]),
             row.names = NULL)
}
write.csv(cox_summary(cox_full), file.path("results", "heart_cox_full.csv"), row.names = FALSE)
write.csv(cox_summary(cox_reduced), file.path("results", "heart_cox_reduced.csv"), row.names = FALSE)
write.csv(cox_summary(cox_final), file.path("results", "heart_cox_final.csv"), row.names = FALSE)

ph_check <- survival::cox.zph(cox_final)
ph_table <- data.frame(term = rownames(ph_check$table),
                       chi_square = ph_check$table[, "chisq"],
                       df = ph_check$table[, "df"],
                       p_value = ph_check$table[, "p"], row.names = NULL)
write.csv(ph_table, file.path("results", "heart_cox_ph_diagnostics.csv"), row.names = FALSE)
png(file.path("figures", "heart_schoenfeld_diagnostics.png"), width = 1250, height = 600, res = 135)
par(mfrow = c(1, 2), mar = c(4, 4, 2, 1))
plot(ph_check, col = "#1E7497")
dev.off()

cat("Heart analysis complete: ", nrow(heart), " records.\n", sep = "")
print(km_results)
print(cox_summary(cox_final))
print(ph_table)

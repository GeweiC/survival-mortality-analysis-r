# Built-in NCCTG lung cancer data: Cox PH, tied-event handling and AFT.
if (!requireNamespace("survival", quietly = TRUE)) {
  stop("Install the survival package: install.packages('survival')")
}
dir.create("results", showWarnings = FALSE, recursive = TRUE)
dir.create("figures", showWarnings = FALSE, recursive = TRUE)

lung_data <- survival::lung
# In survival::lung, status 1 = censored, status 2 = death; Surv handles this.
cox_full <- survival::coxph(survival::Surv(time, status) ~ ., data = lung_data)
cox_final <- survival::coxph(
  survival::Surv(time, status) ~ inst + sex + ph.ecog, data = lung_data
)

tie_freq <- table(lung_data$time)
tie_counts <- data.frame(
  tied_time_groups = sum(tie_freq > 1L),
  observations_at_tied_times = sum(tie_freq[tie_freq > 1L])
)
write.csv(tie_counts, file.path("results", "lung_tie_counts.csv"), row.names = FALSE)

cox_exact <- survival::coxph(
  survival::Surv(time, status) ~ inst + sex + ph.ecog,
  data = lung_data, ties = "exact"
)
cox_efron <- survival::coxph(
  survival::Surv(time, status) ~ inst + sex + ph.ecog,
  data = lung_data, ties = "efron"
)

coef_table <- function(fit, method) {
  b <- coef(fit)
  data.frame(method = method, term = names(b),
             coefficient = as.numeric(b),
             hazard_ratio = as.numeric(exp(b)), row.names = NULL)
}
write.csv(
  rbind(coef_table(cox_exact, "exact"), coef_table(cox_efron, "efron")),
  file.path("results", "lung_cox_ties_comparison.csv"), row.names = FALSE
)

# survreg defaults to Weibull for right-censored survival data; make it explicit.
aft_full <- survival::survreg(survival::Surv(time, status) ~ ., data = lung_data, dist = "weibull")
aft_final <- survival::survreg(
  survival::Surv(time, status) ~ sex + ph.ecog,
  data = lung_data, dist = "weibull"
)
aft_coeff <- coef(aft_final)
aft_se <- sqrt(diag(vcov(aft_final)))[seq_along(aft_coeff)]
aft_table <- data.frame(term = names(aft_coeff), coefficient = as.numeric(aft_coeff),
                        ci_95_lower = as.numeric(aft_coeff - qnorm(0.975) * aft_se),
                        ci_95_upper = as.numeric(aft_coeff + qnorm(0.975) * aft_se),
                        row.names = NULL)
write.csv(aft_table, file.path("results", "lung_aft_final.csv"), row.names = FALSE)

# The log(scale) entry is a separate parameter, not returned by coef().
log_scale <- log(aft_final$scale)
if (nrow(aft_final$var) == length(aft_coeff) + 1L) {
  scale_se <- sqrt(tail(diag(aft_final$var), 1L))
  log_scale_ci <- data.frame(term = "log_scale", coefficient = log_scale,
                             ci_95_lower = log_scale - qnorm(0.975) * scale_se,
                             ci_95_upper = log_scale + qnorm(0.975) * scale_se)
  write.csv(log_scale_ci, file.path("results", "lung_aft_log_scale.csv"), row.names = FALSE)
}

# Cox-based curves for a fixed ECOG score, to visualise the fitted model.
new_cases <- data.frame(inst = c(12, 12), sex = c(1, 2), ph.ecog = c(1, 1))
pred <- survival::survfit(cox_final, newdata = new_cases)
png(file.path("figures", "lung_cox_predicted_survival.png"), width = 1200, height = 800, res = 140)
plot(pred, col = c("#1E7497", "#D97742"), lwd = 2.5, mark.time = FALSE,
     xlab = "Time (days)", ylab = "Model-estimated survival probability",
     main = "NCCTG lung: Cox model estimates (ECOG = 1, inst = 12)")
legend("topright", legend = c("Sex code 1", "Sex code 2"),
       col = c("#1E7497", "#D97742"), lty = 1, lwd = 2.5, bty = "n")
dev.off()

cat("Lung analysis complete. Cox observations:", cox_final$n, "\n")
print(tie_counts)
print(aft_table)

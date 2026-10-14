# Age-specific crude mortality and life tables under two within-year assumptions.
if (!file.exists(file.path("data", "mortality.csv"))) {
  stop("Missing data/mortality.csv; see data/README.md")
}
dir.create("results", showWarnings = FALSE, recursive = TRUE)
dir.create("figures", showWarnings = FALSE, recursive = TRUE)

pension <- read.csv(file.path("data", "mortality.csv"), check.names = FALSE)
required <- c("Age (x)", "Female exposed", "Female deaths", "Male exposed", "Male deaths")
if (!all(required %in% names(pension))) stop("Missing mortality columns")
if (anyNA(pension) || any(pension[c("Male exposed", "Female exposed")] <= 0) ||
    any(pension[c("Male deaths", "Female deaths")] < 0)) {
  stop("Mortality data have missing or invalid exposures/deaths")
}
age <- pension[["Age (x)"]]
if (age[1] != 60 || any(diff(age) != 1)) stop("Age must start at 60 and increase by one year")

# m_x = deaths / central exposure (rates are NOT scaled by 100,000).
m_male <- pension[["Male deaths"]] / pension[["Male exposed"]]
m_female <- pension[["Female deaths"]] / pension[["Female exposed"]]

# Constant force: q_x = 1 - exp(-m_x).
# Uniform distribution of deaths: q_x = m_x / (1 + m_x / 2).
calculate_qx <- function(m, assumption = c("constant", "udd")) {
  assumption <- match.arg(assumption)
  q <- if (assumption == "constant") -expm1(-m) else m / (1 + m / 2)
  if (any(q < 0 | q > 1)) stop("Invalid annual death probability")
  q
}
life_table <- function(q, radix = 100000) {
  out <- numeric(length(q))
  out[1] <- radix
  if (length(q) > 1L) {
    for (i in seq_len(length(q) - 1L)) out[i + 1L] <- out[i] * (1 - q[i])
  }
  out
}

q_male_const <- calculate_qx(m_male, "constant")
q_female_const <- calculate_qx(m_female, "constant")
q_male_udd <- calculate_qx(m_male, "udd")
q_female_udd <- calculate_qx(m_female, "udd")

out <- data.frame(
  age = age,
  male_mx = m_male, female_mx = m_female,
  male_qx_constant = q_male_const, female_qx_constant = q_female_const,
  male_qx_udd = q_male_udd, female_qx_udd = q_female_udd,
  male_lx_constant = life_table(q_male_const),
  female_lx_constant = life_table(q_female_const),
  male_lx_udd = life_table(q_male_udd),
  female_lx_udd = life_table(q_female_udd)
)
write.csv(out, file.path("results", "pension_mortality_full.csv"), row.names = FALSE)
life_columns <- c("age", "male_lx_constant", "female_lx_constant", "male_lx_udd", "female_lx_udd")
write.csv(out[out$age %% 5 == 0, life_columns],
          file.path("results", "pension_life_table_5yr.csv"), row.names = FALSE)

png(file.path("figures", "pension_log_mortality_rates.png"), width = 1200, height = 800, res = 140)
plot(age, ifelse(m_male > 0, log(m_male), NA_real_), type = "l", lwd = 2.5,
     col = "#1E7497", xlab = "Age", ylab = "log(m[x])",
     main = "Log crude central mortality rates by sex")
lines(age, ifelse(m_female > 0, log(m_female), NA_real_), lwd = 2.5, col = "#D97742")
legend("topleft", legend = c("Male", "Female"),
       col = c("#1E7497", "#D97742"), lty = 1, lwd = 2.5, bty = "n")
dev.off()

png(file.path("figures", "pension_life_tables.png"), width = 1250, height = 800, res = 140)
plot(age, out$male_lx_constant, type = "l", lwd = 2.5, col = "#1E7497",
     xlab = "Age", ylab = "Surviving from an initial 100,000",
     ylim = c(0, 100000), main = "Life tables: constant force vs UDD")
lines(age, out$female_lx_constant, col = "#D97742", lwd = 2.5)
lines(age, out$male_lx_udd, col = "#1E7497", lwd = 2.5, lty = 2)
lines(age, out$female_lx_udd, col = "#D97742", lwd = 2.5, lty = 2)
legend("topright", legend = c("Male / constant", "Female / constant", "Male / UDD", "Female / UDD"),
       col = c("#1E7497", "#D97742", "#1E7497", "#D97742"),
       lty = c(1, 1, 2, 2), lwd = 2.5, bty = "n")
dev.off()

cat("Pension mortality analysis complete.\n")
print(round(out[out$age %% 5 == 0, life_columns], 1))

# Dependency-free sanity checks; run from the project root:
# source("tests/basic_checks.R")
q_constant <- function(m) -expm1(-m)
q_udd <- function(m) m / (1 + 0.5 * m)
stopifnot(abs(q_constant(0.1) - (1 - exp(-0.1))) < 1e-12)
stopifnot(abs(q_udd(0.1) - 0.1 / 1.05) < 1e-12)
stopifnot(q_constant(0) == 0, q_udd(0) == 0)
stopifnot(all(q_constant(c(0.01, 0.1, 1.0)) >= 0))
cat("Basic mortality formula checks passed.\n")

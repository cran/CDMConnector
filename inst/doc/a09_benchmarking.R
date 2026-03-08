## ----include = FALSE----------------------------------------------------------
knitr::opts_chunk$set(
  collapse = TRUE,
  comment = "#>"
)

## ----echo = FALSE-------------------------------------------------------------
results_example <- data.frame(
  database = c("postgres", "redshift", "snowflake", "sql_server"),
  time_old_sec = c(120.5, 95.2, 88.1, 110.3),
  time_new_sec = c(45.2, 38.0, 32.5, 42.1),
  ratio_new_over_old = c(0.38, 0.40, 0.37, 0.38),
  n_cohorts = 4L,
  files_included = "cohort_a.json; cohort_b.json; cohort_c.json; cohort_d.json",
  status = "ok",
  stringsAsFactors = FALSE
)
knitr::kable(results_example, digits = 2)

## ----echo = FALSE-------------------------------------------------------------
equiv_example <- data.frame(
  database = c("postgres", "postgres", "postgres", "postgres", "redshift", "redshift"),
  cohort_definition_id = c(NA, 1L, 2L, 3L, NA, 1L),
  n_old = c(15000L, 5000L, 6000L, 4000L, 15000L, 5000L),
  n_new = c(15000L, 5000L, 6000L, 4000L, 15000L, 5000L),
  rows_identical = c(TRUE, TRUE, TRUE, TRUE, TRUE, TRUE),
  status = "ok",
  stringsAsFactors = FALSE
)
knitr::kable(equiv_example)


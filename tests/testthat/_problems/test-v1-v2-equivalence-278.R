# Extracted from test-v1-v2-equivalence.R:278

# prequel ----------------------------------------------------------------------
skip_on_cran()
for (dbtype in dbToTest) {
  test_that(glue::glue("{dbtype} - v1 vs v2 row-level equivalence"), {
    skip_if_not_installed("CirceR")
    if (!(dbtype %in% ciTestDbs)) skip_on_ci()
    if (dbtype != "duckdb") skip_on_cran() else skip_if_not_installed("duckdb")

    prefix <- guid_prefix()
    con <- get_connection(dbtype, DatabaseConnector = testUsingDatabaseConnector)
    cdm_schema <- get_cdm_schema(dbtype)
    write_schema <- get_write_schema(dbtype, prefix = prefix)
    skip_if(any(write_schema == "") || any(cdm_schema == "") || is.null(con))
    on.exit({
      cleanup_cohort_tables(con, write_schema, "v1")
      cleanup_cohort_tables(con, write_schema, "v2")
      disconnect(con)
    }, add = TRUE)

    cdm <- cdmFromCon(con, cdmSchema = cdm_schema, writeSchema = write_schema)
    cs <- readCohortSet(system.file("cohorts2", package = "CDMConnector"))
    compare_v1_v2(cdm, cs)
  })
}
for (dbtype in dbToTest) {
  test_that(glue::glue("{dbtype} - deterministic v1 vs v2 via cdmFromCohortSet"), {
    skip_on_ci()
    skip_if_not_installed("CirceR")
    if (dbtype != "duckdb") skip_on_cran() else skip_if_not_installed("duckdb")

    cs <- readCohortSet(system.file("cohorts2", package = "CDMConnector"))
    mock_cdm <- cdmFromCohortSet(cs, n = 200, seed = 42)
    on.exit(tryCatch(DBI::dbDisconnect(cdmCon(mock_cdm), shutdown = TRUE),
                     error = function(e) NULL), add = TRUE)

    if (dbtype == "duckdb") {
      # Run directly on the mock CDM
      compare_v1_v2(mock_cdm, cs)
    } else {
      # Upload mock CDM to remote database, run both, compare
      prefix <- guid_prefix()
      con <- get_connection(dbtype, DatabaseConnector = testUsingDatabaseConnector)
      cdm_schema <- get_cdm_schema(dbtype)
      write_schema <- get_write_schema(dbtype, prefix = prefix)
      skip_if(any(write_schema == "") || any(cdm_schema == "") || is.null(con))
      on.exit({
        cleanup_cohort_tables(con, write_schema, "v1")
        cleanup_cohort_tables(con, write_schema, "v2")
        disconnect(con)
      }, add = TRUE)

      # Upload the mock CDM clinical tables to the remote DB
      remote_cdm <- copyCdmTo(con, mock_cdm, schema = write_schema, overwrite = TRUE)

      compare_v1_v2(remote_cdm, cs)
    }
  })
}

# test -------------------------------------------------------------------------
skip_on_ci()
skip_if_not_installed("duckdb")
skip_if_not_installed("CirceR")
cohort_dir <- "/Users/ablack/Desktop/AtlasCohortGenerator/inst/cohorts"
skip_if(!dir.exists(cohort_dir), "ATLAS cohort library not available")
json_files <- sort(list.files(cohort_dir, pattern = "\\.json$", full.names = TRUE))
set.seed(42)
sample_files <- sample(json_files, min(50, length(json_files)))
results <- data.frame(
    cohort_name = character(),
    n_v1 = integer(),
    n_v2 = integer(),
    row_match = logical(),
    attrition_match = logical(),
    error = character(),
    stringsAsFactors = FALSE
  )
for (i in seq_along(sample_files)) {
    fp <- sample_files[i]
    cname <- tools::file_path_sans_ext(basename(fp))

    tryCatch({
      json_text <- paste(readLines(fp, warn = FALSE), collapse = "\n")
      cs <- data.frame(
        cohort_definition_id = 1L,
        cohort_name = cname,
        json = json_text,
        stringsAsFactors = FALSE
      )
      cs$cohort <- list(jsonlite::fromJSON(json_text, simplifyVector = FALSE))
      class(cs) <- c("CohortSet", class(cs))

      mock_cdm <- cdmFromCohortSet(cs, n = 100, seed = i)
      on.exit(tryCatch(DBI::dbDisconnect(cdmCon(mock_cdm), shutdown = TRUE),
                       error = function(e) NULL), add = TRUE)

      mock_cdm <- generateCohortSet(mock_cdm, cs, name = "v1",
                                     overwrite = TRUE, computeAttrition = TRUE)
      mock_cdm <- generateCohortSet2(mock_cdm, cs, name = "v2",
                                      overwrite = TRUE, computeAttrition = TRUE)

      v1_data <- dplyr::collect(mock_cdm$v1) |>
        dplyr::mutate(
          cohort_definition_id = as.integer(.data$cohort_definition_id),
          subject_id = as.integer(.data$subject_id),
          cohort_start_date = as.Date(.data$cohort_start_date),
          cohort_end_date = as.Date(.data$cohort_end_date)
        ) |>
        dplyr::select("cohort_definition_id", "subject_id",
                      "cohort_start_date", "cohort_end_date") |>
        dplyr::arrange(.data$subject_id, .data$cohort_start_date)
      v2_data <- dplyr::collect(mock_cdm$v2) |>
        dplyr::mutate(
          cohort_definition_id = as.integer(.data$cohort_definition_id),
          subject_id = as.integer(.data$subject_id),
          cohort_start_date = as.Date(.data$cohort_start_date),
          cohort_end_date = as.Date(.data$cohort_end_date)
        ) |>
        dplyr::select("cohort_definition_id", "subject_id",
                      "cohort_start_date", "cohort_end_date") |>
        dplyr::arrange(.data$subject_id, .data$cohort_start_date)

      row_match <- identical(v1_data, v2_data)

      # Also compare attrition
      att_match <- tryCatch({
        att1 <- omopgenerics::attrition(mock_cdm$v1)
        att2 <- omopgenerics::attrition(mock_cdm$v2)
        # Normalize: remove zero-impact collapse rows
        norm <- function(att) {
          att[!(att$reason == "Cohort records collapsed" &
                att$excluded_records == 0 &
                att$excluded_subjects == 0), ]
        }
        a1 <- norm(att1)
        a2 <- norm(att2)
        cols <- c("number_records", "number_subjects", "reason",
                  "excluded_records", "excluded_subjects")
        identical(a1[, cols], a2[, cols])
      }, error = function(e) FALSE)

      results <- rbind(results, data.frame(
        cohort_name = cname,
        n_v1 = nrow(v1_data),
        n_v2 = nrow(v2_data),
        row_match = row_match,
        attrition_match = att_match,
        error = "",
        stringsAsFactors = FALSE
      ))

      tryCatch(DBI::dbDisconnect(cdmCon(mock_cdm), shutdown = TRUE),
               error = function(e) NULL)

    }, error = function(e) {
      results <<- rbind(results, data.frame(
        cohort_name = cname,
        n_v1 = NA_integer_, n_v2 = NA_integer_,
        row_match = FALSE, attrition_match = FALSE,
        error = conditionMessage(e),
        stringsAsFactors = FALSE
      ))
    })
  }
n_tested <- nrow(results)
n_errors <- sum(nzchar(results$error))
n_row_match <- sum(results$row_match, na.rm = TRUE)
n_att_match <- sum(results$attrition_match, na.rm = TRUE)
pass_rate <- n_row_match / n_tested
message(sprintf("\n=== Batch Test Results ==="))
message(sprintf("Tested:           %d cohorts", n_tested))
message(sprintf("Errors:           %d", n_errors))
message(sprintf("Row match:        %d/%d (%.1f%%)", n_row_match, n_tested, pass_rate * 100))
message(sprintf("Attrition match:  %d/%d (%.1f%%)", n_att_match, n_tested,
                  n_att_match / n_tested * 100))
failures <- results[!results$row_match, ]
if (nrow(failures) > 0) {
    message("\nFailures:")
    for (j in seq_len(nrow(failures))) {
      f <- failures[j, ]
      if (nzchar(f$error)) {
        message(sprintf("  %s: ERROR - %s", f$cohort_name, f$error))
      } else {
        message(sprintf("  %s: v1=%d, v2=%d rows", f$cohort_name, f$n_v1, f$n_v2))
      }
    }
  }
expect_true(pass_rate >= 0.90,
    info = sprintf("Batch pass rate %.1f%% is below 90%% threshold", pass_rate * 100))

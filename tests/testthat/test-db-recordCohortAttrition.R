
test_record_cohort_attrition <- function(con, cdm_schema, write_schema) {

  cdm <- cdm_from_con(
    con = con, cdm_name = "test", cdm_schema = cdm_schema,
    write_schema = write_schema
  )

  cdm <- generateConceptCohortSet(
    cdm,
    conceptSet = list(pharyngitis = 4112343, bronchitis = 260139),
    name = "new_cohort",
    overwrite = TRUE)

  oldAttrition <- attrition(cdm$new_cohort)
  oldCounts <- cohortCount(cdm$new_cohort)
  expect_true(nrow(settings(cdm$new_cohort)) == 2)

  expect_no_error(cdm$new_cohort <- recordCohortAttrition(cdm$new_cohort, reason = "a reason"))
  # running again will produce an error if no new reason is given
  expect_error(cdm$new_cohort <- recordCohortAttrition(cdm$new_cohort))

  expect_s3_class(attrition(cdm$new_cohort), "data.frame")
  expect_s3_class(cohortCount(cdm$new_cohort), "data.frame")
  expect_s3_class(settings(cdm$new_cohort), "data.frame")
  expect_s3_class(cdm$new_cohort, "cohort_table")
  expect_equal(nrow(attrition(cdm$new_cohort)), 4)
  expect_equal(cohortCount(cdm$new_cohort) %>% dplyr::arrange(.data$cohort_definition_id),
               oldCounts %>% dplyr::arrange(.data$cohort_definition_id))

  cdm$new_cohort <- cdm$new_cohort %>%
    dplyr::filter(cohort_start_date >= as.Date("2010-01-01")) %>%
    compute(temporary = FALSE, name = "new_cohort", overwrite = TRUE)

  expect_s3_class(cdm$new_cohort, "cohort_table")

  expect_no_error({
    cdm$new_cohort <- recordCohortAttrition(
      cohort = cdm$new_cohort,
      reason = "Only events after 2010")
  })

  expect_s3_class(attrition(cdm$new_cohort), "data.frame")
  expect_s3_class(cohortCount(cdm$new_cohort), "data.frame")
  expect_s3_class(settings(cdm$new_cohort), "data.frame")
  expect_s3_class(cdm$new_cohort, "cohort_table")

  expect_true(nrow(attrition(cdm$new_cohort)) == 6)
  expect_true(nrow(cohortCount(cdm$new_cohort)) == 2)
  oldCounts <- cohortCount(cdm$new_cohort)

  cdm$new_cohort <- cdm$new_cohort %>%
    dplyr::filter(
      cohort_definition_id != 1 | cohort_start_date <= as.Date("2015-01-01")
    )

  expect_no_error({
    cdm$new_cohort <- recordCohortAttrition(
      cohort = cdm$new_cohort,
      reason = "Only events before 2020",
      cohortId = 1)
  })

  expect_s3_class(attrition(cdm$new_cohort), "data.frame")
  expect_s3_class(cohortCount(cdm$new_cohort), "data.frame")
  expect_s3_class(settings(cdm$new_cohort), "data.frame")
  expect_s3_class(cdm$new_cohort, "cohort_table")

  expect_true(nrow(attrition(cdm$new_cohort)) == 7)
  expect_true(nrow(cohortCount(cdm$new_cohort)) == 2)
  expect_true(
    cdm$new_cohort %>%
      attrition() %>%
      dplyr::filter(.data$cohort_definition_id == 1) %>%
      nrow() == 4
  )

  expect_true(
    cdm$new_cohort %>%
      attrition() %>%
      dplyr::filter(cohort_definition_id == 2) %>%
      nrow() == 3
  )

  expect_equal(
    cdm$new_cohort %>% cohortCount() %>% dplyr::filter(cohort_definition_id == 2),
    oldCounts %>% dplyr::filter(cohort_definition_id == 2)
  )

  cdm$new_cohort <- cdm$new_cohort %>%
    dplyr::filter(!!datepart("cohort_start_date", "month") == 1)

  expect_no_error({
    cdm$new_cohort <- recordCohortAttrition(
      cohort = cdm$new_cohort,
      reason = "Only January events")
  })

  expect_true(nrow(attrition(cdm$new_cohort)) == 9)
  expect_true(nrow(cohortCount(cdm$new_cohort)) == 2)

  expect_true(
    cdm$new_cohort %>%
      attrition() %>%
      dplyr::filter(cohort_definition_id == 1) %>%
      dplyr::pull("reason_id") %>%
      max() == 5
  )

  expect_true(
    cdm$new_cohort %>%
      attrition() %>%
      dplyr::filter(cohort_definition_id == 2) %>%
      dplyr::pull("reason_id") %>%
      max() == 4
  )
}

for (dbtype in dbToTest) {
  test_that(glue::glue("{dbtype} - recordCohortAttrition"), {
    skip_on_cran()
    if (!(dbtype %in% ciTestDbs)) skip_on_ci()
    if (dbtype != "duckdb") skip_on_cran() else skip_if_not_installed("duckdb")
    con <- get_connection(dbtype)
    cdm_schema <- get_cdm_schema(dbtype)
    write_schema <- get_write_schema(dbtype)
    skip_if(any(write_schema == "") || any(cdm_schema == "") || is.null(con))
    test_record_cohort_attrition(con, cdm_schema, write_schema)
    disconnect(con)
  })
}

test_that("record_cohort_attrition works", {
  skip_on_cran()
  skip_if_not_installed("CirceR")
  skip_if_not_installed("duckdb")
  skip_if_not(eunomia_is_available())

  con <- DBI::dbConnect(duckdb::duckdb(eunomia_dir()))
  cdm <- cdm_from_con(
    con = con, cdm_name = "eunomia", cdm_schema = "main", write_schema = "main"
  )

  cohort <- readCohortSet(system.file("cohorts3", package = "CDMConnector"))
  cohort <- cohort %>%
    dplyr::mutate(cohort_name = tolower(cohort_name)) %>%
    dplyr::filter(cohort_name == "gibleed_all")
  cdm <- generateCohortSet(cdm,
                           cohortSet = cohort,
                           name = "gibleed2",
                           overwrite = TRUE)

  cdm$gibleed2 <- cdm$gibleed2 %>%
    dplyr::filter(cohort_start_date >= as.Date("2019-01-01")) %>%
    record_cohort_attrition("After 2019-01-01")

  df <- attrition(cdm$gibleed2) %>%
    dplyr::filter(reason == "After 2019-01-01") %>%
    dplyr::collect()

  expect_true(nrow(df) >= 1)

  cdm$gibleed2 <- cdm$gibleed2 %>%
    dplyr::filter(subject_id == 1)  %>%
    dplyr::filter(subject_id == 2)  %>%
    recordCohortAttrition("zero count")

  expect_equal(attrition(cdm$gibleed2) %>%
    dplyr::filter(reason == "zero count") %>%
    dplyr::pull("number_subjects"), 0)

  DBI::dbDisconnect(con, shutdown = TRUE)
})


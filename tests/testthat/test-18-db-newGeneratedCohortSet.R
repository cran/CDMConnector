test_new_generated_cohort_set <- function(con, cdm_schema, write_schema) {

  cdm <- cdmFromCon(
    con = con, cdmName = "eunomia", cdmSchema = cdm_schema,
    writeSchema = write_schema
  )

  x <- cdm$condition_occurrence %>%
    dplyr::filter(condition_concept_id == 4112343) %>%
    dplyr::mutate(cohort_definition_id = 1L) %>%
    dplyr::select(
      "cohort_definition_id",
      subject_id = "person_id",
      cohort_start_date = "condition_start_date",
      cohort_end_date = "condition_start_date"
    ) %>%
    dplyr::distinct()

  # expect_no_error(
  #   cdm$new_cohort <- x %>%
  #     newGeneratedCohortSet(
  #       cohortSetRef = tibble(
  #         cohort_definition_id = 1, cohort_name = "pharyngitis"
  #       ),
  #       writeSchema = attr(cdm, "write_schema"),
  #       overwrite = TRUE
  #     )
  # )
  # expect_s3_class(cdm$new_cohort, "GeneratedCohortSet")
  # expect_true(all(
  #   c(
  #     "cdm_reference", "cohort_set", "cohort_attrition", "cohort_count",
  #     "tbl_name"
  #   ) %in%
  #   names(attributes(cdm$new_cohort))
  # ))
  #
  # expect_no_error(
  #   cdm$new_cohort <- x %>%
  #     computeQuery() %>%
  #     newGeneratedCohortSet(
  #       cohortSetRef = tibble(
  #         cohort_definition_id = 1, cohort_name = "pharyngitis"
  #       ),
  #       writeSchema = attr(cdm, "write_schema"),
  #       overwrite = TRUE
  #     )
  # )
  # expect_s3_class(cdm$new_cohort, "GeneratedCohortSet")
  # expect_true(all(
  #   c(
  #     "cdm_reference", "cohort_set", "cohort_attrition", "cohort_count",
  #     "tbl_name"
  #   ) %in%
  #     names(attributes(cdm$new_cohort))
  # ))


  cdm$new_cohort <- x %>%
    compute(name = "new_cohort", temporary = FALSE, overwrite = TRUE)

  cdm$new_cohort <- omopgenerics::newCohortTable(
    cdm$new_cohort,
    cohortSetRef = dplyr::tibble(
      cohort_definition_id = 1L,
      cohort_name = "pharyngitis"
  ))

  expect_s3_class(cdm$new_cohort, "cohort_table")

  expect_true(all(
    c("cdm_reference", "cohort_set", "cohort_attrition", "tbl_name") %in% names(attributes(cdm$new_cohort))
  ))

  expect_true(attr(cdm$new_cohort, "tbl_name") == "new_cohort")

  # remove the cohort tables.
  if ("prefix" %in% names(write_schema)) {
    dropSourceTable(cdm, dplyr::starts_with(write_schema["prefix"]))
  } else {
    dropSourceTable(cdm, dplyr::starts_with("new_cohort"))
  }

}

# dbtype = "duckdb"
for (dbtype in dbToTest) {
  test_that(glue::glue("{dbtype} - recordCohortAttrition"), {
    if (!(dbtype %in% ciTestDbs)) skip_on_ci()
    if (dbtype != "duckdb") skip_on_cran() else skip_if_not_installed("duckdb")
    con <- get_connection(dbtype)
    cdm_schema <- get_cdm_schema(dbtype)
    write_schema <- get_write_schema(dbtype)
    skip_if(any(write_schema == "") || any(cdm_schema == "") || is.null(con))
    test_new_generated_cohort_set(con, cdm_schema, write_schema)
    # test_new_generated_cohort_set(con, cdm_schema, get_write_schema(dbtype, prefix = "cdmc_"))
    disconnect(con)
  })
}


test_that("error in newGeneratedCohortSet if cohort_ref has not been computed", {
  skip_if_not_installed("duckdb")
  con <- DBI::dbConnect(duckdb::duckdb(dbdir = eunomiaDir()))
  cdm <- cdmFromCon(
    con = con, cdmName = "eunomia", cdmSchema = "main", writeSchema = "main"
  )

  cohort_ref <- cdm$condition_occurrence %>%
    dplyr::filter(condition_concept_id == 192671) %>%
    dplyr::mutate(cohort_definition_id = 1) %>%
    dplyr::select("cohort_definition_id",
                  "person_id",
                  "condition_start_date",
                  "condition_end_date") %>%
    dplyr::rename("subject_id" = "person_id",
                  "cohort_start_date" = "condition_start_date",
                  "cohort_end_date" = "condition_end_date")

  expect_error(suppressWarnings(omopgenerics::newCohortTable(cohort_ref)))

  DBI::dbDisconnect(con, shutdown = TRUE)
})

test_that("no error if cohort is empty", {
  skip_if_not_installed("CirceR")
  skip_if_not_installed("duckdb")
  # if an empty cohort is passed return an empty GeneratedCohortSet object
  con <- DBI::dbConnect(duckdb::duckdb(dbdir = eunomiaDir()))
  cdm <- cdmFromCon(
    con = con, cdmName = "eunomia", cdmSchema = "main", writeSchema = "main"
  )

  inst_dir <- system.file(package = "CDMConnector", mustWork = TRUE)

  withr::with_dir(inst_dir, {
    cohortSet <- readCohortSet("cohorts2")
  })

  cdm <- generateCohortSet(cdm,
                           cohortSet,
                           name = "cohorts2",
                           overwrite = TRUE,
                           computeAttrition = TRUE)

  expect_true("cohort_table" %in% class(cdm$cohorts2))

  # cdm$cohort_3 <- cdm$cohorts2 %>%
  #   dplyr::filter(cohort_start_date > "2030-01-01") %>%
  #   computeQuery(name = "cohorts_3", temporary = FALSE, schema = cdmWriteSchema(cdm))

  # suppressWarnings({
    cdm$cohort_3 <- cdm$cohorts2 %>%
      dplyr::filter(cohort_start_date > "2030-01-01") %>%
      compute(name = "cohort_3", temporary = FALSE) %>%
      newCohortTable()
  # })

  expect_true("cohort_table" %in% class(cdm$cohort_3))
  # we won't have cohort set or cohort count as we didn't provide the cohort set ref
  # expect_true(nrow(cohort_set(cdm$cohort_3)) == 0)
  # expect_true(nrow(cohort_count(cdm$cohort_3)) == 0)

  c_Ref<- settings(cdm$cohort_3)

  cdm$cohort_3b <- cdm$cohort_3 %>%
    dplyr::compute(name = "cohort_3b", temporary = FALSE) |>
    omopgenerics::newCohortTable(cohortSetRef = c_Ref)

  expect_true("cohort_table" %in% class(cdm$cohort_3b))
  expect_false(nrow(settings(cdm$cohort_3b)) == 0)
  expect_false(nrow(cohortCount(cdm$cohort_3b)) == 0)

  cdmDisconnect(cdm)
})


# issue: https://github.com/darwin-eu-dev/CDMConnector/issues/300
test_that("newGeneratedCohortSet handles empty cohort tables", {
  skip_if_not_installed("duckdb")
  skip_if_not_installed("CirceR")

  con <- DBI::dbConnect(duckdb::duckdb(dbdir = eunomiaDir()))
  cdm <- cdmFromCon(
    con = con, cdmName = "eunomia", cdmSchema = "main", writeSchema = "main"
  )

  cohortSet <- readCohortSet(system.file("cohorts2",
                                         package = "CDMConnector",
                                         mustWork = TRUE))
  cdm <- generateCohortSet(cdm,
                           cohortSet,
                           name = "cohorts2",
                           overwrite = TRUE,
                           computeAttrition = TRUE)

  expect_no_error({
    cdm$cohort_3 <- cdm$cohorts2 %>%
      dplyr::filter(cohort_start_date > "2099-01-01") %>%
      compute(name = "cohort_3", temporary = FALSE) %>%
      omopgenerics::newCohortTable()
  })

  expect_equal(nrow(dplyr::collect(cdm$cohort_3)), 0)
  DBI::dbDisconnect(con, shutdown = T)
})


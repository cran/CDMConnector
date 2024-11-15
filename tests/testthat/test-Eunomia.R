test_that("downloadEunomiaData", {
  skip("manual test")
  path <- downloadEunomiaData()
  expect_true(nchar(path) > 0)

  path <- downloadEunomiaData("GiBleed", overwrite = T)
  con <- DBI::dbConnect(duckdb::duckdb(eunomiaDir("GiBleed")))
  cdm <- cdm_from_con(con, "main", cdm_name = "test")
  expect_s3_class(cdm, "cdm_reference")
  DBI::dbDisconnect(con, shutdown = TRUE)

  con <- DBI::dbConnect(duckdb::duckdb(eunomiaDir("synthea-anemia-10k")))
  cdm <- cdm_from_con(con, "main")
  expect_s3_class(cdm, "cdm_reference")
  DBI::dbDisconnect(con, shutdown = TRUE)

  path <- downloadEunomiaData("synthea-breast_cancer-10k", overwrite = T)
  con <- DBI::dbConnect(duckdb::duckdb(eunomia_dir("synthea-breast_cancer-10k")))
  cdm <- cdm_from_con(con, "main")
  expect_s3_class(cdm, "cdm_reference")
  DBI::dbDisconnect(con, shutdown = TRUE)

  path <- downloadEunomiaData("synthea-covid19-10k", overwrite = T)
  con <- DBI::dbConnect(duckdb::duckdb(eunomia_dir("synthea-covid19-10k")))
  cdm <- cdm_from_con(con, "main")
  expect_s3_class(cdm, "cdm_reference")
  DBI::dbDisconnect(con, shutdown = TRUE)

  path <- downloadEunomiaData("synthea-covid19-200k", overwrite = T)
  con <- DBI::dbConnect(duckdb::duckdb(eunomia_dir("synthea-covid19-200k")))
  cdm <- cdm_from_con(con, "main")
  expect_s3_class(cdm, "cdm_reference")
  DBI::dbDisconnect(con, shutdown = TRUE)

  expect_error(downloadEunomiaData(datasetName = NULL))
  expect_error(downloadEunomiaData(pathToData = NULL))
})

test_that("empty cdm works", {
  # skip("manual test")
  skip_if_not_installed("duckdb")
  skip_if_not(eunomia_is_available("empty_cdm"))

  expect_true("empty_cdm" %in% example_datasets())

  expect_no_error({
    con <- DBI::dbConnect(duckdb::duckdb(eunomia_dir("empty_cdm")))
    cdm <- cdm_from_con(con, "main", "main", cdm_name = "empty_cdm")
  })

  rowcounts <- purrr::map_int(cdm_select_tbl(cdm, -tbl_group("vocab")),
                              ~dplyr::pull(dplyr::count(.), 'n'))

  expect_true(all(rowcounts == 0))
  DBI::dbDisconnect(con, shutdown = T)
})

test_that("synpuf-1k example data has achilles tables", {
  skip_on_cran()
  skip_on_ci() # datasets are large and take a while to download
  skip_if_not_installed("duckdb")

  con <- DBI::dbConnect(duckdb::duckdb(), eunomia_dir("synpuf-1k", "5.3"))
  cdm <- cdm_from_con(con, "main", "main", achilles_schema = "main")
  expect_true(all(c("achilles_analysis", "achilles_results", "achilles_results_dist") %in% names(cdm)))
  cdmDisconnect(cdm)
  expect_true(eunomiaIsAvailable("synpuf-1k", "5.3"))

  con <- DBI::dbConnect(duckdb::duckdb(), eunomia_dir("synpuf-1k", "5.4"))
  cdm <- cdm_from_con(con, "main", "main", achilles_schema = "main")
  expect_true(all(c("achilles_analysis", "achilles_results", "achilles_results_dist") %in% names(cdm)))
  cdmDisconnect(cdm)
  expect_true(eunomiaIsAvailable("synpuf-1k", "5.4"))
})

test_that("requireEunomia", {
  withr::with_envvar(list("EUNOMIA_DATA_FOLDER" = ""), {
    skip_if_not_installed("duckdb")
    expect_identical(Sys.getenv("EUNOMIA_DATA_FOLDER"), "")
    expect_no_error(requireEunomia())
    expect_true(Sys.getenv("EUNOMIA_DATA_FOLDER") != "")
    expect_no_error(con <- duckdb::dbConnect(duckdb::duckdb(), eunomiaDir()))
    duckdb::dbDisconnect(conn = con)
  })
})


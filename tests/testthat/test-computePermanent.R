
test_that("computePermanent works on duckdb", {

  skip_if_not(rlang::is_installed("duckdb", version = "0.6"))
  skip_if_not(eunomia_is_available())

  con <- DBI::dbConnect(duckdb::duckdb(), dbdir = eunomia_dir())
  concept <- dplyr::tbl(con, "concept")

  q <- concept %>%
    dplyr::filter(domain_id == "Drug") %>%
    dplyr::mutate(isRxnorm = (vocabulary_id == "RxNorm")) %>%
    dplyr::count(isRxnorm)

  x <- computePermanent(q, "rxnorm_count")
  expect_error(computePermanent(q, "rxnorm_count"))

  expect_true(nrow(dplyr::collect(x)) == 2)
  expect_true("rxnorm_count" %in% DBI::dbListTables(con))

  x <- appendPermanent(q, "rxnorm_count")
  expect_true(nrow(dplyr::collect(x)) == 4)

  DBI::dbRemoveTable(con, "rxnorm_count")
  DBI::dbDisconnect(con, shutdown = TRUE)
})

test_that("computePermanent works on Postgres", {

  skip_if(Sys.getenv("CDM5_POSTGRESQL_USER") == "")

  con <- DBI::dbConnect(RPostgres::Postgres(),
                        dbname   = Sys.getenv("CDM5_POSTGRESQL_DBNAME"),
                        host     = Sys.getenv("CDM5_POSTGRESQL_HOST"),
                        user     = Sys.getenv("CDM5_POSTGRESQL_USER"),
                        password = Sys.getenv("CDM5_POSTGRESQL_PASSWORD"))

  newTableName <- paste0(c("temptable", sample(1:9, 7, replace = T)), collapse = "")

  vocab <- dplyr::tbl(con, dbplyr::in_schema("cdmv531", "vocabulary"))

  tempSchema <- "ohdsi"

  x <- vocab %>%
    dplyr::filter(vocabulary_id %in% c("ATC", "CPT4")) %>%
    computePermanent(newTableName, schema = tempSchema)

  expect_true(nrow(dplyr::collect(x)) == 2)
  expect_true(newTableName %in% CDMConnector::listTables(con, tempSchema))

  expect_error({vocab %>%
      dplyr::filter(vocabulary_id %in% c("ATC", "CPT4")) %>%
      computePermanent(newTableName, schema = tempSchema)})

  x <- vocab %>%
    dplyr::filter(vocabulary_id %in% c("RxNorm")) %>%
    appendPermanent(newTableName, schema = tempSchema)

  expect_true(nrow(dplyr::collect(x)) == 3)

  DBI::dbRemoveTable(con, DBI::SQL(paste0(c(tempSchema, newTableName), collapse = ".")))
  expect_false(newTableName %in% CDMConnector::listTables(con, tempSchema))
  DBI::dbDisconnect(con)
})

test_that("computePermanent works on SQL Server", {

  skip_if(Sys.getenv("CDM5_SQL_SERVER_USER") == "")

  con <- DBI::dbConnect(odbc::odbc(),
                        Driver   = Sys.getenv("SQL_SERVER_DRIVER"),
                        Server   = Sys.getenv("CDM5_SQL_SERVER_SERVER"),
                        Database = Sys.getenv("CDM5_SQL_SERVER_CDM_DATABASE"),
                        UID      = Sys.getenv("CDM5_SQL_SERVER_USER"),
                        PWD      = Sys.getenv("CDM5_SQL_SERVER_PASSWORD"),
                        TrustServerCertificate="yes",
                        Port     = 1433)

  newTableName <- paste0(c("temptable", sample(1:9, 7, replace = T)), collapse = "")

  vocab <- dplyr::tbl(con, dbplyr::in_catalog("cdmv54", "dbo", "vocabulary"))

  tempSchema <- c("cdmv54", "dbo")

  x <- vocab %>%
    dplyr::filter(vocabulary_id %in% c("ATC", "CPT4")) %>%
    computePermanent(newTableName, schema = tempSchema)

  expect_true(nrow(dplyr::collect(x)) == 2)
  expect_true(newTableName %in% CDMConnector::listTables(con, tempSchema))

  expect_error({vocab %>%
      dplyr::filter(vocabulary_id %in% c("ATC", "CPT4")) %>%
      computePermanent(newTableName, schema = tempSchema)})

  x <- vocab %>%
    dplyr::filter(vocabulary_id %in% c("RxNorm")) %>%
    appendPermanent(newTableName, schema = tempSchema)

  expect_true(nrow(dplyr::collect(x)) == 3)

  DBI::dbRemoveTable(con, DBI::SQL(paste0(c(tempSchema, newTableName), collapse = ".")))
  expect_false(newTableName %in% CDMConnector::listTables(con, tempSchema))
  DBI::dbDisconnect(con)
})

test_that("computePermanent works on Redshift", {

  skip_if(Sys.getenv("CDM5_REDSHIFT_USER") == "")

  con <- DBI::dbConnect(RPostgres::Redshift(),
                        dbname   = Sys.getenv("CDM5_REDSHIFT_DBNAME"),
                        host     = Sys.getenv("CDM5_REDSHIFT_HOST"),
                        port     = Sys.getenv("CDM5_REDSHIFT_PORT"),
                        user     = Sys.getenv("CDM5_REDSHIFT_USER"),
                        password = Sys.getenv("CDM5_REDSHIFT_PASSWORD"))

  newTableName <- paste0(c("temptable", sample(1:9, 7, replace = T)), collapse = "")

  vocab <- dplyr::tbl(con, dbplyr::in_schema("cdmv531", "vocabulary"))

  # tables <- DBI::dbGetQuery(con, "select * from information_schema.tables")
  # tibble::tibble(tables) %>% dplyr::distinct(table_schema)

  tempSchema <- "public"

  x <- vocab %>%
    dplyr::filter(vocabulary_id %in% c("ATC", "CPT4")) %>%
    computePermanent(newTableName, schema = tempSchema)

  expect_true(nrow(dplyr::collect(x)) == 2)
  expect_true(newTableName %in% CDMConnector::listTables(con, tempSchema))

  expect_error({vocab %>%
      dplyr::filter(vocabulary_id %in% c("ATC", "CPT4")) %>%
      computePermanent(newTableName, schema = tempSchema)})

  x <- vocab %>%
    dplyr::filter(vocabulary_id %in% c("RxNorm")) %>%
    appendPermanent(newTableName, schema = tempSchema)

  expect_true(nrow(dplyr::collect(x)) == 3)

  DBI::dbRemoveTable(con, DBI::SQL(paste0(c(tempSchema, newTableName), collapse = ".")))
  expect_false(newTableName %in% CDMConnector::listTables(con, tempSchema))
  DBI::dbDisconnect(con)
})


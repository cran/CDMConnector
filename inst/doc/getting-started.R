## ---- include = FALSE---------------------------------------------------------
library(CDMConnector)
if (!eunomia_is_available()) download_optional_data()

installed_version <- tryCatch(utils::packageVersion("duckdb"), error = function(e) NA)
build <- !is.na(installed_version) && installed_version >= "0.6" && eunomia_is_available()


knitr::opts_chunk$set(
  collapse = TRUE,
  comment = "#>",
  eval = build
)

## -----------------------------------------------------------------------------
library(CDMConnector)

con <- DBI::dbConnect(duckdb::duckdb(), dbdir = eunomia_dir())
cdm <- cdm_from_con(con, cdm_schema = "main")
cdm

## -----------------------------------------------------------------------------
library(dplyr, warn.conflicts = FALSE)
cdm$person %>% 
  count()

cdm$drug_exposure %>% 
  left_join(cdm$concept, by = c("drug_concept_id" = "concept_id")) %>% 
  count(drug = concept_name, sort = TRUE)

## -----------------------------------------------------------------------------
DBI::dbGetQuery(con, "select count(*) as person_count from main.person")

# get the connection from a cdm object using the function `remote_con` from dbplyr
DBI::dbGetQuery(dbplyr::remote_con(cdm$person), "select count(*) as person_count from main.person")

## ---- eval=FALSE--------------------------------------------------------------
#  sql <- SqlRender::translate("select count(*) as person_count from main.person",
#                              targetDialect = dbms(con))
#  DBI::dbGetQuery(con, sql)

## -----------------------------------------------------------------------------
cdm_from_con(con, cdm_tables = starts_with("concept")) # tables that start with 'concept'
cdm_from_con(con, cdm_tables = contains("era")) # tables that contain the substring 'era'
cdm_from_con(con, cdm_tables = tbl_group("vocab")) # pre-defined groups
cdm_from_con(con, cdm_tables = c("person", "observation_period")) # character vector
cdm_from_con(con, cdm_tables = c(person, observation_period)) # bare names
cdm_from_con(con, cdm_tables = matches("person|period")) # regular expression

# If you are using a variable to hold selections then use the `all_of` selection helper
tables_to_include <- c("person", "observation_period")
cdm_from_con(con, cdm_tables = all_of(tables_to_include))

## -----------------------------------------------------------------------------
tbl_group("default")

## ---- echo=FALSE--------------------------------------------------------------
cohort <- tibble(cohort_id = 1L,
                 subject_id = 1L:2L,
                 cohort_start_date = c(Sys.Date(), as.Date("2020-02-03")),
                 cohort_end_date = c(Sys.Date(), as.Date("2020-11-04")))

invisible(DBI::dbExecute(con, "create schema write_schema;"))

DBI::dbWriteTable(con, DBI::Id(schema = "write_schema", table_name = "cohort"), cohort)


## -----------------------------------------------------------------------------
listTables(con, schema = "write_schema")

cdm <- cdm_from_con(con, 
                    cdm_tables = c("person", "observation_period"), 
                    write_schema = "write_schema",
                    cohort_tables = "cohort") 

cdm$cohort

## -----------------------------------------------------------------------------
local_cdm <- cdm %>% 
  collect()

# The cdm tables are now dataframes
local_cdm$person[1:4, 1:4] 

## -----------------------------------------------------------------------------
save_path <- file.path(tempdir(), "tmp")
dir.create(save_path)

cdm %>% 
  stow(path = save_path)

list.files(save_path)

## -----------------------------------------------------------------------------
cdm <- cdm_from_files(save_path)

class(cdm$cohort)

cdm$cohort %>% 
  tally() %>% 
  pull(n)

cdm <- cdm_from_files(save_path, 
                      cdm_tables = c("cohort", "observation_period", "person"), 
                      as_data_frame = FALSE)

class(cdm$cohort)

cdm$cohort %>% 
  tally() %>% 
  pull(n)

## ---- error=TRUE--------------------------------------------------------------
DBI::dbDisconnect(con, shutdown = TRUE)

## -----------------------------------------------------------------------------
connection_details <- dbConnectDetails(duckdb::duckdb(), dbdir = eunomia_dir())

self_contained_query <- function(connection_details) {
  # create a new connection
  con <- DBI::dbConnect(connection_details)
  # close the connection before exiting 
  on.exit(DBI::dbDisconnect(con, shutdown = TRUE))
  # use the connection
  DBI::dbGetQuery(con, "select count(*) as n from main.person")
}

self_contained_query(connection_details)

## ---- error=TRUE--------------------------------------------------------------

library(checkmate)

con <- DBI::dbConnect(duckdb::duckdb(), dbdir = eunomia_dir())


assertTables(cdm_from_con(con, cdm_tables = "drug_era"), tables = c("person"))

# add missing table error to collection
err <- checkmate::makeAssertCollection()
assertTables(cdm_from_con(con, cdm_tables = "drug_era"), tables = c("person"), add = err)
err$getMessages()


## ---- error=TRUE--------------------------------------------------------------
countDrugsByGender <- function(cdm) {
  assertTables(cdm, tables = c("person", "drug_era"), empty.ok = FALSE)

  cdm$person %>%
    dplyr::inner_join(cdm$drug_era, by = "person_id") %>%
    dplyr::count(.data$gender_concept_id, .data$drug_concept_id) %>%
    dplyr::collect()
}

countDrugsByGender(cdm_from_con(con, cdm_tables = "person"))

DBI::dbExecute(con, "delete from drug_era")
countDrugsByGender(cdm_from_con(con))

DBI::dbDisconnect(con, shutdown = TRUE)


## ---- include = FALSE---------------------------------------------------------
library(CDMConnector)
if (Sys.getenv("EUNOMIA_DATA_FOLDER") == "") Sys.setenv("EUNOMIA_DATA_FOLDER" = tempdir())
if (!dir.exists(Sys.getenv("EUNOMIA_DATA_FOLDER"))) dir.create(Sys.getenv("EUNOMIA_DATA_FOLDER"))
if (!eunomia_is_available()) downloadEunomiaData()

knitr::opts_chunk$set(
  collapse = TRUE,
  comment = "#>"
)

## ---- message=FALSE, warning=FALSE--------------------------------------------
library(CDMConnector)
library(dplyr)

## ---- eval=FALSE--------------------------------------------------------------
#  downloadEunomiaData(
#    pathToData = here::here(), # change to the location you want to save the data
#    overwrite = TRUE
#  )
#  # once downloaded, save path to your Renviron: EUNOMIA_DATA_FOLDER="......"
#  # (and then restart R)

## -----------------------------------------------------------------------------
con <- DBI::dbConnect(duckdb::duckdb(), dbdir = eunomia_dir())
cdm <- cdm_from_con(con, cdm_schema = "main")
cdm

## -----------------------------------------------------------------------------
cdm$person %>% 
  glimpse()

## -----------------------------------------------------------------------------
cdm_from_con(con, cdm_schema = "main") %>% cdm_select_tbl("person", "observation_period") # quoted names
cdm_from_con(con, cdm_schema = "main") %>% cdm_select_tbl(person, observation_period) # unquoted names 
cdm_from_con(con, cdm_schema = "main") %>% cdm_select_tbl(starts_with("concept")) # tables that start with 'concept'
cdm_from_con(con, cdm_schema = "main") %>% cdm_select_tbl(contains("era")) # tables that contain the substring 'era'
cdm_from_con(con, cdm_schema = "main") %>% cdm_select_tbl(matches("person|period")) # regular expression

## -----------------------------------------------------------------------------
# pre-defined groups
cdm_from_con(con, "main") %>% cdm_select_tbl(tbl_group("clinical")) 
cdm_from_con(con, "main") %>% cdm_select_tbl(tbl_group("vocab")) 

## -----------------------------------------------------------------------------
tbl_group("default")

## ---- echo=FALSE--------------------------------------------------------------
cohort <- tibble(cohort_definition_id = 1L,
                 subject_id = 1L:2L,
                 cohort_start_date = c(Sys.Date(), as.Date("2020-02-03")),
                 cohort_end_date = c(Sys.Date(), as.Date("2020-11-04")))

invisible(DBI::dbExecute(con, "create schema write_schema;"))

DBI::dbWriteTable(con, DBI::Id(schema = "write_schema", name = "cohort"), cohort)


## -----------------------------------------------------------------------------
cdm <- cdm_from_con(con, 
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
  stow(path = save_path, format = "parquet")

list.files(save_path)

## -----------------------------------------------------------------------------
DBI::dbDisconnect(con, shutdown = TRUE)


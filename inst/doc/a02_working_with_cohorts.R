## ----include = FALSE----------------------------------------------------------

knitr::opts_chunk$set(
  collapse = TRUE,
  eval = rlang::is_installed("CirceR") && rlang::is_installed("Capr"),
  comment = "#>"
)

library(CDMConnector)
library(dplyr, warn.conflicts = FALSE)

if (Sys.getenv("EUNOMIA_DATA_FOLDER") == "") Sys.setenv("EUNOMIA_DATA_FOLDER" = file.path(tempdir(), "eunomia"))
if (!dir.exists(Sys.getenv("EUNOMIA_DATA_FOLDER"))) dir.create(Sys.getenv("EUNOMIA_DATA_FOLDER"))
if (!eunomia_is_available()) downloadEunomiaData()


## -----------------------------------------------------------------------------
path_to_cohort_json_files <- system.file("cohorts1", package = "CDMConnector")
list.files(path_to_cohort_json_files)

readr::read_csv(file.path(path_to_cohort_json_files, "CohortsToCreate.csv"),
                show_col_types = FALSE)

## -----------------------------------------------------------------------------
library(CDMConnector)
path_to_cohort_json_files <- system.file("example_cohorts", 
                                         package = "CDMConnector")
list.files(path_to_cohort_json_files)

con <- DBI::dbConnect(duckdb::duckdb(), eunomia_dir("GiBleed"))
cdm <- cdm_from_con(con, cdm_schema = "main", write_schema = "main")

cohort_set <- read_cohort_set(path_to_cohort_json_files)

cohort_set

cdm <- generate_cohort_set(cdm, 
                           cohort_set,
                           name = "study_cohorts")

cdm$study_cohorts


## -----------------------------------------------------------------------------
cohort_count(cdm$study_cohorts)
cohort_attrition(cdm$study_cohorts)
cohort_set(cdm$study_cohorts)

## ----eval=FALSE---------------------------------------------------------------
#  cdm_gibleed <- cdm %>%
#    cdm_subset_cohort(cohort_table = "study_cohorts")

## -----------------------------------------------------------------------------
library(Capr)

gibleed_concept_set <- cs(192671, name = "gibleed")

gibleed_definition <- cohort(
  entry = conditionOccurrence(gibleed_concept_set)
)

gibleed_male_definition <- cohort(
  entry = conditionOccurrence(gibleed_concept_set, male())
)

# create a named list of Capr cohort definitions
cohort_set = list(gibleed = gibleed_definition,
                  gibleed_male = gibleed_male_definition)

# generate cohorts
cdm <- generate_cohort_set(
  cdm,
  cohort_set = cohort_set,
  name = "gibleed" # name for the cohort table in the cdm
)

cdm$gibleed



## -----------------------------------------------------------------------------

library(dplyr, warn.conflicts = FALSE)

cdm <- generate_concept_cohort_set(
  cdm, 
  concept_set = list(gibleed = 192671), 
  name = "gibleed2", # name of the cohort table
  limit = "all", # use all occurrences of the concept instead of just the first
  end = 10 # set explicit cohort end date 10 days after start
)

cdm$gibleed2 <- cdm$gibleed2 %>% 
  semi_join(
    filter(cdm$person, gender_concept_id == 8507), 
    by = c("subject_id" = "person_id")
  ) %>% 
  record_cohort_attrition(reason = "Male")
  
cohort_attrition(cdm$gibleed2) 

## -----------------------------------------------------------------------------
cohort <- dplyr::tibble(
  cohort_definition_id = 1L,
  subject_id = 1L,
  cohort_start_date = as.Date("1999-01-01"),
  cohort_end_date = as.Date("2001-01-01")
)

cohort

## -----------------------------------------------------------------------------
DBI::dbWriteTable(con, inSchema("main", "cohort", dbms = dbms(con)), value = cohort, overwrite = TRUE)

cdm$cohort <- tbl(con, inSchema("main", "cohort", dbms = dbms(con))) 

## -----------------------------------------------------------------------------
cdm$cohort <- new_generated_cohort_set(cdm$cohort)

## -----------------------------------------------------------------------------
class(cdm$cohort)
cohort_count(cdm$cohort)
cohort_set(cdm$cohort)
cohort_attrition(cdm$cohort)

## -----------------------------------------------------------------------------
DBI::dbWriteTable(con, inSchema("main", "cohort2", dbms = dbms(con)), value = cohort)

cdm$cohort2 <- tbl(con, inSchema("main", "cohort2", dbms = dbms(con))) 

cohort_set <- data.frame(cohort_definition_id = 1L,
                         cohort_name = "made up cohort")

cdm$cohort2 <- new_generated_cohort_set(cdm$cohort2,
                                        cohort_set_ref = cohort_set)

cohort_set(cdm$cohort2)

## -----------------------------------------------------------------------------
DBI::dbDisconnect(con, shutdown = TRUE)


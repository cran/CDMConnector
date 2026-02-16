## ----include = FALSE----------------------------------------------------------

knitr::opts_chunk$set(
  collapse = TRUE,
  eval = rlang::is_installed("CirceR") & rlang::is_installed("Capr") & rlang::is_installed("duckdb"),
  comment = "#>"
)

library(CDMConnector)
library(dplyr, warn.conflicts = FALSE)

if (Sys.getenv("EUNOMIA_DATA_FOLDER") == "") Sys.setenv("EUNOMIA_DATA_FOLDER" = file.path(tempdir(), "eunomia"))
if (!dir.exists(Sys.getenv("EUNOMIA_DATA_FOLDER"))) dir.create(Sys.getenv("EUNOMIA_DATA_FOLDER"))
if (!eunomiaIsAvailable()) downloadEunomiaData()


## -----------------------------------------------------------------------------
pathToCohortJsonFiles <- system.file("cohorts1", package = "CDMConnector")
list.files(pathToCohortJsonFiles)

readr::read_csv(file.path(pathToCohortJsonFiles, "CohortsToCreate.csv"),
                show_col_types = FALSE)

## -----------------------------------------------------------------------------
library(CDMConnector)
pathToCohortJsonFiles <- system.file("example_cohorts", package = "CDMConnector")
list.files(pathToCohortJsonFiles)

con <- DBI::dbConnect(duckdb::duckdb(), eunomiaDir("GiBleed"))
cdm <- cdmFromCon(con, cdmName = "eunomia", cdmSchema = "main", writeSchema = "main")

cohortSet <- readCohortSet(pathToCohortJsonFiles) |>
  mutate(cohort_name = snakecase::to_snake_case(cohort_name))

cohortSet

cdm <- generateCohortSet(
  cdm = cdm, 
  cohortSet = cohortSet,
  name = "study_cohorts"
)

cdm$study_cohorts

## -----------------------------------------------------------------------------
cohortCount(cdm$study_cohorts)
settings(cdm$study_cohorts)
attrition(cdm$study_cohorts)

## ----eval=FALSE---------------------------------------------------------------
# cdm_gibleed <- cdm %>%
#   cdmSubsetCohort(cohortTable = "study_cohorts")

## -----------------------------------------------------------------------------
library(CDMConnector)
con <- DBI::dbConnect(duckdb::duckdb(), eunomiaDir())
cdm <- cdmFromCon(con, cdmSchema = "main", writeSchema = "main")

cohortSet <- readCohortSet(system.file("cohorts3", package = "CDMConnector"))


cdm <- generateCohortSet(cdm, cohortSet, name = "cohort") 

cdm$cohort

cohortCount(cdm$cohort)


## -----------------------------------------------------------------------------
library(dplyr)

cdm$cohort_subset <- cdm$cohort %>% 
  # only keep persons who are in the cohort at least 28 days
  filter(!!datediff("cohort_start_date", "cohort_end_date") >= 28) %>% 
  compute(name = "cohort_subset", temporary = FALSE, overwrite = TRUE) %>% 
  newCohortTable()

cohortCount(cdm$cohort_subset)

## -----------------------------------------------------------------------------
daysInCohort <- cdm$cohort %>% 
  filter(cohort_definition_id %in% c(1,5)) %>% 
  mutate(days_in_cohort = !!datediff("cohort_start_date", "cohort_end_date")) %>% 
  count(cohort_definition_id, days_in_cohort) %>% 
  collect()

daysInCohort

## -----------------------------------------------------------------------------

cdm$cohort_subset <- cdm$cohort %>% 
  filter(!!datediff("cohort_start_date", "cohort_end_date") >= 14) %>% 
  mutate(cohort_definition_id = 10 + cohort_definition_id) %>% 
  union_all(
    cdm$cohort %>%
    filter(!!datediff("cohort_start_date", "cohort_end_date") >= 21) %>% 
    mutate(cohort_definition_id = 100 + cohort_definition_id)
  ) %>% 
  union_all(
    cdm$cohort %>% 
    filter(!!datediff("cohort_start_date", "cohort_end_date") >= 28) %>% 
    mutate(cohort_definition_id = 1000 + cohort_definition_id)
  ) %>% 
  compute(name = "cohort_subset", temporary = FALSE, overwrite = TRUE) # %>% 
  # newCohortTable() # this function creates the cohort object and metadata

cdm$cohort_subset %>% 
  mutate(days_in_cohort = !!datediff("cohort_start_date", "cohort_end_date")) %>% 
  group_by(cohort_definition_id) %>% 
  summarize(mean_days_in_cohort = mean(days_in_cohort, na.rm = TRUE)) %>% 
  collect() %>% 
  arrange(mean_days_in_cohort)


## -----------------------------------------------------------------------------

library(dplyr, warn.conflicts = FALSE)

cdm <- generateConceptCohortSet(
  cdm, 
  conceptSet = list(gibleed = 192671), 
  name = "gibleed2", # name of the cohort table
  limit = "all", # use all occurrences of the concept instead of just the first
  end = 10 # set explicit cohort end date 10 days after start
)

cdm$gibleed2 <- cdm$gibleed2 %>% 
  semi_join(
    filter(cdm$person, gender_concept_id == 8507), 
    by = c("subject_id" = "person_id")
  ) %>% 
  recordCohortAttrition(reason = "Male")
  
attrition(cdm$gibleed2) 

## -----------------------------------------------------------------------------
cohort <- dplyr::tibble(
  cohort_definition_id = 1L,
  subject_id = 1L,
  cohort_start_date = as.Date("1999-01-01"),
  cohort_end_date = as.Date("2001-01-01")
)

cohort

## -----------------------------------------------------------------------------
library(omopgenerics)
cdm <- insertTable(cdm = cdm, name = "cohort", table = cohort, overwrite = TRUE)

cdm$cohort

## -----------------------------------------------------------------------------
cdm$cohort <- newCohortTable(cdm$cohort)

## -----------------------------------------------------------------------------
cohortCount(cdm$cohort)
settings(cdm$cohort)
attrition(cdm$cohort)

## -----------------------------------------------------------------------------
cdm <- insertTable(cdm = cdm, name = "cohort2", table = cohort, overwrite = TRUE)
cdm$cohort2 <- newCohortTable(cdm$cohort2)
settings(cdm$cohort2)

cohort_set <- data.frame(cohort_definition_id = 1L,
                         cohort_name = "made_up_cohort")
cdm$cohort2 <- newCohortTable(cdm$cohort2, cohortSetRef = cohort_set)

settings(cdm$cohort2)

## -----------------------------------------------------------------------------
DBI::dbDisconnect(con, shutdown = TRUE)


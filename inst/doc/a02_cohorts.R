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
cdm <- cdm_from_con(con, cdm_name = "eunomia", cdm_schema = "main", write_schema = "main")

cohort_details <- read_cohort_set(path_to_cohort_json_files) |>
  mutate(cohort_name = snakecase::to_snake_case(cohort_name))

cohort_details

cdm <- generate_cohort_set(
  cdm = cdm, 
  cohort_set = cohort_details,
  name = "study_cohorts"
)

cdm$study_cohorts

## -----------------------------------------------------------------------------
cohort_count(cdm$study_cohorts)
cohort_set(cdm$study_cohorts)
attrition(cdm$study_cohorts)

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
cohort_details = list(gibleed = gibleed_definition,
                  gibleed_male = gibleed_male_definition)

# generate cohorts
cdm <- generate_cohort_set(
  cdm,
  cohort_set = cohort_details,
  name = "gibleed" # name for the cohort table in the cdm
)

cdm$gibleed

## -----------------------------------------------------------------------------
DBI::dbDisconnect(con, shutdown = TRUE)

## -----------------------------------------------------------------------------
library(CDMConnector)
con <- DBI::dbConnect(duckdb::duckdb(), eunomia_dir())
cdm <- cdm_from_con(con, cdm_schema = "main", write_schema = "main")

cohort_set <- read_cohort_set(system.file("cohorts3", package = "CDMConnector"))


cdm <- generate_cohort_set(cdm, cohort_set, name = "cohort") 

cdm$cohort


cohort_count(cdm$cohort)


## -----------------------------------------------------------------------------
library(dplyr)

cdm$cohort_subset <- cdm$cohort %>% 
  # only keep persons who are in the cohort at least 28 days
  filter(!!datediff("cohort_start_date", "cohort_end_date") >= 28) %>% 
  # optionally you can modify the cohort_id
  mutate(cohort_definition_id = 100 + cohort_definition_id) %>% 
  compute(name = "cohort_subset", temporary = FALSE, overwrite = TRUE) %>% 
  new_generated_cohort_set()

cohort_count(cdm$cohort_subset)


## -----------------------------------------------------------------------------
days_in_cohort <- cdm$cohort %>% 
  filter(cohort_definition_id %in% c(1,5)) %>% 
  mutate(days_in_cohort = !!datediff("cohort_start_date", "cohort_end_date")) %>% 
  count(cohort_definition_id, days_in_cohort) %>% 
  collect()

days_in_cohort

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
  compute(name = "cohort_subset", temporary = FALSE, overwrite = TRUE) %>% 
  new_generated_cohort_set() # this function creates the cohort object and metadata

cdm$cohort_subset %>% 
  mutate(days_in_cohort = !!datediff("cohort_start_date", "cohort_end_date")) %>% 
  group_by(cohort_definition_id) %>% 
  summarize(mean_days_in_cohort = mean(days_in_cohort, na.rm = TRUE)) %>% 
  collect() %>% 
  arrange(mean_days_in_cohort)


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
  
attrition(cdm$gibleed2) 

## ----fig.width= 7, fig.height=10----------------------------------------------
library(visR)
gibleed2_attrition <- CDMConnector::attrition(cdm$gibleed2)  %>% 
    dplyr::select(Criteria = "reason", `Remaining N` = "number_subjects")
class(gibleed2_attrition) <- c("attrition", class(gibleed2_attrition))
visr(gibleed2_attrition)

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
cohort_count(cdm$cohort)
cohort_set(cdm$cohort)
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


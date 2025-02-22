## ----include = FALSE----------------------------------------------------------
knitr::opts_chunk$set(
  collapse = TRUE,
  eval = rlang::is_installed("duckdb"),
  # eval = FALSE,
  comment = "#>"
)

## ----include = FALSE----------------------------------------------------------
library(CDMConnector)
if (Sys.getenv("EUNOMIA_DATA_FOLDER") == "") Sys.setenv("EUNOMIA_DATA_FOLDER" = file.path(tempdir(), "eunomia"))
if (!dir.exists(Sys.getenv("EUNOMIA_DATA_FOLDER"))) dir.create(Sys.getenv("EUNOMIA_DATA_FOLDER"))
if (!eunomiaIsAvailable()) downloadEunomiaData()

knitr::opts_chunk$set(
  collapse = TRUE,
  comment = "#>"
)

## ----message=FALSE, warning=FALSE---------------------------------------------
library(CDMConnector)
library(omopgenerics)
library(dplyr)

write_schema <- "main"
cdm_schema <- "main"

con <- DBI::dbConnect(duckdb::duckdb(), 
                      dbdir = eunomiaDir())
cdm <- cdmFromCon(con, 
                    cdmName = "eunomia", 
                    cdmSchema = cdm_schema, 
                    writeSchema = write_schema, 
                    cdmVersion = "5.3")

## -----------------------------------------------------------------------------
cdmName(cdm)

## -----------------------------------------------------------------------------
cdmVersion(cdm)

## -----------------------------------------------------------------------------
cdmCon(cdm)

## -----------------------------------------------------------------------------
DBI::dbListTables(cdmCon(cdm))
DBI::dbListFields(cdmCon(cdm), "person")
DBI::dbGetQuery(cdmCon(cdm), "SELECT * FROM person LIMIT 5")

## ----eval=FALSE---------------------------------------------------------------
# cdm <- generateConceptCohortSet(cdm = cdm,
#                                 conceptSet = list("gi_bleed" = 192671,
#                                                   "celecoxib" = 1118084),
#                                 name = "study_cohorts",
#                                 overwrite = TRUE)
# 
# cdm$study_cohorts %>%
#   glimpse()

## ----eval=FALSE---------------------------------------------------------------
# settings(cdm$study_cohorts)

## ----eval=FALSE---------------------------------------------------------------
# cohortCount(cdm$study_cohorts)

## ----eval=FALSE---------------------------------------------------------------
# attrition(cdm$study_cohorts)

## -----------------------------------------------------------------------------
cdm$gi_bleed <- cdm$condition_occurrence %>% 
  filter(condition_concept_id == 192671) %>% 
  mutate(cohort_definition_id = 1) %>% 
  select(
    cohort_definition_id, 
    subject_id = person_id, 
    cohort_start_date = condition_start_date, 
    cohort_end_date = condition_start_date
  ) %>% 
  compute(name = "gi_bleed", temporary = FALSE, overwrite = TRUE)

cdm$gi_bleed %>% 
  glimpse()

## -----------------------------------------------------------------------------
GI_bleed_cohort_ref <- tibble(cohort_definition_id = 1, cohort_name = "custom_gi_bleed")

cdm$gi_bleed <- omopgenerics::newCohortTable(
  table = cdm$gi_bleed, cohortSetRef = GI_bleed_cohort_ref
)

## -----------------------------------------------------------------------------
settings(cdm$gi_bleed)
cohortCount(cdm$gi_bleed)
attrition(cdm$gi_bleed)


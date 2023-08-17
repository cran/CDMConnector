## ---- include = FALSE---------------------------------------------------------
knitr::opts_chunk$set(
  collapse = TRUE,
  # eval = FALSE,
  comment = "#>"
)

## ---- include = FALSE---------------------------------------------------------
library(CDMConnector)
if (Sys.getenv("EUNOMIA_DATA_FOLDER") == "") Sys.setenv("EUNOMIA_DATA_FOLDER" = file.path(tempdir(), "eunomia"))
if (!dir.exists(Sys.getenv("EUNOMIA_DATA_FOLDER"))) dir.create(Sys.getenv("EUNOMIA_DATA_FOLDER"))
if (!eunomia_is_available()) downloadEunomiaData()

knitr::opts_chunk$set(
  collapse = TRUE,
  comment = "#>"
)

## ---- message=FALSE, warning=FALSE--------------------------------------------
library(CDMConnector)
library(dplyr)

con <- DBI::dbConnect(duckdb::duckdb(), dbdir = eunomia_dir())
cdm <- cdm_from_con(con, cdm_schema = "main", write_schema = "main")

## -----------------------------------------------------------------------------
attr(cdm, "cdm_name")

## -----------------------------------------------------------------------------
cdmName(cdm)
cdm_name(cdm)

## -----------------------------------------------------------------------------
attr(cdm, "cdm_version")

## -----------------------------------------------------------------------------
attr(cdm, "dbcon")

## -----------------------------------------------------------------------------
DBI::dbListTables(attr(cdm, "dbcon"))
DBI::dbListFields(attr(cdm, "dbcon"), "person")
DBI::dbGetQuery(attr(cdm, "dbcon"), "SELECT * FROM person LIMIT 5")

## -----------------------------------------------------------------------------
cdm <- generateConceptCohortSet(cdm = cdm, 
                                conceptSet = list("gi_bleed" = 192671,
                                                  "celecoxib" = 1118084), 
                                name = "study_cohorts")

cdm$study_cohorts %>% 
  glimpse()

## -----------------------------------------------------------------------------
attr(cdm$study_cohorts, "cohort_set")

## ---- eval=FALSE--------------------------------------------------------------
#  cohortSet(cdm$study_cohorts)
#  cohort_set(cdm$study_cohorts)

## -----------------------------------------------------------------------------
attr(cdm$study_cohorts, "cohort_count")

## ---- eval=FALSE--------------------------------------------------------------
#  cohortCount(cdm$study_cohorts)
#  cohort_count(cdm$study_cohorts)

## ---- eval=FALSE--------------------------------------------------------------
#  attr(cdm$study_cohorts, "cohort_attrition")

## ---- eval=FALSE--------------------------------------------------------------
#  cohortAttrition(cdm$study_cohorts)
#  cohort_attrition(cdm$study_cohorts)

## -----------------------------------------------------------------------------
attr(cdm$study_cohorts, "cdm_reference")

## -----------------------------------------------------------------------------
cdm$GI_bleed <- cdm$condition_occurrence %>% 
  filter(condition_concept_id == 192671) %>% 
  mutate(cohort_definition_id = 1) %>% 
  select(cohort_definition_id, person_id,
         condition_start_date, condition_end_date) %>% 
  rename("subject_id" = "person_id", 
         "cohort_start_date" = "condition_start_date", 
         "cohort_end_date" = "condition_end_date")

cdm$GI_bleed %>% 
  glimpse()

## -----------------------------------------------------------------------------
GI_bleed_cohort_ref <- data.frame(cohort_definition_id = 1,
                                  cohort_name = "custom_gi_bleed")

cdm$GI_bleed <- newGeneratedCohortSet(cohortRef = cdm$GI_bleed, 
                                      cohortSetRef = GI_bleed_cohort_ref, 
                                      overwrite = TRUE)

## -----------------------------------------------------------------------------
cohort_set(cdm$GI_bleed)
cohort_count(cdm$GI_bleed)
cohort_attrition(cdm$GI_bleed)
attr(cdm$GI_bleed, "cdm_reference")


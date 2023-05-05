## ---- include = FALSE---------------------------------------------------------

knitr::opts_chunk$set(
  collapse = TRUE,
  comment = "#>"
)

library(CDMConnector)
library(dplyr, warn.conflicts = FALSE)

if (Sys.getenv("EUNOMIA_DATA_FOLDER") == "") Sys.setenv("EUNOMIA_DATA_FOLDER" = file.path(tempdir(), "eunomia"))
if (!dir.exists(Sys.getenv("EUNOMIA_DATA_FOLDER"))) dir.create(Sys.getenv("EUNOMIA_DATA_FOLDER"))
if (!eunomia_is_available()) downloadEunomiaData()


## ---- warning=FALSE, message=FALSE--------------------------------------------
library(CDMConnector)
library(dplyr)

con <- DBI::dbConnect(duckdb::duckdb(), eunomia_dir())

cdm <- CDMConnector::cdm_from_con(
  con = con,
  cdm_schema = "main",
  write_schema = "main"
)

## ---- eval=FALSE--------------------------------------------------------------
#  # devtools::install_github("OHDSI/Capr")
#  library(Capr)
#  
#  gibleed_cohort_definition <- cohort(
#    entry = condition(cs(descendants(192671))),
#    attrition = attrition(
#      "no RA" = withAll(
#        exactly(0,
#                condition(cs(descendants(80809))),
#                duringInterval(eventStarts(-Inf, Inf))))
#    )
#  )
#  
#  # requires CirceR optional dependency
#  cdm <- generateCohortSet(
#    cdm,
#    cohortSet = list(gibleed = gibleed_cohort_definition),
#    name = "gibleed",
#    computeAttrition = TRUE
#  )

## ---- echo=FALSE, eval=FALSE--------------------------------------------------
#  # save data in package. Only do this when editing vignette.
#  cdm$gibleed %>%
#    collect() %>%
#    readr::write_rds(here::here("inst", "rds", "gibleed.rds"))
#  
#  cdm$gibleed %>%
#    cohortCount() %>%
#    collect() %>%
#    readr::write_rds(here::here("inst", "rds", "gibleed_count.rds"))
#  
#  cdm$gibleed %>%
#    cohortAttrition() %>%
#    collect() %>%
#    readr::write_rds(here::here("inst", "rds", "gibleed_attrition.rds"))
#  
#  cdm$gibleed %>%
#    cohortSet() %>%
#    collect() %>%
#    readr::write_rds(here::here("inst", "rds", "gibleed_set.rds"))
#  

## ---- eval=FALSE--------------------------------------------------------------
#  cdm$gibleed %>%
#    glimpse()

## ---- echo=FALSE--------------------------------------------------------------
readr::read_rds(system.file("rds", "gibleed.rds", package = "CDMConnector", mustWork = TRUE)) %>% 
  glimpse()

## ---- eval=FALSE--------------------------------------------------------------
#  cohortCount(cdm$gibleed) %>%
#    glimpse()

## ---- echo=FALSE--------------------------------------------------------------
readr::read_rds(system.file("rds", "gibleed_count.rds", package = "CDMConnector", mustWork = TRUE)) %>% 
  glimpse()

## ---- eval=FALSE--------------------------------------------------------------
#  cohortAttrition(cdm$gibleed) %>%
#    glimpse()

## ---- echo=FALSE--------------------------------------------------------------
readr::read_rds(system.file("rds", "gibleed_attrition.rds", package = "CDMConnector", mustWork = TRUE)) %>% 
  glimpse()

## ---- eval=FALSE--------------------------------------------------------------
#  cohortSet(cdm$gibleed) %>%
#    glimpse()

## ---- echo=FALSE--------------------------------------------------------------
readr::read_rds(system.file("rds", "gibleed_set.rds", package = "CDMConnector", mustWork = TRUE)) %>% 
  glimpse()

## -----------------------------------------------------------------------------
DBI::dbDisconnect(con, shutdown = TRUE)


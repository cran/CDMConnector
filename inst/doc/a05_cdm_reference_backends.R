## ----include = FALSE----------------------------------------------------------
library(CDMConnector)
if (Sys.getenv("EUNOMIA_DATA_FOLDER") == "") Sys.setenv("EUNOMIA_DATA_FOLDER" = file.path(tempdir(), "eunomia"))
if (!dir.exists(Sys.getenv("EUNOMIA_DATA_FOLDER"))) dir.create(Sys.getenv("EUNOMIA_DATA_FOLDER"))
if (!eunomia_is_available()) downloadEunomiaData()

knitr::opts_chunk$set(
  collapse = TRUE,
  comment = "#>", 
  eval = FALSE,
  build = eunomia_is_available()
)

## ----pressure, echo=FALSE, out.width = '80%'----------------------------------
#  # knitr::include_graphics("locations.png")

## ----message=FALSE, warning=FALSE---------------------------------------------
#  library(CDMConnector)
#  library(dplyr, warn.conflicts = FALSE)
#  library(ggplot2)

## ----message=FALSE, warning=FALSE---------------------------------------------
#  con <- DBI::dbConnect(duckdb::duckdb(), dbdir = eunomia_dir())
#  cdm <- cdm_from_con(con, cdm_schema = "main")
#  
#  # first filter to only those with condition_concept_id "4035415"
#  cdm$condition_occurrence %>% tally()
#  
#  cdm$condition_occurrence <- cdm$condition_occurrence %>%
#    filter(condition_concept_id == "4035415") %>%
#    select(person_id, condition_start_date)
#  
#  cdm$condition_occurrence %>% tally()
#  
#  # then left_join person table
#  cdm$person %>% tally()
#  cdm$person <- cdm$condition_occurrence %>%
#    select(person_id) %>%
#    left_join(select(cdm$person, person_id, year_of_birth), by = "person_id")
#  
#  cdm$person %>% tally()

## ----message=FALSE, warning=FALSE---------------------------------------------
#  dOut <- tempfile()
#  dir.create(dOut)
#  CDMConnector::stow(cdm, dOut, format = "parquet")

## ----message=FALSE, warning=FALSE---------------------------------------------
#  cdm_arrow <- cdm_from_files(dOut, as_data_frame = FALSE, cdm_name = "GiBleed")
#  
#  cdm_arrow$person %>%
#    nrow()
#  
#  cdm_arrow$condition_occurrence %>%
#    nrow()
#  

## ----message=FALSE, warning=FALSE---------------------------------------------
#  cdm_arrow$result <- cdm_arrow$person %>%
#    left_join(cdm_arrow$condition_occurrence, by = "person_id") %>%
#    mutate(age_diag = year(condition_start_date) - year_of_birth)

## ----message=FALSE, warning=FALSE---------------------------------------------
#  result <- cdm_arrow$result %>%
#    collect()
#  
#  str(result)
#  
#  result %>%
#    ggplot(aes(age_diag)) +
#    geom_histogram()

## -----------------------------------------------------------------------------
#  DBI::dbDisconnect(con, shutdown = TRUE)


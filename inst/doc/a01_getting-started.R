## ----setup, include = FALSE---------------------------------------------------
library(CDMConnector)
if (Sys.getenv("EUNOMIA_DATA_FOLDER") == "") Sys.setenv("EUNOMIA_DATA_FOLDER" = tempdir())
if (!dir.exists(Sys.getenv("EUNOMIA_DATA_FOLDER"))) dir.create(Sys.getenv("EUNOMIA_DATA_FOLDER"))
if (!eunomiaIsAvailable()) downloadEunomiaData()

knitr::opts_chunk$set(
  collapse = TRUE,
  eval = rlang::is_installed("duckdb"),
  comment = "#>"
)

## -----------------------------------------------------------------------------
library(CDMConnector)
exampleDatasets()

con <- DBI::dbConnect(duckdb::duckdb(), eunomiaDir("GiBleed"))
DBI::dbListTables(con)

## -----------------------------------------------------------------------------
cdm <- cdmFromCon(con, cdmName = "eunomia", cdmSchema = "main", writeSchema = "main")
cdm
cdm$observation_period

## -----------------------------------------------------------------------------
cdm$person %>% 
  dplyr::glimpse()

## ----warning=FALSE------------------------------------------------------------
library(dplyr)
library(ggplot2)

cdm$person %>% 
  group_by(year_of_birth, gender_concept_id) %>% 
  summarize(n = n(), .groups = "drop") %>% 
  collect() %>% 
  mutate(sex = case_when(
    gender_concept_id == 8532 ~ "Female",
    gender_concept_id == 8507 ~ "Male"
  )) %>% 
  ggplot(aes(y = n, x = year_of_birth, fill = sex)) +
  geom_histogram(stat = "identity", position = "dodge") +
  labs(x = "Year of birth", 
       y = "Person count", 
       title = "Age Distribution",
       subtitle = cdmName(cdm),
       fill = NULL) +
  theme_bw()

## ----warning=FALSE------------------------------------------------------------
cdm$condition_occurrence %>% 
  count(condition_concept_id, sort = T) %>% 
  left_join(cdm$concept, by = c("condition_concept_id" = "concept_id")) %>% 
  collect() %>% 
  select("condition_concept_id", "concept_name", "n") 

## ----warning=FALSE------------------------------------------------------------
cdm$condition_occurrence %>% 
  filter(condition_concept_id == 4112343) %>% 
  distinct(person_id) %>% 
  inner_join(cdm$drug_exposure, by = "person_id") %>% 
  count(drug_concept_id, sort = TRUE) %>% 
  left_join(cdm$concept, by = c("drug_concept_id" = "concept_id")) %>% 
  collect() %>% 
  select("concept_name", "n") 

## ----warning=FALSE------------------------------------------------------------
cdm$condition_occurrence %>% 
  filter(condition_concept_id == 4112343) %>% 
  distinct(person_id) %>% 
  inner_join(cdm$drug_exposure, by = "person_id") %>% 
  count(drug_concept_id, sort = TRUE) %>% 
  left_join(cdm$concept, by = c("drug_concept_id" = "concept_id")) %>% 
  show_query() 

## -----------------------------------------------------------------------------
DBI::dbExecute(con, "create schema scratch;")
cdm <- cdmFromCon(con, cdmName = "eunomia", cdmSchema = "main", writeSchema = "scratch")

## ----warning=FALSE------------------------------------------------------------

drugs <- cdm$condition_occurrence %>% 
  filter(condition_concept_id == 4112343) %>% 
  distinct(person_id) %>% 
  inner_join(cdm$drug_exposure, by = "person_id") %>% 
  count(drug_concept_id, sort = TRUE) %>% 
  left_join(cdm$concept, by = c("drug_concept_id" = "concept_id")) %>% 
  compute(name = "test", temporary = FALSE, overwrite = TRUE)

drugs %>% show_query()

drugs

## -----------------------------------------------------------------------------
cdm %>% cdmSelect("person", "observation_period") # quoted names
cdm %>% cdmSelect(person, observation_period) # unquoted names 
cdm %>% cdmSelect(starts_with("concept")) # tables that start with 'concept'
cdm %>% cdmSelect(contains("era")) # tables that contain the substring 'era'
cdm %>% cdmSelect(matches("person|period")) # regular expression

## -----------------------------------------------------------------------------
# pre-defined groups
cdm %>% cdmSelect(tblGroup("clinical")) 
cdm %>% cdmSelect(tblGroup("vocab")) 

## -----------------------------------------------------------------------------
tblGroup("default")

## -----------------------------------------------------------------------------
personIds <- cdm$condition_occurrence %>% 
  filter(condition_concept_id == 255848) %>% 
  distinct(person_id) %>% 
  pull(person_id)

length(personIds)

cdm_pneumonia <- cdm %>%
  cdmSubset(personId = personIds)

tally(cdm_pneumonia$person) %>% 
  pull(n)

cdm_pneumonia$condition_occurrence %>% 
  distinct(person_id) %>% 
  tally() %>% 
  pull(n)

## -----------------------------------------------------------------------------

cdm_100person <- cdmSample(cdm, n = 100)

tally(cdm_100person$person) %>% pull("n")


## -----------------------------------------------------------------------------
cdmFlatten(cdm_pneumonia,
           domain = c("condition_occurrence", "drug_exposure", "measurement")) %>% 
  collect()

## -----------------------------------------------------------------------------
DBI::dbDisconnect(con, shutdown = TRUE)


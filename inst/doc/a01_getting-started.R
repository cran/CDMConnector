## ----setup, include = FALSE---------------------------------------------------
library(CDMConnector)
if (Sys.getenv("EUNOMIA_DATA_FOLDER") == "") Sys.setenv("EUNOMIA_DATA_FOLDER" = tempdir())
if (!dir.exists(Sys.getenv("EUNOMIA_DATA_FOLDER"))) dir.create(Sys.getenv("EUNOMIA_DATA_FOLDER"))
if (!eunomia_is_available()) downloadEunomiaData()

knitr::opts_chunk$set(
  collapse = TRUE,
  eval = rlang::is_installed("duckdb"),
  comment = "#>"
)

## -----------------------------------------------------------------------------
library(CDMConnector)
example_datasets()

con <- DBI::dbConnect(duckdb::duckdb(), eunomia_dir("GiBleed"))
DBI::dbListTables(con)

## -----------------------------------------------------------------------------
cdm <- cdm_from_con(con, cdm_name = "eunomia", cdm_schema = "main", write_schema = "main")
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
       subtitle = cdm_name(cdm),
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
cdm <- cdm_from_con(con, cdm_name = "eunomia", cdm_schema = "main", write_schema = "scratch")

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
cdm %>% cdm_select_tbl("person", "observation_period") # quoted names
cdm %>% cdm_select_tbl(person, observation_period) # unquoted names 
cdm %>% cdm_select_tbl(starts_with("concept")) # tables that start with 'concept'
cdm %>% cdm_select_tbl(contains("era")) # tables that contain the substring 'era'
cdm %>% cdm_select_tbl(matches("person|period")) # regular expression

## -----------------------------------------------------------------------------
# pre-defined groups
cdm %>% cdm_select_tbl(tbl_group("clinical")) 
cdm %>% cdm_select_tbl(tbl_group("vocab")) 

## -----------------------------------------------------------------------------
tbl_group("default")

## -----------------------------------------------------------------------------
person_ids <- cdm$condition_occurrence %>% 
  filter(condition_concept_id == 255848) %>% 
  distinct(person_id) %>% 
  pull(person_id)

length(person_ids)

cdm_pneumonia <- cdm %>%
  cdm_subset(person_id = person_ids)

tally(cdm_pneumonia$person) %>% 
  pull(n)

cdm_pneumonia$condition_occurrence %>% 
  distinct(person_id) %>% 
  tally() %>% 
  pull(n)

## -----------------------------------------------------------------------------

cdm_100person <- cdm_sample(cdm, n = 100)

tally(cdm_100person$person) %>% pull("n")


## -----------------------------------------------------------------------------
cdm_flatten(cdm_pneumonia,
            domain = c("condition", "drug", "measurement")) %>% 
  collect()

## -----------------------------------------------------------------------------
local_cdm <- cdm_100person %>% 
  collect()

# The cdm tables are now dataframes
local_cdm$person[1:4, 1:4] 

## ----eval=FALSE---------------------------------------------------------------
# save_path <- file.path(tempdir(), "tmp")
# dir.create(save_path)
# 
# cdm %>%
#   stow(path = save_path, format = "parquet")
# 
# list.files(save_path)

## ----eval=FALSE---------------------------------------------------------------
# cdm <- cdm_from_files(save_path, cdm_name = "GI Bleed example data")

## -----------------------------------------------------------------------------
DBI::dbDisconnect(con, shutdown = TRUE)


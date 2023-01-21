## ---- include = FALSE---------------------------------------------------------
library(CDMConnector)
if (Sys.getenv("EUNOMIA_DATA_FOLDER") == "") Sys.setenv("EUNOMIA_DATA_FOLDER" = path.expand("~/EunomiaData"))
if (!dir.exists(Sys.getenv("EUNOMIA_DATA_FOLDER"))) dir.create(Sys.getenv("EUNOMIA_DATA_FOLDER"))
if (!eunomia_is_available()) downloadEunomiaData()

knitr::opts_chunk$set(
  collapse = TRUE,
  comment = "#>"
)

## -----------------------------------------------------------------------------
library(CDMConnector)
library(dplyr, warn.conflicts = FALSE)
library(ggplot2)

## -----------------------------------------------------------------------------
con <- DBI::dbConnect(duckdb::duckdb(), dbdir = eunomia_dir())
cdm <- cdm_from_con(con, cdm_schema = "main")
cdm

## ---- message=FALSE-----------------------------------------------------------
cdm$person %>%
  select(year_of_birth) %>%
  collect() %>%
  ggplot(aes(x = year_of_birth)) +
  geom_histogram(bins = 30)

## -----------------------------------------------------------------------------
cdm$observation_period %>%
  select(observation_period_start_date, observation_period_end_date) %>%
  mutate(observation_period = (observation_period_end_date - observation_period_start_date)/365, 25) %>%
  select(observation_period) %>%
  collect() %>%
  ggplot(aes(x = observation_period)) +
  geom_boxplot()

## -----------------------------------------------------------------------------
cdm$person %>%
  tally() %>%
  show_query()

## -----------------------------------------------------------------------------
cdm$person %>%
  summarise(median(year_of_birth))%>%
  show_query()

## ---- warning=FALSE-----------------------------------------------------------
cdm$person %>%
  mutate(gender = case_when(
    gender_concept_id == "8507" ~ "Male",
    gender_concept_id == "8532" ~ "Female",
    TRUE ~ NA_character_))%>%
  show_query()

## -----------------------------------------------------------------------------
DBI::dbDisconnect(con, disconnect = TRUE)


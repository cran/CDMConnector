<!-- README.md is generated from README.Rmd. Please edit that file -->

# [CDMConnector](https://darwin-eu.github.io/CDMConnector/)

<!-- badges: start -->

[![CRAN
status](https://www.r-pkg.org/badges/version/CDMConnector)](https://CRAN.R-project.org/package=CDMConnector)
[![codecov.io](https://codecov.io/gh/OdyOSG/CDMConnector/coverage.svg?branch=main)](https://app.codecov.io/gh/OdyOSG/CDMConnector?branch=main)
[![Build
Status](https://github.com/darwin-eu/CDMConnector/workflows/R-CMD-check/badge.svg)](https://github.com/darwin-eu/CDMConnector/actions?query=workflow%3AR-CMD-check)
<!-- badges: end -->

> Are you using the [tidyverse](https://www.tidyverse.org/) with an OMOP
> Common Data Model?
>
> Interact with your CDM in a pipe-friendly way with CDMConnector.
>
> -   Quickly connect to your CDM and start exploring.
> -   Build data analysis pipelines using familiar dplyr verbs.
> -   Easily extract subsets of CDM data from a database.

## Overview

CDMConnector introduces a single R object that represents an OMOP CDM
relational database inspired by the [dm](https://dm.cynkra.com/),
[DatabaseConnector](http://ohdsi.github.io/DatabaseConnector/), and
[Andromeda](https://ohdsi.github.io/Andromeda/) packages. The cdm object
can be used in dplyr style data analysis pipelines and facilitates
interactive data exploration. cdm objects encapsulate references to
[OMOP CDM tables](https://ohdsi.github.io/CommonDataModel/) in a remote
RDBMS as well as metadata necessary for interacting with a CDM.

[![OMOP CDM
v5.4](https://ohdsi.github.io/CommonDataModel/images/cdm54.png)](https://ohdsi.github.io/CommonDataModel/)

## Features

CDMConnector is meant to be the entry point for composable tidyverse
style data analysis operations on an OMOP CDM. A `cdm_reference` object
behaves like a named list of tables.

-   Quickly create a list of references to a subset of CDM tables
-   Store connection information for later use inside functions
-   Use any DBI driver back-end with the OMOP CDM

See Getting started for more details.

## Installation

CDMConnector can be installed from CRAN:

    install.packages("CDMConnector")

The development version can be installed from GitHub:

    # install.packages("devtools")
    devtools::install_github("darwin-eu/CDMConnector")

## Usage

Create a `cdm_reference` object from any DBI connection. Use the
\`cdm\_schema argument to point to a particular schema in your database.

    library(CDMConnector)

    con <- DBI::dbConnect(duckdb::duckdb(), dbdir = eunomia_dir())
    cdm <- cdm_from_con(con, cdm_schema = "main")
    cdm

    ## # OMOP CDM reference (tbl_duckdb_connection)
    ## 
    ## Tables: person, observation_period, visit_occurrence, visit_detail, condition_occurrence, drug_exposure, procedure_occurrence, device_exposure, measurement, observation, death, note, note_nlp, specimen, fact_relationship, location, care_site, provider, payer_plan_period, cost, drug_era, dose_era, condition_era, metadata, cdm_source, concept, vocabulary, domain, concept_class, concept_relationship, relationship, concept_synonym, concept_ancestor, source_to_concept_map, drug_strength

A `cdm_reference` is a named list of table references:

    library(dplyr, warn.conflicts = FALSE)
    names(cdm)

    ##  [1] "person"                "observation_period"    "visit_occurrence"     
    ##  [4] "visit_detail"          "condition_occurrence"  "drug_exposure"        
    ##  [7] "procedure_occurrence"  "device_exposure"       "measurement"          
    ## [10] "observation"           "death"                 "note"                 
    ## [13] "note_nlp"              "specimen"              "fact_relationship"    
    ## [16] "location"              "care_site"             "provider"             
    ## [19] "payer_plan_period"     "cost"                  "drug_era"             
    ## [22] "dose_era"              "condition_era"         "metadata"             
    ## [25] "cdm_source"            "concept"               "vocabulary"           
    ## [28] "domain"                "concept_class"         "concept_relationship" 
    ## [31] "relationship"          "concept_synonym"       "concept_ancestor"     
    ## [34] "source_to_concept_map" "drug_strength"

Use dplyr verbs with the table references.

    tally(cdm$person)

    ## # Source:   SQL [1 x 1]
    ## # Database: DuckDB 0.8.0 [root@Darwin 21.6.0:R 4.2.2//var/folders/xx/01v98b6546ldnm1rg1_bvk000000gn/T//RtmpGP4CIq/xpjlsqnl]
    ##       n
    ##   <dbl>
    ## 1  2694

Compose operations with the pipe.

    cdm$condition_era %>%
      left_join(cdm$concept, by = c("condition_concept_id" = "concept_id")) %>% 
      count(top_conditions = concept_name, sort = TRUE)

    ## # Source:     SQL [?? x 2]
    ## # Database:   DuckDB 0.8.0 [root@Darwin 21.6.0:R 4.2.2//var/folders/xx/01v98b6546ldnm1rg1_bvk000000gn/T//RtmpGP4CIq/xpjlsqnl]
    ## # Ordered by: desc(n)
    ##    top_conditions                               n
    ##    <chr>                                    <dbl>
    ##  1 Viral sinusitis                          17268
    ##  2 Acute viral pharyngitis                  10217
    ##  3 Acute bronchitis                          8184
    ##  4 Otitis media                              3561
    ##  5 Osteoarthritis                            2694
    ##  6 Streptococcal sore throat                 2656
    ##  7 Sprain of ankle                           1915
    ##  8 Concussion with no loss of consciousness  1013
    ##  9 Sinusitis                                 1001
    ## 10 Acute bacterial sinusitis                  939
    ## # ℹ more rows

Run a simple quality check on a cdm.

    cdm <- cdm_from_con(con, cdm_schema = "main")
    validate_cdm(cdm)

    ## ── CDM v5.3 validation (checking 35 tables) ────────────────────────────────────
    ## visit_detail table expected columns[8:19] vs visit_detail table actual_colums[8:19]
    ##   "visit_detail_type_concept_id"
    ##   "provider_id"
    ##   "care_site_id"
    ## - "visit_detail_source_value"
    ## + "admitting_source_concept_id"
    ## - "visit_detail_source_concept_id"
    ## + "discharge_to_concept_id"
    ## - "admitting_source_value"
    ## + "preceding_visit_detail_id"
    ## - "admitting_source_concept_id"
    ## + "visit_detail_source_value"
    ## - "discharge_to_source_value"
    ## + "visit_detail_source_concept_id"
    ## - "discharge_to_concept_id"
    ## + "admitting_source_value"
    ## - "preceding_visit_detail_id"
    ## + "discharge_to_source_value"
    ## and 2 more ...
    ## condition_occurrence table expected columns[6:16] vs condition_occurrence table actual_colums[6:16]
    ##   "condition_end_date"
    ##   "condition_end_datetime"
    ##   "condition_type_concept_id"
    ## - "condition_status_concept_id"
    ## + "stop_reason"
    ## - "stop_reason"
    ## + "provider_id"
    ## - "provider_id"
    ## + "visit_occurrence_id"
    ## - "visit_occurrence_id"
    ## + "visit_detail_id"
    ## - "visit_detail_id"
    ## + "condition_source_value"
    ## - "condition_source_value"
    ## + "condition_source_concept_id"
    ## - "condition_source_concept_id"
    ## + "condition_status_source_value"
    ## and 1 more ...
    ##     note_nlp table expected columns | note_nlp table actual_colums    
    ## [2] "note_id"                       | "note_id"                    [2]
    ## [3] "section_concept_id"            | "section_concept_id"         [3]
    ## [4] "snippet"                       | "snippet"                    [4]
    ## [5] "\"offset\""                    - "offset"                     [5]
    ## [6] "lexical_variant"               | "lexical_variant"            [6]
    ## [7] "note_nlp_concept_id"           | "note_nlp_concept_id"        [7]
    ## [8] "note_nlp_source_concept_id"    | "note_nlp_source_concept_id" [8]
    ##      cost table expected columns | cost table actual_colums       
    ## [17] "payer_plan_period_id"      | "payer_plan_period_id"     [17]
    ## [18] "amount_allowed"            | "amount_allowed"           [18]
    ## [19] "revenue_code_concept_id"   | "revenue_code_concept_id"  [19]
    ## [20] "revenue_code_source_value" - "reveue_code_source_value" [20]
    ## [21] "drg_concept_id"            | "drg_concept_id"           [21]
    ## [22] "drg_source_value"          | "drg_source_value"         [22]
    ## • 17 empty CDM tables: visit_detail, device_exposure, death, note, note_nlp, specimen, fact_relationship, location, care_site, provider, payer_plan_period, cost, dose_era, metadata, concept_class, source_to_concept_map, drug_strength

## DBI Drivers

CDMConnector is tested using the following DBI driver backends:

-   [RPostgres](https://rpostgres.r-dbi.org/reference/postgres) on
    Postgres and Redshift
-   [odbc](https://solutions.posit.co/connections/db/r-packages/odbc/)
    on Microsoft SQL Server, Oracle, and Databricks/Spark
-   [duckdb](https://duckdb.org/docs/api/r)

## Getting help

If you encounter a clear bug, please file an issue with a minimal
[reproducible example](https://reprex.tidyverse.org/) on
[GitHub](https://github.com/OdyOSG/CDMConnector/issues).

------------------------------------------------------------------------

License: Apache 2.0

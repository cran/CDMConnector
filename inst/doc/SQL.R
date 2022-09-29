## ---- include = FALSE---------------------------------------------------------
knitr::opts_chunk$set(
  collapse = TRUE,
  comment = "#>",
  eval = TRUE
)

## ---- eval=FALSE--------------------------------------------------------------
#  library(CDMConnector)

## ---- eval=FALSE--------------------------------------------------------------
#  count_drug_records <- function(con, cdm_schema, ingredient_concept_id) {
#  
#    # Write the SQL in an R function replacing the parameters
#    sql <- glue::glue("
#      select count(*) as drug_count
#      from {cdm_schema}.drug_exposure de
#      inner join {cdm_schema}.concept_ancestor ca
#      on de.drug_concept_id = ca.descendant_concept_id
#      where ca.ancestor_concept_id = {ingredient_concept_id}")
#  
#    # Translate the sql to the correct dialect
#    sql <- SqlRender::translate(sql, targetDialect = dbms(con))
#  
#    # Execute the SQL and return the result
#    DBI::dbGetQuery(con, sql)
#  }

## ---- eval=FALSE--------------------------------------------------------------
#  library(DBI)
#  con <- DBI::dbConnect(RPostgres::Postgres(),
#                        dbname = "cdm",
#                        host = "localhost",
#                        user = "postgres",
#                        password = Sys.getenv("password"))
#  
#  count_drug_records(con, cdm_schema = "synthea1k", ingredient_concept_id = 923672)

## ---- echo=FALSE--------------------------------------------------------------
dplyr::tibble(drug_count = 11)

## ---- eval=FALSE--------------------------------------------------------------
#  dbms(con)

## ---- echo=FALSE--------------------------------------------------------------
print(c("postgresql"))

## ---- eval=FALSE--------------------------------------------------------------
#  count_drug_records <- function(con, cdm_schema, ingredient_concept_id) {
#  
#    # Write the SQL in an R function replacing the parameters
#    sql <- SqlRender::render("
#      select count(*) as drug_count
#      from @cdm_schema.drug_exposure de
#      inner join @cdm_schema.concept_ancestor ca
#      on de.drug_concept_id = ca.descendant_concept_id
#      where ca.ancestor_concept_id = @ingredient_concept_id",
#      cdm_schema = cdm_schema,
#      ingredient_concept_id = ingredient_concept_id)
#  
#    # Translate the sql to the correct dialect
#    sql <- SqlRender::translate(sql, targetDialect = dbms(con))
#  
#    # Execute the SQL and return the result
#    DBI::dbGetQuery(con, sql)
#  }
#  
#  count_drug_records(con, cdm_schema = "synthea1k", ingredient_concept_id = 923672)

## ---- echo=FALSE--------------------------------------------------------------
dplyr::tibble(drug_count = 11)


## ----include = FALSE----------------------------------------------------------
knitr::opts_chunk$set(
  collapse = TRUE,
  comment = "#>",
  eval = FALSE
)

## ----eval=FALSE---------------------------------------------------------------
#  con <- DBI::dbConnect(RPostgres::Postgres(),
#                        dbname = Sys.getenv("CDM5_POSTGRESQL_DBNAME"),
#                        host = Sys.getenv("CDM5_POSTGRESQL_HOST"),
#                        user = Sys.getenv("CDM5_POSTGRESQL_USER"),
#                        password = Sys.getenv("CDM5_POSTGRESQL_PASSWORD"))
#  
#  cdm <- cdm_from_con(con,
#                      cdm_schema = Sys.getenv("CDM5_POSTGRESQL_CDM_SCHEMA"),
#                      write_schema = Sys.getenv("CDM5_POSTGRESQL_SCRATCH_SCHEMA"))
#  DBI::dbDisconnect(con)

## ----eval=FALSE---------------------------------------------------------------
#  con <- DBI::dbConnect(RPostgres::Redshift(),
#                        dbname   = Sys.getenv("CDM5_REDSHIFT_DBNAME"),
#                        host     = Sys.getenv("CDM5_REDSHIFT_HOST"),
#                        port     = Sys.getenv("CDM5_REDSHIFT_PORT"),
#                        user     = Sys.getenv("CDM5_REDSHIFT_USER"),
#                        password = Sys.getenv("CDM5_REDSHIFT_PASSWORD"))
#  
#  cdm <- cdm_from_con(con,
#                      cdm_schema = Sys.getenv("CDM5_REDSHIFT_CDM_SCHEMA"),
#                      write_schema = Sys.getenv("CDM5_REDSHIFT_SCRATCH_SCHEMA"))
#  DBI::dbDisconnect(con)

## ----eval=FALSE---------------------------------------------------------------
#  con <- DBI::dbConnect(odbc::odbc(),
#                        Driver   = "ODBC Driver 18 for SQL Server",
#                        Server   = Sys.getenv("CDM5_SQL_SERVER_SERVER"),
#                        Database = Sys.getenv("CDM5_SQL_SERVER_CDM_DATABASE"),
#                        UID      = Sys.getenv("CDM5_SQL_SERVER_USER"),
#                        PWD      = Sys.getenv("CDM5_SQL_SERVER_PASSWORD"),
#                        TrustServerCertificate="yes",
#                        Port     = 1433)
#  
#  cdm <- cdm_from_con(con,
#                      cdm_schema = c("tempdb", "dbo"),
#                      write_schema =  c("ATLAS", "RESULTS"))
#  DBI::dbDisconnect(con)

## ----eval=FALSE---------------------------------------------------------------
#  con <- DBI::dbConnect(odbc::odbc(), "SQL")
#  cdm <- cdm_from_con(con,
#                      cdm_schema = c("tempdb", "dbo"),
#                      write_schema =  c("ATLAS", "RESULTS"))
#  DBI::dbDisconnect(con)

## ----eval=FALSE---------------------------------------------------------------
#  con <- DBI::dbConnect(odbc::odbc(),
#                            SERVER = Sys.getenv("SNOWFLAKE_SERVER"),
#                            UID = Sys.getenv("SNOWFLAKE_USER"),
#                            PWD = Sys.getenv("SNOWFLAKE_PASSWORD"),
#                            DATABASE = Sys.getenv("SNOWFLAKE_DATABASE"),
#                            WAREHOUSE = Sys.getenv("SNOWFLAKE_WAREHOUSE"),
#                            DRIVER = Sys.getenv("SNOWFLAKE_DRIVER"))
#  cdm <- cdm_from_con(con,
#                      cdm_schema =  c("OMOP_SYNTHETIC_DATASET", "CDM53"),
#                      write_schema =  c("ATLAS", "RESULTS"))
#  DBI::dbDisconnect(con)

## ----eval=FALSE---------------------------------------------------------------
#  con <- DBI::dbConnect(duckdb::duckdb(),
#                        dbdir=Sys.getenv("CDM5_DUCKDB_FILE"))
#  cdm <- cdm_from_con(con,
#                      cdm_schema = "main",
#                      write_schema = "main")
#  DBI::dbDisconnect(con)


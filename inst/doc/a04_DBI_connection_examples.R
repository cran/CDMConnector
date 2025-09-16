## ----include = FALSE----------------------------------------------------------
knitr::opts_chunk$set(
  collapse = TRUE,
  comment = "#>",
  eval = FALSE
)

## ----eval=FALSE---------------------------------------------------------------
# con <- DBI::dbConnect(RPostgres::Postgres(),
#                       dbname = Sys.getenv("CDM5_POSTGRESQL_DBNAME"),
#                       host = Sys.getenv("CDM5_POSTGRESQL_HOST"),
#                       user = Sys.getenv("CDM5_POSTGRESQL_USER"),
#                       password = Sys.getenv("CDM5_POSTGRESQL_PASSWORD"))
# 
# cdm <- cdmFromCon(con,
#                   cdmSchema = Sys.getenv("CDM5_POSTGRESQL_CDM_SCHEMA"),
#                   writeSchema = Sys.getenv("CDM5_POSTGRESQL_SCRATCH_SCHEMA"))
# 
# DBI::dbDisconnect(con)

## ----eval=FALSE---------------------------------------------------------------
# 
# library(DatabaseConnector)
# connectionDetails <- createConnectionDetails(dbms = "postgresql",
#                                              server = Sys.getenv("CDM5_POSTGRESQL_SERVER"),
#                                              user = Sys.getenv("CDM5_POSTGRESQL_USER"),
#                                              password = Sys.getenv("CDM5_POSTGRESQL_PASSWORD"))
# 
# 
# con <- connect(connectionDetails)
# 
# cdm <- cdmFromCon(con,
#                   cdmSchema = Sys.getenv("CDM5_POSTGRESQL_CDM_SCHEMA"),
#                   writeSchema = Sys.getenv("CDM5_POSTGRESQL_SCRATCH_SCHEMA"))
# 
# disconnect(con)

## ----eval=FALSE---------------------------------------------------------------
# con <- DBI::dbConnect(RPostgres::Redshift(),
#                       dbname   = Sys.getenv("CDM5_REDSHIFT_DBNAME"),
#                       host     = Sys.getenv("CDM5_REDSHIFT_HOST"),
#                       port     = Sys.getenv("CDM5_REDSHIFT_PORT"),
#                       user     = Sys.getenv("CDM5_REDSHIFT_USER"),
#                       password = Sys.getenv("CDM5_REDSHIFT_PASSWORD"))
# 
# cdm <- cdmFromCon(con,
#                   cdmSchema = Sys.getenv("CDM5_REDSHIFT_CDM_SCHEMA"),
#                   writeSchema = Sys.getenv("CDM5_REDSHIFT_SCRATCH_SCHEMA"))
# 
# DBI::dbDisconnect(con)

## ----eval=FALSE---------------------------------------------------------------
# library(DatabaseConnector)
# 
# connectionDetails <- createConnectionDetails(dbms = "redshift",
#                                              server = Sys.getenv("CDM5_REDSHIFT_SERVER"),
#                                              user = Sys.getenv("CDM5_REDSHIFT_USER"),
#                                              password = Sys.getenv("CDM5_REDSHIFT_PASSWORD"),
#                                              port = Sys.getenv("CDM5_REDSHIFT_PORT"))
# con <- connect(connectionDetails)
# 
# cdm <- cdmFromCon(con,
#                   cdmSchema = Sys.getenv("CDM5_REDSHIFT_CDM_SCHEMA"),
#                   writeSchema = Sys.getenv("CDM5_REDSHIFT_SCRATCH_SCHEMA"))
# 
# disconnect(con)

## ----eval=FALSE---------------------------------------------------------------
# con <- DBI::dbConnect(odbc::odbc(),
#                       Driver   = "ODBC Driver 18 for SQL Server",
#                       Server   = Sys.getenv("CDM5_SQL_SERVER_SERVER"),
#                       Database = Sys.getenv("CDM5_SQL_SERVER_CDM_DATABASE"),
#                       UID      = Sys.getenv("CDM5_SQL_SERVER_USER"),
#                       PWD      = Sys.getenv("CDM5_SQL_SERVER_PASSWORD"),
#                       TrustServerCertificate="yes",
#                       Port     = 1433)
# 
# cdm <- cdmFromCon(con,
#                     cdmSchema = c("cdmv54", "dbo"),
#                     writeSchema =  c("tempdb", "dbo"))
# 
# DBI::dbDisconnect(con)

## ----eval=FALSE---------------------------------------------------------------
# con <- DBI::dbConnect(odbc::odbc(), "SQL")
# cdm <- cdmFromCon(con,
#                     cdmSchema = c("tempdb", "dbo"),
#                     writeSchema =  c("ATLAS", "RESULTS"))
# DBI::dbDisconnect(con)

## ----eval=FALSE---------------------------------------------------------------
# library(DatabaseConnector)
# connectionDetails <- createConnectionDetails(
#   dbms = "sql server",
#   server = Sys.getenv("CDM5_SQL_SERVER_SERVER"),
#   user = Sys.getenv("CDM5_SQL_SERVER_USER"),
#   password = Sys.getenv("CDM5_SQL_SERVER_PASSWORD"),
#   port = Sys.getenv("CDM5_SQL_SERVER_PORT")
# )
# 
# con <- connect(connectionDetails)
# 
# cdm <- cdmFromCon(con,
#                   cdmSchema = c("cdmv54", "dbo"),
#                   writeSchema =  c("tempdb", "dbo"))
# 
# disconnect(con)

## ----eval=FALSE---------------------------------------------------------------
# con <- DBI::dbConnect(odbc::odbc(),
#                           SERVER = Sys.getenv("SNOWFLAKE_SERVER"),
#                           UID = Sys.getenv("SNOWFLAKE_USER"),
#                           PWD = Sys.getenv("SNOWFLAKE_PASSWORD"),
#                           DATABASE = Sys.getenv("SNOWFLAKE_DATABASE"),
#                           WAREHOUSE = Sys.getenv("SNOWFLAKE_WAREHOUSE"),
#                           DRIVER = Sys.getenv("SNOWFLAKE_DRIVER"))
# cdm <- cdmFromCon(con,
#                   cdmSchema =  c("OMOP_SYNTHETIC_DATASET", "CDM53"),
#                   writeSchema =  c("ATLAS", "RESULTS"))
# 
# DBI::dbDisconnect(con)

## ----eval=FALSE---------------------------------------------------------------
# library(DatabaseConnector)
# 
# connectionDetails <- createConnectionDetails(
#   dbms = "snowflake",
#   connectionString = Sys.getenv("SNOWFLAKE_CONNECTION_STRING"),
#   user = Sys.getenv("SNOWFLAKE_USER"),
#   password = Sys.getenv("SNOWFLAKE_PASSWORD")
# )
# 
# con <- connect(connectionDetails)
# 
# cdm <- cdmFromCon(con,
#                   cdmSchema =  c("OMOP_SYNTHETIC_DATASET", "CDM53"),
#                   writeSchema =  c("ATLAS", "RESULTS"))
# 
# disconnect(con)

## ----eval=FALSE---------------------------------------------------------------
# con <- DBI::dbConnect(
#   odbc::databricks(),
#   httpPath = Sys.getenv("DATABRICKS_HTTPPATH"),
#   useNativeQuery = FALSE
# )
# 
# cdm <- cdmFromCon(con,
#                   cdmSchema =  "gibleed",
#                   writeSchema = "scratch")
# 
# DBI::dbDisconnect(con)

## ----eval=FALSE---------------------------------------------------------------
# library(DatabaseConnector)
# 
# connectionDetails <- createConnectionDetails(
#   dbms = "spark",
#   user = "token",
#   password = Sys.getenv('DATABRICKS_TOKEN'),
#   connectionString = Sys.getenv('DATABRICKS_CONNECTION_STRING')
# )
# 
# con <- connect(connectionDetails)
# 
# 
# cdm <- cdmFromCon(con,
#                   cdmSchema =  "gibleed",
#                   writeSchema = "scratch")
# 
# disconnect(con)

## ----eval=FALSE---------------------------------------------------------------
# library(CDMConnector)
# con <- DBI::dbConnect(duckdb::duckdb(),
#                       dbdir = eunomiaDir("GiBleed"))
# 
# cdm <- cdmFromCon(con,
#                   cdmSchema = "main",
#                   writeSchema = "main")
# 
# DBI::dbDisconnect(con)

## ----eval=FALSE---------------------------------------------------------------
# library(DatabaseConnector)
# connectionDetails <- createConnectionDetails(
#   "duckdb",
#   server = CDMConnector::eunomiaDir("GiBleed"))
# 
# con <- connect(connectionDetails)
# 
# cdm <- cdmFromCon(con,
#                   cdmSchema = "main",
#                   writeSchema = "main")
# 
# 
# disconnect(con)


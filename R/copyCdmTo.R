# Copyright 2025 DARWIN EU®
#
# This file is part of CDMConnector
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

#' Copy a cdm object from one database to another
#'
#' It may be helpful to be able to easily copy a small test cdm from a local
#' database to a remote for testing. copyCdmTo takes a cdm object and a connection.
#' It copies the cdm to the remote database connection. CDM tables can be prefixed
#' in the new database allowing for multiple cdms in a single shared database
#' schema.
#'
#'
#' @param con A DBI database connection created by `DBI::dbConnect`
#' @param cdm A cdm reference object created by `CDMConnector::cdmFromCon` or `CDMConnector::cdm_from_con`
#' @param schema schema name in the remote database where the user has write permission
#' @param overwrite Should the cohort table be overwritten if it already exists? TRUE or FALSE (default)
#'
#' @return A cdm reference object pointing to the newly created cdm in the remote database
#' @export
copyCdmTo <- function(con, cdm, schema, overwrite = FALSE) {
  checkmate::assertTRUE(DBI::dbIsValid(con))
  checkmate::assertClass(cdm, "cdm_reference")
  if (dbms(con) == "bigquery") rlang::abort("copy_cdm_to on BigQuery is not yet supported!")
  checkmate::assertCharacter(schema, min.len = 1, max.len = 3, all.missing = F)
  checkmate::assertLogical(overwrite, len = 1)

  # create a new source
  newSource <- dbSource(con = con, writeSchema = schema)

  # insert person and observation_period
  cdmTables <- list()
  for (tab in c("person", "observation_period")) {
    cdmTables[[tab]] <- omopgenerics::insertTable(
      cdm = newSource,
      name = tab,
      table = cdm[[tab]] |> dplyr::collect() |> dplyr::as_tibble(),
      overwrite = overwrite
    )
  }

  # create cdm object
  newCdm <- omopgenerics::newCdmReference(
    tables = cdmTables, cdmName = omopgenerics::cdmName(cdm)
  )

  # copy all other tables
  tables_to_copy <- names(cdm)
  tables_to_copy <- tables_to_copy[
    !tables_to_copy %in% c("person", "observation_period")
  ]
  for (i in cli::cli_progress_along(tables_to_copy)) {
    table_name <- tables_to_copy[i]
    cohort <- inherits(cdm[[table_name]], "cohort_table")
    if (cohort) {
      set <- omopgenerics::settings(cdm[[table_name]]) |> dplyr::as_tibble()
      att <- omopgenerics::attrition(cdm[[table_name]]) |> dplyr::as_tibble()
      newCdm <- omopgenerics::insertTable(
        cdm = newCdm, name = paste0(table_name, "_set"), table = set,
        overwrite = overwrite
      )
      newCdm <- omopgenerics::insertTable(
        cdm = newCdm, paste0(table_name, "_attrition"), table = att,
        overwrite = overwrite
      )
    }
    newCdm <- omopgenerics::insertTable(
      cdm = newCdm,
      name = table_name,
      table = cdm[[table_name]] |> dplyr::collect() |> dplyr::as_tibble(),
      overwrite = overwrite
    )
    if (cohort) {
      newCdm[[table_name]] <- omopgenerics::newCohortTable(
        table = newCdm[[table_name]],
        cohortSetRef = newCdm[[paste0(table_name, "_set")]],
        cohortAttritionRef = newCdm[[paste0(table_name, "_attrition")]]
      )
      newCdm[[paste0(table_name, "_set")]] <- NULL
      newCdm[[paste0(table_name, "_attrition")]] <- NULL
    }
  }

  return(newCdm)
}

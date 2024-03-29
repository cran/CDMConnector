% Generated by roxygen2: do not edit by hand
% Please edit documentation in R/utils.R
\name{list_tables}
\alias{list_tables}
\alias{listTables}
\title{List tables in a schema}
\usage{
list_tables(con, schema = NULL)

listTables(con, schema = NULL)
}
\arguments{
\item{con}{A DBI connection to a database}

\item{schema}{The name of a schema in a database. If NULL, returns DBI::dbListTables(con).}
}
\value{
A character vector of table names
}
\description{
DBI::dbListTables can be used to get all tables in a database but not always in a
specific schema. \code{listTables} will list tables in a schema.
}
\examples{
\dontrun{
con <- DBI::dbConnect(duckdb::duckdb(), dbdir = eunomia_dir())
listTables(con, schema = "main")
}
}

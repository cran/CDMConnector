% Generated by roxygen2: do not edit by hand
% Please edit documentation in R/generate.R
\name{generateCohortSet}
\alias{generateCohortSet}
\title{Generate a set of cohorts}
\usage{
generateCohortSet(
  cdm,
  cohortSet,
  cohortTableName = "cohort",
  overwrite = FALSE
)
}
\arguments{
\item{cdm}{cdm reference object}

\item{cohortSet}{A cohort definition set dataframe}

\item{cohortTableName}{The name of the cohort table in the cdm. Defaults to 'cohort'.}

\item{overwrite}{Should the cohort table be overwritten if it already exists? TRUE or FALSE (default).}
}
\value{
cdm reference object with the added cohort table containing generated cohorts
}
\description{
This function generates a set of cohorts in the cohort table.
}

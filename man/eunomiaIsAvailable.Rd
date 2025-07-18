% Generated by roxygen2: do not edit by hand
% Please edit documentation in R/Eunomia.R
\name{eunomiaIsAvailable}
\alias{eunomiaIsAvailable}
\title{Has the Eunomia dataset been cached?}
\usage{
eunomiaIsAvailable(datasetName = "GiBleed", cdmVersion = "5.3")
}
\arguments{
\item{datasetName}{Name of the Eunomia dataset to check. Defaults to "GiBleed".}

\item{cdmVersion}{Version of the Eunomia dataset to check. Must be "5.3" or "5.4".}
}
\value{
TRUE if the eunomia example dataset is available and FALSE otherwise
}
\description{
Has the Eunomia dataset been cached?
}

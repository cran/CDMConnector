# CDMConnector 0.5.0

* Define `generatedCohortSet` class
* Add `summarize_quantile` for cross database quantile queries
* Add `GeneratedCohortSet` object, constructor, and attribute accessor functions
* Add vignette on cohort generation
* Add `cdmSubset`, `cdmSubsetCohort`, `cdmSample` for subsetting a cdm
* Add `cdmFlatten` for transforming a cdm into a single flat table of observations
* Improve test coverage
* Make Java dependency optional
* `cdm_schema` is now required in `cdm_from_con` except for duckdb connections
* Remove visit_detail from default cdm tables
* Deprecate `computePermanent`
* Improve package website

Substantial contributions by @edward-burn, @catalamarti, @Tsemharb who are now
package co-authors.

Released Mar 8, 2023

# CDMConnector 0.4.1

* Add `computeQuery` function for creating temp and persistent tables from dplyr queries
* Download Eunomia from darwin-eu repository as zipped csv files
* Add passing tests for Oracle and Spark
* Add `asDate` wrapper that provides correct as.Date dbplyr translations
* Incorporate code review suggestions from @mvankessel-EMC

Released Jan 21, 2023

# CDMConnector 0.3.0

* Add computePermanent and appendPermanent functions
* Add readCohortSet
* Add generateCohortSet
* Extract Eunomia dataset so that it is downloaded separately

Released Nov 29, 2022

# CDMConnector 0.2.0

* Add support for OMOP v5.3 and v5.4
* Add datediff and dateadd functions that can be used in dplyr::mutate() 
* Add assert_tables function for checking that a cdm object has required tables
* Add camelCase versions of several functions

Released Nov 15, 2022

# CDMConnector 0.1.0

* Initial release Sept 11, 2022
* Added a `NEWS.md` file to track changes to the package.

# Copyright 2024 DARWIN EU®
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

#' Union all cohorts in a single cohort table
#'
#' @param x A tbl reference to a cohort table
#' @param cohort_definition_id A number to use for the new cohort_definition_id
#'
#' `r lifecycle::badge("superseded")`
#'
#' @return A lazy query that when executed will resolve to a new cohort table with
#' one cohort_definition_id resulting from the union of all cohorts in the original
#' cohort table
#' @export
union_cohorts <- function(x, cohort_definition_id = 1L) {
  lifecycle::deprecate_warn("1.1.0", "union_cohorts()", "cohort_union()")
  checkmate::assert_class(x, "tbl")
  checkmate::assert_integerish(cohort_definition_id, len = 1, lower = 0)
  checkmate::assert_subset(c("cohort_definition_id", "subject_id", "cohort_start_date", "cohort_end_date"), colnames(x))
  cohort_definition_id <- as.integer(cohort_definition_id)

  event_date <- event_type <- NA # to remove r check error initialize these variables to NA

  x %>%
    dplyr::select("subject_id", event_date = "cohort_start_date") %>%
    dplyr::group_by(.data$subject_id) %>%
    dplyr::mutate(event_type = -1L, start_ordinal = dplyr::row_number(.data$event_date)) %>%
    dplyr::union_all(dplyr::transmute(x, .data$subject_id, event_date = .data$cohort_end_date, event_type = 1L, start_ordinal = NULL)) %>%
    {if ("tbl_sql" %in% class(.)) dbplyr::window_order(., event_date, event_type) else dplyr::arrange(., .data$event_date, .data$event_type)} %>%
    dplyr::mutate(start_ordinal = cummax(.data$start_ordinal), overall_ordinal = dplyr::row_number()) %>%
    dplyr::filter((2 * .data$start_ordinal) == .data$overall_ordinal) %>%
    dplyr::transmute(.data$subject_id, end_date = .data$event_date) %>%
    dplyr::distinct() %>%
    dplyr::inner_join(x, by = "subject_id") %>%
    dplyr::filter(.data$end_date >= .data$cohort_start_date) %>%
    dplyr::group_by(.data$subject_id, .data$cohort_start_date) %>%
    dplyr::summarise(cohort_end_date = min(.data$end_date, na.rm = TRUE), .groups = "drop") %>%
    dplyr::group_by(.data$subject_id, .data$cohort_end_date) %>%
    dplyr::summarise(cohort_start_date = min(.data$cohort_start_date, na.rm = TRUE), .groups = "drop") %>%
    dplyr::mutate(cohort_definition_id = .env$cohort_definition_id) %>%
    dplyr::select("cohort_definition_id", "subject_id", "cohort_start_date", "cohort_end_date")
}

#' Intersect all cohorts in a single cohort table
#'
#' @param x A tbl reference to a cohort table
#' @param cohort_definition_id A number to use for the new cohort_definition_id
#'
#' `r lifecycle::badge("superseded")`
#'
#' @return A lazy query that when executed will resolve to a new cohort table with
#' one cohort_definition_id resulting from the intersection of all cohorts in the original
#' cohort table
#' @export
intersect_cohorts <- function(x, cohort_definition_id = 1L) {
  lifecycle::deprecate_warn("1.1.0", "intersect_cohorts()", "cohort_intersect()")
  checkmate::assert_class(x, "tbl")
  checkmate::assert_integerish(cohort_definition_id, len = 1, lower = 0)
  checkmate::assert_subset(c("cohort_definition_id", "subject_id", "cohort_start_date", "cohort_end_date"), colnames(x))
  cohort_definition_id <- as.integer(cohort_definition_id)

  # get the total number of cohorts we are intersecting together
  n_cohorts_to_intersect <- x %>%
    dplyr::distinct(.data$cohort_definition_id) %>%
    dplyr::tally(name = "n") %>%
    dplyr::pull("n")

  checkmate::checkIntegerish(n_cohorts_to_intersect, len = 1)

  # create every possible interval
  candidate_intervals <- x %>%
    dplyr::select("subject_id", cohort_date = "cohort_start_date") %>%
    dplyr::union_all(dplyr::select(x, "subject_id", cohort_date = "cohort_end_date")) %>%
    dplyr::group_by(.data$subject_id) %>%
    dplyr::mutate(cohort_date_seq = dplyr::row_number(.data$cohort_date)) %>%
    dplyr::mutate(candidate_start_date = .data$cohort_date,
                  candidate_end_date = dplyr::lead(.data$cohort_date, order_by = c("cohort_date", "cohort_date_seq")))

  # get intervals that are contained within all of the cohorts
  x %>%
    dplyr::inner_join(candidate_intervals, by = "subject_id") %>%
    dplyr::filter(.data$candidate_start_date >= .data$cohort_start_date,
                  .data$candidate_end_date <= .data$cohort_end_date) %>%
    dplyr::distinct(.data$cohort_definition_id,
                    .data$subject_id,
                    .data$candidate_start_date,
                    .data$candidate_end_date) %>%
    dplyr::group_by(.data$subject_id,
                    .data$candidate_start_date,
                    .data$candidate_end_date) %>%
    dplyr::summarise(n_cohorts_interval_is_inside = dplyr::n(), .groups = "drop") %>%
    # only keep intervals that are inside all cohorts we want to intersect (i.e. all cohorts in the input cohort table)
    dplyr::filter(.data$n_cohorts_interval_is_inside == .env$n_cohorts_to_intersect) %>%
    dplyr::mutate(cohort_definition_id = .env$cohort_definition_id) %>%
    dplyr::select("cohort_definition_id",
                  "subject_id",
                  cohort_start_date = "candidate_start_date",
                  cohort_end_date = "candidate_end_date") %>%
    union_cohorts(cohort_definition_id = cohort_definition_id)
}

#' @rdname intersect_cohorts
#' @export
intersectCohorts <- intersect_cohorts

#' @rdname union_cohorts
#' @export
unionCohorts <- union_cohorts

# R/utils.R

allowed_statuses <- c("RECEIVED", "EXTRACTED", "SEQUENCED", "REPORTED")

validate_sample_input <- function(body) {
  required <- c("sample_id", "patient_id", "test_type", "status")
  
  missing <- setdiff(required, names(body))
  if (length(missing) > 0) {
    stop(paste("Missing fields:", paste(missing, collapse = ", ")))
  }
  
  if (!is.character(body$sample_id) || !nzchar(body$sample_id)) {
    stop("sample_id must be a non-empty string")
  }
  
  if (!is.character(body$patient_id) || !nzchar(body$patient_id)) {
    stop("patient_id must be a non-empty string")
  }
  
  if (!is.character(body$test_type) || !nzchar(body$test_type)) {
    stop("test_type must be a non-empty string")
  }
  
  if (!is.character(body$status) || !body$status %in% allowed_statuses) {
    stop(paste(
      "Invalid status. Allowed:",
      paste(allowed_statuses, collapse = ", ")
    ))
  }
  
  TRUE
}
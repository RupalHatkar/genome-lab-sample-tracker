# R/api.R
#* @apiTitle Sample Tracker API
#* @apiDescription API for tracking laboratory sample workflow status.

library(plumber)
library(DBI)
#library(jsonlite)
source("db.R")
source("utils.R")

iso_now <- function() format(Sys.time(), "%Y-%m-%dT%H:%M:%SZ", tz = "UTC")

#* @filter cors
function(req, res) {
  res$setHeader("Access-Control-Allow-Origin", "*")
  res$setHeader("Access-Control-Allow-Methods", "GET, POST, PATCH, OPTIONS")
  res$setHeader("Access-Control-Allow-Headers", "Content-Type")
  if (req$REQUEST_METHOD == "OPTIONS") {
    res$status <- 200
    return(list())
  }
  plumber::forward()
}

#* @param req
#* @get /health
function(req) {
  list(status = "ok", timestamp = iso_now())
}

#* Create a new sample
#* @post /samples
#* @serializer json
function(req, res) {
  body <- jsonlite::fromJSON(req$postBody)
  
  tryCatch({
    validate_sample_input(body)
    
    con <- get_con()
    on.exit(dbDisconnect(con), add = TRUE)
    
    now <- iso_now()
    
    dbWithTransaction(con, {
      dbExecute(
        con,
        "
        INSERT INTO samples (
          sample_id, patient_id, test_type, status, created_at, updated_at
        )
        VALUES (?, ?, ?, ?, ?, ?)
        ",
        params = list(
          body$sample_id,
          body$patient_id,
          body$test_type,
          body$status,
          now,
          now
        )
      )
      
      dbExecute(
        con,
        "
        INSERT INTO audit_log (
          sample_id, action, old_status, new_status, performed_at, performed_by
        )
        VALUES (?, ?, ?, ?, ?, ?)
        ",
        params = list(
          body$sample_id,
          "CREATE",
          NA_character_,
          body$status,
          now,
          NA_character_
        )
      )
    })
    
    res$status <- 201
    list(created = TRUE, sample_id = body$sample_id)
  }, error = function(e) {
    res$status <- 400
    list(error = paste("Unable to create sample:", e$message))
  })
}

#* List samples with optional filters
#* @get /samples
#* @param status Filter by status (optional)
#* @param from_date Filter by created_at >= from_date (ISO8601, optional)
#* @param to_date Filter by created_at <= to_date (ISO8601, optional)
#* @param req
function(req, status = NULL, from_date = NULL, to_date = NULL) {
  con <- get_con()
  
  sql <- "SELECT * FROM samples WHERE 1=1"
  params <- list()
  
  if (!is.null(status) && nzchar(status)) {
    sql <- paste0(sql, " AND status = ?")
    params <- c(params, list(status))
  }
  
  if (!is.null(from_date) && nzchar(from_date)) {
    sql <- paste0(sql, " AND created_at >= ?")
    params <- c(params, list(from_date))
  }
  
  if (!is.null(to_date) && nzchar(to_date)) {
    sql <- paste0(sql, " AND created_at <= ?")
    params <- c(params, list(to_date))
  }
  
  df <- if (length(params) == 0) {
    dbGetQuery(con, sql)
  } else {
    dbGetQuery(con, sql, params = params)
  }
  dbDisconnect(con)
  
  records <- if (nrow(df) == 0) {
    list()
  } else {
    lapply(seq_len(nrow(df)), function(i) {
      as.list(df[i, , drop = FALSE])
    })
  }
  
  list(count = nrow(df), samples = records)
}

#* Get a single sample by sample_id
#* @get /samples/<id>
#* @param id sample_id
#* @param req
function(req, id) {
  con <- get_con()
  df <- dbGetQuery(con, "SELECT * FROM samples WHERE sample_id = ?", params = list(id))
  dbDisconnect(con)
  
  if (nrow(df) == 0) {
    plumber::bail(404, "Sample not found")
  }
  
  as.list(df[1, , drop = FALSE])
}

#* Update sample status
#* @patch /samples/<id>
#* @serializer json
#* @param id sample_id
#* @param req
#* @param res
function(req, res, id) {
  body <- jsonlite::fromJSON(req$postBody)
  
  tryCatch({
    if (is.null(body$status) || !is.character(body$status)) {
      stop("Missing or invalid field: status")
    }
    
    new_status <- body$status
    
    if (!new_status %in% allowed_statuses) {
      stop(paste(
        "Invalid status. Allowed:",
        paste(allowed_statuses, collapse = ", ")
      ))
    }
    
    con <- get_con()
    on.exit(dbDisconnect(con), add = TRUE)
    
    now <- iso_now()
    
    result <- dbWithTransaction(con, {
      df <- dbGetQuery(
        con,
        "SELECT status FROM samples WHERE sample_id = ?",
        params = list(id)
      )
      
      if (nrow(df) == 0) {
        stop("Sample not found")
      }
      
      old_status <- df$status[[1]]
      
      dbExecute(
        con,
        "
        UPDATE samples
        SET status = ?, updated_at = ?
        WHERE sample_id = ?
        ",
        params = list(new_status, now, id)
      )
      
      dbExecute(
        con,
        "
        INSERT INTO audit_log (
          sample_id, action, old_status, new_status, performed_at, performed_by
        )
        VALUES (?, ?, ?, ?, ?, ?)
        ",
        params = list(
          id,
          "UPDATE_STATUS",
          old_status,
          new_status,
          now,
          NA_character_
        )
      )
      
      list(
        updated = TRUE,
        sample_id = id,
        old_status = old_status,
        new_status = new_status
      )
    })
    
    result
  }, error = function(e) {
    if (identical(e$message, "Sample not found")) {
      res$status <- 404
    } else {
      res$status <- 400
    }
    
    list(error = paste("Unable to update sample:", e$message))
  })
}
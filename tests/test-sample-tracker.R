library(testthat)
library(DBI)
library(RSQLite)
library(withr)

source(file.path("..", "R", "db.R"))
source(file.path("..", "R", "utils.R"))

test_that("valid sample input passes validation", {
  body <- list(
    sample_id = "TEST001",
    patient_id = "PATIENT001",
    test_type = "WGS",
    status = "RECEIVED"
  )
  
  expect_true(validate_sample_input(body))
})

test_that("missing required fields fail validation", {
  body <- list(
    sample_id = "TEST002",
    patient_id = "PATIENT002",
    status = "RECEIVED"
  )
  
  expect_error(
    validate_sample_input(body),
    "Missing fields: test_type"
  )
})

test_that("invalid workflow status fails validation", {
  body <- list(
    sample_id = "TEST003",
    patient_id = "PATIENT003",
    test_type = "WGS",
    status = "INVALID_STATUS"
  )
  
  expect_error(
    validate_sample_input(body),
    "Invalid status"
  )
})

test_that("database creates sample and audit entry", {
  test_db <- file.path(tempdir(), "sample_tracker_test.sqlite")
  unlink(test_db)
  
  with_envvar(
    c(SAMPLE_TRACKER_DB = test_db),
    {
      con <- get_con()
      on.exit(dbDisconnect(con), add = TRUE)
      
      now <- "2026-09-22T12:00:00Z"
      
      dbExecute(
        con,
        "
        INSERT INTO samples (
          sample_id, patient_id, test_type, status, created_at, updated_at
        )
        VALUES (?, ?, ?, ?, ?, ?)
        ",
        params = list(
          "TEST004",
          "PATIENT004",
          "RNAseq",
          "RECEIVED",
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
          "TEST004",
          "CREATE",
          NA_character_,
          "RECEIVED",
          now,
          "test_user"
        )
      )
      
      sample_row <- dbGetQuery(
        con,
        "SELECT * FROM samples WHERE sample_id = ?",
        params = list("TEST004")
      )
      
      audit_rows <- dbGetQuery(
        con,
        "SELECT * FROM audit_log WHERE sample_id = ?",
        params = list("TEST004")
      )
      
      expect_equal(nrow(sample_row), 1)
      expect_equal(sample_row$status[[1]], "RECEIVED")
      expect_equal(nrow(audit_rows), 1)
      expect_equal(audit_rows$action[[1]], "CREATE")
      expect_equal(audit_rows$new_status[[1]], "RECEIVED")
    }
  )
  
  unlink(test_db)
})

test_that("duplicate sample IDs are rejected by the database", {
  test_db <- file.path(tempdir(), "duplicate_sample_test.sqlite")
  unlink(test_db)
  
  with_envvar(
    c(SAMPLE_TRACKER_DB = test_db),
    {
      con <- get_con()
      on.exit(dbDisconnect(con), add = TRUE)
      
      now <- "2026-09-22T12:00:00Z"
      
      dbExecute(
        con,
        "
        INSERT INTO samples (
          sample_id, patient_id, test_type, status, created_at, updated_at
        )
        VALUES (?, ?, ?, ?, ?, ?)
        ",
        params = list(
          "TEST005",
          "PATIENT005",
          "WGS",
          "RECEIVED",
          now,
          now
        )
      )
      
      expect_error(
        dbExecute(
          con,
          "
          INSERT INTO samples (
            sample_id, patient_id, test_type, status, created_at, updated_at
          )
          VALUES (?, ?, ?, ?, ?, ?)
          ",
          params = list(
            "TEST005",
            "PATIENT005B",
            "WGS",
            "RECEIVED",
            now,
            now
          )
        ),
        "UNIQUE constraint failed"
      )
    }
  )
  
  unlink(test_db)
})

test_that("status update persists and creates an audit record", {
  test_db <- file.path(tempdir(), "status_update_test.sqlite")
  unlink(test_db)
  
  with_envvar(
    c(SAMPLE_TRACKER_DB = test_db),
    {
      con <- get_con()
      on.exit(dbDisconnect(con), add = TRUE)
      
      created_at <- "2026-09-22T12:00:00Z"
      updated_at <- "2026-09-22T12:05:00Z"
      
      dbExecute(
        con,
        "
        INSERT INTO samples (
          sample_id, patient_id, test_type, status, created_at, updated_at
        )
        VALUES (?, ?, ?, ?, ?, ?)
        ",
        params = list(
          "TEST006",
          "PATIENT006",
          "WGS",
          "RECEIVED",
          created_at,
          created_at
        )
      )
      
      dbExecute(
        con,
        "
        UPDATE samples
        SET status = ?, updated_at = ?
        WHERE sample_id = ?
        ",
        params = list(
          "EXTRACTED",
          updated_at,
          "TEST006"
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
          "TEST006",
          "UPDATE_STATUS",
          "RECEIVED",
          "EXTRACTED",
          updated_at,
          "test_user"
        )
      )
      
      sample_row <- dbGetQuery(
        con,
        "SELECT status, updated_at FROM samples WHERE sample_id = ?",
        params = list("TEST006")
      )
      
      audit_row <- dbGetQuery(
        con,
        "
        SELECT action, old_status, new_status
        FROM audit_log
        WHERE sample_id = ?
        ",
        params = list("TEST006")
      )
      
      expect_equal(sample_row$status[[1]], "EXTRACTED")
      expect_equal(sample_row$updated_at[[1]], updated_at)
      expect_equal(audit_row$action[[1]], "UPDATE_STATUS")
      expect_equal(audit_row$old_status[[1]], "RECEIVED")
      expect_equal(audit_row$new_status[[1]], "EXTRACTED")
    }
  )
  
  unlink(test_db)
})
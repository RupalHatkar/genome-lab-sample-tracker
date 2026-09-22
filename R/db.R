# R/db.R
library(DBI)
library(RSQLite)
library(fs)

get_project_root <- function() {
  # Assumes db.R is inside the project's R/ folder.
  normalizePath(file.path(getwd(), ".."), mustWork = FALSE)
}

get_db_path <- function() {
  configured_path <- Sys.getenv("SAMPLE_TRACKER_DB", unset = "")
  
  if (nzchar(configured_path)) {
    db_path <- configured_path
  } else {
    # If launched by Plumber from R/, use ../data.
    # If launched from project root, use data.
    if (basename(getwd()) == "R") {
      db_path <- file.path("..", "data", "samples.sqlite")
    } else {
      db_path <- file.path("data", "samples.sqlite")
    }
  }
  
  db_path <- normalizePath(db_path, mustWork = FALSE)
  dir_create(path_dir(db_path))
  db_path
}

init_db <- function() {
  db_path <- get_db_path()
  con <- dbConnect(RSQLite::SQLite(), db_path)
  
  dbExecute(con, "PRAGMA busy_timeout = 5000")
  dbExecute(con, "PRAGMA journal_mode = WAL")
  
  dbExecute(con, "
    CREATE TABLE IF NOT EXISTS samples (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      sample_id TEXT UNIQUE NOT NULL,
      patient_id TEXT NOT NULL,
      test_type TEXT NOT NULL,
      status TEXT NOT NULL,
      created_at TEXT NOT NULL,
      updated_at TEXT NOT NULL
    )
  ")
  
  dbExecute(con, "
    CREATE TABLE IF NOT EXISTS audit_log (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      sample_id TEXT NOT NULL,
      action TEXT NOT NULL,
      old_status TEXT,
      new_status TEXT,
      performed_at TEXT NOT NULL,
      performed_by TEXT
    )
  ")
  
  con
}

get_con <- function() {
  init_db()
}
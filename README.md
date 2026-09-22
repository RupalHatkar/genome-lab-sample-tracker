# Genome Lab Sample Tracker (R + Plumber)

A minimal database-backed application for tracking laboratory sample workflow status, designed to demonstrate software engineering practices relevant to clinical genomics informatics.

## Purpose

- Demonstrate ability to design, build, test, document, and deploy a database-backed API for lab operations.
- Illustrate patterns suitable for clinical environments: validation, audit logging, reproducible deployment, and basic CI.

## Architecture

- **API:** Plumber (R) exposing REST endpoints for sample management.
- **Database:** SQLite (file-based) via DBI + RSQLite.
- **Optional UI:** Shiny app consuming the API (to be added).
- **Deployment:** Docker container running the Plumber API; DB mounted as volume.

## Core Entities

### samples

- `id` (INTEGER PRIMARY KEY)
- `sample_id` (TEXT UNIQUE NOT NULL)
- `patient_id` (TEXT NOT NULL)
- `test_type` (TEXT NOT NULL)
- `status` (TEXT NOT NULL; allowed: `RECEIVED`, `EXTRACTED`, `SEQUENCED`, `REPORTED`)
- `created_at` (TEXT ISO8601)
- `updated_at` (TEXT ISO8601)

### audit_log (optional but recommended)

- `id` (INTEGER PRIMARY KEY)
- `sample_id` (TEXT NOT NULL)
- `action` (TEXT NOT NULL; e.g., `CREATE`, `UPDATE_STATUS`)
- `old_status` (TEXT NULL)
- `new_status` (TEXT NULL)
- `performed_at` (TEXT ISO8601)
- `performed_by` (TEXT; optional user/API key)

## API Endpoints (planned)

- `POST   /samples`          – create a sample  
- `GET    /samples`          – list samples (with optional filters)  
- `GET    /samples/{id}`     – get a sample by `sample_id`  
- `PATCH  /samples/{id}`     – update sample status  
- `GET    /health`           – health check  

## Validation & Clinical Considerations

- Input validation on all endpoints (required fields, allowed status values).
- Audit logging for all state changes.
- Documented test plan and validation approach suitable for a clinical environment.
- Reproducible deployment via Docker; environment configuration via env vars.
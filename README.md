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

## Clinical and Privacy Safeguards

This repository is a non-clinical educational prototype. It must not be used with real patient data, clinical sequencing data, clinical results, or production systems.

The prototype demonstrates foundational controls—validation, unique identifiers, timestamps, audit logging, automated tests, CI, and reproducible containerization—but it is not clinically validated.

A production clinical implementation would require formal requirements traceability, risk assessment, access control, authentication, encryption, approved hosting, backup/recovery testing, LIMS interface validation, privacy/security review, user acceptance testing, SOPs, controlled release, and ongoing monitoring.

## User Interfaces

The prototype includes two demonstration interfaces that use synthetic data only.

### Shiny UI

Start the API and Shiny UI together:

```bash
docker compose -f docker/docker-compose.yml up --build
```

Open:

- Shiny UI: `http://127.0.0.1:3838`
- API health endpoint: `http://127.0.0.1:8001/health`

The Shiny UI supports creating a sample, listing samples, and updating workflow status. It connects to the API through the internal Docker Compose network.

### Static HTML/JavaScript UI

The static UI is located at `ui-static/index.html`. For local development, serve it from the project root:

```bash
cd ui-static
python3 -m http.server 8080
```

Open `http://127.0.0.1:8080`.

The API enables CORS for this demonstration interface. The permissive development setting must be restricted to approved origins before any production deployment.

# Requirements Traceability Matrix

## Prototype traceability

| Requirement ID | Requirement summary | Implementation location | Verification evidence | Status |
|---|---|---|---|---|
| UR-001 | Create valid sample record. | `R/api.R`, `R/db.R`, `R/utils.R` | Valid-input and database-insert tests | Verified |
| UR-002 | Reject missing required fields. | `R/utils.R` | Missing-field test | Verified |
| UR-003 | Permit only predefined statuses. | `R/utils.R` | Invalid-status test | Verified |
| UR-004 | Retrieve sample by unique identifier. | `R/api.R` | Manual API verification with `GET /samples/<id>` | Manually verified |
| UR-005 | List and filter samples. | `R/api.R` | Manual API verification with `GET /samples` and query parameters | Manually verified |
| UR-006 | Update status and timestamp. | `R/api.R`, `R/db.R` | Status-update database test; manual PATCH verification | Verified |
| UR-007 | Prevent duplicate sample identifiers. | `R/db.R` | Duplicate-ID database test | Verified |
| UR-008 | Maintain creation and status-update audit trail. | `R/api.R`, `R/db.R` | Audit-log creation and update tests; manual database query | Verified |
| UR-009 | Use isolated test databases. | `tests/test-sample-tracker.R` | Temporary SQLite paths defined in automated tests | Verified |
| UR-010 | Run tests through CI. | `.github/workflows/r-ci.yml` | Green GitHub Actions workflow | Verified |

## Notes

- “Verified” means evidence exists in the automated test suite and/or documented validation activity for this prototype.
- “Manually verified” means the behavior was tested interactively through local API calls but is not yet covered by an automated endpoint-level integration test.
- Before clinical use, all requirements would need approved test protocols, complete execution evidence, review, formal acceptance criteria, and controlled release documentation.
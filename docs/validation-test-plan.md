# Validation Test Plan

## 1. Purpose

This document defines the verification approach for the Genome Lab Sample Tracker prototype. It provides documented evidence that the implemented prototype meets its stated non-clinical requirements.

This document does not constitute clinical validation or authorization for clinical use.

## 2. Scope

The plan covers:

- Input validation.
- SQLite database schema and persistence.
- Unique sample-identifier constraint.
- Sample status updates.
- Audit-log creation.
- Automated test execution.
- Continuous integration execution.

The plan excludes security validation, LIMS interface validation, performance testing, load testing, production deployment qualification, clinical workflow user acceptance testing, and validation with real patient data.

## 3. Test environment

| Component | Test environment |
|---|---|
| Operating system | macOS development environment and GitHub-hosted Ubuntu CI runner |
| Language | R 4.4.x |
| API framework | Plumber |
| Database | SQLite temporary test database |
| Test framework | testthat |
| Version control | Git/GitHub |
| CI | GitHub Actions |
| Test data | Synthetic data only |

## 4. Entry criteria

- Source code is committed to the repository.
- Required R packages are installed.
- Test database is isolated from development data.
- No real patient or clinical data are used.

## 5. Test cases

| Test ID | Requirement | Test activity | Expected result | Evidence |
|---|---|---|---|---|
| VT-001 | UR-001 | Validate a complete, valid sample payload. | Input validation succeeds. | Automated test output |
| VT-002 | UR-002 | Submit a payload missing `test_type`. | Validation returns an error. | Automated test output |
| VT-003 | UR-003 | Submit a payload with an invalid workflow status. | Validation returns an error. | Automated test output |
| VT-004 | UR-001, UR-007 | Insert a sample into a temporary SQLite database. | One row is stored with expected values. | Automated test output |
| VT-005 | UR-007 | Insert a second record using the same sample ID. | Database rejects insert due to unique constraint. | Automated test output |
| VT-006 | UR-008 | Create a sample and inspect `audit_log`. | Audit row shows action `CREATE` and expected new status. | Automated test output |
| VT-007 | UR-006, UR-008 | Change a sample from RECEIVED to EXTRACTED. | Sample status and timestamp update; audit row records old/new status. | Automated test output |
| VT-008 | UR-009 | Run tests using temporary database paths. | Tests do not access project development database. | Test implementation review |
| VT-009 | UR-010 | Push changes to GitHub repository. | GitHub Actions installs dependencies and passes tests. | Green CI run |

## 6. Acceptance criteria

The prototype verification is considered successful when:

- All automated tests pass locally.
- The GitHub Actions CI workflow passes on a clean Ubuntu runner.
- No real patient data are present in the repository or test records.
- Each implemented user requirement has documented verification evidence.

## 7. Deviations

Any unexpected test failure, environment issue, or requirement change must be recorded, assessed for impact, corrected as appropriate, and retested before the prototype is considered verified.

## 8. Change control approach

For each proposed change:

1. Record the requested change and rationale.
2. Identify impacted requirements, source code, database schema, documentation, tests, interfaces, and operational workflows.
3. Assess risk, including patient-safety, privacy, data-integrity, and downtime risks if applicable.
4. Obtain appropriate review/approval before implementation.
5. Implement in version control using a branch and pull request.
6. Update affected tests and documentation.
7. Run automated regression tests and targeted validation.
8. Document results, review the release, and deploy through controlled development, staging, and production environments.

## 9. Limitations

The prototype contains only foundational functional verification. A clinical production system would require substantially broader validation, including approved user requirements, risk management, privacy/security assessment, formal test protocols and results, traceability, interface testing, user acceptance testing, access controls, disaster recovery, training, and change-control records.
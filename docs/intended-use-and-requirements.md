# Intended Use and User Requirements

## 1. Prototype status

This repository contains a software-development prototype created for learning and demonstration. It is not validated for clinical use, is not connected to a Laboratory Information Management System (LIMS), and must not store, transmit, or process real patient information.

All test identifiers used in this repository are synthetic.

## 2. Intended use

The Genome Lab Sample Tracker prototype is intended to demonstrate how a database-backed REST API could support tracking of laboratory sample workflow status in a genomics laboratory.

The prototype supports the following non-clinical functions:

- Create a sample record with a unique sample identifier, synthetic patient identifier, test type, and workflow status.
- Retrieve an individual sample record.
- List sample records and optionally filter by workflow status or creation date.
- Update a sample workflow status.
- Record creation and workflow-status changes in an audit-log table.
- Validate required fields and permitted workflow-status values.

## 3. Out of scope

The prototype does not provide:

- Clinical decision support, variant interpretation, or clinical reporting.
- Integration with an operational LIMS, electronic health record, laboratory instrument, or external clinical system.
- Authentication, authorization, role-based access controls, single sign-on, or user provisioning.
- Encryption, key management, production backups, disaster recovery, monitoring, or incident-management tooling.
- A production-grade relational database or multi-user concurrency design.
- Formal clinical validation, release approval, or deployment to a clinical environment.

## 4. Data classification

Only synthetic, non-identifiable test data may be used in the prototype.

No real patient identifiers, protected health information, sequencing data, variant data, clinical results, or credentials may be placed in the repository, Docker image, development database, logs, test fixtures, or GitHub Actions output.

## 5. User requirements

| ID | User requirement | Risk addressed |
|---|---|---|
| UR-001 | The system shall create a sample record with a unique sample identifier, patient identifier, test type, and valid workflow status. | Incomplete or duplicated sample records |
| UR-002 | The system shall reject requests missing required sample fields. | Incomplete workflow information |
| UR-003 | The system shall allow only predefined workflow statuses: RECEIVED, EXTRACTED, SEQUENCED, and REPORTED. | Invalid or ambiguous workflow state |
| UR-004 | The system shall retrieve a sample by its unique sample identifier. | Inability to locate a tracked sample |
| UR-005 | The system shall list sample records and support optional status and date filters. | Operational visibility limitations |
| UR-006 | The system shall update a sample workflow status and record the update timestamp. | Untracked workflow progression |
| UR-007 | The system shall prevent duplicate sample identifiers. | Duplicate or conflicting records |
| UR-008 | The system shall write an audit record for sample creation and each status update, including old and new status and timestamp. | Lack of traceability |
| UR-009 | Automated tests shall run using isolated temporary databases. | Test contamination of development data |
| UR-010 | The test suite shall run automatically in continuous integration on changes pushed to the repository. | Undetected regression |

## 6. Production controls required before clinical use

Before a system of this type could be considered for clinical deployment, it would require formal requirements review and approval; risk assessment; access controls and authentication; audit logging that includes authenticated user identity; encryption in transit and at rest; vulnerability and security review; backup and recovery validation; production database design; interface specifications and integration testing; user-acceptance testing; training; SOPs; change control; release approval; and ongoing production monitoring.
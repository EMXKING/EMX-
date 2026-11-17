# Feature Verification Rules

These rules exist so that documentation, commit messages and reports never claim more than has been done.

## Status vocabulary

| Status | Meaning | Evidence required |
|--------|---------|-------------------|
| **Designed** | Described in documentation only | A document or ADR |
| **Implemented** | Code exists and builds | Code merged or on a branch; build output |
| **Tested** | Automated tests exist and passed | Test run output recorded |
| **Verified** | Behaviour confirmed in a running environment, including security properties | Tests plus a recorded run against real PostgreSQL and Keycloak; for security controls, a test that fails when the control is removed |

A feature can only be described with the highest status for which evidence exists.

## Rules

1. Never state that something is implemented, tested or verified unless the work was actually performed and the evidence is available.
2. A security control (tenant isolation, authorisation, audit, token validation) is **Designed** until its tests have run against real infrastructure.
3. Mocks and simulations are not verification of real behaviour. They are not used to stand in for functionality.
4. If something could not be run (for example because of a network or Docker limitation), the report says so explicitly and names the blocker.
5. Documentation lists unverified items as unverified, including in ADRs.
6. A pull request states the verification status of each change.

## Current status of the project

| Area | Status | Evidence |
|------|--------|----------|
| PostgreSQL tenant-isolation core (schema, migrations, RLS, roles, privileges) | **Tested** at the database level | `db/tests/run.sh`: 166 checks passed on a disposable PostgreSQL 16.15 cluster, 2026-11-17. `db/tests/mutation_check.sh`: 6 of 6 deliberately broken controls were caught by the suite |
| Tenant isolation end to end (backend guards, Keycloak identity, real client connections) | **Designed** | Backend and Keycloak do not exist yet |
| Authentication, authorisation and audit in the backend | **Designed** | Not implemented |
| Frontend, internationalisation, Keycloak `ui_locales`, `Accept-Language` handling | **Designed** | Not implemented. Keycloak behaviour is unverified |
| Docker Compose environment | **Designed** | Docker daemon starts here, but image pulls are blocked |

The database layer is **Tested**, not **Verified**: verification requires the same controls to be confirmed through the running backend with real Keycloak identity. One limitation is asserted and documented: arbitrary SQL executed as the application role can forge the tenant context ([db/README.md](../../db/README.md)).

## Definition of done (per feature)

- Code implemented with strict typing and lint passing
- Unit and integration tests passing against real PostgreSQL where relevant
- Tenant isolation test and authorisation test for the feature
- Audit events emitted and tested
- English (`en`) and Portuguese (`pt`) translations complete and checked. A feature without both is not complete.
- No secrets, no hardcoded business data, no simulated behaviour
- Documentation updated

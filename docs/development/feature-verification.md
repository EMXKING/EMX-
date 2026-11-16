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

Everything in this repository is **Designed**. No code is implemented, no test has run and no control is verified.

## Definition of done (per feature)

- Code implemented with strict typing and lint passing
- Unit and integration tests passing against real PostgreSQL where relevant
- Tenant isolation test and authorisation test for the feature
- Audit events emitted and tested
- `pt` and `en` translations complete and checked
- No secrets, no hardcoded business data, no simulated behaviour
- Documentation updated

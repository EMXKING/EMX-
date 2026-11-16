# Phase 1 Implementation Sequence

Status: **Plan. Stage 0 (documentation) is the only stage in progress. Stages 1 and later are blocked** until the items in [blockers](blockers-and-open-questions.md) are resolved.

Phase 1 goal: a real, tenant-isolated foundation with real Keycloak login and complete `pt`/`en` support, plus the first real business modules. Every stage ends with tests and an honest verification status ([rules](../development/feature-verification.md)).

## Stage 0: Documentation (in progress)
README, architecture, ADRs, security, development and implementation documents. Owner review of ADRs and open questions.

## Stage 1: Foundation and local infrastructure (blocked)
1. Repository scaffolding: `.gitignore`, `.env.example` (placeholders only), workspace tooling decision.
2. `infra/docker-compose.yml` with PostgreSQL and Keycloak, pinned image versions, localhost-only ports, credentials from environment.
3. Confirm both services start and are reachable. Record the result.

## Stage 2: Tenancy core (blocked)
Tenant isolation is built and proven **before** any business module.
1. Migration tooling and the two database roles (owner and restricted application role).
2. Core tables: organisations, users, memberships, roles, permissions, each with `organisation_id` where tenant-scoped, RLS enabled and forced.
3. Tenant-aware data access layer that sets the organisation per transaction.
4. The full isolation test suite ([tenant isolation](../security/tenant-isolation.md)) passing against a real PostgreSQL.
5. CI check that fails when a business table lacks RLS.

## Stage 3: Identity and platform kernel (blocked)
1. Keycloak realm export (no secrets), clients and roles.
2. NestJS skeleton, configuration, health endpoint.
3. OIDC token validation and tenant context guard, with the authentication test suite.
4. Authorisation guard, deny by default, with the authorisation test suite.
5. Audit log, append-only and tenant-scoped, with its test suite.
6. API i18n: error codes and keys resolved per locale.

## Stage 4: Frontend skeleton (blocked)
1. Vite + React + TypeScript project.
2. Real OIDC login against Keycloak. No simulated login.
3. i18next with `pt` and `en`, runtime language switch persisted per user, parity check in CI.
4. A real screen reading real data from the API.

## Stage 5: First business modules (blocked)
1. Organisation Management.
2. Identity and Access Management (users, memberships and roles on top of Keycloak identity).

## Later phases (not scheduled)
Enterprise Workflow Management, Purchase Approvals, Enterprise Risk Management, Compliance Management, Evidence Management and Audit Management, in the dependency order shown in [modular monolith](../architecture/modular-monolith.md).

## Exit criteria for Phase 1
- Isolation, authentication, authorisation and audit suites pass in CI against real PostgreSQL and Keycloak.
- Complete `pt`/`en` coverage for everything built so far.
- No mock data or simulated behaviour anywhere.
- Documentation and ADRs up to date, with verification status stated honestly.

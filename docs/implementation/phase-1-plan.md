# Phase 1 Implementation Sequence

Status: **Plan. Stage 0 (documentation) is the only stage in progress. Stages 1 and later are blocked** until the items in [blockers](blockers-and-open-questions.md) are resolved.

Phase 1 goal: a real, tenant-isolated foundation with real Keycloak login and complete English and Portuguese support (English is the primary and default language), plus the first real business modules. Every stage ends with tests and an honest verification status ([rules](../development/feature-verification.md)).

## Stage 0: Documentation (in progress)
README, architecture, ADRs, security, development and implementation documents. Owner review of ADRs and open questions.

## Stage 1: Foundation and local infrastructure (blocked)
1. Repository scaffolding: `.gitignore`, `.env.example` (placeholders only), workspace tooling decision.
2. `infra/docker-compose.yml` with PostgreSQL and Keycloak, pinned image versions, localhost-only ports, credentials from environment.
3. Confirm both services start and are reachable. Record the result.

## Stage 2: Tenancy core (database part DONE and tested; backend parts blocked)
Tenant isolation is built and proven **before** any business module.
1. **Done:** migration tooling (checksummed SQL migrations) and the two database roles (owner and restricted application role).
2. **Done:** core tables (organisations, users, memberships, roles, permissions, role-permission and membership-role links) with `organisation_id` where tenant-scoped, RLS enabled and forced.
3. Tenant-aware data access layer in NestJS that sets the organisation per transaction. **Blocked** (needs the backend). The database side, `emx.set_tenant_context`, is done.
4. **Done at the database level:** the isolation test suite passes against a real PostgreSQL 16.15 (166 checks; `db/tests/run.sh`). Not yet repeated through the backend.
5. **Partly done:** the catalog check that fails when a table lacks RLS exists (`db/tests/010_structure.sql`); no CI pipeline runs it yet.

The database layer was built without network access, using the native PostgreSQL 16 binaries. See [db/README.md](../../db/README.md).

## Stage 3: Identity and platform kernel (blocked)
1. Keycloak realm export (no secrets), clients and roles.
2. NestJS skeleton, configuration, health endpoint.
3. OIDC token validation and tenant context guard, with the authentication test suite.
4. Authorisation guard, deny by default, with the authorisation test suite.
5. Audit log, append-only and tenant-scoped, with its test suite.
6. API i18n: stable English error codes and keys, localised from `Accept-Language` with `Content-Language` returned on localised responses. Emails, background notifications, scheduled messages and generated documents use the recipient's saved profile language (English if none).

## Stage 4: Frontend skeleton (blocked)
1. Vite + React + TypeScript project.
2. Real OIDC login against Keycloak. No simulated login.
3. i18next with English (`en`, default and canonical) and Portuguese (`pt`). Language selector on the login page and throughout the authenticated app, one language displayed at a time, choice stored in local storage before login and in the user profile after authentication, selected language passed to Keycloak through `ui_locales` (after verification), `Accept-Language` set explicitly by the frontend on API requests (never the browser's native preference), the most recent explicit selection winning over the saved profile and being saved after authentication, and an `en`/`pt` key parity check that fails CI.
4. A real screen reading real data from the API.

## Stage 5: First business modules (blocked)
1. Organisation Management.
2. Identity and Access Management (users, memberships and roles on top of Keycloak identity).

## Later phases (not scheduled)
Enterprise Workflow Management, Purchase Approvals, Enterprise Risk Management, Compliance Management, Evidence Management and Audit Management, in the dependency order shown in [modular monolith](../architecture/modular-monolith.md).

## Exit criteria for Phase 1
- Isolation, authentication, authorisation and audit suites pass in CI against real PostgreSQL and Keycloak.
- Complete English and Portuguese coverage for everything built so far, with English as the default.
- No mock data or simulated behaviour anywhere.
- Documentation and ADRs up to date, with verification status stated honestly.

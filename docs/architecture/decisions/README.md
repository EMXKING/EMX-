# Architecture Decision Records

An ADR records one significant decision, why it was made and what follows from it. ADRs are immutable once accepted. To change a decision, write a new ADR that supersedes the old one.

## Status values

- **Accepted**: confirmed by the project owner.
- **Proposed**: drafted, awaiting owner confirmation.
- **Superseded**: replaced by a later ADR.

An accepted ADR records a *decision*, not proof that the decision has been implemented or tested. Each ADR has a **Verification** section stating what, if anything, has been verified. At the time of writing, only the database-level parts of ADR-0003, ADR-0007 and ADR-0008 have been implemented and tested; everything else is unimplemented.

## Index

| ADR | Title | Status |
|-----|-------|--------|
| [0001](0001-frontend-react-typescript-vite.md) | Frontend: React + TypeScript + Vite | Accepted |
| [0002](0002-backend-nestjs-typescript.md) | Backend: NestJS + TypeScript | Accepted |
| [0003](0003-database-postgresql.md) | Database: PostgreSQL | Accepted |
| [0004](0004-authentication-keycloak-oidc.md) | Authentication: Keycloak + OIDC/OAuth2 | Accepted (realm model Proposed) |
| [0005](0005-infrastructure-docker-compose.md) | Infrastructure: Docker Compose | Accepted |
| [0006](0006-en-pt-internationalisation.md) | Internationalisation: English primary, Portuguese secondary (i18next) | Accepted, revised 2026-11-16 (Keycloak `ui_locales` pending verification) |
| [0007](0007-shared-schema-multitenancy.md) | Shared-schema multi-tenancy with organisation_id | Accepted |
| [0008](0008-postgresql-row-level-security.md) | PostgreSQL Row-Level Security | Accepted |
| [0009](0009-authn-authz-audit-architecture.md) | Authentication, authorisation and audit architecture | Proposed |

## Template

```
# ADR-NNNN: Title
Status: Proposed | Accepted | Superseded by ADR-XXXX
Date: YYYY-MM-DD

## Context
## Decision
## Consequences
## Alternatives considered
## Verification
```

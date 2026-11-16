# Technology Stack

Status: the items marked **Approved** were confirmed by the project owner. Everything else is **Undecided** and must be decided through an ADR before it is used.

## Approved

| Layer | Technology | ADR |
|-------|------------|-----|
| Frontend | React + TypeScript + Vite | [0001](decisions/0001-frontend-react-typescript-vite.md) |
| Backend | NestJS + TypeScript | [0002](decisions/0002-backend-nestjs-typescript.md) |
| Database | PostgreSQL | [0003](decisions/0003-database-postgresql.md) |
| Authentication | Keycloak with OIDC / OAuth2 | [0004](decisions/0004-authentication-keycloak-oidc.md) |
| Infrastructure | Docker Compose | [0005](decisions/0005-infrastructure-docker-compose.md) |
| Internationalisation | i18next, `pt` and `en` | [0006](decisions/0006-pt-en-internationalisation.md) |
| Tenancy | Shared schema with `organisation_id` | [0007](decisions/0007-shared-schema-multitenancy.md) |
| Tenant enforcement | PostgreSQL Row-Level Security | [0008](decisions/0008-postgresql-row-level-security.md) |
| Auth architecture | Authentication, authorisation and audit | [0009](decisions/0009-authn-authz-audit-architecture.md) |
| Architecture style | Modular monolith | [modular-monolith.md](modular-monolith.md) |

The EMX application code is TypeScript only. Keycloak and PostgreSQL run as packaged services from their own container images; EMX does not write code in any other language for them.

## Undecided (need an ADR before use)

| Topic | Notes |
|-------|-------|
| Database access layer (ORM, query builder or SQL-first) | Must support setting a per-transaction organisation context for Row-Level Security |
| Migration tool | Must support SQL migrations, because RLS policies are SQL |
| Package manager and monorepo tooling | npm, pnpm or yarn workspaces |
| Frontend component library and state management | None chosen |
| Test frameworks | Proposed in [testing strategy](../development/testing-strategy.md), not confirmed |
| Evidence file storage | Local volume or an S3-compatible service; no paid service may be activated |
| Background jobs, email, observability | None chosen |
| License | Not decided |

Exact dependency versions are intentionally not listed. They will be recorded when dependencies are installed and verified.

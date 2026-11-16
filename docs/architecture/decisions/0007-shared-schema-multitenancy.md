# ADR-0007: Shared-schema multi-tenancy with organisation_id

Status: Accepted
Date: 2026-11-16

## Context
EMX serves many organisations. Their data must be strictly isolated. Isolation must be designed before any business module exists, because retrofitting it is hard and error-prone.

## Decision
All organisations share one PostgreSQL database and schema. Every business table carries a non-nullable `organisation_id` column identifying the owning organisation. Isolation is enforced in two independent layers: strict backend authorisation and PostgreSQL Row-Level Security ([ADR-0008](0008-postgresql-row-level-security.md)).

## Consequences
- Every business table has `organisation_id NOT NULL`, indexed, and part of relevant unique constraints and foreign keys so references cannot cross tenants.
- `organisation_id` is derived from the verified identity token, never from client input.
- Cross-tenant operations (for example platform administration) are explicit, separately authorised and audited. They are not an implicit bypass.
- Shared-schema makes operations simple but means one defect can affect all tenants, so tenant isolation tests are mandatory and block releases.
- Per-tenant backup or restore is harder than with separate databases. Accepted trade-off.
- Details: [tenant isolation](../../security/tenant-isolation.md).

## Alternatives considered
Database-per-tenant and schema-per-tenant give stronger physical separation but higher operational cost. They were not chosen by the project owner.

## Verification
Not implemented. Not verified. No isolation test exists yet.

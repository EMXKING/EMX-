# ADR-0003: Database: PostgreSQL

Status: Accepted
Date: 2026-11-16

## Context
EMX stores relational, audit-sensitive business data for many organisations and needs transactional integrity, constraints and database-enforced tenant isolation.

## Decision
PostgreSQL is the system of record for all business data. It is used for tenancy enforcement through Row-Level Security.

## Consequences
- **No hardcoded business data replaces PostgreSQL.** Application data comes from the database.
- Schema changes are versioned SQL migrations committed to the repository. RLS policies are part of migrations.
- Two database roles are required: a migration/owner role and a restricted application role without superuser or `BYPASSRLS` ([ADR-0008](0008-postgresql-row-level-security.md)).
- Credentials are supplied through environment configuration and never committed.
- The major PostgreSQL version will be pinned when the container image is chosen. The sandbox currently has client tools for version 16, which is an environment fact, not a decision.

## Alternatives considered
Other databases were not adopted because the stack was fixed by the project owner.

## Verification
Not implemented. Not verified. No PostgreSQL server has been run for EMX.

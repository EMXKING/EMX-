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
**Partly implemented and tested** (2026-11-17): the versioned SQL migrations, the owner and restricted application roles, and Row-Level Security run against a disposable PostgreSQL 16.15 cluster (`db/tests/run.sh`, 166 checks passed). See [db/README.md](../../../db/README.md). Not verified: the PostgreSQL container image and Docker Compose environment (image pulls are blocked), and use from the NestJS backend, which does not exist yet.

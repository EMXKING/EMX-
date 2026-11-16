# ADR-0008: PostgreSQL Row-Level Security

Status: Accepted
Date: 2026-11-16

## Context
Application-level filtering alone fails if a developer forgets a filter. The database must refuse cross-tenant access even when application code is wrong.

## Decision
Every business table has Row-Level Security enabled and forced. Policies restrict rows to the organisation set for the current transaction.

## Design rules
1. `ALTER TABLE ... ENABLE ROW LEVEL SECURITY` and `FORCE ROW LEVEL SECURITY` on every business table. Without `FORCE`, the table owner bypasses policies.
2. Policies use both `USING` (which rows are visible) and `WITH CHECK` (which rows may be written), comparing `organisation_id` with the transaction's organisation setting.
3. The current organisation is set per transaction (transaction-scoped setting, for example `SET LOCAL` or `set_config(..., true)`), so it cannot leak between requests on a pooled connection.
4. If the setting is absent, policies must match **no rows**. Missing context fails closed.
5. The application connects as a restricted role: not a superuser, not the table owner, without `BYPASSRLS`. Superusers and `BYPASSRLS` roles bypass RLS, so they are never used by the API.
6. A separate role runs migrations and owns the tables.
7. New business tables are not accepted without RLS and an isolation test. A CI check will list tables lacking RLS (planned).

## Consequences
- Every database access must run inside a transaction that sets the organisation context. The data access layer must make doing otherwise difficult or impossible.
- Pooled connections require transaction-scoped settings only.
- Policies can affect query planning; indexes on `organisation_id` are required and performance must be measured.
- RLS is a safety net, not a replacement for backend authorisation (see [ADR-0009](0009-authn-authz-audit-architecture.md)).

## Alternatives considered
Application-only filtering was rejected as insufficient.

## Verification
Not implemented. Not verified. These rules are design requirements to be proven by automated tests against a real PostgreSQL ([testing strategy](../../development/testing-strategy.md)).

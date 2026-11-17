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
**Rules 1 to 6: implemented and tested** (2026-11-17) on a disposable PostgreSQL 16.15 cluster with `db/tests/run.sh` (166 checks passed): RLS enabled and forced on the six protected tables, `USING` and `WITH CHECK` policies, missing context returning no rows, a restricted application role without superuser or `BYPASSRLS`, and a separate owner role that is itself subject to RLS. `db/tests/mutation_check.sh` showed the suite fails when a policy is made permissive, `FORCE` is removed, `WITH CHECK` is removed or the application role gets `BYPASSRLS`.

**Implementation notes:**
- The context is held in two transaction-local settings and set through `emx.set_tenant_context(user, organisation)`, which refuses users who are not active members of an active organisation.
- Rule 7's CI check exists as a catalog test (`db/tests/010_structure.sql`) but there is no CI pipeline yet.

**Limitation (tested and documented):** any session can set the custom setting directly, so arbitrary SQL run as the application role can forge the context. RLS protects against missing filters and application bugs, not against that. See [db/README.md](../../../db/README.md).

**Not verified:** behaviour through the NestJS data-access layer and pooled production-style connections.

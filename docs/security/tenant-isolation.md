# Tenant Isolation

Status: **Database layer implemented and tested (2026-11-17). Backend layer designed only. End-to-end isolation not verified.** Tenant isolation is the first thing to be built and proven, before any business module ([Phase 1 plan](../implementation/phase-1-plan.md)).

| Layer | Status |
|-------|--------|
| 2. Database: Row-Level Security, roles, privileges, composite foreign keys | **Tested**: 166 checks passed on a disposable PostgreSQL 16.15 cluster; 6 of 6 deliberately broken controls were caught (`db/tests/run.sh`, `db/tests/mutation_check.sh`) |
| 1. Backend authorisation (NestJS guards, token validation, tenant resolution) | **Designed**, not implemented |
| Tenant context from a verified Keycloak identity | **Designed**, not implemented |

Details of what the database layer does and does not guarantee: [db/README.md](../../db/README.md).

Decisions: [ADR-0007](../architecture/decisions/0007-shared-schema-multitenancy.md), [ADR-0008](../architecture/decisions/0008-postgresql-row-level-security.md).

## Model

One database, one schema. Every business table has `organisation_id NOT NULL`. Two independent layers enforce isolation:

| Layer | Mechanism | Fails when |
|-------|-----------|------------|
| 1. Backend authorisation | Guard resolves the organisation from the verified token and checks membership and permission | A developer skips or misconfigures a guard |
| 2. Database | Row-Level Security restricts every query to the transaction's organisation | The database role bypasses RLS, or context is set wrongly |

Either layer alone should prevent cross-tenant access. Both must be tested.

## Tenant context

- Source: verified token claims mapped to an organisation the user is an active member of. Never a client-supplied header, parameter or body field.
- A user belonging to several organisations selects one per session; the selection is validated against membership.
- The context is held per request and written into the database transaction before any query runs.

## Database rules

1. `organisation_id NOT NULL`, indexed.
2. RLS `ENABLE` and `FORCE` on every business table.
3. `USING` and `WITH CHECK` policies compare `organisation_id` with the transaction-scoped setting.
4. Absent setting matches no rows.
5. API role: not superuser, not table owner, no `BYPASSRLS`. Migration role is separate.
6. Composite uniqueness and foreign keys include `organisation_id` so a row in tenant A cannot reference a row in tenant B.
7. Cross-tenant platform operations use a separate, explicitly authorised and audited path. They are not a general bypass.

## Application rules

- All data access goes through a layer that opens a transaction and sets the context. Direct use of a raw connection outside it is forbidden and checked in review and, where possible, by tests.
- Caches, queues, files and logs are also tenant-scoped. Cache keys include the organisation. Evidence files are stored and retrieved under organisation-scoped paths with authorisation checks.
- Responses must not reveal whether another tenant's resource exists. Cross-tenant lookups behave like "not found".

## Required tests (must exist before any business module)

| Test | Expected result |
|------|-----------------|
| User of A lists resources | Only A's rows |
| User of A reads B's resource by id | Not found |
| User of A updates or deletes B's row | No effect, refused |
| User of A inserts a row with B's `organisation_id` | Rejected by `WITH CHECK` |
| Query with no organisation context | Zero rows, no error leaking data |
| Request supplies a different organisation id in header or body | Ignored or rejected |
| Application role attempts to bypass RLS | Not possible |
| Pooled connection reused by a different tenant | No leakage |
| Foreign key from A's row to B's row | Rejected |
| New table without RLS | CI check fails |

These tests run against a real PostgreSQL instance, not a mock.

### Result at the database level (2026-11-17)

Every row of the table above that concerns the database is covered by `db/tests/`, except the two that need the backend:

| Required test | Database-level result |
|---------------|-----------------------|
| User of A lists resources | Passed (`030`) |
| User of A reads B's resource by id | Passed (`040`) |
| User of A updates or deletes B's row | Passed (`050`) |
| User of A inserts a row with B's `organisation_id` | Passed, refused by `WITH CHECK` (`050`) |
| Query with no organisation context | Passed, zero rows (`020`) |
| Application role attempts to bypass RLS | Passed (`080`) |
| Pooled connection reused by a different tenant | Passed at the SQL level (`070`) |
| Foreign key from A's row to B's row | Passed (`060`) |
| New table without RLS | Catalog check passed (`010`); no CI pipeline yet |
| Request supplies a different organisation id in header or body | **Not testable here**: needs the backend |

## Known limits

Shared schema means a defect can affect many tenants, backups are not per tenant, and noisy tenants share resources. These are accepted trade-offs of the approved model.

Limits found while implementing the database layer:

- **Forged context.** Any session can set the transaction-local setting that carries the organisation. Code that can run arbitrary SQL as the application role can therefore read another organisation's data. RLS defends against missing filters and application bugs, not against that. The backend must use parameterised queries only, one data-access layer, and an identity from a verified token. This is asserted by a test so the documentation stays true.
- **Existence side channels.** Unique and foreign-key checks bypass RLS by PostgreSQL design, so a globally unique value (such as a user's Keycloak subject or email) can reveal that it exists elsewhere. Identifiers are random UUIDs.
- **A user's own cross-organisation data is visible to that user.** In an organisation-A context, a user who also belongs to B can see their own B membership row and B's name, so they can choose an organisation. Nothing else of B is visible.
- **Tenant provisioning** (creating organisations) is not available to the application role and is not implemented.

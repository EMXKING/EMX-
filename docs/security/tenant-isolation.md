# Tenant Isolation

Status: **Design only. Not implemented. Not verified.** Tenant isolation is the first thing to be built and proven, before any business module ([Phase 1 plan](../implementation/phase-1-plan.md)).

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

## Known limits

Shared schema means a defect can affect many tenants, backups are not per tenant, and noisy tenants share resources. These are accepted trade-offs of the approved model.

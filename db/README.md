# EMX database layer

PostgreSQL schema, migrations and security tests for the multi-tenant foundation.

Status: **implemented and tested at the database level** against PostgreSQL 16.15 on a disposable cluster. The backend (NestJS), Keycloak integration and the frontend do not exist yet, so end-to-end tenant isolation is **not** verified. See [Known limitations](#known-limitations).

## Layout

| Path | Purpose |
|------|---------|
| `bootstrap/001_roles_and_database.sql` | Superuser, once per cluster: roles `emx_owner` and `emx_app`, the database, connection privileges |
| `bootstrap/002_database_security.sql` | Superuser, once per database: schema `emx`, baseline revokes |
| `migrations/NNNN_*.sql` | Versioned migrations, run as `emx_owner` |
| `scripts/bootstrap.sh` | Runs the bootstrap (needs a superuser connection) |
| `scripts/migrate.sh` | Applies pending migrations with checksum protection |
| `tests/` | SQL security tests, the disposable-cluster harness and the mutation check |

## Roles

| Role | Purpose | Notes |
|------|---------|-------|
| `emx_owner` | Owns the schema and tables, runs migrations | Not superuser, no `BYPASSRLS`. Subject to RLS itself (`FORCE`), so it sees no tenant rows |
| `emx_app` | The application | Not superuser, no `BYPASSRLS`, owns nothing, no DDL. Minimum privileges only |

Neither role is a member of the other. No passwords are stored in the repository; authentication is configured per environment outside git.

## Data model

| Table | Tenant-owned (`organisation_id`) | RLS | Notes |
|-------|----------------------------------|-----|-------|
| `organisations` | the tenant itself (`id`) | yes | The app cannot create or delete organisations |
| `users` | no (global identity, linked to Keycloak) | yes | A user can belong to several organisations |
| `organisation_memberships` | yes | yes | Unique per (organisation, user) |
| `roles` | yes | yes | Scoped to one organisation |
| `permissions` | no (global catalogue) | no | Read-only for the app; none are seeded yet |
| `role_permissions` | yes | yes | Composite FK to `roles` includes `organisation_id` |
| `membership_roles` | yes | yes | Composite FKs include `organisation_id` |

Every tenant-owned table has `organisation_id NOT NULL` with a default taken from the tenant context, so callers never need to (and must not) supply it.

## How the tenant context works

The backend calls, inside the transaction that runs the request's queries:

```sql
SELECT emx.set_tenant_context(<verified user id>, <organisation id>);
```

- Values are transaction-local (`set_config(..., true)`): they disappear at COMMIT or ROLLBACK and cannot leak between pooled requests.
- The function refuses (SQLSTATE `42501`) unless the user is an active member of an active organisation and is itself active.
- `emx.set_user_context(<user id>)` sets only the user, for listing the user's own organisations and first-login provisioning.
- With no context, policies match no rows (fail closed). A malformed value raises an error.
- The identity passed in must come from a verified token. The database cannot verify that itself.

## Running the tests

Needs PostgreSQL 16 server binaries, no network, no installs:

```bash
bash db/tests/run.sh            # bootstrap + migrate + all security tests on a disposable cluster
bash db/tests/mutation_check.sh # proves the tests fail when a control is deliberately broken
```

The harness creates a brand-new cluster under `/var/tmp`, on a non-default port with **no TCP listener**, and removes it afterwards. It never touches an existing cluster. It uses trust authentication, which is acceptable only because that cluster is private and short-lived. All data is synthetic.

## Known limitations

1. **Forged context.** Any session can set the custom setting `emx.organisation_id`. Code that can run arbitrary SQL as `emx_app` (SQL injection, a compromised backend) can read another organisation's data. RLS defends against missing filters and application bugs, not against that. This is asserted in `tests/085_known_limitations.sql`. Mitigations belong in the backend (parameterised queries only, a single data-access layer, identity from a verified token) and are not implemented yet.
2. **Existence side channels.** Unique and foreign-key checks bypass RLS by PostgreSQL design. Globally unique values (a user's Keycloak subject or email) can reveal that a value exists elsewhere, and a foreign-key error can reveal that an id exists. Ids are random UUIDs.
3. **Tenant provisioning is not implemented.** The app role cannot create organisations. How a new tenant is created (platform administration) is an open question.
4. **Not covered yet:** an audit log table, `updated_at` maintenance (no triggers), seeded permission codes and default roles per organisation, performance of the policies at scale, backup and restore.
5. **Not tested here:** the NestJS guards, Keycloak token validation, the frontend, and any real client connection path. The tests use `psql` directly.

# Testing Strategy

Status: **Strategy only. No tests exist. Tool names below are proposals, not decisions.**

## Principles

- Tests run against real dependencies where behaviour matters. Tenant isolation and RLS are tested against a real PostgreSQL instance, never against a mock or in-memory substitute.
- Authentication is tested against real token validation. A test may use a locally generated signing key and issuer for token tests, clearly labelled as test infrastructure, but the application contains no auth bypass.
- A feature is not "done" without tests, and a security control is not "verified" without a test that fails when the control is removed.

## Levels

| Level | Scope | Proposed tools |
|-------|-------|----------------|
| Unit | Pure logic, policies, validators | Backend: NestJS default test tooling; frontend: Vitest (natural with Vite) |
| Integration | API plus real PostgreSQL, migrations, RLS, authorisation | Same runner, with a disposable test database |
| Contract | API request and response shapes shared with frontend | To decide |
| End to end | Browser through Keycloak to API to database | To decide |
| Static checks | Type check, lint, secret scan, dependency audit | To decide |

## Mandatory security suites

1. **Tenant isolation** suite listed in [tenant isolation](../security/tenant-isolation.md).
2. **Authentication** suite: expired, tampered, wrong issuer and audience, missing token ([identity](../security/identity.md)).
3. **Authorisation** suite: deny by default, per-role permissions, separation of duties ([RBAC](../security/rbac.md)).
4. **Audit** suite: events recorded, append-only, tenant-scoped ([audit logging](../security/audit-logging.md)).

These suites gate every merge once they exist.

## Internationalisation tests

- Every translation key exists in both `en` and `pt`. CI **fails** on any missing key or key present in only one language, and a release is blocked by it.
- English fallback is disabled in test and production builds, so a missing key fails rather than silently showing English.
- The language is stored in local storage before login, and English is shown when nothing is stored, regardless of browser language.
- The selected language is passed to Keycloak through `ui_locales` (to be verified against the selected Keycloak version).
- The API localises user-facing messages from `Accept-Language` (`pt`, `pt-PT` and `pt-BR` resolve to `pt`; unsupported or absent resolves to `en`) and returns `Content-Language`. Field names, codes and identifiers stay English.
- After login the language is saved in the user profile, and an explicit preference wins over the default.
- No hardcoded user-visible text in components.
- First-time visitors and new accounts see English by default, regardless of browser language.
- The language selector works on the login page and throughout the authenticated application.
- Only one language is displayed at a time on each screen.
- The selected language persists across sessions and is applied after sign-in.
- API errors resolve in both languages; error codes and identifiers stay in English.

## Test data

Test data is created by tests or fixtures in the test database. It is never shipped as application data and never used to make a screen appear to work.

## Environment

Integration and end-to-end tests need PostgreSQL and Keycloak running. Currently blocked by network and Docker availability ([blockers](../implementation/blockers-and-open-questions.md)).

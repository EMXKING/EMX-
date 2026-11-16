# System Architecture

Status: **Design only.** No component below exists yet.

## Components

```
Browser (React + TypeScript + Vite, i18next pt/en)
   |  OIDC Authorization Code + PKCE         |  HTTPS API calls with access token
   v                                          v
Keycloak (identity provider)            NestJS API (modular monolith)
                                              |  validates JWT (issuer, audience, signature, expiry)
                                              |  resolves organisation_id from the verified token
                                              v
                                        PostgreSQL (shared schema, Row-Level Security)
```

All components run locally through Docker Compose for development. There is no public deployment.

## Responsibilities

| Component | Responsible for | Not responsible for |
|-----------|-----------------|---------------------|
| Frontend | UI, locale switching, OIDC login flow, calling the API | Any authorisation decision that matters; the backend always re-checks |
| Keycloak | Authentication, credentials, sessions, token issuing | Business permissions and tenant data |
| NestJS API | Token validation, authorisation, business rules, audit logging, tenant context | Storing passwords or issuing tokens |
| PostgreSQL | Data, constraints, Row-Level Security as the last line of defence | Application authorisation logic |

## Request flow (target design)

1. The user signs in at Keycloak through the OIDC Authorization Code flow with PKCE.
2. The frontend sends the access token to the API.
3. A global authentication guard verifies the token. Unauthenticated requests are rejected.
4. The tenant context is taken **only** from verified token claims, never from a header, query parameter or body supplied by the client.
5. An authorisation guard checks the user's role and permissions within that organisation.
6. The service layer opens a database transaction and sets the organisation for that transaction (see [tenant isolation](../security/tenant-isolation.md)).
7. Queries run under Row-Level Security. Cross-tenant rows are invisible even if application code is wrong.
8. Security-relevant events are written to the audit log (see [audit logging](../security/audit-logging.md)).
9. Error and validation messages are returned as translation keys plus the resolved text for the requested locale (see [ADR-0006](decisions/0006-pt-en-internationalisation.md)).

## Cross-cutting platform capabilities

These live in a shared platform kernel, not in business modules: tenant context, authentication and authorisation guards, audit logging, database access, internationalisation and configuration.

## Environments

| Environment | Status |
|-------------|--------|
| Local development (Docker Compose) | Planned; blocked by network and Docker daemon (see [blockers](../implementation/blockers-and-open-questions.md)) |
| Shared or staging | Not planned in Phase 1 |
| Public production | Out of scope; requires explicit approval |

## Not yet decided

Object storage for evidence files, background job processing, email delivery, observability tooling and the ORM or query layer. See [open questions](../implementation/blockers-and-open-questions.md).

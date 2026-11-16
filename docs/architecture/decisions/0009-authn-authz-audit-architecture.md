# ADR-0009: Authentication, authorisation and audit architecture

Status: Proposed
Date: 2026-11-16

## Context
EMX handles risk, compliance and approval data where accountability matters. It needs a clear separation between who a user is, what they may do and what was done.

## Decision

### Authentication
Keycloak authenticates users ([ADR-0004](0004-authentication-keycloak-oidc.md)). The backend validates every access token. No endpoint is public unless it is explicitly marked, and public endpoints are limited to health checks.

### Authorisation
Authorisation is evaluated in the backend, in this order, on every request:
1. Token valid.
2. Organisation resolved from the verified token and the user is an active member.
3. Role-based permission check for the requested action, scoped to the organisation ([RBAC](../../security/rbac.md)).
4. Resource-level rules where needed, for example approval limits or ownership.
5. Database Row-Level Security as the final, independent layer.

Deny by default: an action without an explicit permission is refused.

### Audit
Security-relevant and business-significant events are written to an append-only audit log, scoped by `organisation_id`, storing who, what, when, which organisation and the outcome ([audit logging](../../security/audit-logging.md)).

## Consequences
- Roles and permissions are defined by EMX and stored in PostgreSQL. Keycloak supplies identity and a coarse role claim; fine-grained permission data is not trusted from the client.
- Authorisation logic is centralised in guards and policy services, not scattered across controllers.
- The audit log must itself be tenant-isolated and protected against modification by the application role.
- Open: whether permissions are assigned only through roles or also directly. See [open questions](../../implementation/blockers-and-open-questions.md).

## Alternatives considered
Delegating all fine-grained authorisation to Keycloak was not preferred, because business rules such as approval limits depend on EMX data.

## Verification
Not implemented. Not verified.

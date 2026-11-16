# Audit Logging

Status: **Design only. Not implemented. Not verified.**

Related: [ADR-0009](../architecture/decisions/0009-authn-authz-audit-architecture.md). Note that the platform **audit log** described here is distinct from the **Audit Management** business module ([modular monolith](../architecture/modular-monolith.md)).

## Purpose

A trustworthy record of who did what, when, in which organisation and with what result, to support accountability, investigation and compliance.

## What is recorded (proposed)

- Authentication-related events the backend can observe, such as failed authorisation and denied access.
- Membership, role and permission changes.
- Create, update, delete and state changes of business records, including workflow and approval decisions.
- Access to sensitive records, such as evidence downloads (scope to confirm).
- Administrative and cross-tenant platform operations.

## Record fields (proposed)

| Field | Notes |
|-------|-------|
| Timestamp | Server-side, UTC |
| `organisation_id` | Tenant scope |
| Actor | Authenticated user identifier; system actor for automated actions |
| Event code | Stable code, not translated text |
| Resource type and id | What was affected |
| Outcome | Success or denied or failed |
| Details | Structured, with sensitive values excluded or masked |
| Request correlation id | Links related records |

Event codes are locale-independent so records stay readable in both `pt` and `en`; display text is produced at read time.

## Integrity

- Append-only: the application role can insert but not update or delete audit records.
- Audit records are tenant-isolated with Row-Level Security like any business table.
- Retention and archival policy to be decided.
- Tamper-evidence (for example hash chaining) is under consideration, not decided.

## What must never be logged

Passwords, tokens, secrets and unnecessary personal data. Log content is reviewed for sensitive values.

## Required tests

Events recorded for each defined action; actor and organisation correct; application role cannot update or delete records; one tenant cannot read another's audit records; failed actions recorded; no secrets in records.

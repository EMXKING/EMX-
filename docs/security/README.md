# EMX Security

Status: **Design, except the database-level tenant-isolation controls (Row-Level Security, roles and privileges), which are implemented and tested but not yet verified end to end** (see [tenant isolation](tenant-isolation.md)). No backend, authentication, authorisation or audit control is implemented. A control is only called "verified" when an automated test or a recorded manual check proves it (see [feature verification](../development/feature-verification.md)).

| Document | Content |
|----------|---------|
| [tenant-isolation.md](tenant-isolation.md) | How organisations are kept apart |
| [rbac.md](rbac.md) | Role-based access control model |
| [identity.md](identity.md) | Keycloak, OIDC and token handling |
| [audit-logging.md](audit-logging.md) | Audit trail design |

## Security principles

1. **Deny by default.** Access requires an explicit permission.
2. **Defence in depth.** Tenant isolation is enforced by backend authorisation and by Row-Level Security, independently.
3. **Never trust the client.** Organisation, role and identity come from verified tokens and server-side data, not from request input. Client-side checks are usability only.
4. **Fail closed.** Missing tenant context, invalid tokens or unknown permissions produce a refusal, not a fallback.
5. **Least privilege.** The API database role has no superuser or `BYPASSRLS`. Users get the narrowest role that works.
6. **No secrets in the repository.** Credentials, keys and tokens come from environment configuration. `.env.example` contains placeholders only.
7. **No fake security.** No simulated login, no stubbed authorisation that always allows, no hardcoded users.
8. **Accountability.** Significant actions are recorded in an audit log.
9. **Validate all input** at the boundary, and encode output.
10. **Prove it.** Controls are claimed only after tests demonstrate them.

## Threats of particular concern

| Threat | Primary mitigation (planned) |
|--------|------------------------------|
| One organisation reading or changing another's data | Tenant context from token, RLS, isolation tests |
| Forged or replayed tokens | Signature, issuer, audience and expiry validation |
| Privilege escalation inside an organisation | Central authorisation, deny by default, role change auditing |
| Tampering with audit records | Append-only design, restricted database privileges |
| Secret leakage | No secrets in git, secret scanning in CI (planned) |
| Injection | Parameterised queries, input validation |

A full threat model has not been written and is a Phase 1 task.

# Role-Based Access Control

Status: **Design only. Not implemented. Not verified.** Role names and permissions are a starting proposal for owner review, not a final model.

Related: [ADR-0009](../architecture/decisions/0009-authn-authz-audit-architecture.md).

## Principles

- Deny by default. No permission, no access.
- Roles are scoped to an organisation. A user can hold different roles in different organisations.
- Roles and permissions are stored in PostgreSQL and evaluated by the backend. Keycloak supplies identity; it is not the source of fine-grained permissions.
- Permission checks are centralised in guards and policy services.
- Changes to roles, permissions and memberships are audited.
- The frontend hides what a user cannot do for usability only. The backend always re-checks.

## Model

```
user --(membership)--> organisation
membership --(has)--> role(s)
role --(grants)--> permission(s)
permission = action on a resource type, e.g. risk:read, risk:update, purchase-request:approve
```

## Proposed initial roles (to confirm)

| Role | Intent |
|------|--------|
| Organisation administrator | Manages the organisation, members and roles |
| Manager | Approves and oversees work within defined limits |
| Risk owner | Maintains risks and treatments |
| Compliance officer | Manages obligations and controls |
| Auditor | Runs audits; read access to evidence and records as needed |
| Requester | Creates requests such as purchase requests |
| Read-only | Views permitted records |

Platform-level administration across organisations is a separate, tightly controlled concern and is not an organisation role.

## Resource-level rules

Some decisions depend on data, not only role, for example approval limits on purchase approvals, ownership of a risk, or separation of duties (a requester must not approve their own request). These are modelled as explicit policies, tested individually.

## Required tests

- Each permission denied to a role that lacks it.
- Roles in organisation A confer nothing in organisation B.
- Separation of duties enforced.
- Role changes take effect and are audited.
- Missing permission mapping results in denial.

## Open questions

Whether permissions can be granted directly to users as well as through roles, whether custom roles per organisation are required in Phase 1, and the exact separation-of-duties rules. See [open questions](../implementation/blockers-and-open-questions.md).

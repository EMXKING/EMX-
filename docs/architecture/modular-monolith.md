# Modular Monolith

Status: **Design.** The folder layout and rules below are proposed and unenforced until the code exists.

EMX is one deployable NestJS application organised into modules with explicit boundaries. The aim is the operational simplicity of one deployment with the discipline needed to extract a module into a service later if it is ever justified.

## Module map

```
platform/ (shared kernel)
  tenancy, auth (OIDC guard), authorisation, audit-log, database, i18n, config

modules/
  organisation-management      (1)
  identity-access-management   (2)
  workflow-management          (3)
  purchase-approvals           (4)
  risk-management              (5)
  compliance-management        (6)
  evidence-management          (7)
  audit-management             (8)
```

## Naming: audit log vs Audit Management

- **Audit log** (platform): a tamper-resistant technical record of who did what in the system. Applies to every module.
- **Audit Management** (business module 8): internal audit engagements, findings and follow-up, as a product feature.

These are different things and must not share tables or code. The project owner should confirm this reading (see [open questions](../implementation/blockers-and-open-questions.md)).

## Dependency rules (proposed)

1. A module may depend on the platform kernel.
2. A module may depend on another module **only through its public interface** (an exported service or a published in-process event), never its internal files or tables.
3. No module reads or writes another module's tables. Each module owns its tables.
4. No dependency cycles. Allowed direction:

```
organisation-management  <-  identity-access-management
            ^                          ^
            |                          |
    workflow-management  <-  purchase-approvals
            ^
evidence-management  <-  risk-management, compliance-management, audit-management
```

Meaning: every module may use organisation and identity; purchase approvals builds on workflow; risk, compliance and audit management attach evidence through the evidence module's interface.

5. Every business table has `organisation_id` and Row-Level Security (see [ADR-0007](decisions/0007-shared-schema-multitenancy.md) and [ADR-0008](decisions/0008-postgresql-row-level-security.md)).
6. Cross-module references use identifiers, not database foreign keys across ownership boundaries, unless a decision record permits it.

## Enforcement (planned, not yet in place)

Boundary rules will be enforced by lint rules and architecture tests in CI. Until they exist, boundaries are a convention and must be checked in review.

## Build order

Tenancy core first, then Organisation Management and Identity and Access Management, then the remaining modules. See the [Phase 1 plan](../implementation/phase-1-plan.md).

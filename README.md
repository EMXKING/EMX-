# EMX

EMX is an independent enterprise technology company building a universal enterprise platform.

This repository (`EMXKING/EMX-`) holds the platform source code and its engineering documentation.

> **Development status: documentation and design phase.**
> No application code exists yet. No dependency has been installed, no service has been started and no security control has been implemented or tested. Everything described in this repository is a **design** unless a document explicitly says it has been verified. See [Feature verification rules](docs/development/feature-verification.md).

## First product: Enterprise Workflow + Risk + Compliance

The first product helps an organisation run approvals and manage risk, compliance, evidence and audits in one place, with strict isolation between organisations (tenants).

### Initial business modules

| # | Module | Purpose |
|---|--------|---------|
| 1 | Organisation Management | Organisations (tenants), units and structure |
| 2 | Identity and Access Management | Users, roles and permissions, integrated with Keycloak |
| 3 | Enterprise Workflow Management | Configurable workflows, steps and tasks |
| 4 | Purchase Approvals | Purchase requests and approval routing, built on workflow |
| 5 | Enterprise Risk Management | Risk register, assessment and treatment |
| 6 | Compliance Management | Obligations, controls and compliance status |
| 7 | Evidence Management | Evidence records linked to risks, controls and audits |
| 8 | Audit Management | Audit engagements, findings and follow-up |

Module boundaries are described in [Modular monolith](docs/architecture/modular-monolith.md).

## Approved technology stack

| Layer | Technology |
|-------|------------|
| Frontend | React + TypeScript + Vite |
| Backend | NestJS + TypeScript |
| Database | PostgreSQL |
| Authentication | Keycloak with OIDC / OAuth2 |
| Internationalisation | i18next, Portuguese (`pt`) and English (`en`) |
| Infrastructure | Docker Compose |
| Architecture | Modular monolith |

The stack is fixed. Changes require a new Architecture Decision Record.

## Non-negotiable requirements

- **Real functionality only.** No mock dashboards, simulated login or hardcoded business data standing in for PostgreSQL.
- **Multi-tenancy.** PostgreSQL shared schema with `organisation_id` on every business table, strict backend authorisation and Row-Level Security. Tenant isolation is designed and proven before any business module is built.
- **Security.** Keycloak is the only identity provider. Secrets are never committed.
- **Complete Portuguese and English.** Every user-facing string, in the interface, API messages, validation errors, emails and login pages, must be available in `pt` and `en`, with switching at runtime.
- **No public deployment and no paid services** without explicit approval.

## Documentation map

| Area | Location |
|------|----------|
| Architecture | [docs/architecture/](docs/architecture/README.md) |
| Architecture Decision Records | [docs/architecture/decisions/](docs/architecture/decisions/README.md) |
| Security | [docs/security/](docs/security/README.md) |
| Development standards | [docs/development/](docs/development/README.md) |
| Implementation plan and blockers | [docs/implementation/](docs/implementation/README.md) |

## Branching

`main` is protected by convention: no direct commits. Work happens on feature branches and reaches `main` only through a reviewed pull request. Current branch for documentation: `feature/phase1-foundation`.

## License

Not yet decided. See open questions in [docs/implementation/blockers-and-open-questions.md](docs/implementation/blockers-and-open-questions.md).

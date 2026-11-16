# Blockers and Open Questions

Status as of 2026-11-16.

## Blockers

| # | Blocker | Impact | Needed to clear |
|---|---------|--------|-----------------|
| B1 | Network access for package installs is blocked in the current sandbox; registry probes failed | Cannot install NestJS, React, Vite or i18next dependencies, so no application code can be built or tested | Allow `registry.npmjs.org` in network settings (a new chat may be needed to pick up the change) |
| B2 | Container registries unreachable | Cannot pull PostgreSQL or Keycloak images | Allow the registry hosts listed in [infrastructure dependencies](infrastructure-dependencies.md) |
| B3 | Docker daemon not running | Compose cannot start services | Start the daemon if the sandbox permits, or agree a fallback |
| B4 | Keycloak not installed | No identity provider to test OIDC against | Resolved by B2/B3, or a downloaded distribution as fallback |
| B5 | No pull request or workflow permission confirmed | Cannot open PRs or add CI from here | Confirm GitHub permissions listed in [infrastructure dependencies](infrastructure-dependencies.md) |

Application implementation does not begin until B1 to B4 are resolved.

## Open questions for the project owner

### Product and architecture
1. Is **Audit Management** (internal audit engagements) distinct from the platform **audit log** (technical audit trail)? This documentation assumes yes.
2. Keycloak realm model: single realm with an organisation claim, or one realm per organisation? Does the chosen Keycloak version's Organizations capability fit?
3. Can a user belong to several organisations? If so, how is the active organisation selected?
4. Are custom roles per organisation required in Phase 1, or only a fixed role set? May permissions be granted directly to users?
5. Separation-of-duties and approval-limit rules for Purchase Approvals.
6. How are platform-level administrators across organisations handled and audited?

### Internationalisation
Resolved by the project owner on 2026-11-16: English (`en`) is the primary, default and canonical language; Portuguese (`pt`) is the secondary supported language ([ADR-0006](../architecture/decisions/0006-en-pt-internationalisation.md)). The default language and the fallback to English are therefore no longer open.

7. Which Portuguese variant is the target for `pt` (European, Brazilian, other)?
   - Where is the language choice stored in the browser before login, and how is it passed to the Keycloak login page (for example the OIDC `ui_locales` parameter, to be checked against the chosen Keycloak version)?
   - How does the API receive the language for a request, given that persisted user preference comes first and English is the default?
   - Is the English fallback for a missing translation acceptable as a safety net (treated as a defect), given that only one language is displayed at a time?

### Technology decisions still open
8. Database access layer (ORM, query builder or SQL-first) and migration tool. Both must support per-transaction RLS context and SQL policies.
9. Package manager and monorepo tooling.
10. Frontend state management, routing and component library.
11. Test frameworks for backend, frontend and end to end.
12. Evidence file storage approach, without any paid service.
13. Background jobs, email delivery and observability.
14. Token storage approach in the browser.

### Governance
15. License for the repository.
16. Retention, archival and tamper-evidence requirements for audit records.
17. Data residency and compliance obligations that affect hosting, backups and personal data handling.

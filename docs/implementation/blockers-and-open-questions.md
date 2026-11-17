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
Closed by the project owner on 2026-11-16 ([ADR-0006](../architecture/decisions/0006-en-pt-internationalisation.md)):

| Topic | Decision |
|-------|----------|
| Primary language | English (`en`) is primary, default and canonical; Portuguese (`pt`) is secondary |
| Portuguese variant | Neutral international `pt`; structure extensible to `pt-PT` and `pt-BR` later |
| Pre-login persistence | Browser local storage; English for first-time visitors regardless of browser language |
| Keycloak | Selected language passed with OIDC `ui_locales`; selector on the login experience; **subject to verification** |
| API language | HTTP `Accept-Language` for user-facing messages, **set explicitly by the frontend** from the selected EMX language, never from the browser's native preference; localised responses return `Content-Language`; identifiers, field names and codes stay English |
| Emails and background output | Emails, background notifications, scheduled messages and generated documents use the recipient's saved profile language, English if none **(resolved 2026-11-16)** |
| Missing translations | English fallback for development only; missing Portuguese is a defect; CI fails; no incomplete or mixed-language production releases |
| After login | Language preference saved in the EMX user profile; explicit preference beats the default |
| Preference conflicts | The most recent explicit selection wins and is saved after successful authentication; without an explicit selection the saved profile preference is retained **(resolved 2026-11-16)** |

Still open:

7. Internationalisation items that remain:
   - **Verify Keycloak behaviour** against the selected version: that `ui_locales` is honoured, that realm locales for `en` and `pt` are configurable, that the login selector works, and how a language chosen on a Keycloak page returns to the application.
   - **Conflict rule and Keycloak:** the conflict rule is resolved (ADR-0006, D8). Whether a language chosen on a Keycloak-hosted page can be returned to the application, and so counted as an explicit selection, depends on the unverified Keycloak behaviour above.
   - **`Accept-Language` in browsers:** verify that an explicitly set header replaces the browser's default in the supported browsers, and decide how browser requests that scripts cannot control (for example direct download links) carry the language.
   - **Portuguese review:** who reviews and approves the neutral Portuguese glossary and translations, and when is the style guide written?

### Technology decisions still open
8. Database access layer (ORM, query builder or SQL-first) and migration tool. Both must support per-transaction RLS context and SQL policies.
9. Package manager and monorepo tooling.
10. Frontend state management, routing and component library.
11. Test frameworks for backend, frontend and end to end.
12. Evidence file storage approach, without any paid service.
13. Background jobs, email delivery and observability.
14. Token storage approach in the browser.

### Raised by the database implementation (2026-11-17)
18. **Tenant provisioning.** The application role cannot create organisations. Who creates a tenant, through what privileged path, and how is that audited? (Relates to question 6.)
19. **Forged tenant context.** Arbitrary SQL run as the application role can set the organisation context directly (tested, documented). Is a stronger binding of the context to the session needed, beyond parameterised queries and a single data-access layer?
20. **Existence side channels.** Globally unique user email and Keycloak subject, and foreign-key errors, can reveal that a value exists in another organisation. Acceptable, or should user identity be partitioned?
21. **Visibility of a multi-organisation user's own memberships.** In an organisation context a user can still see their own membership rows and organisation names in other organisations, to choose between them. Confirm this is wanted.
22. **Audit log table, `updated_at` maintenance, seeded permission codes and default roles per organisation** are not part of the first migrations. In which order should they follow?
23. **Policy performance.** Not measured. Needs data volumes and a performance test before real use.

### Governance
15. License for the repository.
16. Retention, archival and tamper-evidence requirements for audit records.
17. Data residency and compliance obligations that affect hosting, backups and personal data handling.

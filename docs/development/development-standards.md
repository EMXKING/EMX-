# Development Standards

Status: applies from the first line of application code. Not yet enforced by tooling.

## Language and code

- TypeScript with `strict` enabled on frontend and backend. `any` requires a justification in review.
- English is the canonical language for technical documentation, API terminology (endpoints, fields, enumerations, error codes), system identifiers (code, database tables and columns, permission names, audit event codes, translation keys) and default system messages.
- Lint and format configuration is committed and run in CI (tools to be chosen).
- Validate all external input at the boundary. Use parameterised queries only.
- No business logic in controllers or React components beyond orchestration.
- No hardcoded business data, users or credentials. No simulated login or stubbed authorisation.

## Security in code

- Tenant context comes from the verified token only.
- Every database access goes through the tenant-aware data layer.
- New business tables need `organisation_id`, RLS and an isolation test in the same change.
- Never log secrets, tokens or unnecessary personal data.
- Secrets and credentials never enter the repository; run secret scanning before pushing (planned in CI).

## Internationalisation

- No hardcoded user-visible strings. Use translation keys and namespaces per module.
- English (`en`) is the primary and default language and the source for translation; Portuguese (`pt`) is the secondary language.
- Every key must exist in both `en` and `pt` in the same change. A feature is not complete until both are complete.
- Only one language is displayed at a time. The language selector works on the login page and throughout the authenticated application, and the choice is persisted.
- API errors return stable English codes and keys.

## Git workflow

- `main` receives changes only through reviewed pull requests. No direct commits and no force-push.
- Work on feature branches, for example `feature/<short-description>`.
- Small, focused commits with clear messages.
- Rebase or merge `main` into the feature branch as needed; never rewrite shared history.

## Pull request checklist

- [ ] Tests added or updated and passing
- [ ] Tenant isolation considered; RLS and isolation test for any new table
- [ ] Authorisation checks and permissions defined
- [ ] Audit events defined for significant actions
- [ ] English (`en`, canonical) and Portuguese (`pt`) strings both complete
- [ ] No secrets, no hardcoded business data
- [ ] Docs and ADRs updated if a decision changed
- [ ] Verification status stated honestly (see [feature verification](feature-verification.md))

## Dependencies

Each new dependency is justified, license-checked and pinned. No paid service or SaaS is introduced without explicit approval.

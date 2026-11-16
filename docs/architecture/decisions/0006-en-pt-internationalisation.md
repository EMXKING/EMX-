# ADR-0006: Internationalisation: English primary, Portuguese secondary (i18next)

Status: Accepted (revised 2026-11-16). Items under "Proposed details" need confirmation.
Date: 2026-11-16

## Revision history

- **2026-11-16 (initial draft):** recorded Portuguese (`pt`) and English (`en`) as two equal locales with the default undecided.
- **2026-11-16 (correction by the project owner):** English (`en`) is the official primary language of EMX. Portuguese (`pt`) is the secondary supported language. English is the default and the canonical language. This revision replaces the earlier wording. The file was renamed from `0006-en-pt-internationalisation.md` to put English first; no other decision changed.

## Context
Complete English and Portuguese support is a core requirement, not a later enhancement. The project owner has fixed English as the primary language and Portuguese as the secondary language.

## Decision
i18next provides translation in the frontend. Two languages are supported:

| Language | Code | Role |
|----------|------|------|
| English | `en` | Primary, default and canonical |
| Portuguese | `pt` | Secondary, fully supported |

### Language behaviour (requirements)
1. **English is the default** for first-time visitors and for new accounts. The default does not depend on the browser's language setting.
2. **Portuguese is fully supported.** Nothing is available in English only.
3. **A language selector** lets users switch between English and Portuguese on the **login page** and **throughout the authenticated application**.
4. **Only one language is displayed at a time.** There are no side-by-side or mixed bilingual screens.
5. **The selection is persisted.** For an authenticated user it is stored with their account preference and applied on every device. For a visitor who has not signed in, the choice is remembered in the browser and carried into the login flow, then saved to the account preference after sign-in.
6. **Completeness gate:** every new feature includes complete English and Portuguese translations before it is considered complete ([feature verification](../../development/feature-verification.md)).

### English is canonical
English is the canonical language for:
- technical documentation, including ADRs and all files under `docs/`;
- API terminology and public contracts: endpoint names, field names, enumerations and error codes;
- system identifiers: code, database tables and columns, permission names, audit event codes and translation keys;
- default system messages. English text is the source of truth from which Portuguese is translated.

## What "complete" means
Every user-facing string in:
- the web interface, including labels, buttons, empty states, notifications and confirmations;
- API validation and error messages;
- emails and generated documents;
- Keycloak login, account and error pages;
- dates, numbers and currency, formatted for the selected language.

## Consequences
- No hardcoded user-visible text in components. Strings use translation keys, organised in namespaces per module. Keys and namespace names are English identifiers.
- English files are the source; each key is added in `en` first and `pt` in the same change.
- The API returns stable English error codes and translation keys, and resolves text for the user's selected language. Clients must not parse message text.
- Every key must exist in both `en` and `pt`. CI will fail on a missing key in either language (planned check).
- A missing translation at runtime falls back to English as a safety net only. It is treated as a defect, reported, and must not ship, because it would break the one-language-at-a-time rule.
- Stored business data entered by users is not translated automatically.
- Audit log entries store English event codes, not translated text, so records stay language-independent.
- The login page, which is served by Keycloak, must offer the same two-language selector and carry the choice into the application. The standard OIDC `ui_locales` request parameter is one candidate mechanism; this must be checked against the chosen Keycloak version.

## Proposed details (need confirmation)
- Which Portuguese variant is the target for `pt` (for example European, Brazilian or other). The code `pt` is used until decided; a regional variant would need a new decision.
- Where the pre-login choice is stored in the browser, and how it is synchronised with the Keycloak login page.
- How the API learns the language for requests: persisted user preference first, then an explicit client-supplied language, then English. The browser's `Accept-Language` header does not override the English default for first-time visitors.

## Alternatives considered
Other i18n libraries were not adopted because the stack was fixed by the project owner. Equal, co-primary languages were rejected by the project owner in favour of an English-primary model.

## Verification
Not implemented. Not verified. No translation file exists yet.

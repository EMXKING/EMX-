# ADR-0006: Internationalisation: i18next, Portuguese (pt) and English (en)

Status: Accepted. Items under "Proposed details" need confirmation.
Date: 2026-11-16

## Context
Complete Portuguese and English support is a core requirement, not a later enhancement.

## Decision
i18next provides translation in the frontend. Two locales are supported: `pt` and `en`. Users can switch language at runtime and the choice persists per user.

## What "complete" means
Every user-facing string in:
- the web interface, including labels, buttons, empty states, notifications and confirmations;
- API validation and error messages;
- emails and generated documents;
- Keycloak login, account and error pages;
- dates, numbers and currency, formatted by locale.

## Consequences
- No hardcoded user-visible text in components. Strings use translation keys, organised in namespaces per module.
- The API returns stable error codes and translation keys, and resolves text for the requested locale. Clients must not parse message text.
- Every key must exist in both `pt` and `en`. CI will fail on a missing key in either locale (planned check).
- Stored business data entered by users is not translated automatically.
- Audit log entries store event codes, not translated text, so records stay locale-independent.

## Proposed details (need confirmation)
- Default locale and fallback behaviour when a key is missing.
- Which Portuguese variant is the target (for example European, Brazilian or other). The code `pt` is used until decided; a regional variant would need a new decision.
- How the API learns the locale: persisted user preference first, then the `Accept-Language` header.

## Alternatives considered
Other i18n libraries were not adopted because the stack was fixed by the project owner.

## Verification
Not implemented. Not verified. No translation file exists yet.

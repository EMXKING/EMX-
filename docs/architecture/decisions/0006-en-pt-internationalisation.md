# ADR-0006: Internationalisation: English primary, Portuguese secondary (i18next)

Status: Accepted (revised 2026-11-16). The Keycloak `ui_locales` mechanism is accepted as the approach but is **subject to verification** against the selected Keycloak version.
Date: 2026-11-16

## Revision history

- **2026-11-16 (initial draft):** recorded Portuguese (`pt`) and English (`en`) as two equal locales with the default undecided.
- **2026-11-16 (correction by the project owner):** English (`en`) is the official primary, default and canonical language; Portuguese (`pt`) is the secondary supported language. The file was renamed from `0006-pt-en-internationalisation.md` to put English first.
- **2026-11-16 (closing decisions by the project owner):** closed the remaining open details: Portuguese variant policy, pre-login persistence, Keycloak language passing, API language handling, missing-translation policy and profile persistence. See "Decisions".
- **2026-11-16 (three further decisions by the project owner):** (a) emails, background notifications, scheduled messages and generated documents use the recipient's saved profile language, English if none (D7); (b) the frontend must explicitly set `Accept-Language`, the browser's native language must not override EMX, and localised API responses return `Content-Language` (D4); (c) the most recent explicit language selection wins over the saved profile and is saved after authentication (D8).

## Context
Complete English and Portuguese support is a core requirement, not a later enhancement. English is the primary language and Portuguese is the secondary language.

## Decision

### Supported languages

| Language | Code | Role |
|----------|------|------|
| English | `en` | Primary, default and canonical |
| Portuguese | `pt` | Secondary, fully supported; neutral international Portuguese |

### Core behaviour
1. English is the default for first-time visitors and new accounts, **regardless of the browser's language setting**.
2. Portuguese is fully supported. Nothing ships in English only.
3. A language selector exists on the login experience and throughout the authenticated application.
4. Only one language is displayed at a time. No mixed or bilingual screens.
5. Every new feature includes complete English and Portuguese translations before it is considered complete.
6. English is canonical for technical documentation, API terminology, API field names, system identifiers, translation keys, audit event codes, internal system terminology and default system messages.

### D1. Portuguese variant
- `pt` is **neutral international Portuguese**, avoiding unnecessary regional expressions, idioms and spelling or vocabulary tied to one country.
- The architecture must be **extensible to `pt-PT` and `pt-BR`** later, without restructuring. Language tags are handled as BCP 47 tags. A future variant contains only the keys that differ and falls back to `pt`, then to English only under the development rule in D5. i18next supports configurable fallback chains; the exact configuration is confirmed at implementation.
- `pt-PT` and `pt-BR` are **not supported variants today**. A request for one resolves to `pt`.
- A Portuguese glossary and style guide for the neutral register is to be written during implementation, so terminology stays consistent across modules.

### D2. Pre-login persistence
- The selected language is stored in the browser's **local storage** under an agreed key, before login.
- A first-time visitor with no stored choice sees **English**, regardless of browser language. The browser's language setting is never used to choose the default.
- Local storage holds only the language code, nothing sensitive. It can be empty or unavailable (for example private browsing), so the application must work, in English, without it.

### D3. Keycloak login experience
- The selected language is passed to Keycloak with the standard OIDC **`ui_locales`** authentication request parameter, so the login pages open in the chosen language.
- The login experience provides a **language selector** and shows one language at a time. Keycloak login, account and error pages are themed in English and Portuguese.
- Keycloak runs on a different origin from the application, so it cannot read the application's local storage. `ui_locales` is the way the choice reaches it.
- **To verify against the selected Keycloak version before implementation:**
  - that `ui_locales` is honoured and the realm's supported locales are configured for `en` and `pt`;
  - that Keycloak's own selector works, and how a language chosen on a Keycloak page returns to the application (for example through a token claim or a post-login read of the profile);
  - how theme message bundles are supplied for both languages.

  Until verified, this is an accepted approach, not a proven one.

### D4. API language
- The API uses the HTTP **`Accept-Language`** request header to localise user-facing messages (validation errors, error descriptions, notifications shown to the user). Matching considers supported tags and quality values; `pt`, `pt-PT` and `pt-BR` resolve to `pt`; anything unsupported or absent resolves to `en`.
- **The frontend must explicitly set `Accept-Language`** on its API requests, from the currently selected EMX language (`en` or `pt`, as resolved by D8). It must not send, forward or rely on the browser's native language preference. The browser's language must never override EMX's English default or the user's explicit language selection. Whether an explicitly set header reliably replaces the browser's default in every supported browser is **not yet verified** and must be tested.
- **Every API response that contains localised messages returns a `Content-Language` header** with the language actually used (`en` or `pt`). If the requested language is unsupported or absent, the API uses `en` and returns `Content-Language: en`.
- Requests that the browser makes without script control (for example a direct download link) cannot carry the explicit header. How those are handled is an open question.
- **Not localised:** API field names, endpoints, enumerations, error codes, translation keys, identifiers and audit event codes. These are English and stable. Clients use codes and keys, never message text.
- **No request, no header:** emails, background notifications, scheduled messages and generated documents have no request to read a header from. They follow D7.

### D5. Missing translations
- English fallback is allowed **only as a development safety mechanism**, so a developer sees something while working. It logs a warning.
- **A missing Portuguese translation is a defect.** CI fails when any required key is missing in `en` or `pt`, or when a key exists in one language and not the other.
- Fallback to English must not be enabled in production builds. Production releases must not contain incomplete translations or mixed-language interfaces.
- A release is blocked if the translation check fails.
- A future variant (`pt-PT`, `pt-BR`) is checked for unknown keys but is not required to be complete, because it inherits from `pt` by design.

### D6. Persistence in the EMX user profile
- After authentication, the user's language preference is **stored in their EMX user profile** (a column on the user record, holding a supported language code).
- An **explicit user preference takes priority over the default**. English is used only when no explicit preference exists. Conflicts between explicit selections are resolved by D8.
- A new account starts with `en`, unless the person explicitly chose Portuguese before or during sign-up, in which case that explicit choice is saved.
- Changing the language in the application updates the profile and applies on every device.

### D7. Emails, background notifications and generated documents
- This applies to **emails, background notifications, scheduled messages and generated user-facing documents**, where localisation is supported.
- The language is the **recipient's saved language preference from their EMX user profile**. If no preference exists, the language is **English (`en`)**. This includes recipients who have no EMX user profile.
- The language is resolved per recipient when the message or document is generated. One message is written in one language; there are no bilingual messages.
- The language of the person who triggered the action, and any `Accept-Language` header, play no part, because background output has no request context.
- Any output type that cannot yet be localised must be recorded as a known limitation in that feature's documentation.
- Audit event codes and other identifiers remain English.

### D8. Language preference conflicts
Rule: **the most recent explicit user language selection takes precedence.** An explicit selection is a deliberate use of a language selector, on the login experience or inside the application.

Before authentication the application shows the language in local storage, or English if none (D2). After successful authentication:

1. If the user made an explicit selection during the current visit, that language becomes the active preference and is **saved to their EMX profile**, replacing the saved value.
2. Otherwise the **saved profile preference is retained** and becomes active. Local storage is updated to match it.
3. If the profile has no saved preference, the language in local storage (an earlier explicit choice) is used and saved; if there is none either, English is used.

Example: English is saved in the profile. The user selects Portuguese on the login page and signs in. Portuguese becomes the active preference after successful authentication and is saved to the profile.

Further rules:
- The save happens only after successful authentication. If sign-in fails or is abandoned, the profile is unchanged.
- A language change made inside the authenticated application is explicit, applies immediately and is saved to the profile.
- If the same user changes language on two devices, the most recent explicit selection wins.
- Whether a language chosen on a Keycloak-hosted page can be returned to the application, and therefore counted as an explicit selection, depends on Keycloak behaviour that is **not yet verified** (see D3).

## What "complete" means
Every user-facing string in:
- the web interface, including labels, buttons, empty states, notifications and confirmations;
- API user-facing messages;
- emails and generated documents;
- Keycloak login, account and error pages;
- dates, numbers and currency, formatted for the selected language.

## Consequences
- No hardcoded user-visible text in components. Strings use English translation keys in namespaces per module. English is the source; Portuguese is translated from it, in the same change.
- The user record gains a language field, owned by the Identity and Access Management module.
- Audit log entries store English event codes, so records are language-independent; display text is produced at read time.
- Stored business data entered by users is not translated automatically.
- Tests cover English default, the selector on login and in the application, one language at a time, persistence in local storage and in the profile, `ui_locales` hand-off, `Accept-Language` handling, and the CI translation check ([testing strategy](../../development/testing-strategy.md)).

## Alternatives considered
- Equal, co-primary languages: rejected by the project owner in favour of English primary.
- Choosing the default from the browser language: rejected; English is always the default.
- Shipping `pt-PT` and `pt-BR` now: deferred; the structure keeps the door open.

## Verification
Not implemented. Not verified. No translation file exists. The Keycloak `ui_locales` behaviour has not been checked against any Keycloak version.

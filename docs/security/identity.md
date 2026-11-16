# Identity and Token Handling

Status: **Design only. Not implemented. Not verified.** No Keycloak instance has been run for EMX.

Related: [ADR-0004](../architecture/decisions/0004-authentication-keycloak-oidc.md).

## Responsibilities

- **Keycloak**: credentials, password policy, multi-factor options, sessions and token issuing.
- **EMX backend**: validating tokens, mapping identity to organisation membership and authorising actions.
- **EMX never** stores passwords, implements its own login, or issues tokens.

## Login flow

OIDC Authorization Code flow with PKCE from the React application. No implicit flow. No client secret in the browser.

## Backend token validation (every request)

| Check | Requirement |
|-------|-------------|
| Signature | Verified against Keycloak's published signing keys; key rotation handled |
| Issuer | Must match the configured Keycloak realm |
| Audience | Must include the EMX API |
| Expiry and not-before | Enforced, with small, bounded clock tolerance |
| Token type | Access token only |

Invalid or missing tokens are rejected before any business logic runs.

## Mapping identity to the organisation

The backend maps the token subject to an EMX user record and the user's active organisation memberships. The organisation for a request comes from this verified mapping, never from client input. The realm layout (single realm versus realm per organisation) is proposed, not final; see ADR-0004.

## Language and the login flow

The application passes the user's selected language to Keycloak with the OIDC `ui_locales` parameter so the login pages open in that language, and the login experience offers a language selector ([ADR-0006](../architecture/decisions/0006-en-pt-internationalisation.md), D3). First-time visitors see English. After successful authentication the language preference is saved in the EMX user profile. The most recent explicit language selection wins: a language chosen on the login page replaces a different saved value, and without an explicit selection the saved profile preference is kept (D8). Emails and background output use the recipient's saved profile language, or English if none (D7). The frontend sets `Accept-Language` explicitly, and the browser's native language never overrides EMX (D4). The `ui_locales` behaviour is **not yet verified** against any Keycloak version. Language preference is not a security claim: the backend never uses it for authorisation or tenant decisions.

## Token storage in the browser

The storage approach (in-memory versus other options) is a security decision still to be made. The default position is to avoid persistent token storage that scripts can read, and the choice will be recorded in an ADR before login is implemented.

## Configuration and secrets

- Realm configuration is exported into the repository **without** secrets, credentials or real user data.
- Client secrets, admin credentials and database passwords come from environment variables.
- A `.env.example` contains placeholder names only.
- Secret scanning is planned in CI.

## Session and logout

Token lifetimes, refresh handling and logout behaviour will be defined at implementation and tested. Security-relevant authentication events available from Keycloak will be considered for the audit trail.

## Required tests

Expired, tampered, wrong-issuer and wrong-audience tokens rejected; missing token rejected; user without membership refused; client-supplied organisation ignored.

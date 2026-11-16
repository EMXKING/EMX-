# ADR-0004: Authentication: Keycloak + OIDC/OAuth2

Status: Accepted. The realm model below is **Proposed** and needs owner confirmation.
Date: 2026-11-16

## Context
EMX must authenticate users securely without storing or handling passwords itself, and must support enterprise identity requirements.

## Decision
Keycloak is the only identity provider. The frontend uses OIDC Authorization Code flow with PKCE. The backend acts as an OAuth2 resource server that validates access tokens.

## Consequences
- No password storage, login form or token issuing in EMX code. **No simulated authentication.**
- The backend verifies signature (against Keycloak's published keys), issuer, audience and expiry on every request.
- Keycloak handles authentication; EMX authorises. Business permissions are evaluated in the backend (see [ADR-0009](0009-authn-authz-audit-architecture.md)).
- The realm is exported as configuration into the repository with **no secrets or credentials**. Client secrets and admin credentials come from environment configuration.
- Keycloak login pages must be available in `pt` and `en`.

## Proposed realm model (needs confirmation)
A single EMX realm, with the user's organisation membership carried in a token claim that the backend maps to `organisation_id`. The alternative, one realm per organisation, gives stronger identity separation but adds operational cost. Keycloak also has an Organizations capability in recent versions. Which approach fits must be checked against the Keycloak version chosen before this is finalised. The backend must never trust an organisation identifier sent by the client.

## Alternatives considered
Building custom authentication was rejected for security reasons.

## Verification
Not implemented. Not verified. No Keycloak instance has been run for EMX.

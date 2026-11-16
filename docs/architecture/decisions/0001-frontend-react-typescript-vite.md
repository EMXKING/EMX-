# ADR-0001: Frontend: React + TypeScript + Vite

Status: Accepted
Date: 2026-11-16

## Context
EMX needs a rich, maintainable single-page web application for workflow, risk and compliance screens, with complete English (primary) and Portuguese (secondary) support and OIDC login.

## Decision
The frontend is a React application written in TypeScript and built and served in development with Vite.

## Consequences
- Strict TypeScript is required (`strict` enabled); `any` needs a justification in review.
- The frontend authenticates with Keycloak through the OIDC Authorization Code flow with PKCE. Tokens are never hardcoded and no simulated login exists.
- All user-visible text goes through i18next ([ADR-0006](0006-en-pt-internationalisation.md)).
- Server data comes from the real API. Hardcoded business data is not permitted.
- Client-side checks improve usability only. They are never the security boundary.
- State management, routing and component library are undecided and need their own decision.

## Alternatives considered
Other frontend frameworks were not adopted because the stack was fixed by the project owner.

## Verification
Not implemented. Not verified.

# ADR-0002: Backend: NestJS + TypeScript

Status: Accepted
Date: 2026-11-16

## Context
EMX needs a backend with strong structure for modules, dependency injection, guards and validation, in the same language as the frontend so types can be shared.

## Decision
The backend is a NestJS application written in TypeScript, organised as a modular monolith (see [modular-monolith.md](../modular-monolith.md)).

## Consequences
- NestJS modules map to EMX business modules; guards, interceptors and pipes implement authentication, authorisation, tenant context and validation.
- Strict TypeScript. All external input is validated at the boundary.
- Request-scoped tenant context (for example using Node's `AsyncLocalStorage`) carries the verified `organisation_id`. The exact mechanism will be chosen in implementation and covered by tests.
- The database access layer is undecided. It must allow every query to run inside a transaction that has the organisation context set ([ADR-0008](0008-postgresql-row-level-security.md)).
- EMX application code is TypeScript only.

## Alternatives considered
Other backend frameworks were not adopted because the stack was fixed by the project owner.

## Verification
Not implemented. Not verified.

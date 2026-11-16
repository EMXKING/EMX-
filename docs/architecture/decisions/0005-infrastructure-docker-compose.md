# ADR-0005: Infrastructure: Docker Compose

Status: Accepted
Date: 2026-11-16

## Context
Developers need a reproducible local environment with PostgreSQL and Keycloak, without depending on paid or public services.

## Decision
Docker Compose defines the local environment: PostgreSQL, Keycloak and later the API and web app as needed. The Compose files live under `infra/`.

## Consequences
- Local only. **No public deployment and no paid service** may be created from these files without explicit approval.
- No credentials in Compose files. Values come from an untracked `.env` file; a `.env.example` with placeholders and no real secrets is committed.
- Service ports bind to localhost only.
- Image tags are pinned to specific versions once chosen, not `latest`.
- Pulling images requires network access to the container registries. Currently blocked (see [blockers](../../implementation/blockers-and-open-questions.md)). The Docker daemon is also not running in the current sandbox.
- If Docker cannot run, native PostgreSQL is a possible fallback for database work, but Keycloak would then need a separate installation approach.

## Alternatives considered
Orchestrators for production were not considered; production is out of scope.

## Verification
Not implemented. Not verified. `docker compose` CLI exists in the sandbox, but the daemon is not running and no EMX Compose file exists.

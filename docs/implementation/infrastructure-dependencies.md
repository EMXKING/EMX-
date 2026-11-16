# Infrastructure Dependencies

Status: observed environment facts from the audit on 2026-11-16 (cloud development sandbox). The commands below are checks to run; their results are not recorded here until they have actually been run after the blockers are cleared.

## Observed in the sandbox

| Item | Observed |
|------|----------|
| Node.js, npm, pnpm, yarn | Present |
| Git, Make, jq, gh | Present |
| Docker CLI and Compose CLI | Present |
| Docker daemon | **Not running** (a `dockerd` binary exists; whether it can be started is untested) |
| PostgreSQL client and server binaries (16.x) | Present, no server running |
| Keycloak | Not installed |
| Network access for package installs and container registries | **Blocked or unconfirmed** (npm and registry probes failed) |

## What Phase 1 needs

### Network (allowlist)

| Purpose | Hosts (to confirm on first use) |
|---------|--------------------------------|
| npm packages | `registry.npmjs.org` |
| PostgreSQL container image | `registry-1.docker.io`, `auth.docker.io`, `production.cloudflare.docker.com` |
| Keycloak container image | `quay.io` and its CDN hosts |
| Source control | `github.com` (works through the session proxy) |

### Runtime
A running Docker daemon, or an agreed fallback (native PostgreSQL plus a separately obtained Keycloak distribution).

### GitHub permissions
- Contents: read and write on `EMXKING/EMX-` (push feature branches; never `main`).
- Pull requests: read and write, if pull requests are to be opened from here.
- Workflow permission, only if CI files under `.github/workflows/` are to be pushed.
- Recommended: branch protection on `main` requiring pull requests.

## Commands to verify readiness (run when blockers are cleared)

```bash
cd /home/claude/emx-
git switch feature/phase1-foundation

# network
npm ping
curl -sSI https://registry-1.docker.io/v2/ | head -1
curl -sSI https://quay.io/v2/ | head -1

# docker
docker info
docker compose version
docker pull postgres:<pinned-version>
docker pull quay.io/keycloak/keycloak:<pinned-version>
```

Versions are placeholders. They will be chosen and pinned in an ADR or in the Compose file when the images can be pulled.

## Commands for the first implementation stage (not yet runnable; files do not exist)

```bash
docker compose -f infra/docker-compose.yml --env-file .env up -d
docker compose -f infra/docker-compose.yml ps
```

`.env` is created locally from `.env.example` with real values that are never committed.

## Out of scope

Public deployment, paid services and cloud accounts. None may be activated without explicit approval.

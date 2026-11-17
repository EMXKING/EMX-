# Repository Structure

Status: **Planned layout. Today only `README.md`, `docs/`, `db/` and `.gitignore` exist; the rest is planned.** Tooling choices (package manager, monorepo tool) are undecided.

```
EMX-/
├── README.md
├── docs/                       existing: architecture, security, development, implementation
├── apps/
│   ├── api/                    NestJS backend (modular monolith)
│   │   └── src/
│   │       ├── platform/       tenancy, auth, authorisation, audit-log, database, i18n, config
│   │       └── modules/        one folder per business module
│   └── web/                    React + TypeScript + Vite frontend
│       └── src/
│           └── locales/        en/ (canonical), pt/ (neutral); pt-PT/ and pt-BR/ may be added later as overrides
├── packages/                   shared TypeScript types and contracts (if needed)
├── db/                         EXISTS: PostgreSQL layer, see db/README.md
│   ├── bootstrap/              superuser setup: roles, database, schema
│   ├── migrations/             versioned SQL migrations, including RLS policies
│   ├── scripts/                bootstrap.sh and migrate.sh
│   └── tests/                  SQL security tests, run.sh harness, mutation_check.sh
├── infra/
│   ├── docker-compose.yml      local PostgreSQL and Keycloak
│   └── keycloak/               realm export (no secrets)
├── .env.example                placeholders only
└── .gitignore                  EXISTS: excludes .env, build output, dependencies
```

## Rules

- `.env` files with real values are never committed. `.env.example` contains placeholder names only.
- Each business module in `apps/api/src/modules/` owns its tables, DTOs and tests, and exposes a public interface ([modular monolith](../architecture/modular-monolith.md)).
- Migrations are append-only once merged. Fix mistakes with a new migration.
- Translation files live next to the code that uses them and are checked for `en`/`pt` parity. English is the source; Portuguese is translated from it.
- Generated files, dependencies and build output are not committed.

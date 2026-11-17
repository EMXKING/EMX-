-- 0002: organisations (the tenants) and users.
--
-- organisations: one row per tenant. Its "id" is the tenant identifier that every
--   tenant-owned table references as organisation_id.
-- users: the global EMX identity record, linked to the Keycloak subject. A user
--   can belong to several organisations through organisation_memberships, so the
--   user row itself is not owned by one organisation. It is still protected by
--   row-level security (see 0006) so one tenant cannot enumerate another's users.
--
-- Row-level security is enabled and FORCED here, at creation. Until the policies
-- in 0006 exist, these tables deny every row (default deny).

CREATE TABLE emx.organisations (
  id          uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  slug        text        NOT NULL,
  name        text        NOT NULL,
  status      text        NOT NULL DEFAULT 'active',
  created_at  timestamptz NOT NULL DEFAULT now(),
  updated_at  timestamptz NOT NULL DEFAULT now(),
  CONSTRAINT organisations_slug_key UNIQUE (slug),
  CONSTRAINT organisations_slug_format CHECK (slug ~ '^[a-z0-9]([a-z0-9-]{0,62}[a-z0-9])?$'),
  CONSTRAINT organisations_name_not_blank CHECK (btrim(name) <> ''),
  CONSTRAINT organisations_status_valid CHECK (status IN ('active', 'suspended', 'closed'))
);

CREATE TABLE emx.users (
  id                   uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  keycloak_subject     text        NOT NULL,
  email                text        NOT NULL,
  display_name         text        NOT NULL,
  -- NULL means "no explicit preference": English is used (ADR-0006, D6/D7).
  language_preference  text,
  status               text        NOT NULL DEFAULT 'active',
  created_at           timestamptz NOT NULL DEFAULT now(),
  updated_at           timestamptz NOT NULL DEFAULT now(),
  CONSTRAINT users_keycloak_subject_key UNIQUE (keycloak_subject),
  CONSTRAINT users_keycloak_subject_not_blank CHECK (btrim(keycloak_subject) <> ''),
  CONSTRAINT users_email_format CHECK (btrim(email) <> '' AND position('@' IN email) > 1),
  CONSTRAINT users_display_name_not_blank CHECK (btrim(display_name) <> ''),
  CONSTRAINT users_language_preference_valid CHECK (language_preference IS NULL OR language_preference IN ('en', 'pt')),
  CONSTRAINT users_status_valid CHECK (status IN ('active', 'suspended'))
);
CREATE UNIQUE INDEX users_email_lower_key ON emx.users (lower(email));

ALTER TABLE emx.organisations ENABLE ROW LEVEL SECURITY;
ALTER TABLE emx.organisations FORCE ROW LEVEL SECURITY;
ALTER TABLE emx.users ENABLE ROW LEVEL SECURITY;
ALTER TABLE emx.users FORCE ROW LEVEL SECURITY;

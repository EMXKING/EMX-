-- 0004: permissions catalogue, roles, role-permission and membership-role links.
--
-- permissions: a GLOBAL catalogue of permission codes ("resource:action"). It is
--   not tenant-owned and holds no tenant data; the application may only read it.
--   Permission codes are defined by the modules that introduce them, so none are
--   seeded here.
-- roles: tenant-owned. Roles are scoped to one organisation.
-- role_permissions, membership_roles: tenant-owned link tables. Their composite
--   foreign keys include organisation_id, so a link can only join a role and a
--   membership that belong to the SAME organisation.

CREATE TABLE emx.permissions (
  id           uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  code         text        NOT NULL,
  description  text        NOT NULL DEFAULT '',
  created_at   timestamptz NOT NULL DEFAULT now(),
  CONSTRAINT permissions_code_key UNIQUE (code),
  CONSTRAINT permissions_code_format CHECK (code ~ '^[a-z][a-z0-9_-]*:[a-z][a-z0-9_-]*$')
);

CREATE TABLE emx.roles (
  id               uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  organisation_id  uuid        NOT NULL DEFAULT emx.current_organisation_id()
                               REFERENCES emx.organisations (id) ON DELETE RESTRICT,
  code             text        NOT NULL,
  name             text        NOT NULL,
  description      text        NOT NULL DEFAULT '',
  is_system        boolean     NOT NULL DEFAULT false,
  created_at       timestamptz NOT NULL DEFAULT now(),
  updated_at       timestamptz NOT NULL DEFAULT now(),
  CONSTRAINT roles_org_id_key UNIQUE (organisation_id, id),
  CONSTRAINT roles_org_code_key UNIQUE (organisation_id, code),
  CONSTRAINT roles_code_format CHECK (code ~ '^[a-z][a-z0-9_-]*$'),
  CONSTRAINT roles_name_not_blank CHECK (btrim(name) <> '')
);

CREATE TABLE emx.role_permissions (
  organisation_id  uuid        NOT NULL DEFAULT emx.current_organisation_id(),
  role_id          uuid        NOT NULL,
  permission_id    uuid        NOT NULL REFERENCES emx.permissions (id) ON DELETE RESTRICT,
  created_at       timestamptz NOT NULL DEFAULT now(),
  PRIMARY KEY (organisation_id, role_id, permission_id),
  CONSTRAINT role_permissions_role_fk FOREIGN KEY (organisation_id, role_id)
    REFERENCES emx.roles (organisation_id, id) ON DELETE CASCADE
);

CREATE TABLE emx.membership_roles (
  organisation_id  uuid        NOT NULL DEFAULT emx.current_organisation_id(),
  membership_id    uuid        NOT NULL,
  role_id          uuid        NOT NULL,
  created_at       timestamptz NOT NULL DEFAULT now(),
  PRIMARY KEY (organisation_id, membership_id, role_id),
  CONSTRAINT membership_roles_membership_fk FOREIGN KEY (organisation_id, membership_id)
    REFERENCES emx.organisation_memberships (organisation_id, id) ON DELETE CASCADE,
  CONSTRAINT membership_roles_role_fk FOREIGN KEY (organisation_id, role_id)
    REFERENCES emx.roles (organisation_id, id) ON DELETE CASCADE
);

-- Row-level security enabled and forced at creation (default deny until 0006).
-- The permissions catalogue is global reference data and has no RLS by design.
ALTER TABLE emx.roles ENABLE ROW LEVEL SECURITY;
ALTER TABLE emx.roles FORCE ROW LEVEL SECURITY;
ALTER TABLE emx.role_permissions ENABLE ROW LEVEL SECURITY;
ALTER TABLE emx.role_permissions FORCE ROW LEVEL SECURITY;
ALTER TABLE emx.membership_roles ENABLE ROW LEVEL SECURITY;
ALTER TABLE emx.membership_roles FORCE ROW LEVEL SECURITY;

-- 0003: organisation memberships (a user belongs to one or more organisations).
--
-- Tenant-owned: organisation_id is NOT NULL and defaults to the transaction's
-- tenant context, so callers do not need to (and must not) supply it.
-- UNIQUE (organisation_id, id) exists so other tenant-owned tables can reference a
-- membership with a COMPOSITE foreign key that includes organisation_id. That makes
-- it impossible, at the database level, to link a row of one organisation to a
-- membership of another.

CREATE TABLE emx.organisation_memberships (
  id               uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  organisation_id  uuid        NOT NULL DEFAULT emx.current_organisation_id()
                               REFERENCES emx.organisations (id) ON DELETE RESTRICT,
  user_id          uuid        NOT NULL REFERENCES emx.users (id) ON DELETE RESTRICT,
  status           text        NOT NULL DEFAULT 'active',
  created_at       timestamptz NOT NULL DEFAULT now(),
  updated_at       timestamptz NOT NULL DEFAULT now(),
  CONSTRAINT organisation_memberships_org_id_key UNIQUE (organisation_id, id),
  CONSTRAINT organisation_memberships_org_user_key UNIQUE (organisation_id, user_id),
  CONSTRAINT organisation_memberships_status_valid
    CHECK (status IN ('invited', 'active', 'suspended', 'removed'))
);
CREATE INDEX organisation_memberships_user_id_idx ON emx.organisation_memberships (user_id);

ALTER TABLE emx.organisation_memberships ENABLE ROW LEVEL SECURITY;
ALTER TABLE emx.organisation_memberships FORCE ROW LEVEL SECURITY;

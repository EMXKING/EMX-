-- 0006: row-level security policies and the application role's privileges.
--
-- Every policy applies TO emx_app only. No policy applies to any other role, so
-- with FORCE ROW LEVEL SECURITY even the table owner (emx_owner) sees and changes
-- no tenant rows. Superusers and BYPASSRLS roles bypass RLS by design and are never
-- used by the application.
--
-- Pattern for tenant-owned tables:
--   USING      (organisation_id = current tenant)   which rows are visible/changeable
--   WITH CHECK (organisation_id = current tenant)   which rows may be written
-- (SELECT) wrapping lets PostgreSQL evaluate the context function once per query.

------------------------------------------------------------------------------
-- organisations
--   visible: the active organisation, plus organisations where the current user
--            is an active member (so the user can choose one).
--   changeable: only the active organisation. No INSERT or DELETE for the app:
--            creating a tenant is a platform operation (see open questions).
------------------------------------------------------------------------------
CREATE POLICY organisations_select ON emx.organisations FOR SELECT TO emx_app
  USING (
    id = (SELECT emx.current_organisation_id())
    OR EXISTS (
      SELECT 1 FROM emx.organisation_memberships m
       WHERE m.organisation_id = organisations.id
         AND m.user_id = (SELECT emx.current_user_id())
         AND m.status = 'active'
    )
  );
CREATE POLICY organisations_update ON emx.organisations FOR UPDATE TO emx_app
  USING (id = (SELECT emx.current_organisation_id()))
  WITH CHECK (id = (SELECT emx.current_organisation_id()));

------------------------------------------------------------------------------
-- users (global identity table)
--   visible: the current user, and users who are members of the active organisation.
--   insert: only the current user's own row (first-login provisioning).
--   update: only the current user's own row.
------------------------------------------------------------------------------
CREATE POLICY users_select ON emx.users FOR SELECT TO emx_app
  USING (
    id = (SELECT emx.current_user_id())
    OR EXISTS (
      SELECT 1 FROM emx.organisation_memberships m
       WHERE m.user_id = users.id
         AND m.organisation_id = (SELECT emx.current_organisation_id())
    )
  );
CREATE POLICY users_insert ON emx.users FOR INSERT TO emx_app
  WITH CHECK (id = (SELECT emx.current_user_id()));
CREATE POLICY users_update ON emx.users FOR UPDATE TO emx_app
  USING (id = (SELECT emx.current_user_id()))
  WITH CHECK (id = (SELECT emx.current_user_id()));

------------------------------------------------------------------------------
-- organisation_memberships
--   visible: all memberships of the active organisation, plus the current user's
--            OWN memberships in any organisation (needed to list and pick one).
--   write: only inside the active organisation.
------------------------------------------------------------------------------
CREATE POLICY organisation_memberships_select ON emx.organisation_memberships FOR SELECT TO emx_app
  USING (
    organisation_id = (SELECT emx.current_organisation_id())
    OR user_id = (SELECT emx.current_user_id())
  );
CREATE POLICY organisation_memberships_insert ON emx.organisation_memberships FOR INSERT TO emx_app
  WITH CHECK (organisation_id = (SELECT emx.current_organisation_id()));
CREATE POLICY organisation_memberships_update ON emx.organisation_memberships FOR UPDATE TO emx_app
  USING (organisation_id = (SELECT emx.current_organisation_id()))
  WITH CHECK (organisation_id = (SELECT emx.current_organisation_id()));

------------------------------------------------------------------------------
-- roles, role_permissions, membership_roles: strictly the active organisation.
------------------------------------------------------------------------------
CREATE POLICY roles_select ON emx.roles FOR SELECT TO emx_app
  USING (organisation_id = (SELECT emx.current_organisation_id()));
CREATE POLICY roles_insert ON emx.roles FOR INSERT TO emx_app
  WITH CHECK (organisation_id = (SELECT emx.current_organisation_id()));
CREATE POLICY roles_update ON emx.roles FOR UPDATE TO emx_app
  USING (organisation_id = (SELECT emx.current_organisation_id()))
  WITH CHECK (organisation_id = (SELECT emx.current_organisation_id()));
CREATE POLICY roles_delete ON emx.roles FOR DELETE TO emx_app
  USING (organisation_id = (SELECT emx.current_organisation_id()));

CREATE POLICY role_permissions_select ON emx.role_permissions FOR SELECT TO emx_app
  USING (organisation_id = (SELECT emx.current_organisation_id()));
CREATE POLICY role_permissions_insert ON emx.role_permissions FOR INSERT TO emx_app
  WITH CHECK (organisation_id = (SELECT emx.current_organisation_id()));
CREATE POLICY role_permissions_delete ON emx.role_permissions FOR DELETE TO emx_app
  USING (organisation_id = (SELECT emx.current_organisation_id()));

CREATE POLICY membership_roles_select ON emx.membership_roles FOR SELECT TO emx_app
  USING (organisation_id = (SELECT emx.current_organisation_id()));
CREATE POLICY membership_roles_insert ON emx.membership_roles FOR INSERT TO emx_app
  WITH CHECK (organisation_id = (SELECT emx.current_organisation_id()));
CREATE POLICY membership_roles_delete ON emx.membership_roles FOR DELETE TO emx_app
  USING (organisation_id = (SELECT emx.current_organisation_id()));

------------------------------------------------------------------------------
-- Privileges for the application role: the minimum needed. RLS decides WHICH rows;
-- these grants decide WHICH operations at all.
------------------------------------------------------------------------------
GRANT EXECUTE ON FUNCTION
  emx.current_organisation_id(),
  emx.current_user_id(),
  emx.set_user_context(uuid),
  emx.set_tenant_context(uuid, uuid)
TO emx_app;

GRANT SELECT, UPDATE (name, updated_at)                                ON emx.organisations TO emx_app;
GRANT SELECT, INSERT, UPDATE (email, display_name, language_preference, updated_at)
                                                                       ON emx.users TO emx_app;
GRANT SELECT, INSERT, UPDATE                                           ON emx.organisation_memberships TO emx_app;
GRANT SELECT                                                           ON emx.permissions TO emx_app;
GRANT SELECT, INSERT, UPDATE, DELETE                                   ON emx.roles TO emx_app;
GRANT SELECT, INSERT, DELETE                                           ON emx.role_permissions TO emx_app;
GRANT SELECT, INSERT, DELETE                                           ON emx.membership_roles TO emx_app;
-- No privileges at all on emx.schema_migrations.

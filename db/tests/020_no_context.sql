-- Missing tenant context must deny access (fail closed). Runs as the application role.
\ir _vars.psql
\connect :dbname emx_app
\set VERBOSITY terse
\echo == 020 missing tenant context denies access ==

-- No context at all (each statement is its own transaction, so nothing is set).
SELECT t.expect_count('no context: organisations visible = 0', 'select count(*) from emx.organisations', 0);
SELECT t.expect_count('no context: users visible = 0', 'select count(*) from emx.users', 0);
SELECT t.expect_count('no context: memberships visible = 0', 'select count(*) from emx.organisation_memberships', 0);
SELECT t.expect_count('no context: roles visible = 0', 'select count(*) from emx.roles', 0);
SELECT t.expect_count('no context: role_permissions visible = 0', 'select count(*) from emx.role_permissions', 0);
SELECT t.expect_count('no context: membership_roles visible = 0', 'select count(*) from emx.membership_roles', 0);
SELECT t.expect_count('permissions catalogue is global reference data and stays readable', 'select count(*) from emx.permissions', 2);

SELECT t.expect_error('no context: insert with an explicit organisation id is refused by RLS',
  format($q$insert into emx.roles (organisation_id, code, name) values (%L, 'x', 'X')$q$, :'orgA'),
  ARRAY['42501'], '%row-level security%');
SELECT t.expect_error('no context: insert without an organisation id is refused (default is NULL)',
  $q$insert into emx.roles (code, name) values ('x', 'X')$q$, ARRAY['23502', '42501']);
SELECT t.expect_affected('no context: update changes no rows', $q$update emx.roles set name = 'hacked'$q$, 0);
SELECT t.expect_affected('no context: delete removes no rows', $q$delete from emx.roles$q$, 0);

-- Explicitly empty context.
BEGIN;
SELECT set_config('emx.organisation_id', '', true);
SELECT t.expect_count('empty context: roles visible = 0', 'select count(*) from emx.roles', 0);
SELECT t.expect_count('empty context: memberships visible = 0', 'select count(*) from emx.organisation_memberships', 0);
COMMIT;

-- A user context alone (no organisation) must not expose any tenant-owned rows.
BEGIN;
SELECT emx.set_user_context(:'alice');
SELECT t.expect_count('user-only context: roles visible = 0', 'select count(*) from emx.roles', 0);
SELECT t.expect_count('user-only context: role_permissions visible = 0', 'select count(*) from emx.role_permissions', 0);
SELECT t.expect_count('user-only context: membership_roles visible = 0', 'select count(*) from emx.membership_roles', 0);
COMMIT;

-- A malformed context value fails closed with an error, never with data.
BEGIN;
SELECT set_config('emx.organisation_id', 'not-a-uuid', true);
SELECT t.expect_error('malformed context value: query errors instead of returning rows',
  'select count(*) from emx.roles', ARRAY['22P02']);
ROLLBACK;

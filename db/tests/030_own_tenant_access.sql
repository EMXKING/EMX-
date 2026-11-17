-- Organisation A can access and manage ITS OWN records. All writes are rolled back so
-- the fixtures stay intact for the later tests.
\ir _vars.psql
\connect :dbname emx_app
\set VERBOSITY terse
\echo == 030 organisation A can access its own records ==

BEGIN;
SELECT emx.set_tenant_context(:'alice', :'orgA');

SELECT t.expect_count('own tenant: organisation A visible', format('select count(*) from emx.organisations where id = %L', :'orgA'), 1);
SELECT t.expect_count('own tenant: only one organisation visible', 'select count(*) from emx.organisations', 1);
SELECT t.expect_count('own tenant: 4 memberships of A visible', 'select count(*) from emx.organisation_memberships', 4);
SELECT t.expect_count('own tenant: 2 roles of A visible', 'select count(*) from emx.roles', 2);
SELECT t.expect_count('own tenant: 3 role-permission links of A visible', 'select count(*) from emx.role_permissions', 3);
SELECT t.expect_count('own tenant: 2 membership-role links of A visible', 'select count(*) from emx.membership_roles', 2);
SELECT t.expect_count('own tenant: A members visible as users (alice, carol, erin, frank)', 'select count(*) from emx.users', 4);

-- organisation_id is taken from the context, not from the caller.
SELECT t.expect_affected('own tenant: insert role WITHOUT supplying organisation_id',
  $q$insert into emx.roles (code, name) values ('auditor-x', 'Auditor X')$q$, 1);
SELECT t.expect_count('own tenant: new role was stamped with the context organisation',
  format($q$select count(*) from emx.roles where code = 'auditor-x' and organisation_id = %L$q$, :'orgA'), 1);
SELECT t.expect_affected('own tenant: insert role with explicit own organisation id',
  format($q$insert into emx.roles (organisation_id, code, name) values (%L, 'auditor-y', 'Auditor Y')$q$, :'orgA'), 1);
SELECT t.expect_affected('own tenant: update own role', $q$update emx.roles set name = 'Renamed' where code = 'auditor-x'$q$, 1);
SELECT t.expect_affected('own tenant: link a permission to own role',
  format($q$insert into emx.role_permissions (role_id, permission_id) values (%L, %L)$q$, :'roleA2', :'permUpdate'), 1);
SELECT t.expect_affected('own tenant: unlink the permission again',
  format($q$delete from emx.role_permissions where role_id = %L and permission_id = %L$q$, :'roleA2', :'permUpdate'), 1);
SELECT t.expect_affected('own tenant: assign a role to own membership',
  format($q$insert into emx.membership_roles (membership_id, role_id) values (%L, %L)$q$, :'memCarolA', :'roleA1'), 1);
SELECT t.expect_affected('own tenant: remove that role assignment',
  format($q$delete from emx.membership_roles where membership_id = %L and role_id = %L$q$, :'memCarolA', :'roleA1'), 1);
SELECT t.expect_affected('own tenant: delete own role', $q$delete from emx.roles where code = 'auditor-x'$q$, 1);
SELECT t.expect_affected('own tenant: rename own organisation',
  format($q$update emx.organisations set name = 'Synthetic Org A renamed' where id = %L$q$, :'orgA'), 1);
SELECT t.expect_affected('own tenant: user updates own language preference',
  format($q$update emx.users set language_preference = 'pt' where id = %L$q$, :'alice'), 1);
SELECT t.expect_error('own tenant: unsupported language code is rejected by the database',
  format($q$update emx.users set language_preference = 'fr' where id = %L$q$, :'alice'), ARRAY['23514']);
ROLLBACK;

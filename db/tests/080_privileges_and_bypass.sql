-- The application role cannot weaken the controls, and even the table owner is
-- subject to row-level security. Section 1 runs as emx_app, section 2 as emx_owner.
\ir _vars.psql
\connect :dbname emx_app
\set VERBOSITY terse
\echo == 080 privileges and bypass attempts ==

-- 1. emx_app
SELECT t.expect_error('app cannot create organisations', $q$insert into emx.organisations (slug, name) values ('zzz', 'Z')$q$, ARRAY['42501'], 'permission denied%');
SELECT t.expect_error('app cannot delete users', $q$delete from emx.users$q$, ARRAY['42501'], 'permission denied%');
SELECT t.expect_error('app cannot delete memberships', $q$delete from emx.organisation_memberships$q$, ARRAY['42501'], 'permission denied%');
SELECT t.expect_error('app cannot truncate tenant tables', $q$truncate emx.roles$q$, ARRAY['42501'], 'permission denied%');
SELECT t.expect_error('app cannot modify the permissions catalogue', $q$insert into emx.permissions (code) values ('x:y')$q$, ARRAY['42501'], 'permission denied%');
SELECT t.expect_error('app cannot read the migration bookkeeping table', $q$select count(*) from emx.schema_migrations$q$, ARRAY['42501'], 'permission denied%');
SELECT t.expect_error('app cannot create tables in schema emx', $q$create table emx.evil (id int)$q$, ARRAY['42501']);
SELECT t.expect_error('app cannot create tables in schema public', $q$create table public.evil (id int)$q$, ARRAY['42501']);
SELECT t.expect_error('app cannot disable row-level security', $q$alter table emx.roles disable row level security$q$, ARRAY['42501'], '%must be owner%');
SELECT t.expect_error('app cannot turn FORCE off', $q$alter table emx.roles no force row level security$q$, ARRAY['42501'], '%must be owner%');
SELECT t.expect_error('app cannot drop a policy', $q$drop policy roles_select on emx.roles$q$, ARRAY['42501'], '%must be owner%');
SELECT t.expect_error('app cannot add a permissive policy', $q$create policy evil on emx.roles for select using (true)$q$, ARRAY['42501'], '%must be owner%');
SELECT t.expect_error('app cannot become the owner role', $q$set role emx_owner$q$, ARRAY['42501']);
SELECT t.expect_error('app cannot become the superuser', $q$set role postgres$q$, ARRAY['42501']);
-- GRANT by a role that holds privileges WITHOUT grant option is a no-op that only emits a
-- WARNING (it is not an error), so assert the property that matters: privileges unchanged.
SELECT t.expect_error('app cannot grant itself privileges on a table it has no access to',
  $q$grant select on emx.schema_migrations to emx_app$q$, ARRAY['42501'], 'permission denied%');
SELECT t.expect_error('app cannot grant privileges to PUBLIC on a table it has no grant option for',
  $q$grant select on emx.schema_migrations to public$q$, ARRAY['42501'], 'permission denied%');
GRANT ALL ON emx.roles TO emx_app;
SELECT t.expect_true('app GRANT ALL on roles changed nothing: still no TRUNCATE, REFERENCES or TRIGGER privilege',
  $q$select not has_table_privilege('emx_app', 'emx.roles', 'TRUNCATE')
        and not has_table_privilege('emx_app', 'emx.roles', 'REFERENCES')
        and not has_table_privilege('emx_app', 'emx.roles', 'TRIGGER')$q$);
GRANT SELECT ON emx.roles TO PUBLIC;
SELECT t.expect_true('app GRANT to PUBLIC changed nothing: PUBLIC still has no privilege on roles',
  $q$select not has_table_privilege('public', 'emx.roles', 'SELECT')$q$);

-- Column-level grants: sensitive columns cannot be changed by the application.
BEGIN;
SELECT emx.set_tenant_context(:'alice', :'orgA');
SELECT t.expect_error('app cannot change an organisation status', format($q$update emx.organisations set status = 'closed' where id = %L$q$, :'orgA'), ARRAY['42501'], 'permission denied%');
SELECT t.expect_error('app cannot change its own account status', format($q$update emx.users set status = 'active' where id = %L$q$, :'alice'), ARRAY['42501'], 'permission denied%');
SELECT t.expect_error('app cannot change the Keycloak subject link', format($q$update emx.users set keycloak_subject = 'other' where id = %L$q$, :'alice'), ARRAY['42501'], 'permission denied%');
ROLLBACK;

-- Turning row_security off does not bypass anything for a role without BYPASSRLS.
BEGIN;
SELECT emx.set_tenant_context(:'alice', :'orgA');
SET LOCAL row_security = off;
SELECT t.expect_error('SET row_security = off cannot be used to bypass policies',
  'select count(*) from emx.roles', ARRAY['42501'], '%row-level security%');
ROLLBACK;

-- 2. emx_owner: FORCE ROW LEVEL SECURITY applies to the table owner as well.
\connect :dbname emx_owner
\set VERBOSITY terse
SELECT t.expect_count('owner: FORCE RLS - sees no organisations', 'select count(*) from emx.organisations', 0);
SELECT t.expect_count('owner: FORCE RLS - sees no users', 'select count(*) from emx.users', 0);
SELECT t.expect_count('owner: FORCE RLS - sees no memberships', 'select count(*) from emx.organisation_memberships', 0);
SELECT t.expect_count('owner: FORCE RLS - sees no roles', 'select count(*) from emx.roles', 0);
SELECT t.expect_error('owner: cannot insert tenant rows either (no policy applies to it)',
  format($q$insert into emx.roles (organisation_id, code, name) values (%L, 'x', 'X')$q$, :'orgA'), ARRAY['42501'], '%row-level security%');
SELECT t.expect_error('owner cannot become the application role', $q$set role emx_app$q$, ARRAY['42501']);

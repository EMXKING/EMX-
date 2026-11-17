-- Structural security checks read from the PostgreSQL catalogs. This is also the
-- prototype of the CI check that fails when a table is added without RLS.
\ir _vars.psql
\connect :dbname postgres
\set VERBOSITY terse
\echo == 010 structure and role attributes ==

-- Every table must be explicitly classified, so a new table cannot slip in unnoticed.
SELECT t.expect_true('every table in schema emx is classified as tenant-owned or known non-tenant', $q$
  SELECT NOT EXISTS (
    SELECT 1 FROM pg_class c JOIN pg_namespace n ON n.oid = c.relnamespace
     WHERE n.nspname = 'emx' AND c.relkind IN ('r', 'p')
       AND c.relname NOT IN ('roles', 'role_permissions', 'organisation_memberships', 'membership_roles',
                             'organisations', 'users', 'permissions', 'schema_migrations'))
$q$);

SELECT t.expect_true('exactly the four tenant-owned tables have organisation_id, NOT NULL, defaulting to the context', $q$
  SELECT array_agg(c.relname::text ORDER BY c.relname)
           = ARRAY['membership_roles', 'organisation_memberships', 'role_permissions', 'roles']
         AND bool_and(a.attnotnull) AND bool_and(a.atthasdef)
    FROM pg_attribute a JOIN pg_class c ON c.oid = a.attrelid JOIN pg_namespace n ON n.oid = c.relnamespace
   WHERE n.nspname = 'emx' AND c.relkind = 'r' AND a.attname = 'organisation_id' AND NOT a.attisdropped
$q$);

SELECT t.expect_true('RLS is ENABLED and FORCED on all six protected tables', $q$
  SELECT count(*) = 6 FROM pg_class c JOIN pg_namespace n ON n.oid = c.relnamespace
   WHERE n.nspname = 'emx' AND c.relrowsecurity AND c.relforcerowsecurity
     AND c.relname IN ('roles', 'role_permissions', 'organisation_memberships', 'membership_roles',
                       'organisations', 'users')
$q$);

SELECT t.expect_true('every protected table has at least one policy', $q$
  SELECT count(DISTINCT tablename) = 6 FROM pg_policies WHERE schemaname = 'emx'
$q$);

SELECT t.expect_true('every policy applies to emx_app only (none to PUBLIC or other roles)', $q$
  SELECT NOT EXISTS (SELECT 1 FROM pg_policies WHERE schemaname = 'emx' AND roles <> ARRAY['emx_app']::name[])
$q$);

SELECT t.expect_true('the global permissions catalogue is the only data table without RLS', $q$
  SELECT array_agg(c.relname::text ORDER BY c.relname) = ARRAY['permissions', 'schema_migrations']
    FROM pg_class c JOIN pg_namespace n ON n.oid = c.relnamespace
   WHERE n.nspname = 'emx' AND c.relkind = 'r' AND NOT c.relrowsecurity
$q$);

SELECT t.expect_true('emx_app and emx_owner are not superuser, BYPASSRLS, CREATEROLE, CREATEDB or REPLICATION', $q$
  SELECT count(*) = 2 AND NOT bool_or(rolsuper OR rolbypassrls OR rolcreaterole OR rolcreatedb OR rolreplication)
    FROM pg_roles WHERE rolname IN ('emx_app', 'emx_owner')
$q$);

SELECT t.expect_true('emx_app is not a member of emx_owner (migration and application privileges are separate)', $q$
  SELECT NOT pg_has_role('emx_app', 'emx_owner', 'MEMBER') AND NOT pg_has_role('emx_owner', 'emx_app', 'MEMBER')
$q$);

SELECT t.expect_true('emx_app owns no objects in schema emx', $q$
  SELECT NOT EXISTS (
    SELECT 1 FROM pg_class c JOIN pg_namespace n ON n.oid = c.relnamespace
     WHERE n.nspname = 'emx' AND c.relowner = (SELECT oid FROM pg_roles WHERE rolname = 'emx_app'))
    AND NOT EXISTS (
    SELECT 1 FROM pg_proc p JOIN pg_namespace n ON n.oid = p.pronamespace
     WHERE n.nspname = 'emx' AND p.proowner = (SELECT oid FROM pg_roles WHERE rolname = 'emx_app'))
$q$);

SELECT t.expect_true('all tables in schema emx are owned by emx_owner', $q$
  SELECT NOT EXISTS (
    SELECT 1 FROM pg_class c JOIN pg_namespace n ON n.oid = c.relnamespace
     WHERE n.nspname = 'emx' AND c.relkind = 'r'
       AND c.relowner <> (SELECT oid FROM pg_roles WHERE rolname = 'emx_owner'))
$q$);

SELECT t.expect_true('emx_app has USAGE but not CREATE on schema emx', $q$
  SELECT has_schema_privilege('emx_app', 'emx', 'USAGE') AND NOT has_schema_privilege('emx_app', 'emx', 'CREATE')
$q$);

SELECT t.expect_true('emx_app cannot create organisations, delete memberships/users or truncate roles', $q$
  SELECT NOT has_table_privilege('emx_app', 'emx.organisations', 'INSERT')
     AND NOT has_table_privilege('emx_app', 'emx.organisations', 'DELETE')
     AND NOT has_table_privilege('emx_app', 'emx.organisation_memberships', 'DELETE')
     AND NOT has_table_privilege('emx_app', 'emx.users', 'DELETE')
     AND NOT has_table_privilege('emx_app', 'emx.roles', 'TRUNCATE')
     AND NOT has_table_privilege('emx_app', 'emx.permissions', 'INSERT')
     AND NOT has_table_privilege('emx_app', 'emx.schema_migrations', 'SELECT')
$q$);

SELECT t.expect_true('no function in schema emx is executable by PUBLIC', $q$
  SELECT NOT EXISTS (
    SELECT 1 FROM pg_proc p JOIN pg_namespace n ON n.oid = p.pronamespace
     WHERE n.nspname = 'emx'
       AND (p.proacl IS NULL
            OR EXISTS (SELECT 1 FROM aclexplode(p.proacl) a WHERE a.grantee = 0 AND a.privilege_type = 'EXECUTE')))
$q$);

SELECT t.expect_true('database is not connectable by PUBLIC', $q$
  SELECT NOT has_database_privilege('public', current_database(), 'CONNECT')
$q$);

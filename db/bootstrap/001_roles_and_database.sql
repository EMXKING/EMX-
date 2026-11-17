-- EMX bootstrap step 1 of 2: cluster-level roles and the database.
--
-- PRIVILEGED, run once per cluster by a superuser, connected to the maintenance
-- database (for example "postgres"). Never run by the application.
-- Usage: psql -v ON_ERROR_STOP=1 -v dbname=emx -d postgres -f 001_roles_and_database.sql
--
-- No passwords are set here and none belong in the repository. Authentication
-- for these roles is configured per environment (pg_hba.conf and secrets that
-- are supplied outside git).
--
-- Roles
--   emx_owner  owns the schema and all tables; runs migrations. Cannot bypass RLS
--              and, because tables use FORCE ROW LEVEL SECURITY, is itself subject
--              to the policies.
--   emx_app    the application's role. Not a superuser, no BYPASSRLS, owns nothing,
--              receives only the privileges granted in migration 0006.

DO $$
BEGIN
  IF NOT EXISTS (SELECT 1 FROM pg_roles WHERE rolname = 'emx_owner') THEN
    CREATE ROLE emx_owner LOGIN;
  END IF;
  IF NOT EXISTS (SELECT 1 FROM pg_roles WHERE rolname = 'emx_app') THEN
    CREATE ROLE emx_app LOGIN;
  END IF;
END
$$;

-- Enforce the security-relevant attributes explicitly, whether or not the roles
-- already existed.
ALTER ROLE emx_owner NOSUPERUSER NOCREATEDB NOCREATEROLE NOREPLICATION NOBYPASSRLS;
ALTER ROLE emx_app   NOSUPERUSER NOCREATEDB NOCREATEROLE NOREPLICATION NOBYPASSRLS;

-- The migration role must not be able to become the application role or the reverse.
-- (Neither role is granted membership in the other.)

-- Functions created by emx_owner must not be executable by PUBLIC by default.
ALTER DEFAULT PRIVILEGES FOR ROLE emx_owner REVOKE EXECUTE ON FUNCTIONS FROM PUBLIC;

SELECT format('CREATE DATABASE %I OWNER emx_owner ENCODING ''UTF8''', :'dbname')
WHERE NOT EXISTS (SELECT 1 FROM pg_database WHERE datname = :'dbname')
\gexec

REVOKE ALL ON DATABASE :"dbname" FROM PUBLIC;
GRANT CONNECT ON DATABASE :"dbname" TO emx_owner, emx_app;

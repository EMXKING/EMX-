-- EMX bootstrap step 2 of 2: schema and baseline privileges inside the database.
--
-- PRIVILEGED, run once per database by a superuser, connected to the EMX database.
-- Usage: psql -v ON_ERROR_STOP=1 -d emx -f 002_database_security.sql

-- Nobody gets anything by default.
REVOKE ALL ON SCHEMA public FROM PUBLIC;
REVOKE TEMPORARY ON DATABASE :"DBNAME" FROM PUBLIC;

-- All EMX objects live in schema "emx", owned by the migration role.
CREATE SCHEMA IF NOT EXISTS emx AUTHORIZATION emx_owner;
REVOKE ALL ON SCHEMA emx FROM PUBLIC;
GRANT USAGE ON SCHEMA emx TO emx_app;
-- emx_app deliberately has no CREATE on the schema.

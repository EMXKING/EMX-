-- DOCUMENTED LIMITATION, asserted so the documentation stays true.
--
-- The tenant context is a transaction-local setting. PostgreSQL lets ANY session set a
-- custom setting such as emx.organisation_id, so code that can run ARBITRARY SQL as
-- emx_app (for example through an SQL injection flaw or a compromised backend) can
-- forge the context. Row-level security protects against missing filters and
-- application bugs; it does NOT defend against a caller that can execute arbitrary
-- SQL with the application role.
--
-- Mitigations live in the backend and are NOT yet implemented: parameterised queries
-- only, one data-access layer that sets the context, identity taken from a verified
-- token, and (to be evaluated) a stronger binding of the context to the session.
\ir _vars.psql
\connect :dbname emx_app
\set VERBOSITY terse
\echo == 085 documented limitation: forged context ==

BEGIN;
SELECT set_config('emx.organisation_id', :'orgB', true);
SELECT t.expect_count('KNOWN LIMITATION confirmed: arbitrary SQL as emx_app can forge the organisation context and read B roles',
  'select count(*) from emx.roles', 2);
ROLLBACK;

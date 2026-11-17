-- Final check, as the superuser: after every attack attempt above, the data in the
-- database is byte-for-byte what the fixtures created.
\ir _vars.psql
\connect :dbname postgres
\set VERBOSITY terse
\echo == 090 data integrity after all tests ==

SELECT t.expect_true('whole database is identical to the fixture baseline (no test changed any row)',
  'select t.fingerprint() = (select fp from t.baseline)');
SELECT t.expect_count('organisation B still has its 2 roles', format('select count(*) from emx.roles where organisation_id = %L', :'orgB'), 2);
SELECT t.expect_count('organisation B still has its 2 memberships', format('select count(*) from emx.organisation_memberships where organisation_id = %L', :'orgB'), 2);
SELECT t.expect_count('organisation A still has its 2 roles', format('select count(*) from emx.roles where organisation_id = %L', :'orgA'), 2);

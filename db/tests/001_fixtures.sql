-- SYNTHETIC test data only. Loaded as the superuser (who bypasses row-level
-- security) purely to create fixtures in the disposable test database.
-- Nothing here is real, and nothing here is part of the product.
\ir _vars.psql
\connect :dbname postgres
\set VERBOSITY terse
\echo == 001 synthetic fixtures ==

INSERT INTO emx.organisations (id, slug, name, status) VALUES
  (:'orgA', 'synthetic-org-a', 'Synthetic Org A', 'active'),
  (:'orgB', 'synthetic-org-b', 'Synthetic Org B', 'active'),
  (:'orgC', 'synthetic-org-c', 'Synthetic Org C (suspended)', 'suspended');

INSERT INTO emx.users (id, keycloak_subject, email, display_name, language_preference, status) VALUES
  (:'alice', 'synthetic-sub-alice', 'alice@example.test', 'Synthetic Alice', 'en', 'active'),
  (:'bob',   'synthetic-sub-bob',   'bob@example.test',   'Synthetic Bob',   NULL, 'active'),
  (:'carol', 'synthetic-sub-carol', 'carol@example.test', 'Synthetic Carol', 'pt', 'active'),
  (:'dave',  'synthetic-sub-dave',  'dave@example.test',  'Synthetic Dave',  NULL, 'active'),
  (:'erin',  'synthetic-sub-erin',  'erin@example.test',  'Synthetic Erin',  NULL, 'active'),
  (:'frank', 'synthetic-sub-frank', 'frank@example.test', 'Synthetic Frank', NULL, 'suspended');

INSERT INTO emx.organisation_memberships (id, organisation_id, user_id, status) VALUES
  (:'memAliceA', :'orgA', :'alice', 'active'),
  (:'memCarolA', :'orgA', :'carol', 'active'),
  (:'memErinA',  :'orgA', :'erin',  'suspended'),
  (:'memFrankA', :'orgA', :'frank', 'active'),
  (:'memBobB',   :'orgB', :'bob',   'active'),
  (:'memCarolB', :'orgB', :'carol', 'active'),
  (:'memDaveC',  :'orgC', :'dave',  'active');

INSERT INTO emx.permissions (id, code, description) VALUES
  (:'permRead',   'synthetic:read',   'Synthetic read permission'),
  (:'permUpdate', 'synthetic:update', 'Synthetic update permission');

INSERT INTO emx.roles (id, organisation_id, code, name) VALUES
  (:'roleA1', :'orgA', 'admin',  'Synthetic A Admin'),
  (:'roleA2', :'orgA', 'viewer', 'Synthetic A Viewer'),
  (:'roleB1', :'orgB', 'admin',  'Synthetic B Admin'),
  (:'roleB2', :'orgB', 'viewer', 'Synthetic B Viewer');

INSERT INTO emx.role_permissions (organisation_id, role_id, permission_id) VALUES
  (:'orgA', :'roleA1', :'permRead'), (:'orgA', :'roleA1', :'permUpdate'), (:'orgA', :'roleA2', :'permRead'),
  (:'orgB', :'roleB1', :'permRead'), (:'orgB', :'roleB1', :'permUpdate'), (:'orgB', :'roleB2', :'permRead');

INSERT INTO emx.membership_roles (organisation_id, membership_id, role_id) VALUES
  (:'orgA', :'memAliceA', :'roleA1'),
  (:'orgA', :'memCarolA', :'roleA2'),
  (:'orgB', :'memBobB',   :'roleB1'),
  (:'orgB', :'memCarolB', :'roleB1');

-- Baseline of the whole database. The final test proves it is unchanged.
CREATE TABLE t.baseline AS SELECT t.fingerprint() AS fp;

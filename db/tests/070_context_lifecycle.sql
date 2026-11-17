-- Tenant context establishment, validation and lifecycle (transaction-local).
\ir _vars.psql
\connect :dbname emx_app
\set VERBOSITY terse
\echo == 070 tenant context: validation and transaction-local lifecycle ==

-- The database refuses to set a context the user is not entitled to.
BEGIN;
SELECT t.expect_error('alice (member of A only) cannot enter organisation B',
  format('select emx.set_tenant_context(%L, %L)', :'alice', :'orgB'), ARRAY['42501'], '%not an active member%');
SELECT t.expect_count('a refused switch leaves no tenant rows visible', 'select count(*) from emx.roles', 0);
COMMIT;

SELECT t.expect_error('dave (member of suspended org C only) cannot enter organisation A',
  format('select emx.set_tenant_context(%L, %L)', :'dave', :'orgA'), ARRAY['42501']);
SELECT t.expect_error('dave cannot enter the suspended organisation C either',
  format('select emx.set_tenant_context(%L, %L)', :'dave', :'orgC'), ARRAY['42501']);
SELECT t.expect_error('erin (suspended membership) cannot enter organisation A',
  format('select emx.set_tenant_context(%L, %L)', :'erin', :'orgA'), ARRAY['42501']);
SELECT t.expect_error('frank (suspended user) cannot enter organisation A',
  format('select emx.set_tenant_context(%L, %L)', :'frank', :'orgA'), ARRAY['42501']);
SELECT t.expect_error('an unknown user cannot enter any organisation',
  format('select emx.set_tenant_context(%L, %L)', '00000000-0000-0000-0000-0000000000ee', :'orgA'), ARRAY['42501']);
SELECT t.expect_error('a NULL user is rejected', format('select emx.set_tenant_context(NULL, %L)', :'orgA'), ARRAY['22004']);
SELECT t.expect_error('a NULL organisation is rejected', format('select emx.set_tenant_context(%L, NULL)', :'alice'), ARRAY['22004']);

-- Switching organisation inside one transaction replaces the context completely.
BEGIN;
SELECT emx.set_tenant_context(:'carol', :'orgA');
SELECT t.expect_count('carol in A: sees A roles', format('select count(*) from emx.roles where organisation_id = %L', :'orgA'), 2);
SELECT emx.set_tenant_context(:'carol', :'orgB');
SELECT t.expect_count('carol re-targeted to B: A roles no longer visible', format('select count(*) from emx.roles where organisation_id = %L', :'orgA'), 0);
SELECT t.expect_count('carol re-targeted to B: B roles visible', format('select count(*) from emx.roles where organisation_id = %L', :'orgB'), 2);
COMMIT;

-- Context is transaction-local: it must not survive COMMIT or ROLLBACK.
SELECT emx.set_tenant_context(:'alice', :'orgA');
SELECT t.expect_count('context does not survive the end of its transaction (autocommit)', 'select count(*) from emx.roles', 0);
SELECT t.expect_true('settings are empty after the transaction ended',
  $q$select coalesce(current_setting('emx.organisation_id', true), '') = '' and coalesce(current_setting('emx.user_id', true), '') = ''$q$);

BEGIN;
SELECT emx.set_tenant_context(:'alice', :'orgA');
SELECT t.expect_count('inside the transaction the context works', 'select count(*) from emx.roles', 2);
ROLLBACK;
SELECT t.expect_count('context does not survive ROLLBACK', 'select count(*) from emx.roles', 0);

-- Connection reuse (pooling): sequential transactions for different tenants on the SAME
-- connection never see each other's context.
BEGIN;
SELECT emx.set_tenant_context(:'alice', :'orgA');
SELECT t.expect_count('pooled connection, request 1 (A): sees A only', format('select count(*) from emx.roles where organisation_id = %L', :'orgA'), 2);
COMMIT;
BEGIN;
SELECT emx.set_tenant_context(:'bob', :'orgB');
SELECT t.expect_count('pooled connection, request 2 (B): sees B roles', format('select count(*) from emx.roles where organisation_id = %L', :'orgB'), 2);
SELECT t.expect_count('pooled connection, request 2 (B): sees no A roles', format('select count(*) from emx.roles where organisation_id = %L', :'orgA'), 0);
COMMIT;
BEGIN;
SELECT t.expect_count('pooled connection, request 3 (no context): sees nothing', 'select count(*) from emx.roles', 0);
COMMIT;

-- User-only context: lists the user's own organisations and nothing else.
BEGIN;
SELECT emx.set_user_context(:'carol');
SELECT t.expect_count('user context: carol sees her 2 own memberships', 'select count(*) from emx.organisation_memberships', 2);
SELECT t.expect_count('user context: carol sees her 2 organisations', 'select count(*) from emx.organisations', 2);
SELECT t.expect_count('user context: no tenant roles visible', 'select count(*) from emx.roles', 0);
COMMIT;

-- First-login provisioning of the user row: only the current user's own row.
BEGIN;
SELECT emx.set_user_context(:'newuser');
SELECT t.expect_affected('provisioning: a user can create its OWN row',
  format($q$insert into emx.users (id, keycloak_subject, email, display_name) values (%L, 'synthetic-sub-new', 'new.user@example.test', 'Synthetic New')$q$, :'newuser'), 1);
SELECT t.expect_error('provisioning: a user cannot create a row for ANOTHER id',
  format($q$insert into emx.users (id, keycloak_subject, email, display_name) values (%L, 'synthetic-sub-evil', 'evil@example.test', 'Evil')$q$, :'bob'),
  ARRAY['42501'], '%row-level security%');
ROLLBACK;

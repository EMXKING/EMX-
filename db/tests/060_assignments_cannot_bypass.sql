-- Membership and role assignments cannot be used to bypass tenant isolation.
-- All writes here are rolled back.
\ir _vars.psql
\connect :dbname emx_app
\set VERBOSITY terse
\echo == 060 membership and role assignments cannot bypass tenant isolation ==

BEGIN;
SELECT emx.set_tenant_context(:'alice', :'orgA');

-- Composite foreign keys include organisation_id: a link can only join rows of the
-- same organisation. With the organisation taken from the context (A), referencing
-- a B role or a B membership finds no matching (A, id) pair.
SELECT t.expect_error('assign a B role to an A membership is rejected',
  format($q$insert into emx.membership_roles (membership_id, role_id) values (%L, %L)$q$, :'memCarolA', :'roleB1'),
  ARRAY['23503']);
SELECT t.expect_error('assign an A role to a B membership is rejected',
  format($q$insert into emx.membership_roles (membership_id, role_id) values (%L, %L)$q$, :'memBobB', :'roleA1'),
  ARRAY['23503']);
SELECT t.expect_error('link a permission to a B role from A is rejected',
  format($q$insert into emx.role_permissions (role_id, permission_id) values (%L, %L)$q$, :'roleB1', :'permRead'),
  ARRAY['23503']);
SELECT t.expect_error('assignment into B with explicit B organisation id is refused by RLS',
  format($q$insert into emx.membership_roles (organisation_id, membership_id, role_id) values (%L, %L, %L)$q$, :'orgB', :'memBobB', :'roleB1'),
  ARRAY['42501'], '%row-level security%');
SELECT t.expect_error('mixed assignment (organisation A, B membership, B role) is rejected',
  format($q$insert into emx.membership_roles (organisation_id, membership_id, role_id) values (%L, %L, %L)$q$, :'orgA', :'memBobB', :'roleB1'),
  ARRAY['23503']);

-- A membership cannot reference a user that does not exist.
SELECT t.expect_error('membership for a non-existent user is rejected',
  format($q$insert into emx.organisation_memberships (user_id) values (%L)$q$, '00000000-0000-0000-0000-0000000000ff'),
  ARRAY['23503']);

-- Assignment rows cannot be modified in place (no UPDATE privilege), so a link cannot
-- be re-pointed at another organisation's role or membership.
SELECT t.expect_error('membership-role links cannot be updated (no UPDATE privilege)',
  format($q$update emx.membership_roles set role_id = %L where membership_id = %L$q$, :'roleB1', :'memAliceA'),
  ARRAY['42501'], 'permission denied%');

-- Adding an existing user (bob, a member of B) to A is legitimate multi-organisation
-- membership. It grants nothing in B and changes nothing in B.
SELECT t.expect_affected('adding bob to organisation A is allowed (multi-organisation membership)',
  format($q$insert into emx.organisation_memberships (user_id) values (%L)$q$, :'bob'), 1);
SELECT t.expect_count('...and the new membership belongs to organisation A',
  format($q$select count(*) from emx.organisation_memberships where user_id = %L and organisation_id = %L$q$, :'bob', :'orgA'), 1);
SELECT t.expect_count('...and gave A no access to B roles', format('select count(*) from emx.roles where organisation_id = %L', :'orgB'), 0);
ROLLBACK;

-- Role assignments of a legitimate A membership grant nothing in B.
BEGIN;
SELECT emx.set_tenant_context(:'carol', :'orgA');
SELECT t.expect_count('carol in A sees only the A role assignments (2)', 'select count(*) from emx.membership_roles', 2);
SELECT t.expect_count('carol in A does not see her B role assignment', format('select count(*) from emx.membership_roles where membership_id = %L', :'memCarolB'), 0);
COMMIT;

-- The membership lookup used to establish context only honours ACTIVE rows.
BEGIN;
SELECT emx.set_tenant_context(:'carol', :'orgB');
SELECT t.expect_count('carol switched to B sees B roles (2)', 'select count(*) from emx.roles', 2);
SELECT t.expect_count('carol switched to B no longer sees A roles', format('select count(*) from emx.roles where organisation_id = %L', :'orgA'), 0);
COMMIT;

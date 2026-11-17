-- Organisation A cannot INSERT into, UPDATE or DELETE organisation B's records.
-- This file COMMITS, so if any attempt had a real effect it would persist, and the
-- final integrity test (090) would detect it.
\ir _vars.psql
\connect :dbname emx_app
\set VERBOSITY terse
\echo == 050 organisation A cannot write to organisation B ==

BEGIN;
SELECT emx.set_tenant_context(:'alice', :'orgA');

-- INSERT with B's organisation id: refused by the RLS WITH CHECK clause.
SELECT t.expect_error('A cannot insert a role into B',
  format($q$insert into emx.roles (organisation_id, code, name) values (%L, 'evil', 'Evil')$q$, :'orgB'),
  ARRAY['42501'], '%row-level security%');
SELECT t.expect_error('A cannot add a membership to B (self-escalation)',
  format($q$insert into emx.organisation_memberships (organisation_id, user_id) values (%L, %L)$q$, :'orgB', :'alice'),
  ARRAY['42501'], '%row-level security%');
SELECT t.expect_error('A cannot add a role-permission link to B',
  format($q$insert into emx.role_permissions (organisation_id, role_id, permission_id) values (%L, %L, %L)$q$, :'orgB', :'roleB2', :'permUpdate'),
  ARRAY['42501'], '%row-level security%');
SELECT t.expect_error('A cannot add a membership-role link to B',
  format($q$insert into emx.membership_roles (organisation_id, membership_id, role_id) values (%L, %L, %L)$q$, :'orgB', :'memBobB', :'roleB2'),
  ARRAY['42501'], '%row-level security%');
SELECT t.expect_error('A cannot insert a user row for someone else',
  format($q$insert into emx.users (id, keycloak_subject, email, display_name) values (%L, 'synthetic-sub-x', 'x@example.test', 'X')$q$, :'bob'),
  ARRAY['42501'], '%row-level security%');

-- UPDATE of B rows: invisible, so zero rows are affected.
SELECT t.expect_affected('A cannot update a B role', format($q$update emx.roles set name = 'hacked' where id = %L$q$, :'roleB1'), 0);
SELECT t.expect_affected('A cannot update all roles of B', format($q$update emx.roles set name = 'hacked' where organisation_id = %L$q$, :'orgB'), 0);
SELECT t.expect_affected('A cannot suspend a B membership', format($q$update emx.organisation_memberships set status = 'removed' where id = %L$q$, :'memBobB'), 0);
SELECT t.expect_affected('A cannot rename organisation B', format($q$update emx.organisations set name = 'hacked' where id = %L$q$, :'orgB'), 0);
SELECT t.expect_affected('A cannot change user bob', format($q$update emx.users set display_name = 'hacked' where id = %L$q$, :'bob'), 0);
SELECT t.expect_affected('A cannot pull a B role into A by changing organisation_id',
  format($q$update emx.roles set organisation_id = %L where id = %L$q$, :'orgA', :'roleB1'), 0);

-- Moving an A row INTO B is refused by the RLS WITH CHECK clause.
SELECT t.expect_error('A cannot move its own role to B',
  format($q$update emx.roles set organisation_id = %L where id = %L$q$, :'orgB', :'roleA1'),
  ARRAY['42501'], '%row-level security%');
SELECT t.expect_error('A cannot move its own membership to B',
  format($q$update emx.organisation_memberships set organisation_id = %L where id = %L$q$, :'orgB', :'memAliceA'),
  ARRAY['42501'], '%row-level security%');

-- DELETE of B rows: invisible, so zero rows are affected.
SELECT t.expect_affected('A cannot delete a B role', format($q$delete from emx.roles where id = %L$q$, :'roleB1'), 0);
SELECT t.expect_affected('A cannot delete all B roles', format($q$delete from emx.roles where organisation_id = %L$q$, :'orgB'), 0);
SELECT t.expect_affected('A cannot delete B role-permission links', format($q$delete from emx.role_permissions where organisation_id = %L$q$, :'orgB'), 0);
SELECT t.expect_affected('A cannot delete B membership-role links', format($q$delete from emx.membership_roles where organisation_id = %L$q$, :'orgB'), 0);
COMMIT;

-- Deleting every role "visible" to A must remove only A's roles in an A context.
-- Run inside a transaction that is rolled back so A's fixtures survive.
BEGIN;
SELECT emx.set_tenant_context(:'alice', :'orgA');
SELECT t.expect_affected('unfiltered DELETE by A touches only A rows (2 roles)', 'delete from emx.roles', 2);
ROLLBACK;

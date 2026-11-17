-- Organisation A cannot READ organisation B's records, including through joins and
-- unions, and including for a user who belongs to both organisations.
\ir _vars.psql
\connect :dbname emx_app
\set VERBOSITY terse
\echo == 040 organisation A cannot read organisation B ==

BEGIN;
SELECT emx.set_tenant_context(:'alice', :'orgA');

SELECT t.expect_count('A cannot see organisation B', format('select count(*) from emx.organisations where id = %L', :'orgB'), 0);
SELECT t.expect_count('A cannot list roles by filtering on B', format('select count(*) from emx.roles where organisation_id = %L', :'orgB'), 0);
SELECT t.expect_count('A cannot read a B role by its id', format('select count(*) from emx.roles where id = %L', :'roleB1'), 0);
SELECT t.expect_count('A sees only its own 2 roles in total', 'select count(*) from emx.roles', 2);
SELECT t.expect_count('A cannot see B memberships', format('select count(*) from emx.organisation_memberships where organisation_id = %L', :'orgB'), 0);
SELECT t.expect_count('A cannot read a B membership by its id', format('select count(*) from emx.organisation_memberships where id = %L', :'memBobB'), 0);
SELECT t.expect_count('A cannot see B role-permission links', format('select count(*) from emx.role_permissions where organisation_id = %L', :'orgB'), 0);
SELECT t.expect_count('A cannot see B membership-role links', format('select count(*) from emx.membership_roles where organisation_id = %L', :'orgB'), 0);
SELECT t.expect_count('A cannot see user bob (member of B only)', format('select count(*) from emx.users where id = %L', :'bob'), 0);
SELECT t.expect_count('A cannot see user dave (member of suspended org C only)', format('select count(*) from emx.users where id = %L', :'dave'), 0);
SELECT t.expect_count('join cannot reach B rows', format($q$
  select count(*) from emx.membership_roles mr join emx.roles r on r.id = mr.role_id where r.organisation_id = %L$q$, :'orgB'), 0);
SELECT t.expect_count('union cannot reach B rows', format($q$
  select count(*) from (select id from emx.roles union all select id from emx.roles) s where id = %L$q$, :'roleB1'), 0);
SELECT t.expect_count('subquery cannot reach B rows', format($q$
  select count(*) from emx.roles where organisation_id in (select id from emx.organisations where id = %L)$q$, :'orgB'), 0);
COMMIT;

-- carol belongs to BOTH organisations. In an organisation-A context she still must
-- not read B's tenant data. She can see her OWN B membership row (and organisation
-- B's name) so that she can choose between her organisations; nothing else of B.
BEGIN;
SELECT emx.set_tenant_context(:'carol', :'orgA');
SELECT t.expect_count('multi-org user in A: B roles invisible', format('select count(*) from emx.roles where organisation_id = %L', :'orgB'), 0);
SELECT t.expect_count('multi-org user in A: B role-permission links invisible', format('select count(*) from emx.role_permissions where organisation_id = %L', :'orgB'), 0);
SELECT t.expect_count('multi-org user in A: B membership-role links invisible', format('select count(*) from emx.membership_roles where organisation_id = %L', :'orgB'), 0);
SELECT t.expect_count('multi-org user in A: only her OWN B membership row is visible', format('select count(*) from emx.organisation_memberships where organisation_id = %L', :'orgB'), 1);
SELECT t.expect_count('multi-org user in A: no OTHER B memberships visible', format('select count(*) from emx.organisation_memberships where organisation_id = %L and user_id <> %L', :'orgB', :'carol'), 0);
SELECT t.expect_count('multi-org user in A: user bob (B member) is invisible', format('select count(*) from emx.users where id = %L', :'bob'), 0);
SELECT t.expect_count('multi-org user in A: sees A and B in her organisation list', 'select count(*) from emx.organisations', 2);
SELECT t.expect_count('multi-org user in A: users visible = carol plus A members', 'select count(*) from emx.users', 4);
COMMIT;

-- And the other direction: bob in B cannot read A.
BEGIN;
SELECT emx.set_tenant_context(:'bob', :'orgB');
SELECT t.expect_count('B cannot see A roles', format('select count(*) from emx.roles where organisation_id = %L', :'orgA'), 0);
SELECT t.expect_count('B cannot see A memberships', format('select count(*) from emx.organisation_memberships where organisation_id = %L', :'orgA'), 0);
SELECT t.expect_count('B cannot see organisation A', format('select count(*) from emx.organisations where id = %L', :'orgA'), 0);
SELECT t.expect_count('B sees only its own 2 roles', 'select count(*) from emx.roles', 2);
SELECT t.expect_count('B cannot see user alice', format('select count(*) from emx.users where id = %L', :'alice'), 0);
COMMIT;

-- Test helpers. Installed ONLY in the disposable test database, never by migrations.
-- Each helper raises an exception beginning with 'FAIL:' on a failed check and emits
-- a 'PASS:' notice otherwise. Dynamic SQL runs as the CALLER (SECURITY INVOKER), so it
-- is subject to that role's privileges and row-level security.
\ir _vars.psql
\connect :dbname postgres
\set VERBOSITY terse
\echo == 000 helpers ==

CREATE SCHEMA t;
GRANT USAGE ON SCHEMA t TO PUBLIC;

-- Passes when the single integer returned by p_sql equals p_expected.
CREATE FUNCTION t.expect_count(p_label text, p_sql text, p_expected bigint) RETURNS void
LANGUAGE plpgsql AS $f$
DECLARE n bigint;
BEGIN
  EXECUTE p_sql INTO n;
  IF n IS DISTINCT FROM p_expected THEN
    RAISE EXCEPTION 'FAIL: % (expected %, got %)', p_label, p_expected, n;
  END IF;
  RAISE NOTICE 'PASS: %', p_label;
END
$f$;

-- Passes when the DML statement affects exactly p_expected rows.
CREATE FUNCTION t.expect_affected(p_label text, p_sql text, p_expected bigint) RETURNS void
LANGUAGE plpgsql AS $f$
DECLARE n bigint;
BEGIN
  EXECUTE p_sql;
  GET DIAGNOSTICS n = ROW_COUNT;
  IF n IS DISTINCT FROM p_expected THEN
    RAISE EXCEPTION 'FAIL: % (expected % rows affected, got %)', p_label, p_expected, n;
  END IF;
  RAISE NOTICE 'PASS: %', p_label;
END
$f$;

-- Passes only when the statement FAILS with one of the given SQLSTATEs and, if given,
-- an error message matching p_msg_like. A statement that succeeds is a failure.
CREATE FUNCTION t.expect_error(p_label text, p_sql text, p_states text[], p_msg_like text DEFAULT NULL) RETURNS void
LANGUAGE plpgsql AS $f$
DECLARE v_state text; v_msg text;
BEGIN
  BEGIN
    EXECUTE p_sql;
  EXCEPTION WHEN OTHERS THEN
    GET STACKED DIAGNOSTICS v_msg = MESSAGE_TEXT;
    v_state := SQLSTATE;
    IF v_state = ANY (p_states) AND (p_msg_like IS NULL OR v_msg LIKE p_msg_like) THEN
      RAISE NOTICE 'PASS: % [% %]', p_label, v_state, v_msg;
      RETURN;
    END IF;
    RAISE EXCEPTION 'FAIL: % (unexpected error % : %)', p_label, v_state, v_msg;
  END;
  RAISE EXCEPTION 'FAIL: % (statement succeeded but must have been refused)', p_label;
END
$f$;

-- Passes when the boolean returned by p_sql is true.
CREATE FUNCTION t.expect_true(p_label text, p_sql text) RETURNS void
LANGUAGE plpgsql AS $f$
DECLARE b boolean;
BEGIN
  EXECUTE p_sql INTO b;
  IF b IS DISTINCT FROM true THEN
    RAISE EXCEPTION 'FAIL: % (condition was %)', p_label, b;
  END IF;
  RAISE NOTICE 'PASS: %', p_label;
END
$f$;

-- Fingerprint of ALL rows in every EMX table. Only meaningful for a superuser
-- (who bypasses row-level security), so it sees the true database content.
CREATE FUNCTION t.fingerprint() RETURNS text LANGUAGE sql AS $f$
  SELECT md5(concat_ws('#',
    (SELECT coalesce(string_agg(x::text, '|' ORDER BY x::text), '') FROM emx.organisations x),
    (SELECT coalesce(string_agg(x::text, '|' ORDER BY x::text), '') FROM emx.users x),
    (SELECT coalesce(string_agg(x::text, '|' ORDER BY x::text), '') FROM emx.organisation_memberships x),
    (SELECT coalesce(string_agg(x::text, '|' ORDER BY x::text), '') FROM emx.permissions x),
    (SELECT coalesce(string_agg(x::text, '|' ORDER BY x::text), '') FROM emx.roles x),
    (SELECT coalesce(string_agg(x::text, '|' ORDER BY x::text), '') FROM emx.role_permissions x),
    (SELECT coalesce(string_agg(x::text, '|' ORDER BY x::text), '') FROM emx.membership_roles x)))
$f$;

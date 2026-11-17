-- 0001: tenant context helper functions.
--
-- The tenant context is carried in two transaction-local settings:
--   emx.organisation_id  the active organisation
--   emx.user_id          the authenticated EMX user
-- Both are set by the backend from a VERIFIED identity (never from request
-- input) with set_config(..., is_local => true), so they vanish at the end of the
-- transaction and cannot leak between requests on a pooled connection.
--
-- A missing or empty setting yields NULL, and "organisation_id = NULL" matches no
-- rows: missing context fails closed. A malformed value raises an error, which
-- also denies access.

CREATE FUNCTION emx.current_organisation_id() RETURNS uuid
LANGUAGE sql STABLE PARALLEL SAFE
SET search_path = pg_catalog
AS $$ SELECT nullif(current_setting('emx.organisation_id', true), '')::uuid $$;

CREATE FUNCTION emx.current_user_id() RETURNS uuid
LANGUAGE sql STABLE PARALLEL SAFE
SET search_path = pg_catalog
AS $$ SELECT nullif(current_setting('emx.user_id', true), '')::uuid $$;

REVOKE ALL ON FUNCTION emx.current_organisation_id() FROM PUBLIC;
REVOKE ALL ON FUNCTION emx.current_user_id() FROM PUBLIC;

-- 0005: functions the backend uses to establish the tenant context.
--
-- Both functions use set_config(..., is_local => true): the values last only until
-- the end of the current transaction. They MUST be called inside a transaction
-- that also runs the request's queries.
--
-- The identity passed in must come from a VERIFIED token, never from the frontend.
-- The database cannot verify that on its own; that is the backend's job (see
-- docs/security/tenant-isolation.md, "Known limits").
--
-- Both functions are SECURITY INVOKER on purpose: they run with the caller's
-- privileges and under the caller's row-level security, so they can only see what
-- the policies allow.

-- Sets only the user, for the phase before an organisation is chosen (listing the
-- caller's own organisations) and for first-login provisioning of the user row.
CREATE FUNCTION emx.set_user_context(p_user_id uuid) RETURNS void
LANGUAGE plpgsql
SET search_path = pg_catalog
AS $$
BEGIN
  IF p_user_id IS NULL THEN
    RAISE EXCEPTION 'user context requires a user id' USING ERRCODE = '22004';
  END IF;
  PERFORM set_config('emx.organisation_id', '', true);
  PERFORM set_config('emx.user_id', p_user_id::text, true);
END
$$;

-- Sets the user and the active organisation, but only if the user is an ACTIVE
-- member of an ACTIVE organisation and is itself active. Otherwise the context is
-- cleared and the call fails with insufficient_privilege (42501).
CREATE FUNCTION emx.set_tenant_context(p_user_id uuid, p_organisation_id uuid) RETURNS void
LANGUAGE plpgsql
SET search_path = pg_catalog
AS $$
BEGIN
  IF p_user_id IS NULL OR p_organisation_id IS NULL THEN
    RAISE EXCEPTION 'tenant context requires a user id and an organisation id' USING ERRCODE = '22004';
  END IF;

  -- Start from a clean slate, then set the user first so the user's own
  -- membership rows become visible to the membership check below.
  PERFORM set_config('emx.organisation_id', '', true);
  PERFORM set_config('emx.user_id', p_user_id::text, true);

  IF NOT EXISTS (
    SELECT 1
      FROM emx.organisation_memberships m
      JOIN emx.organisations o ON o.id = m.organisation_id AND o.status = 'active'
      JOIN emx.users u         ON u.id = m.user_id         AND u.status = 'active'
     WHERE m.user_id = p_user_id
       AND m.organisation_id = p_organisation_id
       AND m.status = 'active'
  ) THEN
    PERFORM set_config('emx.user_id', '', true);
    RAISE EXCEPTION 'not an active member of an active organisation' USING ERRCODE = '42501';
  END IF;

  PERFORM set_config('emx.organisation_id', p_organisation_id::text, true);
END
$$;

REVOKE ALL ON FUNCTION emx.set_user_context(uuid) FROM PUBLIC;
REVOKE ALL ON FUNCTION emx.set_tenant_context(uuid, uuid) FROM PUBLIC;

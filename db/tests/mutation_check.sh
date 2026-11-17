#!/usr/bin/env bash
# Mutation check: proves the security tests actually have teeth.
#
# For each mutant, this copies db/ into a temporary directory, deliberately BREAKS one
# security control in the COPY (the repository files are never modified), runs the full
# suite against a disposable cluster, and requires the suite to FAIL. A mutant that the
# suite fails to detect means a control is not really tested.
#
# Needs no network and installs nothing. Takes a few runs of the normal suite.
set -uo pipefail

HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SRC="$(cd "$HERE/.." && pwd)"
WORK="$(mktemp -d /var/tmp/emx-mutation.XXXXXX)"
trap 'case "$WORK" in /var/tmp/emx-mutation.*) rm -rf "$WORK" ;; esac' EXIT

MUTANTS=(
  permissive-select-policy   # a policy that lets every row through
  no-force-rls               # table owner no longer subject to RLS
  cross-tenant-fk            # link table can join rows of different organisations
  no-membership-check        # context can be set for an organisation the user is not in
  no-with-check-on-insert    # rows can be inserted into another organisation
  app-bypassrls              # application role gets BYPASSRLS
)

apply_mutation() {
  local name="$1" m="$2/db/migrations" b="$2/db/bootstrap"
  case "$name" in
    permissive-select-policy)
      perl -0pi -e 's/(CREATE POLICY roles_select.*?USING \().*?(\);)/${1}true${2}/s' "$m/0006_policies_and_grants.sql" ;;
    no-force-rls)
      sed -i '/emx.roles FORCE ROW LEVEL SECURITY/d' "$m/0004_roles_and_permissions.sql" ;;
    cross-tenant-fk)
      perl -0pi -e 's/(CONSTRAINT membership_roles_role_fk FOREIGN KEY \()organisation_id, role_id(\)\s+REFERENCES emx\.roles \()organisation_id, id/${1}role_id${2}id/s' "$m/0004_roles_and_permissions.sql" ;;
    no-membership-check)
      sed -i 's/  IF NOT EXISTS (/  IF false AND NOT EXISTS (/' "$m/0005_context_setters.sql" ;;
    no-with-check-on-insert)
      perl -0pi -e 's/(CREATE POLICY roles_insert.*?WITH CHECK \().*?(\);)/${1}true${2}/s' "$m/0006_policies_and_grants.sql" ;;
    app-bypassrls)
      sed -i '/^ALTER ROLE emx_app/ s/NOBYPASSRLS/BYPASSRLS/' "$b/001_roles_and_database.sql" ;;
  esac
}

detected=0
total=0
for name in "${MUTANTS[@]}"; do
  total=$((total + 1))
  dir="$WORK/$name"
  mkdir -p "$dir"
  cp -r "$SRC" "$dir/db"
  apply_mutation "$name" "$dir"
  if diff -rq "$SRC" "$dir/db" >/dev/null; then
    echo "ERROR: mutation '$name' changed nothing; the mutation itself is broken" >&2
    exit 9
  fi
  bash "$dir/db/tests/run.sh" >"$dir/out.txt" 2>&1
  rc=$?
  first_fail="$(grep -m1 'ERROR: FAIL' "$dir/out.txt" | sed -E 's/^ +ERROR: //' | cut -c1-160)"
  if [ "$rc" -ne 0 ] && [ -n "$first_fail" ]; then
    echo "DETECTED   $name  <-  $first_fail"
    detected=$((detected + 1))
  else
    echo "NOT DETECTED  $name  (suite exit code $rc)  <-- a control is not really tested"
  fi
done

echo
echo "mutants detected: $detected of $total"
[ "$detected" -eq "$total" ] || exit 1
echo "RESULT: PASS (every deliberately broken control was caught)"

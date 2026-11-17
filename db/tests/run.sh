#!/usr/bin/env bash
# Runs the whole database test suite against a DISPOSABLE PostgreSQL cluster.
#
#  - Creates a brand-new cluster in a temporary directory under /var/tmp.
#  - Listens on a Unix socket only (no TCP) and a non-default port.
#  - Never touches the system cluster or any existing data directory.
#  - Uses trust authentication, which is acceptable ONLY because the cluster is
#    private, unreachable over the network and destroyed at the end.
#  - Uses synthetic data only. Needs no network and installs nothing.
#
# Exit status is 0 only if every migration step and every test passed.
set -euo pipefail

HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DBDIR="$(cd "$HERE/.." && pwd)"
PGBIN="${PG_BIN:-/usr/lib/postgresql/16/bin}"
PORT="${EMX_TEST_PGPORT:-55433}"
DB="emx_test"
LOG_OUT="${EMX_TEST_LOG:-}"

[ "$PORT" != "5432" ] || { echo "refusing to use the default PostgreSQL port" >&2; exit 2; }
for b in initdb pg_ctl postgres psql; do
  [ -x "$PGBIN/$b" ] || { echo "missing $PGBIN/$b" >&2; exit 2; }
done

if [ "$(id -u)" = "0" ]; then AS=(runuser -u postgres --); else AS=(); fi

TMP="$(mktemp -d /var/tmp/emx-dbtest.XXXXXX)"
if [ "$(id -u)" = "0" ]; then chown postgres:postgres "$TMP"; fi
chmod 700 "$TMP"

cleanup() {
  "${AS[@]}" "$PGBIN/pg_ctl" -D "$TMP/data" -m immediate stop >/dev/null 2>&1 || true
  case "$TMP" in /var/tmp/emx-dbtest.*) rm -rf "$TMP" ;; esac
}
trap cleanup EXIT

"${AS[@]}" mkdir "$TMP/sock"
echo "== creating disposable cluster in $TMP (port $PORT, socket only) =="
"${AS[@]}" "$PGBIN/initdb" -D "$TMP/data" -E UTF8 -U postgres --auth-local=trust --auth-host=reject >"$TMP/initdb.log" 2>&1
"${AS[@]}" "$PGBIN/pg_ctl" -D "$TMP/data" -l "$TMP/server.log" -w -t 60 \
  -o "-p $PORT -c listen_addresses='' -c unix_socket_directories='$TMP/sock'" start >/dev/null

export PGHOST="$TMP/sock" PGPORT="$PORT"
export PATH="$PGBIN:$PATH"

# Safety: prove we are talking to the disposable cluster, not the system one.
DATADIR="$(psql -X -At -U postgres -d postgres -c 'show data_directory')"
[ "$DATADIR" = "$TMP/data" ] || { echo "UNSAFE: connected to unexpected data directory $DATADIR" >&2; exit 2; }
VERNUM="$(psql -X -At -U postgres -d postgres -c 'show server_version_num')"
[ "$VERNUM" -ge 160000 ] || { echo "PostgreSQL 16 or newer required (got $VERNUM)" >&2; exit 2; }
echo "server: $(psql -X -At -U postgres -d postgres -c 'select version()' | cut -c1-70)"
echo "data directory: $DATADIR"

echo; echo "== bootstrap (roles, database, schema) as superuser =="
PGUSER=postgres EMX_DB="$DB" "$DBDIR/scripts/bootstrap.sh"

echo; echo "== migrations: first run as emx_owner =="
PGUSER=emx_owner PGDATABASE="$DB" "$DBDIR/scripts/migrate.sh" | tee "$TMP/migrate1.log"
grep -q 'applied=6 skipped=0' "$TMP/migrate1.log" || { echo "FAIL: expected 6 migrations applied" >&2; exit 1; }

echo; echo "== migrations: second run must apply nothing (idempotent) =="
PGUSER=emx_owner PGDATABASE="$DB" "$DBDIR/scripts/migrate.sh" | tee "$TMP/migrate2.log"
grep -q 'applied=0 skipped=6' "$TMP/migrate2.log" || { echo "FAIL: second run was not a no-op" >&2; exit 1; }

echo; echo "== migrations: an edited applied migration must be detected =="
cp -r "$DBDIR/migrations" "$TMP/migrations_tampered"
echo '-- tampered' >> "$TMP/migrations_tampered/0001_tenant_context_functions.sql"
if PGUSER=emx_owner PGDATABASE="$DB" MIGRATIONS_DIR="$TMP/migrations_tampered" "$DBDIR/scripts/migrate.sh" >"$TMP/tamper.log" 2>&1; then
  echo "FAIL: tampered migration was accepted" >&2; exit 1
fi
grep -q 'CHECKSUM MISMATCH' "$TMP/tamper.log" || { echo "FAIL: no checksum error reported" >&2; exit 1; }
echo "PASS: tampered migration rejected ($(grep -m1 'CHECKSUM MISMATCH' "$TMP/tamper.log"))"

echo; echo "== migrations: refusing to run as the application role =="
if PGUSER=emx_app PGDATABASE="$DB" "$DBDIR/scripts/migrate.sh" >"$TMP/asapp.log" 2>&1; then
  echo "FAIL: migrations ran as emx_app" >&2; exit 1
fi
echo "PASS: $(head -1 "$TMP/asapp.log")"

echo; echo "== security tests =="
total_pass=0
failed=0
: > "$TMP/all_tests.log"
for f in "$HERE"/[0-9]*.sql; do
  name="$(basename "$f")"
  set +e
  out="$(psql -X -q -v ON_ERROR_STOP=1 -v dbname="$DB" -U postgres -d "$DB" -o /dev/null -f "$f" 2>&1)"
  rc=$?
  set -e
  printf '%s\n' "$out" >> "$TMP/all_tests.log"
  printf '%s\n' "$out" | sed -E 's/^psql:[^ ]+ NOTICE:  /  /; s/^psql:[^ ]+ ERROR:  /  ERROR: /'
  npass="$(printf '%s\n' "$out" | grep -c 'NOTICE:  PASS:' || true)"
  nfail="$(printf '%s\n' "$out" | grep -c 'FAIL:' || true)"
  total_pass=$((total_pass + npass))
  if [ "$rc" -ne 0 ] || [ "$nfail" -ne 0 ]; then
    echo "  >>> $name FAILED (exit $rc, $nfail failing checks)"
    failed=$((failed + 1))
    break
  fi
done

echo
echo "== summary =="
echo "checks passed: $total_pass"
echo "files failed:  $failed"
if [ -n "$LOG_OUT" ]; then cp "$TMP/all_tests.log" "$LOG_OUT"; echo "full log: $LOG_OUT"; fi
if [ "$failed" -ne 0 ]; then echo "RESULT: FAIL"; exit 1; fi
echo "RESULT: PASS"

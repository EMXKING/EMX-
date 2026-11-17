#!/usr/bin/env bash
# Runs the privileged bootstrap (roles, database, schema). Requires a superuser
# connection supplied through the standard libpq variables (PGHOST, PGPORT, PGUSER).
# No password is stored in this repository; supply PGPASSFILE/PGPASSWORD from your
# secret store if the server requires one.
set -euo pipefail

HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DB="${EMX_DB:-emx}"
: "${PGUSER:?PGUSER must name a superuser for the bootstrap}"

psql -X -q -v ON_ERROR_STOP=1 -v dbname="$DB" -d postgres \
  -f "$HERE/../bootstrap/001_roles_and_database.sql"

# DBNAME is set so the second file can reference the database name.
psql -X -q -v ON_ERROR_STOP=1 -v DBNAME="$DB" -d "$DB" \
  -f "$HERE/../bootstrap/002_database_security.sql"

echo "bootstrap complete for database '$DB'"

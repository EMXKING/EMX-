#!/usr/bin/env bash
# Applies versioned SQL migrations in order, as the migration role (emx_owner).
#
# - Each migration runs in a single transaction together with its bookkeeping row.
# - Applied migrations are never re-run. Their SHA-256 checksum is recorded and a
#   changed file is an error: fix mistakes with a new migration, never by editing.
# - Connection comes from the standard libpq variables (PGHOST, PGPORT, PGUSER,
#   PGDATABASE). No password is stored in this repository.
set -euo pipefail

HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DIR="${MIGRATIONS_DIR:-$HERE/../migrations}"
: "${PGUSER:?PGUSER must be the migration role (emx_owner)}"

if [ "${PGUSER}" = "emx_app" ]; then
  echo "refusing to run migrations as the application role" >&2
  exit 2
fi

PSQL=(psql -X -q -At -v ON_ERROR_STOP=1)

"${PSQL[@]}" -c "CREATE TABLE IF NOT EXISTS emx.schema_migrations (
  version     text PRIMARY KEY,
  filename    text NOT NULL,
  checksum    text NOT NULL,
  applied_at  timestamptz NOT NULL DEFAULT now()
)"

applied=0
skipped=0
shopt -s nullglob
files=("$DIR"/*.sql)
if [ "${#files[@]}" -eq 0 ]; then
  echo "no migrations found in $DIR" >&2
  exit 1
fi

for f in "${files[@]}"; do
  name="$(basename "$f")"
  if [[ ! "$name" =~ ^([0-9]{4})_[a-z0-9_]+\.sql$ ]]; then
    echo "invalid migration file name: $name (expected NNNN_description.sql)" >&2
    exit 1
  fi
  version="${BASH_REMATCH[1]}"
  sum="$(sha256sum "$f" | cut -d' ' -f1)"
  existing="$("${PSQL[@]}" -c "SELECT checksum FROM emx.schema_migrations WHERE version = '$version'")"

  if [ -n "$existing" ]; then
    if [ "$existing" != "$sum" ]; then
      echo "CHECKSUM MISMATCH for applied migration $name" >&2
      echo "  recorded: $existing" >&2
      echo "  current:  $sum" >&2
      echo "Applied migrations must not be edited. Add a new migration instead." >&2
      exit 1
    fi
    echo "skip   $name"
    skipped=$((skipped + 1))
    continue
  fi

  echo "apply  $name"
  "${PSQL[@]}" --single-transaction -f "$f" \
    -c "INSERT INTO emx.schema_migrations (version, filename, checksum) VALUES ('$version', '$name', '$sum')"
  applied=$((applied + 1))
done

echo "migrations: applied=$applied skipped=$skipped"

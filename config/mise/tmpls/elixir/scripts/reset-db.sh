#!/usr/bin/env bash
# Explicitly reset the dev and test databases. Destructive by design.
# Run by `mise run db:reset`, never as part of routine setup or worktree start.
set -euo pipefail

case "${MIX_ENV:-dev}" in
  dev|test) ;;
  *) echo "error: refusing database reset with MIX_ENV=${MIX_ENV}" >&2; exit 2 ;;
esac

# A reset must target this project's shared local cluster, never an inherited
# production/staging URL or a cluster belonging to another checkout.
common_dir="$(git rev-parse --path-format=absolute --git-common-dir 2>/dev/null)"
expected_root="$(dirname "$common_dir")/tmp/pg"
[ -n "${DATABASE_URL:-}" ] && { echo 'error: DATABASE_URL must be unset for db:reset' >&2; exit 2; }
[ "${PG_ROOT:-}" = "$expected_root" ] || { echo "error: PG_ROOT must be $expected_root" >&2; exit 2; }
[ "${PGDATA:-}" = "$expected_root/data" ] || { echo "error: PGDATA must be $expected_root/data" >&2; exit 2; }
[ -z "${PGHOST:-}" ] || [ "$PGHOST" = "$expected_root" ] || {
  echo "error: PGHOST must be unset or $expected_root" >&2; exit 2;
}
[ -z "${PGSERVICE:-}" ] || { echo 'error: PGSERVICE must be unset for db:reset' >&2; exit 2; }
expected_port="$(bash .config/scripts/pg-port.sh)"
[ -z "${PGPORT:-}" ] || [ "$PGPORT" = "$expected_port" ] || {
  echo "error: PGPORT must be unset or $expected_port" >&2; exit 2;
}

printf 'This will drop and recreate the dev and test databases. Continue? [y/N] '
read -r answer
case "$answer" in
  y|Y|yes|YES) ;;
  *) echo 'db reset cancelled'; exit 0 ;;
esac

mix ecto.reset
env MIX_ENV=test mix ecto.reset

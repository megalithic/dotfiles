#!/usr/bin/env bash
# Ensure this checkout's dev and test databases exist, are migrated, and the
# dev ones are seeded once. Safe to rerun: it never drops or resets a database
# it did not just create. Run by `mise run wt:db` (part of wt:setup).
set -euo pipefail

case "${MIX_ENV:-dev}" in
  dev | test) ;;
  *)
    echo "error: refusing database setup with MIX_ENV=${MIX_ENV}" >&2
    exit 2
    ;;
esac
# Every dev step (create, migrate, seed, drop) runs as dev, so an inherited
# MIX_ENV=test never seeds or drops the test databases.
export MIX_ENV=dev
# Without a UTF-8 locale Erlang writes stdout as latin1. mise stops reading a
# task's output at the first invalid UTF-8 byte, and the seed's logger then
# blocks on the full pipe forever (seen with LANG unset).
export LANG="${LANG:-en_US.UTF-8}"

create_db() { # mix env
  local output rc
  output="$(env MIX_ENV="$1" mix ecto.create 2>&1)" || rc=$?
  rc="${rc:-0}"
  printf '%s\n' "$output"
  CREATE_OUTPUT="$output"
  if [ "$rc" -ne 0 ] && ! printf '%s' "$output" | grep -Eiq 'already exists|already been created'; then
    return "$rc"
  fi
}

seed_dev() {
  if mix help ecto.seed >/dev/null 2>&1; then
    mix ecto.seed
  elif [ -f priv/repo/seeds.exs ]; then
    mix run priv/repo/seeds.exs
  fi
}

# Seed scripts are not rerun-safe (plain inserts crash on existing rows, some
# wipe tables first), so only dev databases created here get seeded. The
# marker carries that across a failed run: a migration error after create must
# not leave the databases existing and unseeded forever.
pending=.local/state/seed-pending

create_db dev
if grep -q 'already been created' <<<"$CREATE_OUTPUT"; then
  if grep -q 'has been created' <<<"$CREATE_OUTPUT"; then
    echo 'warning: some dev databases already existed; skipped seeding. Run: mise run db:reset' >&2
  fi
elif grep -q 'has been created' <<<"$CREATE_OUTPUT"; then
  mkdir -p "$(dirname "$pending")"
  : >"$pending"
fi
create_db test

mix ecto.migrate
env MIX_ENV=test mix ecto.migrate

if [ -f "$pending" ]; then
  seed_dev || {
    # Drop the half-seeded databases so the next run creates and seeds them
    # again instead of seeding on top of partial rows.
    mix ecto.drop || echo 'warning: could not drop the new dev databases' >&2
    rm -f "$pending"
    echo 'error: seeding failed on fresh dev databases; dropped them. Fix it, then rerun setup' >&2
    exit 1
  }
  rm -f "$pending"
  echo 'seeded the new dev databases'
fi

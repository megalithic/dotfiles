#!/usr/bin/env bash
# Routine app setup: hex/rebar, deps, assets, and existing databases.
# Run by `mise run setup` (after the `preflight` dependency). This script never
# drops or resets a database; use the explicit `db:reset` task when needed.
set -euo pipefail
mix archive.install github hexpm/hex branch main --force
mix local.rebar --force
mix deps.get
mix assets.setup

create_db() {
  local env_prefix="${1:-}"
  local output rc
  if [ -n "$env_prefix" ]; then
    output="$(env "$env_prefix" mix ecto.create 2>&1)" || rc=$?
  else
    output="$(mix ecto.create 2>&1)" || rc=$?
  fi
  rc="${rc:-0}"
  printf '%s\n' "$output"
  CREATE_OUTPUT="$output"
  if [ "$rc" -ne 0 ] && ! printf '%s' "$output" | grep -Eiq 'already exists|already been created'; then
    return "$rc"
  fi
}

create_db
dev_create_output="$CREATE_OUTPUT"
create_db MIX_ENV=test

# Fresh (per-worktree) databases are empty after create; services crash on
# missing tables without this. ecto.migrate covers every configured repo and
# is idempotent on already-migrated databases.
mix ecto.migrate
env MIX_ENV=test mix ecto.migrate

seed_dev() {
  if mix help ecto.seed >/dev/null 2>&1; then
    mix ecto.seed
  elif [ -f priv/repo/seeds.exs ]; then
    mix run priv/repo/seeds.exs
  fi
}

# Seed scripts are not rerun-safe (plain inserts crash on existing rows, some
# wipe tables first), so only seed dev databases this run created.
if grep -q 'already been created' <<<"$dev_create_output"; then
  if grep -q 'has been created' <<<"$dev_create_output"; then
    echo 'warning: some dev databases already existed; skipped seeding. Run: mise run db:reset' >&2
  fi
elif grep -q 'has been created' <<<"$dev_create_output"; then
  seed_dev || {
    # Drop the fresh databases so the next setup creates and seeds them again
    # instead of finding them existing and skipping the seed.
    mix ecto.drop || echo 'warning: could not drop the new dev databases' >&2
    echo 'error: seeding failed on fresh dev databases; dropped them. Fix it, then rerun setup' >&2
    exit 1
  }
fi

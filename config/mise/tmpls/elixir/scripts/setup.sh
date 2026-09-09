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
  if [ "$rc" -ne 0 ] && ! printf '%s' "$output" | grep -Eiq 'already exists|already been created'; then
    return "$rc"
  fi
}

create_db
create_db MIX_ENV=test

# Fresh (per-worktree) databases are empty after create; services crash on
# missing tables without this. ecto.migrate covers every configured repo and
# is idempotent on already-migrated databases.
mix ecto.migrate
env MIX_ENV=test mix ecto.migrate

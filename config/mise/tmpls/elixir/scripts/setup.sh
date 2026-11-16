#!/usr/bin/env bash
# Routine app setup: hex/rebar, deps, assets, then the databases (db-ensure.sh).
# Run by `mise run setup` (after the `preflight` dependency) and the first
# `dev:setup` of a checkout. It never resets an existing database; use the
# explicit `db:reset` task when needed.
set -euo pipefail
mix archive.install github hexpm/hex branch main --force
mix local.rebar --force
mix deps.get
mix assets.setup
bash "$(dirname "$0")/db-ensure.sh"

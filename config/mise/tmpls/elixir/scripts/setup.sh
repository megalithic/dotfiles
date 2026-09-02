#!/usr/bin/env bash
# Full app setup: hex/rebar, deps, assets, and dev + test databases.
# Run by `mise run setup` (after the `preflight` dependency).
set -euo pipefail
mix archive.install github hexpm/hex branch main --force
mix local.rebar --force
mix deps.get
mix assets.setup

mix ecto.create || mix ecto.drop
mix ecto.reset
env MIX_ENV=test mix ecto.reset

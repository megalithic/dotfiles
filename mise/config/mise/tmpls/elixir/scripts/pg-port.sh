#!/usr/bin/env bash
# Resolve the shared postgres port, mirroring phx-port.sh's deterministic
# scheme but keyed per REPO (not per worktree): one shared cluster lives in
# the main repo's ./tmp/pg and serves every worktree, so all checkouts of a
# repo must agree on the port while DIFFERENT repos must not collide on 5432.
#   1. explicit PGPORT override wins
#   2. deterministic: 5433 + (cksum(repo-name) % 1000)
# cksum (POSIX) instead of :erlang.phash2 — nothing on the Elixir side
# recomputes this (dev.exs/test.exs read the PGPORT env), so no hash parity
# is needed and it works before mise has installed elixir. Base 5433 keeps
# the range (5433-6432) clear of a stock system postgres on 5432.
set -euo pipefail

# 1. explicit override wins (dev.exs/test.exs read PGPORT)
if [ -n "${PGPORT:-}" ]; then
  echo "$PGPORT"
  exit 0
fi

# 2. deterministic per-repo port, anchored to the MAIN repo root via
#    git-common-dir (worktree-aware — same answer from every checkout).
common="$(git rev-parse --path-format=absolute --git-common-dir 2>/dev/null || true)"
if [ -z "$common" ]; then
  echo 5432
  exit 0
fi
repo="$(basename "$(dirname "$common")")"
sum="$(printf %s "$repo" | cksum | cut -d' ' -f1)"
echo $((5433 + sum % 1000))

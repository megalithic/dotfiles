# shellcheck shell=bash
# env.sh — sourced by mise via `[env] _.source` from the generated project
# stub (.config/mise.toml). Lives in dotfiles so env behavior is owned here,
# not in per-project copies.
#
# IMPORTANT: mise sources this with cwd = the CONFIG ROOT of whichever config
# is being evaluated (ancestor first for nested worktrees), so only
# repo-keyed values belong here — everything below resolves through the
# shared git-common-dir and yields the same result from the main checkout or
# any of its worktrees. Worktree-sensitive vars (GIT_WORKTREE, PHX_PORT) stay
# in the stub as `{{ cwd }}`-anchored Tera execs, because the ancestor
# config's evaluation must resolve against the checkout being entered.
#
# Every value respects a pre-set var (mise reverses its own exports before
# re-evaluating, so stale values from a previous directory never stick).
# No `set -e`: a failing command must never abort mise env evaluation.

[ -n "${HOST:-}" ] || HOST=127.0.0.1
export HOST

# ── Shared postgres: ONE instance, hosted in the main repo ──────────────
# Anchored to the MAIN repo root via git-common-dir (identical from any
# worktree). `./tmp/` is gitignored in participating repos.
_wt_tmpl_scripts="$HOME/.dotfiles/config/mise/tmpls/elixir/scripts"
_wt_gcd="$(git rev-parse --path-format=absolute --git-common-dir 2>/dev/null || true)"
if [ -n "$_wt_gcd" ]; then
  [ -n "${PG_ROOT:-}" ] || PG_ROOT="$(dirname "$_wt_gcd")/tmp/pg"
  # unix socket dir (psql/pg_ctl use this)
  [ -n "${PGHOST:-}" ] || PGHOST="$PG_ROOT"
  # Deterministic per-repo port (5433 + cksum(repo) % 1000) so parallel repos
  # don't fight over 5432. Respects pre-set PGPORT; dev.exs + test.exs read
  # this, Ecto via localhost TCP.
  [ -n "${PGPORT:-}" ] || PGPORT="$(bash "$_wt_tmpl_scripts/pg-port.sh" 2>/dev/null || echo 5432)"
  [ -n "${PG_LOG:-}" ] || PG_LOG="$PG_ROOT/postgres.log"
  [ -n "${PGDATA:-}" ] || PGDATA="$PG_ROOT/data"
  export PG_ROOT PGHOST PGPORT PG_LOG PGDATA
fi
unset _wt_tmpl_scripts _wt_gcd

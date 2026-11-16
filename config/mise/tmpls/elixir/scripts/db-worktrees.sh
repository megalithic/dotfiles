#!/usr/bin/env bash
# Drop per-worktree databases from this repo's shared local postgres.
#
#   db-worktrees.sh drop ID          drop the databases of worktree ID (rwt prune
#                                    runs this after removing the worktree)
#   db-worktrees.sh orphans [--drop] list databases no worktree uses, with sizes;
#                                    drops them only with --drop
#
# A worktree's databases are <base>_<id>, where <base> is one of the main
# checkout's databases (any name ending in _dev or _test: rx_dev, rx_lf_test ...)
# and <id> its GIT_WORKTREE. Postgres cuts names to 63 bytes, so matching
# compares truncated names. The main checkout's databases have no suffix and are
# never touched, and neither is any name a live worktree could use.
#
# Only the server in the main checkout's tmp/pg is reached, over its unix
# socket, and only after it reports that data directory. A stopped server is
# left alone: the databases stay until the next run.
set -euo pipefail
export LC_ALL=C
unset PGSERVICE PGSERVICEFILE PGHOSTADDR PGDATABASE PGUSER PGOPTIONS

die() {
  echo "error: $*" >&2
  exit 2
}

mode="${1:-}"
case "$mode" in
  drop)
    target="${2:-}"
    [ -n "$target" ] || die "drop needs a worktree id"
    ;;
  orphans)
    apply=0
    case "${2:-}" in
      '') ;;
      --drop) apply=1 ;;
      *) die "unknown flag: $2" ;;
    esac
    ;;
  *) die "usage: db-worktrees.sh drop ID | orphans [--drop]" ;;
esac
case "${MIX_ENV:-dev}" in
  dev | test) ;;
  *) die "refusing to drop databases with MIX_ENV=$MIX_ENV" ;;
esac

scripts="$(cd "$(dirname "$0")" && pwd)"
rwt="$scripts/../../../../../bin/rwt"
common="$(git rev-parse --path-format=absolute --git-common-dir)" || die "not in a git checkout"
main="$(cd "$(dirname "$common")" && pwd -P)"
repo="$(basename "$main")"
root="$main/tmp/pg"
port="${PGPORT:-$(bash "$scripts/pg-port.sh")}"

if ! pg_isready -q -h "$root" -p "$port" 2>/dev/null; then
  echo "postgres for $repo is not running (:$port); left its worktree databases in place"
  exit 0
fi

sql() { psql -X -q -At -v ON_ERROR_STOP=1 -h "$root" -p "$port" -U postgres -d postgres -c "$1"; }

datadir="$(sql 'SHOW data_directory')"
[ "$(cd "$datadir" 2>/dev/null && pwd -P)" = "$root/data" ] ||
  die "the server on $root:$port serves $datadir, not $root/data; refusing"

# name<TAB>bytes for every database on the server.
dbs="$(sql "SELECT datname || chr(9) || pg_database_size(datname) FROM pg_database WHERE NOT datistemplate ORDER BY 1")"
# Bases: names ending in _dev or _test, and the part of <base>_<id> names up to
# the first _dev_ or _test_, so a base whose main database is gone still counts.
bases="$(cut -f1 <<<"$dbs" | awk '
  /^[a-z0-9_]+_(dev|test)$/ { print; next }
  match($0, /_(dev|test)_/) && substr($0, 1, RSTART - 1) ~ /^[a-z0-9_]+$/ { print substr($0, 1, RSTART + RLENGTH - 2) }' | sort -u)"

names_for() { # id -> the truncated database names worktree id would use
  local b
  for b in $bases; do printf '%.63s\n' "${b}_$1"; done
}

# Every id a live worktree may use: its rwt id, its directory name (older
# setups) and a GIT_WORKTREE pinned in its .env (Ultimate's ult_<n>).
live_ids() {
  local wt
  git -C "$main" worktree list --porcelain | sed -n 's/^worktree //p' | while IFS= read -r wt; do
    [ "$wt" != "$main" ] || continue
    "$rwt" id "$wt" 2>/dev/null && echo
    basename "$wt"
    cat "$wt/.env" "$wt/.env.local" 2>/dev/null | sed -nE 's/^(export )?GIT_WORKTREE=//p' | tr -d "\"'" || true
  done | { grep -v '^$' || true; } | sort -u
}
live="$(live_ids | while IFS= read -r id; do names_for "$id"; done | sort -u)"

if [ "$mode" = drop ]; then
  ! grep -Fxq "$target" < <(live_ids) || die "worktree $target still exists; prune it first"
  wanted="$(names_for "$target" | sort -u)"
  shared="$(comm -12 <(printf '%s\n' "$wanted") <(printf '%s\n' "$live"))"
  [ -z "$shared" ] || printf 'kept %s: a live worktree uses that name too\n' "$shared"
  candidates="$(comm -23 <(printf '%s\n' "$wanted") <(printf '%s\n' "$live"))"
else
  # <base>_<suffix> names no live worktree uses.
  candidates="$(awk -F'\t' '
    FILENAME == ARGV[1] { b[++nb] = $0; skip[$0] = 1; next }
    FILENAME == ARGV[2] { skip[$0] = 1; next }
    !($1 in skip) { for (i = 1; i <= nb; i++) if (index($1, b[i] "_") == 1) { print $1; next } }' \
    <(printf '%s\n' "$bases") <(printf '%s\n' "$live") <(printf '%s\n' "$dbs"))"
  apply_label="dry run; rerun with --drop to drop them"
fi

# Keep only names that exist, with their sizes.
found="$(awk -F'\t' 'NR == FNR { if ($0 != "") want[$0] = 1; next } ($1 in want)' <(printf '%s\n' "$candidates") <(printf '%s\n' "$dbs"))"
human() { awk -v b="$1" 'BEGIN { split("B KB MB GB TB", u); i = 1; while (b >= 1024 && i < 5) { b /= 1024; i++ } f = i == 1 ? "%d %s" : "%.1f %s"; printf f, b, u[i] }'; }

if [ -z "$found" ]; then
  if [ "$mode" = drop ]; then echo "no databases of $target on $repo's server"; else echo "no orphaned worktree databases on $repo's server"; fi
  exit 0
fi

total=0 count=0
while IFS=$'\t' read -r name bytes; do
  if [ "$mode" = drop ] || [ "$apply" = 1 ]; then
    # FORCE ends leftover sessions; nothing live uses these databases.
    sql "DROP DATABASE IF EXISTS \"${name//\"/\"\"}\" WITH (FORCE)"
    printf 'dropped %s (%s)\n' "$name" "$(human "$bytes")"
  else
    printf '%10s  %s\n' "$(human "$bytes")" "$name"
  fi
  total=$((total + bytes)) count=$((count + 1))
done <<<"$found"
if [ "$mode" = drop ] || [ "$apply" = 1 ]; then
  echo "$repo: dropped $count database(s), $(human "$total")"
else
  echo "$repo: $count orphaned database(s), $(human "$total") ($apply_label)"
fi

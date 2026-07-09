#!/usr/bin/env bash
# Resolve the Phoenix dev port, mirroring config/dev.exs:
#   port: String.to_integer(System.get_env("PORT") || "#{4000 + worktree_port_offset}")
#   worktree_port_offset = :erlang.phash2(GIT_WORKTREE, 1000)
# Copied to <project>/.config/scripts/phx-port.sh by the generator and called
# directly by the mise PHX_PORT env and bootstrap:pi (there is no
# .local/bin/phx-port). Root resolves via git toplevel, with a dirname
# fallback ("../.." = project root from .config/scripts/).
set -euo pipefail
# Root = git toplevel of the CALLER's cwd (worktree-aware — the main repo's
# script may be invoked for a nested worktree). Script location is fallback.
root="$(git rev-parse --show-toplevel 2>/dev/null || true)"
[ -n "$root" ] || root="$(cd "$(dirname "$0")/../.." && pwd)"
base=4000 # RxWeb.Endpoint http :port base in config/dev.exs

# 1. explicit override wins (dev.exs reads PORT first)
if [ -n "${PORT:-}" ]; then
  echo "$PORT"
  exit 0
fi

# 2. running server: beam process whose cwd is this checkout. Lowest
#    listening TCP port is Phoenix (4000+off < live_debugger 4008+off
#    < erlang distribution ports).
for pid in $(pgrep -x beam.smp 2>/dev/null || true); do
  cwd="$(lsof -a -p "$pid" -d cwd -Fn 2>/dev/null | sed -n 's/^n//p' | head -1)"
  [ "$cwd" = "$root" ] || continue
  p="$(lsof -a -p "$pid" -iTCP -sTCP:LISTEN -P -Fn 2>/dev/null |
    sed -n 's/^n.*:\([0-9][0-9]*\)$/\1/p' | sort -n | head -1)"
  if [ -n "$p" ]; then
    echo "$p"
    exit 0
  fi
done

# 3. deterministic fallback: base + :erlang.phash2(GIT_WORKTREE, 1000).
#    Cached per worktree — an elixir boot per shell prompt is too slow.
#    Self-derives GIT_WORKTREE ({repo}-{branch-slug}) when unset, so the
#    port is correct even before mise env exports it (fresh worktrees).
wt="${GIT_WORKTREE:-}"
if [ -z "$wt" ] && [ -x "$HOME/.dotfiles/bin/wt" ]; then
  wt="$("$HOME/.dotfiles/bin/wt" id "$root" 2>/dev/null || true)"
fi
if [ -z "$wt" ]; then
  gd="$(git -C "$root" rev-parse --git-dir 2>/dev/null || true)"
  case "$gd" in
  */worktrees/*)
    repo="$(basename "$(dirname "$(git -C "$root" rev-parse --path-format=absolute --git-common-dir)")")"
    br="$(git -C "$root" branch --show-current 2>/dev/null)"
    [ -n "$br" ] || br="$(basename "$root")"
    wt="${repo}-$(printf "%s" "$br" | tr -c "A-Za-z0-9_" "-" | sed -e "s/--*/-/g" -e "s/^-//" -e "s/-*$//")"
    ;;
  esac
fi
# slashes in branch-name worktrees would create subdirs — flatten for filename
wt_file="$(printf "%s" "${wt:-main}" | tr -c "A-Za-z0-9_." "-")"
cache="$root/.local/cache/phx-port-${wt_file}"
if [ -s "$cache" ]; then
  cat "$cache"
  exit 0
fi
if command -v elixir >/dev/null 2>&1; then
  port="$(GIT_WORKTREE="$wt" elixir -e '
    off =
      case System.get_env("GIT_WORKTREE") do
        w when w in [nil, ""] -> 0
        w -> :erlang.phash2(w, 1000)
      end
    IO.puts(4000 + off)')"
  mkdir -p "$(dirname "$cache")"
  echo "$port" >"$cache"
  echo "$port"
else
  echo "$base"
fi

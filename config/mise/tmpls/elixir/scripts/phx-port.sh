#!/usr/bin/env bash
# Resolve the Phoenix dev port, mirroring config/dev.exs:
#   port: String.to_integer(System.get_env("PORT") || "#{4000 + worktree_port_offset}")
#   worktree_port_offset = :erlang.phash2(GIT_WORKTREE, 1000)
# Runs in place from the dotfiles template (nothing is copied into the
# project). Called via absolute path by the mise stub's PHX_PORT env,
# dev-services.sh, wt-services-cmd.sh, and bootstrap-pi.sh (there is no
# .local/bin/phx-port). Root resolves via git toplevel of the caller's cwd;
# the dirname fallback only matters if git is unavailable.
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

# 2. running server: beam process whose cwd is this checkout AND whose
#    command line runs `mix phx.server` — other beams share the cwd
#    (pi-elixir project VMs, `mix test` runs) and would match a bare cwd
#    probe. Lowest listening TCP port in the deterministic Phoenix range
#    (4000..4999 = 4000 + phash2(_, 1000)) is the server; ports outside the
#    range (erlang distribution, live_debugger never wins: 4008+offset >
#    4000+offset) are ignored rather than misreported.
for pid in $(pgrep -x beam.smp 2>/dev/null || true); do
  # `|| true` guards: pid may vanish between pgrep and lsof (exit 1), and
  # `head -1` can SIGPIPE upstream (exit 141) — either would kill the script
  # under set -euo pipefail.
  case "$(ps -o command= -p "$pid" 2>/dev/null || true)" in
  *phx.server*) ;;
  *) continue ;;
  esac
  cwd="$(lsof -a -p "$pid" -d cwd -Fn 2>/dev/null | sed -n 's/^n//p' | head -1 || true)"
  [ "$cwd" = "$root" ] || continue
  p="$(lsof -a -p "$pid" -iTCP -sTCP:LISTEN -P -Fn 2>/dev/null |
    sed -n 's/^n.*:\([0-9][0-9]*\)$/\1/p' |
    awk '$1 >= 4000 && $1 <= 4999' | sort -n | head -1 || true)"
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
# Mise evaluates this script before adding configured tools to PATH. Use the
# globally managed Elixir in that case, without triggering an installation.
elixir_cmd=()
if command -v elixir >/dev/null 2>&1; then
  elixir_cmd=(elixir)
elif command -v mise >/dev/null 2>&1; then
  elixir_cmd=(mise exec --cd "$HOME" -- elixir)
fi
if [ "${#elixir_cmd[@]}" -eq 0 ]; then
  echo "$base"
  exit 0
fi
port="$(GIT_WORKTREE="$wt" MISE_AUTO_INSTALL=false "${elixir_cmd[@]}" -e '
  offset =
    case System.get_env("GIT_WORKTREE") do
      w when w in [nil, ""] -> 0
      w -> :erlang.phash2(w, 1000)
    end
  IO.puts(4000 + offset)')"
mkdir -p "$(dirname "$cache")"
echo "$port" >"$cache"
echo "$port"

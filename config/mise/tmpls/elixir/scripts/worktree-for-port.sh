#!/usr/bin/env bash
# Resolve a Phoenix dev PORT back to the worktree that serves it. This is the
# runtime inverse of phx-port.sh: instead of deriving a port from GIT_WORKTREE,
# it looks up the live beam.smp listening on the port and reports the worktree
# facts derived from that process. Runs in place from the dotfiles template
# (nothing is copied into the project).
#
# Why lookup instead of reversing the hash: phx-port.sh assigns
# port = 4000 + :erlang.phash2(GIT_WORKTREE, 1000), which is not invertible
# (1000 buckets, collisions). The authoritative mapping at runtime is the OS:
# whichever phx.server beam holds the listening socket owns that port, and its
# cwd IS the worktree root. cwd is the only always-present join key.
#
# Usage:
#   worktree-for-port.sh <port>        # emit JSON facts for that port
#   worktree-for-port.sh               # detect the active tmux pane's worktree
#                                        port via phx-port.sh, then resolve it
#
# Output (JSON, one line):
#   {"port":N,"pid":N,"root":"...","worktree":"name","session":"name",
#    "pgport":N|null,"phxPort":N|null}
# Exits non-zero with {"error":"..."} when no server owns the port.
set -euo pipefail

self_dir="$(cd "$(dirname "$0")" && pwd)"

port="${1:-}"
if [ -z "$port" ]; then
  # No port given: derive it for the caller's cwd via the sibling script.
  port="$(bash "$self_dir/phx-port.sh" 2>/dev/null | tail -n 1 || true)"
fi

emit_error() {
  printf '{"error":"%s"}\n' "$1" >&2
  exit 1
}

case "$port" in
'' | *[!0-9]*) emit_error "invalid or undetectable port: '${port}'" ;;
esac

# Find the beam.smp that (a) runs phx.server and (b) listens on $port. Mirrors
# phx-port.sh's server-detection guards: a bare cwd probe would also match
# pi-elixir project VMs and `mix test` runs that share the worktree cwd.
found_pid=""
found_root=""
for pid in $(pgrep -x beam.smp 2>/dev/null || true); do
  case "$(ps -o command= -p "$pid" 2>/dev/null || true)" in
  *phx.server*) ;;
  *) continue ;;
  esac
  listens="$(lsof -a -p "$pid" -iTCP -sTCP:LISTEN -P -Fn 2>/dev/null |
    sed -n 's/^n.*:\([0-9][0-9]*\)$/\1/p' || true)"
  if printf '%s\n' "$listens" | grep -qx "$port"; then
    found_pid="$pid"
    found_root="$(lsof -a -p "$pid" -d cwd -Fn 2>/dev/null | sed -n 's/^n//p' | head -1 || true)"
    break
  fi
done

[ -n "$found_pid" ] || emit_error "no phx.server beam listening on port ${port}"
[ -n "$found_root" ] || emit_error "could not resolve cwd for pid ${found_pid}"

# Worktree name: prefer `wt id`, else GIT_WORKTREE-style {repo}-{branch-slug}.
worktree=""
if [ -x "$HOME/.dotfiles/bin/wt" ]; then
  worktree="$("$HOME/.dotfiles/bin/wt" id "$found_root" 2>/dev/null || true)"
fi
if [ -z "$worktree" ]; then
  gd="$(git -C "$found_root" rev-parse --git-dir 2>/dev/null || true)"
  case "$gd" in
  */worktrees/*)
    repo="$(basename "$(dirname "$(git -C "$found_root" rev-parse --path-format=absolute --git-common-dir 2>/dev/null)")")"
    br="$(git -C "$found_root" branch --show-current 2>/dev/null || true)"
    [ -n "$br" ] || br="$(basename "$found_root")"
    worktree="${repo}-$(printf "%s" "$br" | tr -c "A-Za-z0-9_" "-" | sed -e "s/--*/-/g" -e "s/^-//" -e "s/-*\$//")"
    ;;
  *) worktree="$(basename "$found_root")" ;;
  esac
fi

# Tmux session name: ground truth is the live tmux session whose session_path
# is the worktree root (ftm/wt name the session after the worktree, e.g.
# provider_portal-sm-spp-enable-auth). This is what bridge.ts records as the
# manifest `session` field and what tell/Hammerspoon route by. It is NOT the
# .envrc SNAME (${APP_NAME}-${WORKTREE_NAME}), which differs. Fall back to the
# worktree name (equal in practice) when tmux is unavailable.
session="$(tmux list-sessions -F '#{session_path}\t#{session_name}' 2>/dev/null |
  sed -n "s#^${found_root}\t##p" | head -1)"
[ -n "$session" ] || session="$worktree"

# Optional facts pulled from the running process environment (best-effort).
proc_env="$(ps -Eww -o command= -p "$found_pid" 2>/dev/null | tr ' ' '\n' || true)"
pgport="$(printf '%s\n' "$proc_env" | sed -n 's/^PGPORT=\([0-9][0-9]*\)$/\1/p' | head -1)"
phx_env="$(printf '%s\n' "$proc_env" | sed -n 's/^PHX_PORT=\([0-9][0-9]*\)$/\1/p' | head -1)"

json_str() { printf '%s' "$1" | sed 's/\\/\\\\/g; s/"/\\"/g'; }
num_or_null() { case "$1" in '' | *[!0-9]*) printf 'null' ;; *) printf '%s' "$1" ;; esac; }

printf '{"port":%s,"pid":%s,"root":"%s","worktree":"%s","session":"%s","pgport":%s,"phxPort":%s}\n' \
  "$port" \
  "$found_pid" \
  "$(json_str "$found_root")" \
  "$(json_str "$worktree")" \
  "$(json_str "$session")" \
  "$(num_or_null "$pgport")" \
  "$(num_or_null "$phx_env")"

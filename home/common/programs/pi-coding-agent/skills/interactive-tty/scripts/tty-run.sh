#!/usr/bin/env bash
# tty-run.sh — run commands that need user interaction from an agent context.
#
# Two modes:
#
#   sudo mode   For commands that only need elevated privileges. Shows the
#               user WHY sudo is needed and WHAT will run, then validates
#               sudo in a tmux popup — the native Touch ID dialog (pam_tid)
#               appears; typing the password in the popup is the fallback.
#               After validation the real command runs with cached
#               credentials in the agent's own shell, so output is captured.
#
#   popup mode  For commands that need typed input (logins, prompts). Runs
#               the command inside `tmux display-popup` with a reason header;
#               the popup grabs focus, auto-closes, and focus returns to the
#               invoking pane automatically.
#
# Usage:
#   tty-run.sh sudo  -m "reason" [-t timeout_s] -- <command> [args...]
#   tty-run.sh popup [-m "reason"] [-t timeout_s] [-w width] [-h height] -- <command> [args...]
#
# Mode auto-detection: if no mode is given and the first command word is
# `sudo`, sudo mode is used (the leading `sudo` is stripped); otherwise popup.
#
# Exit codes:
#   command's own exit code
#   124  timed out waiting for the user
#   125  popup closed without reporting a status
#   2    usage / environment error
set -euo pipefail

mode=""
reason=""
hint=""
timeout=600
width="70%"
height="45%"

usage() {
  cat >&2 <<'EOF'
usage: tty-run.sh [sudo|popup] [-m reason] [-t timeout_s] [-w width] [-h height] -- <command> [args...]
  sudo mode requires -m: explain why sudo is needed and what the command does.
EOF
}

case "${1:-}" in
sudo | popup)
  mode=$1
  shift
  ;;
esac

while [[ $# -gt 0 ]]; do
  case "$1" in
  -m | --reason)
    reason=$2
    shift 2
    ;;
  -t | --timeout)
    timeout=$2
    shift 2
    ;;
  -w | --width)
    width=$2
    shift 2
    ;;
  -h | --height)
    height=$2
    shift 2
    ;;
  --help)
    usage
    exit 0
    ;;
  --)
    shift
    break
    ;;
  *) break ;;
  esac
done

if [[ $# -eq 0 ]]; then
  usage
  exit 2
fi

if [[ -z ${TMUX:-} ]]; then
  echo "tty-run: not inside tmux" >&2
  exit 2
fi

# Auto-detect mode from the command itself.
if [[ -z $mode ]]; then
  if [[ $1 == sudo ]]; then mode=sudo; else mode=popup; fi
fi

# In sudo mode a leading `sudo` in the command is redundant — strip it.
if [[ $mode == sudo && $1 == sudo ]]; then
  shift
  if [[ $# -eq 0 ]]; then
    echo "tty-run: no command after sudo" >&2
    exit 2
  fi
fi

if [[ $mode == sudo && -z $reason ]]; then
  echo 'tty-run: sudo mode requires -m "reason" (why sudo is needed, what the command does)' >&2
  exit 2
fi

cmd_display=$*
[[ -n $reason ]] || reason="Interactive input needed for: $cmd_display"

ec_file=$(mktemp -t pi-tty-ec.XXXXXX)
runner=$(mktemp -t pi-tty-run.XXXXXX)
rm -f "$ec_file" # existence of this file signals completion
popup_pid=""

cleanup() {
  if [[ -n $popup_pid ]] && kill -0 "$popup_pid" 2>/dev/null; then
    tmux display-popup -C 2>/dev/null || true
    wait "$popup_pid" 2>/dev/null || true
  fi
  rm -f "$ec_file" "$runner"
}
trap cleanup EXIT

# write_runner <quoted-command-string> <display-command>
# Builds the popup script: reason header, optional hint, the command, an
# on-failure pause so the user can read the error, then exit-code handoff.
write_runner() {
  cat >"$runner" <<EOF
#!/bin/bash
printf '\\033[1m── %s\\033[0m\\n' $(printf '%q' "$reason")
printf '   \\$ %s\\n' $(printf '%q' "$2")
printf '%s\\n' $(printf '%q' "$hint")
printf '\\n'
$1
ec=\$?
if [ \$ec -ne 0 ]; then
  printf '\\n\\033[31mexit %s\\033[0m — press Enter to close\\n' "\$ec"
  read -r -t 12 _ || true
fi
echo \$ec > $(printf '%q' "$ec_file")
exit \$ec
EOF
  chmod +x "$runner"
}

# run_popup — open the popup and wait (bounded) for the exit-code file.
# Sets global `ec`. Returns 0, or 124/125 on timeout/vanish.
run_popup() {
  tmux display-popup -E -w "$width" -h "$height" -T " interactive input " "$runner" &
  popup_pid=$!
  local elapsed=0
  while [[ ! -s $ec_file ]]; do
    if ! kill -0 "$popup_pid" 2>/dev/null; then
      [[ -s $ec_file ]] && break
      echo "tty-run: popup closed without reporting a status" >&2
      return 125
    fi
    if ((elapsed >= timeout)); then
      echo "tty-run: timed out after ${timeout}s waiting for interactive input" >&2
      return 124
    fi
    sleep 1
    elapsed=$((elapsed + 1))
  done
  wait "$popup_pid" 2>/dev/null || true
  popup_pid=""
  ec=$(cat "$ec_file")
  return 0
}

if [[ $mode == sudo ]]; then
  # Tell the agent-side log why sudo is happening (mirrors the popup header).
  printf 'tty-run: sudo requested\n  reason:  %s\n  command: sudo %s\n' "$reason" "$cmd_display"
  if ! sudo -n true 2>/dev/null; then
    hint="   Authenticate with Touch ID (native dialog), or type your password below."
    write_runner "$(printf '%q ' sudo -v)" "sudo -v  (cache credentials for: $cmd_display)"
    run_popup || exit $?
    if [[ $ec -ne 0 ]]; then
      echo "tty-run: sudo authentication failed/cancelled (exit $ec)" >&2
      exit "$ec"
    fi
  fi
  # Credentials cached — run for real in this shell so output is captured.
  exec sudo "$@"
fi

# popup mode: run the whole command inside the popup.
write_runner "$(printf '%q ' "$@")" "$cmd_display"
run_popup || exit $?
exit "$ec"

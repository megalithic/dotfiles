#!/usr/bin/env bash
# Turn Tidewave vision mode on or off on the Tidewave Connect tab for $PHX_PORT (default 4000), through chrome-cdp.
set -euo pipefail

want=${1:-}
[ "$want" = on ] || [ "$want" = off ] || {
  echo "usage: vision-mode.sh on|off" >&2
  exit 2
}
port=${PHX_PORT:-4000}
cdp=~/.pi/agent/skills/chrome-cdp/scripts/cdp.mjs
target_state=$([ "$want" = on ] && echo true || echo false)

t=$($cdp list | awk -v u="localhost:$port/tidewave/connect" 'index($0, u) {print $1; exit}')
[ -n "$t" ] || {
  echo "no Tidewave Connect tab for port $port; open http://localhost:$port/tidewave/connect first" >&2
  exit 1
}

state() { $cdp eval "$t" 'String(document.querySelector("[role=switch]")?.getAttribute("aria-checked"))' | tail -1; }

current=$(state)
[ "$current" = true ] || [ "$current" = false ] || {
  echo "vision-mode switch not found on tab $t (got: $current); look for [switch] Vision mode with cdp.mjs snap $t" >&2
  exit 1
}

if [ "$current" != "$target_state" ]; then
  if [ "$want" = on ]; then
    # getDisplayMedia fails with "Invalid state" unless Helium has OS focus and the tab is in front.
    osascript -e 'tell application "Helium" to activate'
    $cdp evalraw "$t" Page.bringToFront >/dev/null
  fi
  read -r x y < <($cdp eval "$t" '(b => Math.round(b.x + b.width / 2) + " " + Math.round(b.y + b.height / 2))(document.querySelector("[role=switch]").getBoundingClientRect())' | tail -1)
  $cdp clickxy "$t" "$x" "$y" >/dev/null
  for _ in $(seq 1 45); do
    [ "$(state)" = "$target_state" ] && break
    sleep 2
  done
fi

now=$(state)
echo "vision mode on port $port: $([ "$now" = true ] && echo on || echo off)"
[ "$now" = "$target_state" ]

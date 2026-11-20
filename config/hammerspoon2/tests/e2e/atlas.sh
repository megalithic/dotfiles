#!/usr/bin/env bash
# End-to-end check of Hammerspoon 2 in Atlas's helper desktop. Nothing here
# posts synthetic keys (they would reach the person's desktop): links drive the
# HUD and the Shade seam, and Atlas's own key presses check the tap. Held F19
# is checked on the real keyboard (AGENTS.md).
#
# One-time setup (see config/hammerspoon2/AGENTS.md): copy the files with
# `atlas environment`, `atlas install-app` the app, and have Seth grant
# Hammerspoon 2 Accessibility.
set -euo pipefail
export ATLAS_SESSION="${ATLAS_SESSION:-hs2-e2e}"

helper() { atlas run -- /bin/sh -c "$1"; }

helper 'rm -f "$HOME/hs2-e2e.log"'
atlas open --app "Hammerspoon 2" >/dev/null
atlas open hammerspoon2://reload >/dev/null
sleep 2

# Without hyper, layer keys and others pass through to TextEdit.
atlas open --app TextEdit >/dev/null
atlas key --app TextEdit cmd+n >/dev/null
atlas wait --app TextEdit >/dev/null
atlas type --app TextEdit "ntcj" >/dev/null

# hyper+Return's path: the stub sup has nothing to open (exit 3), the stub
# Shade answers visible, so the HUD shows. Screenshot, then off.
# The log should show `sup show actions --hold`, `sup open`, then `shade toggle write`.
atlas open hammerspoon2://trigger >/dev/null
sleep 1
atlas screenshot --new-file
atlas open hammerspoon2://hud-off >/dev/null

# hyper+Escape: `sup dismiss --action`.
atlas open hammerspoon2://dismiss >/dev/null

# Each Shade verb through the armed layer.
# One hold at a time: each link arms after 0.5s and releases hyper after it.
for verb in write tell capture edit; do
  atlas open "hammerspoon2://action?verb=$verb" >/dev/null
  sleep 1
done

helper 'cat "$HOME/hs2-e2e.log"'
atlas elements --app TextEdit --role AXTextArea --full

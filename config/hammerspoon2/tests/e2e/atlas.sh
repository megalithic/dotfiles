#!/usr/bin/env bash
# End-to-end check of the hyper layer in Atlas's helper desktop, beside a
# minimal v1 (v1-init.lua). Atlas can't press F19 or hold keys, so the e2e
# config posts the sequence itself; this script sets the stage and reads back.
#
# One-time setup (see config/hammerspoon2/AGENTS.md): copy the files with
# `atlas environment`, install both apps with `atlas install-app`, and have
# Seth grant Hammerspoon 2 Accessibility inside the helper.
#
# Prints both logs and TextEdit's text; the screenshot shows the HUD.
set -euo pipefail
export ATLAS_SESSION="${ATLAS_SESSION:-hs2-e2e}"

helper() { atlas run -- /bin/sh -c "$1"; }

helper 'rm -f "$HOME/hs2-e2e.log" "$HOME/hs1-e2e.log"'
atlas open hammerspoon2://reload >/dev/null
atlas open --app Hammerspoon >/dev/null
atlas open --app TextEdit >/dev/null
atlas key --app TextEdit cmd+n >/dev/null
atlas wait --app TextEdit >/dev/null
sleep 2
atlas open hammerspoon2://e2e >/dev/null
# Opening the URL may bring Hammerspoon 2 forward; the sequence waits 2 s.
atlas open --app TextEdit >/dev/null
# F19 is held from 2 s to about 7.5 s; the HUD shows from 2.25 s.
sleep 3
atlas screenshot --new-file
sleep 6
helper 'cat "$HOME/hs2-e2e.log"; echo ---; cat "$HOME/hs1-e2e.log"'
atlas elements --app TextEdit --role AXTextArea

---
id: dot-skd0
status: closed
deps: []
links: []
created: 2026-08-31T21:03:17Z
type: feature
priority: 2
assignee: Seth Messer
---
# Load notiwatchd launchd agent

notiwatchd binary is built and FDA-granted (~/.local/bin/notiwatchd). Write the launchd plist (dev.mise.com.megadots.notiwatchd, generated from bootstrap.macos.launchd.agents in config.toml or written directly matching the dev.mise convention), bootstrap it into gui/501, and verify the daemon runs under launchd: log output in ~/.cache/notiwatchd-stdout.log, events recorded to ~/.local/share/notiwatchd/notifications.db, socket at ~/.local/state/notiwatchd/sock. Precondition: bin/notiwatchd.swift relocation to config/notiwatchd/ is done (build script SRC updated).

## Acceptance Criteria

1. plist exists in ~/Library/LaunchAgents with dev.mise.com.megadots.notiwatchd label pointing at bin/notiwatchd-launchd. 2. launchctl print gui/501/dev.mise.com.megadots.notiwatchd shows running. 3. A real notification lands in notifications.db while running under launchd (not terminal). 4. Survives launchctl kickstart -k.

---
id: dot-4zab
status: closed
deps: []
links: []
created: 2026-06-30T16:20:24Z
type: task
priority: 2
assignee: [REDACTED]
tags: [ready-for-development]
---

# Create and wire source forks: megalithic/helium + submodule

Create the megalithic/helium fork on GitHub (from imputnet/helium), then update the helium-macos submodule to point at it and initialize.

Files:

- ~/code/oss/helium-macos/.gitmodules — change submodule.helium-chromium.url from https://github.com/imputnet/helium.git to git@github.com:megalithic/helium.git
- ~/code/oss/helium-macos/helium-chromium/ — currently uninitialized (git submodule status shows - prefix)

Commands to run:

1. Create fork on GitHub: go to https://github.com/imputnet/helium, click Fork, set owner to megalithic
2. git config -f .gitmodules submodule.helium-chromium.url git@github.com:megalithic/helium.git
3. git submodule sync helium-chromium
4. git submodule update --init --recursive helium-chromium
5. Read version files: cat helium-chromium/chromium_version.txt helium-chromium/revision.txt revision.txt

## Acceptance Criteria

1. git submodule status helium-chromium no longer starts with - (initials are initialized)
2. git -C helium-chromium remote -v points at megalithic/helium, not imputnet/helium
3. Build scripts can read version files from submodule

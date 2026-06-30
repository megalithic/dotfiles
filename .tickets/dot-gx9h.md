---
id: dot-gx9h
status: open
deps: []
links: []
created: 2026-06-30T16:20:59Z
type: task
priority: 2
assignee: [REDACTED]
tags: [ready-for-development]
---

# Simplify nix Helium package to thin artifact consumer

Remove Widevine download/injection and helper re-signing from pkgs/helium-browser.nix. Make it a thin consumer that only fetches/unpacks/wraps.

File: ~/.dotfiles/pkgs/helium-browser.nix

Changes:

- Use fetchurl/fetchzip for megalithic/helium-macos DMG release (keep current version 0.12.5.1 until release task updates it)
- Support local path: override for iteration (parameterize src)
- Native build inputs: only undmg/fetchurl, makeWrapper — no 7zz, curl, cacert, python3, fd, unzip needed
- Remove postUnpack Widevine download/injection logic (lines ~30-80)
- Remove postFixup helper codesign mutations (lines ~80-127)
- Keep passthru.appLocation = wrapper
- Keep installPhase that copies Helium.app to /Applications/ and wraps /bin/helium

Must still produce a working /Applications/Helium.app and /bin/helium wrapper.

## Acceptance Criteria

1. just validate home succeeds
2. nix build --no-link .#helium-browser succeeds (or just validate home)
3. /Applications/Helium.app exists and is a valid app bundle
4. /bin/helium wrapper exists and is executable
5. No codesign mutation occurs in Nix build log (no codesign invocations)
6. No Widevine download in build log

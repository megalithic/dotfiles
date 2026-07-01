---
id: dot-w2ut
status: closed
deps: [dot-gbcl, dot-wjlb]
links: []
created: 2026-06-30T16:21:42Z
type: task
priority: 2
assignee: [REDACTED]
tags: [ready-for-development]
---

# Release signed DMG artifact and switch nix package source

Publish the first signed helium-macos DMG from the source fork and point dotfiles at it.

Steps:

1. In ~/code/oss/helium-macos: create a git tag (e.g. v0.12.5.1-mega1) and push
2. Create GitHub release from tag, attach the DMG from build/helium\_<version>\_macos.dmg
3. Update ~/.dotfiles/pkgs/helium-browser.nix:
   - Set version to the release tag
   - Set url to https://github.com/megalithic/helium-macos/releases/download//helium_X.Y.Z_arm64-macos.dmg
   - Update sha256 (use nix-prefetch-url or lib.fakeSha256 + error message to get the real hash)
4. Run just validate home to verify fetch succeeds
5. Run just home to switch to new package

Must keep local-dev path: override working so future iteration can use path: instead of release URL.

## Acceptance Criteria

1. GitHub release exists at megalithic/helium-macos with DMG attached
2. Nix fetches release artifact by sha256 hash
3. Installed app code signature team is [REDACTED] (verify with codesign -dv)
4. /Applications/Helium.app opens without ad-hoc helper resigning from Nix
5. Local path: override still works for development iteration

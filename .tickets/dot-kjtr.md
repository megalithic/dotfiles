---
id: dot-kjtr
status: closed
deps: [dot-wu29]
links: []
created: 2026-06-30T16:21:13Z
type: task
priority: 2
assignee: [REDACTED]
tags: [ready-for-development]
---

# Update Helium HM module for thin package and new options

Update ~/.dotfiles/home/common/programs/helium-browser/default.nix to use new mkChromiumBrowser options from ticket dot-wu29.

Changes:

- Replace manual --remote-debugging-port=9223 in commandLineArgs with remoteDebuggingPort = 9223 option
- Move --disable-features=OutdatedBuildDetector to experimentalFeatures.disable option if applicable
- Keep all other commandLineArgs (--no-first-run, --no-default-browser-check, etc.)
- Keep extensions/prodversion workaround (reads framework version dir for update URL)
- Keep keyEquivalents (NSUserKeyEquivalents for Close Tab, New Tab, etc.)
- Keep install-to-Applications activation (rsync) — but update comments to reflect source-signed artifact model: no more ad-hoc signing, no Widevine mutation
- Keep darwinWrapperApp.enable = false
- Keep home.packages add for bin/helium wrapper

Verify mkChromiumBrowser.nix already has the options from dot-wu29 before using them.

## Acceptance Criteria

1. just validate home passes
2. Generated commandLineArgs include --remote-debugging-port=9223 from option (not hardcoded)
3. Activation still skips when Helium is running
4. /Applications/Helium.app can be updated from signed artifact without ad-hoc signing
5. Extensions update URL still includes correct prodversion

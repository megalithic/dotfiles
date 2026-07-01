---
id: dot-wu29
status: closed
deps: []
links: []
created: 2026-06-30T16:21:07Z
type: feature
priority: 2
assignee: [REDACTED]
tags: [ready-for-development]
---

# Add mkChromiumBrowser runtime options: remoteDebuggingPort, experimentalFeatures

Add declarative options to ~/.dotfiles/lib/builders/mkChromiumBrowser.nix so browser modules don't hard-code flags.

New options:

- remoteDebuggingPort: nullOr port, default null. When set, appends --remote-debugging-port=N to commandLineArgs
- experimentalFeatures.enable: listOf str, default []. Appends --enable-features=comma,joined
- experimentalFeatures.disable: listOf str, default []. Appends --disable-features=comma,joined

Also add customAccelerators option (attrsOf submodule with added/removed lists) as a seam for future use — but mark it as deferred (no pref seeding yet, since native shortcuts are deferred).

Merge generated flags into the wrapper args in the browser module's commandLineArgs generation. Options should be visible (not hidden) so they show in docs.

Reference: current mkChromiumBrowser.nix has commandLineArgs, keyEquivalents, extensions, darwinWrapperApp options around lines 46-63.

## Acceptance Criteria

1. just validate passes (nix eval succeeds)
2. Setting remoteDebuggingPort = 9223 generates --remote-debugging-port=9223 in wrapper args
3. Setting experimentalFeatures.enable = ["FeatureA", "FeatureB"] generates --enable-features=FeatureA,FeatureB
4. Setting experimentalFeatures.disable = ["FeatureC"] generates --disable-features=FeatureC
5. All three compose without duplicate flags

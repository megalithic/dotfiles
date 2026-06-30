---
id: dot-gvyg
status: open
deps: [dot-kjtr]
links: []
created: 2026-06-30T16:21:21Z
type: feature
priority: 2
assignee: [REDACTED]
tags: [ready-for-development]
---

# Add managed policy/preferences for Helium extension and browser defaults

Write policy-shaped settings to ~/Library/Managed Preferences/net.imput.helium.plist via nix activation, replacing direct profile mutation.

File: ~/.dotfiles/home/common/programs/helium-browser/default.nix (add managed plist activation)

Settings to manage:

- ExtensionInstallForcelist: array of extension_id;update_url strings for Surfingkeys, Firenvim, LiveDebugger, Clear Downloads, Enhancer for YouTube
- ExtensionSettings: per-extension dict with update_url override (prodversion baked in) — verify exact policy key names from Chromium policy_templates.json first
- DefaultSearchProviderEnabled: true
- DefaultSearchProviderName: Kagi (or browser default)
- DeveloperToolsAvailability: 1 (allow devtools, disallow extensions? verify exact enum)
- CommandLineFlagSecurityWarningsEnabled: false
- SUAutomaticallyUpdate: false (Sparkle)
- SUEnableAutomaticChecks: false (Sparkle)

Method: home.activation.heliumManagedPrefs writes a plist to ~/Library/Managed Preferences/net.imput.helium.plist using /usr/libexec/PlistBuddy or a nix-generated plist file.

IMPORTANT: verify exact policy key names and types from target Chromium policy_templates.json before writing. The names above are from research — some may have different exact keys.

## Acceptance Criteria

1. chrome://policy or helium://policy shows expected policies applied
2. Extensions install and update with prodversion in URL
3. Default search engine settings are applied
4. DevTools are available
5. Command-line flag warnings are suppressed
6. No direct Chromium profile JSON writes in activation

---
id: dot-rmen
status: open
deps: []
links: []
created: 2026-06-10T14:37:21Z
type: task
priority: 2
assignee: Seth Messer
tags: [ready-for-development]
---

# Audit shade-next panel visual polish against Shade

Evaluate shade-next panel visuals using the supplied screenshot and compare against the working Shade implementation. Document why the current panel is not truly rounded/transparent/shadowed and identify exact Swift/AppKit changes needed before implementation.

Observed issues from screenshot/eval:

- panel reads as flat gray, not true macOS vibrancy/transparency
- rounded corners do not feel like a polished clipped material surface
- shadow is weak or absent, so panel does not lift from underlying content
- border/edge definition is weak

File hints:

- ~/code/shade-next/Sources/ShadeNextApp/PanelController.swift currently builds KeyablePanel + NSVisualEffectView and sets hasShadow/cornerRadius
- ~/code/shade-next/Sources/ShadeNextCore/Config/VisualConfig.swift currently owns visual settings
- ~/code/shade/Sources/ShadePanel.swift contains the existing Shade focus-border and dimUnfocusedOpacity implementation to compare/port
- home/common/programs/shade-next/default.nix provides generated config defaults for shade-next

Verification:

- timeout 30 rg -n "NSVisualEffectView|hasShadow|cornerRadius|alphaValue|dimUnfocused|didResignKey|didBecomeKey" ~/code/shade-next ~/code/shade -g "\*.swift"

## Acceptance Criteria

1. Findings identify concrete AppKit causes for missing true transparency, rounded clipping, shadow, and border treatment.
2. Findings compare shade-next PanelController.swift to ShadePanel.swift dimming/focus-border behavior.
3. Findings name exact files/functions to change for implementation.
4. Findings include recommended config keys/defaults if new visual settings are needed.
5. No code changes are required for this audit ticket.

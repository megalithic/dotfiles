---
id: dot-s0ha
status: open
deps: 4:1:deps: [, dot-rmen]
links: []
created: 2026-06-10T14:37:21Z
type: feature
priority: 2
assignee: Seth Messer
tags: [ready-for-development]
---

# Implement shade-next true panel transparency and focus dimming

Implement the visual fixes identified by the shade-next UI polish audit so the panel has real rounded vibrancy/transparency, visible shadow lift, a subtle border, and Shade-like unfocused dimming.

Desired behavior:

- NSPanel/window is non-opaque with clear background
- content uses an inner rounded/clipped NSVisualEffectView or equivalent material surface
- shadow is not clipped by the rounded content layer; use window shadow or an outer non-clipped shadow container/path
- subtle border/stroke makes edges readable on light and dark backgrounds
- when shade-next loses key/focus to another app but remains visible, panel dims to configured opacity and restores to full opacity when focused, similar to Shade
- visual defaults are configurable through shade-next config where appropriate

File hints:

- ~/code/shade-next/Sources/ShadeNextApp/PanelController.swift
- ~/code/shade-next/Sources/ShadeNextCore/Config/VisualConfig.swift
- ~/code/shade-next/Tests/ShadeNextCoreTests/ for config/model tests
- ~/code/shade/Sources/ShadePanel.swift as reference for focus notifications, alphaValue, and dimUnfocusedOpacity
- home/common/programs/shade-next/default.nix if new config keys/defaults are added

Verification:

- timeout 600 bash -lc "cd ~/code/shade-next && devenv shell -- swift build"
- timeout 600 bash -lc "cd ~/code/shade-next && devenv shell -- swift test"
- timeout 600 just validate home if home/common/programs/shade-next/default.nix changes

## Acceptance Criteria

1. shade-next panel uses a non-opaque clear window and clipped rounded visual/material surface so transparency/vibrancy is visible.
2. Rounded corners are true clipped corners with no square opaque background showing through.
3. Shadow remains visible around the rounded panel and is not clipped by the content layer.
4. A subtle border/stroke improves edge definition on light and dark backgrounds.
5. Unfocused dimming is implemented: losing key/focus lowers panel opacity to a configured value; gaining focus restores full opacity.
6. Relevant visual defaults are configurable and wired through VisualConfig/default Nix config when needed.
7. `swift build` and `swift test` pass in ~/code/shade-next; `just validate home` passes if dotfiles config changed.

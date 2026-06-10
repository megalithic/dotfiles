---
id: dot-k9xk
status: open
deps: 4:1:deps: 4:1:deps: 4:1:deps: [, dot-1iip, dot-mv1h, dot-j262]
links: []
created: 2026-06-10T00:58:13Z
type: feature
priority: 3
assignee: Seth Messer
tags: [shade-next, phase-3, deferred]
---

# shade-next: context gathering + quick-capture-with-context chord (hyper+shift+enter)

Replicate shade's hyper+shift+enter quick-capture: gather frontmost-app/selection/URL/window context, then open shade-next seeded as a note: capture with that context. Mirrors shade's split (ContextGatherer + open_new_capture).

Plan:

1. CaptureContext model in ShadeNextCore (appName, appType, windowTitle, url, selection, filePath, timestamp), Codable + testable (lean port of shade GatheredContext).
2. Two gather paths: (a) Hammerspoon-gathered (no new TCC; Lua reads frontmost app + selection/pasteboard, passes via URL params or a context file shade-next reads on show) FIRST; (b) Swift AXContextGatherer (Accessibility API, richer, needs AX permission) behind a protocol, LATER.
3. Transport: control method capture{text?,context} and/or context file ~/.local/state/shade-next/context.json that prefill/show reads (extends dot-j262 protocol).
4. Seed the note: route note:, NoteCommitter embeds context as callout/frontmatter matching shade capture_context/capture_selection shape.
5. Default chord hyper+shift+enter -> gather context -> open focused note: capture seeded with it.
6. Tests: CaptureContext round-trip + capture command headless; manual notes for live chord + AX permission.

Deferred per user; revisit after dot-1iip.

## Acceptance Criteria

1. CaptureContext model exists in core, Codable, unit-tested round-trip.
2. A capture transport (command and/or context file) seeds shade-next as a focused note: capture with gathered context.
3. hyper+shift+enter gathers context (Hammerspoon path first) and opens the capture; committed note contains app/url/selection context.
4. Swift AX gathering documented as a follow-up (permission noted) if not in this pass.
5. just validate home passes; current shade capture flow untouched.

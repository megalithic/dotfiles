---
id: dot-fpev
status: open
deps: [dot-vnmm]
links: []
created: 2026-05-13T20:48:05Z
type: task
priority: 2
assignee: Seth Messer
parent: dot-dylm
tags: [ready-for-development]
---
# Research codediff and VCS review-bundle export for pinvim

Research Step 7 from ~/.local/share/pi/plans/dotfiles/nvim-pi-custom-vision_PLAN.md before implementation. Do not build the exporter yet. Instead, map how config/nvim/lua/plugins/codediff.lua, annotator integration, jj/git diff sources, and a future config/nvim/lua/pinvim/review.lua should cooperate to produce a `pinvim.review.v1` payload. Answer what data is reliably available from codediff and annotator today, what differs between jj and git-backed diffs, and what payload shape and hook points should be used.

Capture findings as a question-and-answer style research artifact or detailed ticket notes. Include recommended schema, lifecycle, user entrypoints, failure cases, and unresolved questions. Small local probes are allowed for discovery; no durable feature implementation in this ticket.

## Acceptance Criteria

1. Research documents how review export should hook into codediff and annotator surfaces, including likely files/functions to extend and whether work should live in `after/plugin/pinvim.lua` versus reusable `lua/pinvim/*` modules.
2. Research answers what review-bundle fields are available or derivable for both jj and git-backed diffs: diff session metadata, hunk context, annotations, selected ranges, VCS metadata, and requested action.
3. Research proposes a concrete `pinvim.review.v1` schema, including required fields, optional fields, normalization rules, and fallback behavior when codediff or annotator data is missing.
4. Research identifies open questions, risks, and recommended follow-up implementation slices for export wiring, especially around jj/git differences and codediff state ownership.
5. Any probe commands or headless checks used for discovery are recorded, and no lasting review-bundle implementation is required for ticket completion.


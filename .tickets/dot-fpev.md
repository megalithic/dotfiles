---
id: dot-fpev
status: closed
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

Research Step 7 from ~/.local/share/pi/plans/dotfiles/nvim-pi-custom-vision_PLAN.md before implementation. Do not build the exporter yet. Start from the desired fresh UX: `gpa` may annotate word/selection through annotator.nvim, then a later command batches all file/diff annotations to pi. Map how config/nvim/lua/plugins/codediff.lua, annotator integration, hunk.nvim, jj/git diff sources, and a future config/nvim/lua/pinvim/review.lua should cooperate to produce a `pinvim.review.v1` payload. Answer what data is reliably available from codediff/hunk/annotator today, what differs between jj and git-backed diffs, and what payload shape and hook points should be used.

Capture findings as a question-and-answer style research artifact or detailed ticket notes. Include recommended schema, lifecycle, user entrypoints, failure cases, and unresolved questions. Small local probes are allowed for discovery; no durable feature implementation in this ticket.

## Acceptance Criteria

1. Research documents how annotation capture (`gpa` concept) and review export should hook into annotator, codediff, and hunk surfaces, including likely files/functions to extend and whether work should live in reusable `lua/pinvim/*` modules rather than loader/legacy code.
2. Research answers what review-bundle fields are available or derivable for both jj and git-backed diffs: diff session metadata, hunk context, annotations, selected ranges, VCS metadata, and requested action.
3. Research proposes a concrete `pinvim.review.v1` schema, including required fields, optional fields, normalization rules, and fallback behavior when codediff or annotator data is missing.
4. Research identifies open questions, risks, and recommended follow-up implementation slices for export wiring, especially around jj/git differences and codediff state ownership.
5. Any probe commands or headless checks used for discovery are recorded, and no lasting review-bundle implementation is required for ticket completion.

## Verification

For any implementation change under this pinvim/vision workstream, run:

1. `just home`
2. `nvim --headless '+lua require("pinvim").setup()' +qa`
3. `bin/pinvim-protocol-smoke` — deterministic mock Unix-socket test that asserts nvim sends `hello`, receives `hello_ack`, sends `heartbeat`, receives heartbeat response, and `require("pinvim").setup().health()` reports `ok`.

For research-only tickets, run these before closing any downstream implementation ticket that uses the research.

## Notes

**2026-05-19T16:11:59Z**

Superseded by ~/.local/share/pi/plans/dotfiles/pinvim-review-diff-mode_TASK.md and \_PLAN.md. Research questions in this ticket (annotator/codediff/hunk cooperation, jj vs git availability, pinvim.review.v1 schema, hook points) are answered in the TASK file's Findings and the PLAN's per-step design. Implementation seeded as new tickets under dot-dylm. Closing as superseded.

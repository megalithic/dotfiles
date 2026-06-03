---
id: dot-t4dd
status: closed
deps: [dot-fpev]
links: []
created: 2026-05-13T20:48:05Z
type: task
priority: 2
assignee: Seth Messer
parent: dot-dylm
tags: [ready-for-development]
---

# Research pi-side handling for review bundles and diff UX

Research Step 8 from ~/.local/share/pi/plans/dotfiles/nvim-pi-custom-vision_PLAN.md before implementation. Do not wire review-bundle handling yet. Instead, study how `home/common/programs/pi-coding-agent/extensions/pinvim.ts` should receive, validate, store, summarize, and surface `review_bundle` payloads coming from jj/git/codediff review flows. If `bridge.ts` remains on any ingress path, treat it as optional shim/forwarder only rather than semantic owner.

Capture findings as a question-and-answer style research artifact or detailed ticket notes. Focus on message boundaries between thin transport shims and `pinvim.ts` state/UI ownership, lifecycle for per-process latest-review state, command/status UX such as `/pinvim-review`, and how much diff data should be preserved versus summarized for pi context.

## Acceptance Criteria

1. Research defines recommended responsibility split with `pinvim.ts` as semantic owner and `bridge.ts` only as optional shim/forwarder if still needed.
2. Research answers how pi should represent jj/git/codediff review data internally: raw bundle retention, summarized context injection, command output, and stale-state cleanup behavior.
3. Research proposes command/status UX for active review context, including at least one recommended design for `/pinvim-review` and any footer/widget/status surfaces.
4. Research identifies compatibility and payload-size risks for diff-heavy review bundles, plus recommended guardrails for truncation, summarization, or lazy rendering.
5. Research leaves clear implementation follow-ups and does not require durable review-bundle code changes for completion.

## Verification

For any implementation change under this pinvim/vision workstream, run:

1. `just home`
2. `nvim --headless '+lua require("pinvim").setup()' +qa`
3. `bin/pinvim-protocol-smoke` — deterministic mock Unix-socket test that asserts nvim sends `hello`, receives `hello_ack`, sends `heartbeat`, receives heartbeat response, and `require("pinvim").setup().health()` reports `ok`.

For research-only tickets, run these before closing any downstream implementation ticket that uses the research.

## Notes

**2026-06-03T19:40:18Z**

Deprecated: superseded by pinvim rewrite plan at ~/.local/share/pi/plans/.dotfiles/pinvim-rewrite_PLAN.md. Closing for posterity; architecture is being rebooted.

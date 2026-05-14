---
id: dot-t4dd
status: open
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

Research Step 8 from ~/.local/share/pi/plans/dotfiles/nvim-pi-custom-vision_PLAN.md before implementation. Do not wire bridge or pinvim bundle handling yet. Instead, study how home/common/programs/pi-coding-agent/extensions/bridge.ts and the new pinvim extension should receive, validate, store, summarize, and surface `review_bundle` payloads coming from jj/git/codediff review flows.

Capture findings as a question-and-answer style research artifact or detailed ticket notes. Focus on message boundaries between bridge transport and pinvim state/UI, lifecycle for per-process latest-review state, command/status UX such as `/pinvim-review`, and how much diff data should be preserved versus summarized for pi context.

## Acceptance Criteria

1. Research defines recommended responsibility split between `bridge.ts` and `pinvim.ts` for `review_bundle` validation, normalization, storage, and UI/status presentation.
2. Research answers how pi should represent jj/git/codediff review data internally: raw bundle retention, summarized context injection, command output, and stale-state cleanup behavior.
3. Research proposes command/status UX for active review context, including at least one recommended design for `/pinvim-review` and any footer/widget/status surfaces.
4. Research identifies compatibility and payload-size risks for diff-heavy review bundles, plus recommended guardrails for truncation, summarization, or lazy rendering.
5. Research leaves clear implementation follow-ups and does not require durable bridge or pinvim review-bundle code changes for completion.


---
id: dot-l8f0
status: open
deps: [dot-t4dd]
links: []
created: 2026-05-13T20:48:05Z
type: task
priority: 2
assignee: Seth Messer
parent: dot-dylm
tags: [ready-for-development]
---
# Research editor-aware policy for diff, review, notes, and Elixir contexts

Research Step 9 from ~/.local/share/pi/plans/dotfiles/nvim-pi-custom-vision_PLAN.md before implementation. Do not build policy injection yet. Instead, map how the future pinvim extension should detect and classify diff/review buffers, markdown notes contexts, and Elixir/HEEx/Surface/Phoenix files, then decide what persona/tool-policy guidance each class should apply.

This ticket should answer policy-design questions, especially for jj/git/codediff/review flows: what makes a buffer a review context, which tools or instructions should be preferred or discouraged, how manual user intent should override auto-policy, and where policy logic should live (`pinvim.ts`, `pinvim-policy.ts`, Neovim metadata, or all three).

Capture findings as a question-and-answer style research artifact or detailed ticket notes. Small probes are allowed; no durable policy-injection implementation in this ticket.

## Acceptance Criteria

1. Research defines detection signals for review-oriented contexts, including jj/git diffs, codediff sessions, review bundles, markdown notes paths, and Elixir-family files.
2. Research proposes policy/persona recommendations for each context class, including preferred tools, discouraged tools, and any system-prompt or context-injection wording.
3. Research answers how automatic policy should interact with explicit user intent so auto-selection stays helpful without overriding direct instructions.
4. Research recommends module boundaries and data flow for future implementation, including whether policy logic belongs in `pinvim-policy.ts`, `pinvim.ts`, nvim metadata, or a shared schema.
5. Research records open questions and follow-up implementation slices; no durable policy-selection code is required for ticket completion.

## Verification

For any implementation change under this pinvim/vision workstream, run:

1. `just home`
2. `nvim --headless '+lua require("pinvim").setup()' +qa`
3. `bin/pinvim-protocol-smoke` — deterministic mock Unix-socket test that asserts nvim sends `hello`, receives `hello_ack`, sends `heartbeat`, receives heartbeat response, and `require("pinvim").setup().health()` reports `ok`.

For research-only tickets, run these before closing any downstream implementation ticket that uses the research.


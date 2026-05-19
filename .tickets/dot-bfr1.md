---
id: dot-bfr1
status: open
deps: [dot-7p71]
links: []
created: 2026-05-19T16:12:47Z
type: feature
priority: 2
assignee: Seth Messer
parent: dot-dylm
tags: [ready-for-development]
---
# pinvim review: send bundles from nvim and remap gps/gpS

Plan step 5. Build pinvim.review.v1 bundles from review state, changed files, selected scope, annotations, and capped raw diff data. The gps and gpS keymaps are registered by config/nvim/lua/pinvim/review.lua (not by pinvim.lua); both are mode-aware. In review mode gps sends the bundle without prompt and gpS sends with user prompt. Outside review mode gps sends normal explicit context without prompt and gpS sends normal explicit context with prompt (replaces current gpa send-explicit/gps send-with-prompt semantics). Add PiReviewSend/PinvimReviewSend and PiReviewPrompt/PinvimReviewPrompt commands.

## Acceptance Criteria

1. Bundle builder serializes scope, file list, annotations, and capped raw diff into a pinvim.review.v1 review_bundle frame.
2. Raw diff payload is byte-capped with a documented limit and truncation marker.
3. gps and gpS keymaps are registered by config/nvim/lua/pinvim/review.lua (not by pinvim.lua); in review mode gps sends bundle no-prompt and gpS sends bundle with prompt.
4. Outside review mode gps sends normal explicit context no-prompt; gpS sends normal explicit context with prompt.
5. Old explicit-send keymap behavior (previous gpa = no-prompt, gps = with-prompt) is removed and AGENTS.md updated note will follow in step 8.
6. PiReviewSend/PinvimReviewSend and PiReviewPrompt/PinvimReviewPrompt commands registered.
7. stylua --check config/nvim/lua/pinvim.lua config/nvim/lua/pinvim/review.lua clean.
8. just validate home passes.
9. nvim --headless '+lua require("pinvim").setup()' '+qa' exits 0.
10. bin/pinvim-protocol-smoke passes.
11. Manual: inside review, gps delivers a bundle visible via /pinvim-review.


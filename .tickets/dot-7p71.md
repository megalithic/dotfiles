---
id: dot-7p71
status: open
deps: [dot-pbw1]
links: []
created: 2026-05-19T16:12:35Z
type: feature
priority: 2
assignee: Seth Messer
parent: dot-dylm
tags: [ready-for-development]
---
# pinvim review: pi-side review_bundle protocol (pinvim.review.v1)

Plan step 4. Extend home/common/programs/pi-coding-agent/extensions/pinvim.ts with review_bundle payload support using protocol pinvim.review.v1. Validate required fields, store latest active review bundle per-process, summarize it for user context, update status text with active review info, and add /pinvim-review command to show review status/summary. bridge.ts must not own any review semantics. Supersedes research ticket dot-t4dd findings.

## Acceptance Criteria

1. pinvim.ts accepts message type=review_bundle with protocol=pinvim.review.v1 and validates required fields (scope, files, annotations, diff, vcs metadata).
2. Invalid bundles are rejected with a clear log/error; valid bundles are stored as latest active review state per process.
3. Active review summary appears in pinvim status footer/text.
4. /pinvim-review command registered and shows current review status/summary.
5. bridge.ts contains no review semantics.
6. just validate home passes.
7. nvim --headless '+lua require("pinvim").setup()' '+qa' exits 0.
8. bin/pinvim-protocol-smoke passes.
9. Manual: send a minimal review_bundle JSON frame over a running pinvim socket; /pinvim-review reflects it.


---
id: dot-am3n
status: open
deps: []
links: []
created: 2026-05-07T16:46:32Z
type: bug
priority: 2
assignee: Seth Messer
tags: [ready-for-development]
---

# Add conflict guard between stop-hook and pi-review-loop extensions

Both stop-hook.ts and pi-review-loop fire follow-up turns after agent completes.
When pi-review-loop is active (iterating fresh-eyes reviews), stop-hook should NOT
also fire its nudge — the review loop already handles verification.

Approach: pi-review-loop exports a flag (or emits an event) indicating active state.
stop-hook checks this flag and skips nudge when review-loop is active.

Implementation options:

1. Shared global: pi-review-loop sets globalThis.\_\_reviewLoopActive, stop-hook checks it
2. Event bus: pi-review-loop emits event, stop-hook listens
3. Extension state: use pi.events or shared state mechanism

Option 1 is simplest and matches existing pattern (sentinel uses globalThis.\_\_sentinel).

Files: home/common/programs/pi-coding-agent/extensions/stop-hook.ts
home/common/programs/pi-coding-agent/extensions/pi-review-loop/

## Acceptance Criteria

1. When pi-review-loop is actively iterating, stop-hook does not fire its nudge
2. When pi-review-loop is NOT active, stop-hook fires normally
3. No regression: stop-hook still nudges on non-reviewed tasks
4. No regression: pi-review-loop still iterates as before
5. just validate home passes

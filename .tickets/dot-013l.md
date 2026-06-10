---
id: dot-013l
status: open
deps: []
links: []
created: 2026-06-10T00:07:36Z
type: bug
priority: 1
assignee: Seth Messer
parent: dot-0fjk
tags: [pi, extensions, pool, bug]
---

# Handle queued messages when pool rotation hits active agent

When codex-pool rate-limits openadi-codex and rotates to alt-codex, runtime extension can throw: `Agent is already processing. Specify streamingBehavior (steer or followUp) to queue the message.` Repro log: `[pool:codex-pool] Rate limited on openadi-codex; rotating within pool codex-pool; active alt-codex (gpt-5.5)` followed by `Extension "<runtime>" error: Agent is already processing. Specify streamingBehavior (steer or followUp) to queue the message.` Investigate pool rotation / retry path and pass the correct streamingBehavior when sending a message to an already-active agent, or avoid issuing the duplicate send.

## Acceptance Criteria

1. Rate-limit rotation within codex-pool no longer throws `Agent is already processing`.
2. Retry/rotation path explicitly chooses `steer` or `followUp` when target agent is active, or gates duplicate sends.
3. Add regression coverage or a manual reproduction note.

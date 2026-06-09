---
id: dot-e5sy
status: closed
deps: 4:1:deps: [, dot-at3w]
links: []
created: 2026-06-09T15:10:56Z
type: task
priority: 2
assignee: Seth Messer
tags: [ready-for-development, shade-next]
---

# Spike Pi target discovery and safe draft mirroring

In ~/code/shade-next, integrate conservative Pi handoff behavior for pi: routes. Implement active Pi discovery, ambiguity handling, live draft mirroring, detach-on-direct-edit behavior, restore-on-empty behavior, and commit-without-submit behavior. File hints: Pi adapter modules in ~/code/shade-next and current Pi ecosystem references in ~/.dotfiles/home/common/programs/pi-coding-agent/ and related notes in shade-next_TASK.md.

## Acceptance Criteria

1. If Pi target is missing or ambiguous, shade-next saves draft and asks instead of guessing.
2. Live mirroring can detach when user edits Pi input directly.
3. If linked Pi input is empty on refocus, mirror can restore without clobbering user-owned text.
4. Commit fills and refocuses Pi input but never submits automatically.
5. Verification includes manual notes or tests for ambiguous target, detach, restore, and commit behavior.

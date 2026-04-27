---
id: dot-0oy1
status: open
deps: []
links: []
created: 2026-04-28T13:56:53Z
type: task
priority: 1
assignee: Seth Messer
external-ref: meg-ppzd
parent: dot-0fjk
tags: [cross-repo, coordination, megadots, tracking]
---
# Cross-repo coordination: megadots reconcile interaction with pi ecosystem

Mirror of megadots meg-ppzd. Tracks how active ~/.dotfiles pi tickets interact with the megadots → ~/.dotfiles migration + reconcile work. Source-of-truth status doc at ~/.local/share/pi/plans/megadots/cross-repo-status.md (lives in megadots plans dir, both repos read it).

## Design

## Why this exists

User flagged explicit risk of losing track of cross-repo state. ~/.dotfiles is being replaced by megadots. Some open pi tickets here will be superseded; others are independent and should complete here. This ticket prevents work duplication and tracks decisions.

## Coordination with megadots

- Megadots side ticket: **meg-ppzd** (parent meg-8lkv) — primary tracking
- Status doc: ~/.local/share/pi/plans/megadots/cross-repo-status.md — single source of truth
- This ticket mirrors meg-ppzd decisions

## Decision per ticket in this repo

| This ticket | Decision | Driven by megadots ticket |
|---|---|---|
| **dot-edp8** (in_progress, nvim ephemeral pi tmux split) | Finish here, port artifact to megadots | Megadots nvim reconcile Stage 2 waits for this |
| **dot-fsxj** (otahontas parity + jj-first) | **Close as superseded** by megadots reconcile sub-epics | Megadots reconcile sub-epics own this work |
| **dot-86tz** (project MCP config .pi/mcp.json) | Defer here; megadots implements once | Megadots pi-coding-agent reconcile Stage 2 |
| **dot-p774** (commit scope guard) | Continue here independently | None |
| **dot-qr4m** (pi-multi-pass extension) | Continue here independently | None |
| **dot-0hug** (Glimpse review UI) | Continue here independently | None |
| **dot-kts9** (nvim↔pi unify) | Finish here (nvim work), port to megadots | Megadots nvim reconcile Stage 2 coordinates |

## Action items in this repo

1. Close dot-fsxj with link to meg-ppzd + reconcile sub-epic IDs (once they exist)
2. Add note to dot-edp8 + dot-kts9 bodies: artifacts will port to megadots
3. Add note to dot-86tz body: deferred until megadots pi-coding-agent reconcile

## Acceptance Criteria

1. dot-fsxj closed with reference to meg-ppzd + megadots reconcile sub-epic IDs.
2. dot-edp8, dot-kts9 bodies note future port to megadots.
3. dot-86tz body notes deferred-until-megadots status.
4. This ticket links to meg-ppzd via external-ref.
5. Stays open until megadots reconcile Stage 2 sub-epic closes (parallel to meg-ppzd lifecycle).


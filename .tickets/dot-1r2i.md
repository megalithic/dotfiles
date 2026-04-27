---
id: dot-1r2i
status: closed
deps: []
links: []
created: 2026-04-22T16:19:18Z
type: chore
priority: 2
assignee: Seth Messer
parent: dot-fsxj
tags: [ready-for-development]
---
# Remove extensions/checkpoint.ts (broken, replaced by ticket-vcs.ts)

Decision Q5 in dot-fsxj: checkpoint.ts (570 lines) is not working properly. Will be replaced by extensions/ticket-vcs.ts (new, in ticket dot-<TBD>). Remove checkpoint to prevent interference.

## Files

- ~/.dotfiles/home/common/programs/ai/pi-coding-agent/extensions/checkpoint.ts — delete
- Verify no imports: rg 'checkpoint' ~/.dotfiles/home/common/programs/ai/pi-coding-agent/
- Any slash commands registered by checkpoint (/checkpoint, /goal, 'set goal:', 'working on:' parsers) — confirm none are referenced elsewhere

## Preserve (for reference)

The jj bookmark detection logic in checkpoint.ts (lines ~145-150, 188-195) is the pattern ticket-vcs.ts should reuse:

  jj log -r @ --no-graph -T bookmarks

Copy that pattern to the new extension's implementation. Don't block this ticket on ticket-vcs.ts completion — just capture the snippet in a note for the ticket-vcs.ts worker.

## Cleanup

- Remove any state files checkpoint.ts created (check for ~/.pi/agent/checkpoint-*.json or similar)

## Acceptance Criteria

1. extensions/checkpoint.ts no longer exists
2. 'rg checkpoint ~/.dotfiles/home/common/programs/ai/pi-coding-agent/' returns no hits (or only unrelated matches)
3. 'just validate home' + 'just home' pass
4. 'pi' starts without errors about missing checkpoint extension
5. No orphaned /checkpoint or /goal commands left dangling — 'pi' doesn't show them in /help
6. Captured jj-bookmark-detection snippet posted as note on the ticket-vcs ticket before closing this one



---

**🔒 CLOSED-AS-SUPERSEDED 2026-04-28**

Absorbed by megadots ticket `meg-lp2m` (parent `meg-yblr` Stage 1 + blocks `meg-u3i3` Stage 2). Single tracker carries the obligation; substance preserved in `meg-lp2m` body. Source: `~/.local/share/pi/plans/megadots/cross-repo-status.md`.

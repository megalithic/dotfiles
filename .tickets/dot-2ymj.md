---
id: dot-2ymj
status: closed
deps: [dot-z8ku]
links: []
created: 2026-04-22T16:18:25Z
type: task
priority: 1
assignee: Seth Messer
parent: dot-fsxj
tags: [ready-for-development]
---
# Port scripts/work-tickets.sh from otahontas/nix, adapt for jj

Port scripts/work-tickets.sh from /tmp/otahontas-nix/home/configs/pi-coding-agent/scripts/work-tickets.sh. Main runner loop: iterates 'tk ready -T ready-for-development', spawns 'pi -p' worker for each, runs verification pass, tallies completed/skipped, then final review. Logs to .tickets/logs/<timestamp>.log.

## Files

- Source: /tmp/otahontas-nix/home/configs/pi-coding-agent/scripts/work-tickets.sh
- Dest: ~/.dotfiles/home/common/programs/ai/pi-coding-agent/scripts/work-tickets.sh
- Verify default.nix packages it into PATH (scripts/ directory handling — check existing build-session-index.sh treatment)

## jj adaptations

Upstream uses 'git diff HEAD~1' in the verification prompt. Rewrite:

  if [ -d .jj ]; then
    DIFF_CMD='jj diff -r @-'
  else
    DIFF_CMD='git diff HEAD~1'
  fi

Inject DIFF_CMD into the VERIFY_PROMPT expansion. Keep rest of verification text identical (test/lint discovery, unused imports check, lat.md check).

## Script header

Upstream auto-enters 'devenv shell' if 'tk' not on PATH. Our setup has tk in Nix profile — devenv auto-enter is unnecessary but leave the block intact for portability to projects that use devenv.

## Packaging

Check ~/.dotfiles/home/common/programs/ai/pi-coding-agent/default.nix for how scripts/build-session-index.sh is exposed. Apply same pattern to work-tickets.sh so it lands in PATH as 'work-tickets'.

## Acceptance Criteria

1. File at ~/.dotfiles/home/common/programs/ai/pi-coding-agent/scripts/work-tickets.sh with jj-aware DIFF_CMD variable
2. default.nix updated to install work-tickets to PATH (mirroring build-session-index.sh if that's how it's done, else whatever scripts/ pattern exists)
3. 'just validate home' + 'just home' pass
4. 'which work-tickets' returns path after rebuild
5. 'work-tickets' in a repo with .jj and no ready tickets exits cleanly with 'No more ready tickets. Done.'
6. Smoke test: create trivial ticket ('add blank line to README'), run 'work-tickets' in ~/.dotfiles, confirm: ticket transitions open→in_progress→closed, verification pass runs, final review runs, log file written to .tickets/logs/



---

**🔒 CLOSED-AS-SUPERSEDED 2026-04-28**

Absorbed by megadots ticket `meg-lp2m` (parent `meg-yblr` Stage 1 + blocks `meg-u3i3` Stage 2). Single tracker carries the obligation; substance preserved in `meg-lp2m` body. Source: `~/.local/share/pi/plans/megadots/cross-repo-status.md`.

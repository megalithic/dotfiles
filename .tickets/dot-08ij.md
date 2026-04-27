---
id: dot-08ij
status: closed
deps: [dot-1r2i]
links: []
created: 2026-04-22T16:19:44Z
type: feature
priority: 1
assignee: Seth Messer
parent: dot-fsxj
tags: [ready-for-development]
---
# New extension: extensions/ticket-vcs.ts (tk↔jj bookmark hooks + session state)

New extension hooking tk lifecycle into jj bookmarks (git fallback when no .jj).

## File

- ~/.dotfiles/home/common/programs/ai/pi-coding-agent/extensions/ticket-vcs.ts (new)
- Auto-discovered by default.nix (no nix changes required)

## Hooks

### tool_call 'bash' — intercept tk commands

Parse bash command for 'tk start <id>' or 'tk close <id>' patterns.

**tk start <id>:**
1. Detect VCS: if .jj exists → jj path; else git path
2. jj: run 'jj log -r @ --no-graph -T bookmarks' → if current bookmark is not <id>, run 'jj feat <id>' (our alias) or 'jj bookmark create <id>'
3. git: 'git checkout -b <id>' if branch doesn't exist
4. If already on matching bookmark/branch: no-op, log 'resuming'

**tk close <id>:**
1. Peek current jj description: 'jj log -r @ --no-graph -T description'
2. If empty or '(no description set)': inject prompt into conversation suggesting: 'jj dm "feat(<type>): <title> (closes <id>)"' where <type>/<title> come from 'tk show <id>'
3. Do NOT auto-run the commit — just surface the suggestion
4. Do NOT auto-push — per AGENTS.md

### stop_hook — persist in-progress ticket state

On session stop:
1. Run 'tk query' and parse JSON for tickets with status=in_progress
2. If any exist: write ~/.pi/state/current-ticket.json:
     { "id": "dot-xxxx", "bookmark": "dot-xxxx", "started_at": "2026-04-22T15:00:00Z", "cwd": "/path/to/repo" }
3. If none: remove the state file

### session_start — restore

On new session start:
1. Read ~/.pi/state/current-ticket.json if exists
2. Emit a markdown notice: '🎫 Resuming work on ticket {id} (bookmark: {bookmark})'
3. Don't auto-switch bookmark — surface info only

## Reuse from checkpoint.ts (deleted in dot-1r2i)

    const result = await piApi.exec("jj", ["log", "-r", "@", "--no-graph", "-T", "bookmarks"]);
    const bookmark = result.stdout?.trim();

Same pattern for description lookup: 'jj log -r @ --no-graph -T description'.

## Config surface (settings.json)

Optional knobs (document in README-style comment at top of file):
- ticketVcs.enabled (default true)
- ticketVcs.autoCreateBookmark (default true) — if false, only suggest
- ticketVcs.suggestCommitOnClose (default true)

## Rules references

- jj-first per AGENTS.md 'Version Control (Jujutsu)' section
- Never push without user approval
- Respect Sentinel ticket_gate toggle (if ticket_gate=true in sentinel-rules.json, make this extension require an active ticket before any bash mutations)

## Acceptance Criteria

1. extensions/ticket-vcs.ts exists with three hooks: tool_call, stop_hook, session_start
2. Detects .jj vs git correctly; behaves right in both cases
3. 'tk start dot-xxxx' in a repo with .jj triggers 'jj feat dot-xxxx' (or no-op if already on bookmark)
4. 'tk start dot-xxxx' in a git-only repo triggers 'git checkout -b dot-xxxx' (or no-op)
5. 'tk close dot-xxxx' with empty jj description surfaces a 'jj dm' suggestion in conversation (does NOT execute)
6. After stop-hook: ~/.pi/state/current-ticket.json exists with {id, bookmark, started_at, cwd} when a ticket is in_progress
7. After stop-hook with no in-progress ticket: ~/.pi/state/current-ticket.json does NOT exist (removed if present)
8. On new session start with stale state file + in_progress ticket: emits '🎫 Resuming' notice
9. 'just validate home' + 'just home' pass
10. Extension respects ticketVcs.enabled config knob (set false → no hooks fire)



---

**🔒 CLOSED-AS-SUPERSEDED 2026-04-28**

Absorbed by megadots ticket `meg-lp2m` (parent `meg-yblr` Stage 1 + blocks `meg-u3i3` Stage 2). Single tracker carries the obligation; substance preserved in `meg-lp2m` body. Source: `~/.local/share/pi/plans/megadots/cross-repo-status.md`.

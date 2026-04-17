---
id: dot-ndc3
status: open
deps: []
links: []
created: 2026-04-17T16:48:34Z
type: feature
priority: 3
assignee: Seth Messer
---
# Shade: nvumi-inspired scratch buffer with natural language action hooks

Build a scratch buffer system for the Shade app inspired by nvumi
(github.com/josephburgess/nvumi) — a neovim plugin that evaluates natural
language expressions inline in a scratch buffer using numi-cli.

The vision goes beyond calculator: a natural language command surface that can
dispatch actions via hooks. The scratch buffer becomes a universal input for
quick actions.

## Core concept

Open a floating scratch buffer (like nvumi). Type natural language. Lines are
evaluated and dispatched based on pattern matching to registered hooks.

## Hook system

Hooks register patterns and handlers. Examples:

1. **Calculator** (nvumi baseline) — math expressions evaluated via numi-cli,
   results shown as virtual text
2. **Ticket creation** — `create ticket: fix the auth bug in rx` dispatches to
   pi (or ephemeral pi instance) which runs `tk create` in the matched
   repo/cwd. Could detect repo from context or explicit mention.
3. **Reminders** — `remind me at 3pm tomorrow to review PR` creates a reminder
   in macOS Reminders via osascript/Shortcuts
4. **Notes** — `note: look into caching strategy for API` appends to a daily
   note file
5. **Pi dispatch** — `tell pi: investigate the test failures in rx` sends a
   message to a running pi instance via bridge.ts socket, or spawns ephemeral

## Architecture sketch

- Scratch buffer opens as floating window (like nvumi uses snacks.scratch)
- Each line parsed against registered hook patterns (ordered by priority)
- First matching hook handles the line
- Results shown as virtual text (success/failure/preview)
- Hooks are Lua modules that register themselves
- Hook interface: `{ pattern: string|fn, handler: fn, preview?: fn }`

## Pi integration for ticket creation

When a line matches ticket creation pattern:
- Detect target repo (from explicit mention, current cwd, or prompt user)
- Send to pi via bridge.ts socket (like compose mode does)
- Or spawn ephemeral `pi -p 'tk create ...' --cwd <repo>`
- Show result (ticket ID) as virtual text

## macOS Reminders integration

When a line matches reminder pattern:
- Parse natural language date/time (numi-cli can help, or use date command)
- Create reminder via osascript or Shortcuts framework
- Show confirmation as virtual text

## Research needed

- How nvumi structures its evaluator/processor pipeline (lua/nvumi/*.lua)
- numi-cli capabilities beyond math (date parsing, unit conversion)
- macOS Reminders API via osascript vs Shortcuts
- Whether to build as nvim plugin or Shade-specific feature
- How to handle async hook results (pi responses take time)
- Whether hooks should be nvim-only or also work from pi TUI

## Acceptance Criteria

1. Research complete with architecture decision documented
2. Prototype scratch buffer with at least calculator hook working
3. Hook registration system designed and documented
4. At least one dispatch hook (ticket or reminder) prototyped
5. Integration path with existing pi/bridge infrastructure identified


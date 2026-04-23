---
id: dot-ndc3
status: open
deps: []
links: []
parent: dot-gm39
created: 2026-04-17T16:48:34Z
type: feature
priority: 3
assignee: Seth Messer
---
# Shade: nvumi-inspired scratch buffer with natural language action hooks

## Vision

Opening Shade drops you into a **scratch buffer by default**. Type anything.
Each line is evaluated and dispatched based on intent — like Fantastical's
natural language input, but for everything.

**Shade's identity**: a gateway to CLI tools via nvim. Single-purpose,
single-entry-point interactions. The scratch buffer is the primary surface.

## How it works

Type a line → buffer detects intent → dispatches to handler → shows result as
virtual text.

| You type | What happens |
|----------|--------------|
| `245 * 18.5` | Evaluate via numi-cli, show result |
| `150 lbs in kg` | numi-cli conversion, show result |
| `remind me to review PR at 3pm tomorrow` | Task in today's daily note `## Tasks` |
| `buy groceries on Saturday` | Task in daily note, migrates daily until done |
| `note: look into caching strategy` | Append to daily note `## Notes` or `## Captures` |
| `tell pi: investigate test failures in rx` | Send to pi instance (future) |
| `create ticket: fix auth bug` | Dispatch to tk (future) |

## Intent detection

### Phase 1: explicit prefixes

Prefixes provide clear dispatch and get the pipeline working first:

| Prefix | Intent | Handler |
|--------|--------|---------|
| `calc:` or `=` | Math/conversion | numi-cli |
| `task:` or `todo:` | Task | Append to daily note `## Tasks` |
| `remind:` | Reminder/task with time | Daily note + notification TBD |
| `note:` | Capture | Append to daily note `## Notes` or `## Captures` |
| `pi:` or `tell pi:` | Pi dispatch | bridge.ts / ephemeral (future) |
| `ticket:` | Ticket creation | tk create (future) |

### Phase 2: prefix-optional (infer intent)

Drop prefix requirement — buffer infers from how line reads. Prefixes still
work as explicit override.

Possible approaches:
- **numi-cli first** — try numi-cli on every line. If result, it's math.
- **Pattern matching** — regex/lua patterns for task keywords (remind, buy,
  at Xpm, tomorrow, etc.) inspired by Fantastical's parser
- **LLM classification** — local model for ambiguous lines
- **Hybrid** — numi-cli → pattern match → fallback to LLM or "just text"

Phase 2 is the goal. Prefixes are scaffolding, not the destination.

## Task migration (bullet journal style)

Tasks added to today's daily note under `## Tasks`:
```markdown
## Tasks
- [ ] review PR by 3pm #reminder
- [ ] buy groceries Saturday #life
```

Incomplete tasks migrate forward to each new daily note until completed. Verify
whether obsidian.nvim / periodic notes already handles this — fill gaps.

### Daily note structure (current)

Path: `$NOTES_HOME/daily/YYYY/YYYYMMDD.md`

```markdown
## Notes
## Tasks
- [ ] task here #tag
## Captures
## Links
```

## Decision: nvim plugin approach

Build as a **neovim plugin** first. Shade loads it, but it works anywhere nvim
runs. Shade-specific integration (loading config, shade-specific nvim config
path) is a separate concern.

Future: shade-specific nvim config manageable from dotfiles. Shade config would
accept a path to nvim config OR default to `~/.config/nvim/`.

## Architecture sketch

- Scratch buffer opens as floating window (like nvumi uses snacks.scratch)
- Each line parsed against registered hook patterns (ordered by priority)
- First matching hook handles the line
- Results shown as virtual text (success/failure/preview)
- Hooks are Lua modules that register themselves
- Hook interface: `{ pattern: string|fn, handler: fn, preview?: fn }`

## Research needed

- nvumi's evaluator pipeline (lua/nvumi/*.lua) — how it processes lines
- numi-cli capabilities (math, dates, units, timezone, what else?)
- Fantastical's natural language patterns — what makes it feel magic?
- Current daily note task migration — does obsidian.nvim handle this already?
- Shade repo: current scratch buffer / launch behavior
- Async result handling in virtual text (for slow hooks like pi dispatch)

## Acceptance criteria

### Phase 1
1. Scratch buffer opens as default Shade surface
2. Prefix-based dispatch pipeline working
3. Math/conversion via numi-cli with virtual text results
4. `task:` / `remind:` appends to today's daily note `## Tasks`
5. `note:` appends to daily note `## Notes` or `## Captures`

### Phase 2
6. Prefix-optional intent inference working
7. Task migration forward on daily note creation (verify or implement)
8. Hook registration system for third-party extensibility

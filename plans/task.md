# Glimpse-powered interactive review UI for plans, tickets, epics, and diffs

## Findings

### What is glimpse?
- [HazAT/glimpse](https://github.com/HazAT/glimpse) — native macOS WKWebView micro-UI
- Sub-50ms startup, bidirectional JSON Lines over stdin/stdout
- `open(html, opts)` — persistent window with live `setHTML()` updates
- `prompt(html, opts)` — one-shot dialog, returns user response via `window.glimpse.send(data)`
- `win.on('message', data => ...)` — receive structured JSON from webview
- `win.send(js)` — eval JS in webview (push live data)
- Dark mode detection, screen info, frameless/transparent modes
- Installable as pi package: `pi install npm:glimpseui`

### Use cases identified
1. **Epic/ticket overview review** — collapsible phases, per-phase feedback textareas
2. **Plan document review** — rendered markdown with section-level annotation (✅/✏️/comment)
3. **Diff review** — jj diff parsed + syntax highlighted, hunk-level comments
4. **Ticket refinement** — editable ticket fields submitted back
5. **Multi-ticket triage** — kanban/list view with priority reorder

### Architecture decisions
- Pi extension at `extensions/glimpse-review.ts`
- Commands: `/glimpse <ticket-id>`, `/glimpse plan [path]`, `/glimpse diff [rev]`, `/glimpse tickets [filter]`
- Aliases: `/peek` and `/view` point to same handler
- `/glimpse` not `/review` — `/review` already exists for text-based agent-driven code review
- HTML template system: `renderEpicReview()`, `renderPlanReview()`, `renderDiffReview()`, `renderTicketForm()`
- All templates adapt to dark mode via `win.info.appearance.darkMode`

### Feedback flow
```
pi extension → generates HTML → glimpse window (WKWebView)
                                     ↓ user reviews + annotates
                                     ↓ window.glimpse.send({feedback: [...]})
pi extension ← structured JSON ← glimpse window
     ↓
inject into conversation / apply to tickets
```

### Iteration model
- After receiving feedback, agent processes it, regenerates content
- Pushes updated HTML to same window via `setHTML()` — no window re-open

### Dependencies
- glimpseui npm package (needs macOS, compiles native Swift)
- pi extension API (slash commands, conversation injection)
- tk CLI (ticket reading/editing)
- jj CLI (diff output)

### Child tickets outlined in epic
1. Install + integrate glimpseui
2. Core extension scaffold
3. Epic/ticket review template
4. Plan document review template
5. Diff review template
6. Feedback injection
7. Iteration loop (setHTML)
8. Ticket refinement form

## Open questions

- How does `pi install npm:glimpseui` interact with nix-managed extensions? Need to check if it persists across rebuilds or needs nix wrapping
- What's the pi extension API for injecting messages back into conversation? Need to read extension docs
- Does glimpse need any special permissions (TCC) on macOS?
- How to parse jj diff output reliably for the diff view?
- Should ticket triage (use case #5) be deferred? It's significantly more complex than the others

## Sources

- `.tickets/dot-0hug.md` — epic ticket with full background
- `.tickets/dot-0fjk.md` — parent ticket
- [HazAT/glimpse](https://github.com/HazAT/glimpse) — README, API
- `skills/glimpse/SKILL.md` — patterns for dialogs, forms, markdown viewers (referenced in epic, may not exist yet locally)

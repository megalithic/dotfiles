---
id: dot-0hug
status: open
deps: []
links: []
created: 2026-04-23T17:22:25Z
type: epic
priority: 1
assignee: Seth Messer
parent: dot-0fjk
tags: [epic, pi-coding-agent, glimpse, review, feedback]
---
# Glimpse-powered interactive review UI for plans, tickets, epics, and diffs

Build a pi extension using HazAT's glimpse (native macOS WKWebView micro-UI) to present plans, ticket/epic overviews, and jj diffs in a rich HTML interface where the user can review, annotate, and submit feedback that flows back to the pi agent session.

## Background

[HazAT/glimpse](https://github.com/HazAT/glimpse) is a native micro-UI that opens a WKWebView window and speaks bidirectional JSON Lines over stdin/stdout. Sub-50ms startup. Key capabilities:

- `open(html, opts)` — persistent window with live `setHTML()` updates
- `prompt(html, opts)` — one-shot dialog, returns user's response via `window.glimpse.send(data)`
- `win.on('message', data => ...)` — receive structured JSON from webview
- `win.send(js)` — eval JS in webview (push live data)
- Dark mode detection, screen info, frameless/transparent modes
- Installable as pi package: `pi install npm:glimpseui`

## Feasibility Assessment

**Yes, this is fully possible.** Glimpse's bidirectional messaging model maps perfectly to the review workflow:

1. Pi extension generates HTML (plan doc, epic overview, diff view)
2. Opens glimpse window with inline feedback forms per section
3. User reviews, adds annotations/comments per section, clicks "Submit"
4. `window.glimpse.send({ feedback: [...] })` sends structured feedback back
5. Extension receives feedback via `win.on('message')` and injects it into the conversation as a user message or processes it directly

The `setHTML()` method allows iterating — agent processes feedback, regenerates content, pushes update to same window.

## Use Cases

### 1. Epic/Ticket Overview Review
Render an epic (e.g., meg-8lkv megadots completion) as rich HTML with collapsible phases. Each phase has an inline textarea for feedback. User reviews all phases, adds notes like "Phase 2: also need to port kanata config" or "Phase 5: defer GPG setup", submits. Agent receives structured `{ phase: 2, feedback: "also need to port kanata config" }` for each annotation.

### 2. Plan Document Review
Render a plan doc (e.g., megadots-completion-plan.md) as formatted HTML. Each section gets a feedback affordance. User can approve sections (✅), request changes (✏️), or add comments. Submitted feedback includes section ID + action + comment text.

### 3. Diff Review
Run `jj diff` or `jj diff -r @-`, parse output, render as side-by-side or unified diff with syntax highlighting. User can comment on specific hunks/files, approve or reject changes. Useful before committing or as part of ticket-worker verification.

### 4. Ticket Refinement
Show a single ticket's full content (description, acceptance criteria, design notes) in a editable form. User tweaks wording, adds acceptance criteria, submits. Agent applies changes via `tk edit` or direct file edit.

### 5. Multi-Ticket Triage
Show all open tickets in a kanban-like or list view. User can drag to reorder priority, check/uncheck for inclusion in a sprint, add quick notes. Submit returns the full triage result.

## Architecture

### Extension: `extensions/glimpse-review.ts`

Registers slash commands:

| Command | Description |
|---------|-------------|
| `/glimpse <ticket-id>` | Open ticket/epic in glimpse for review |
| `/glimpse plan [path]` | Open a plan document for review |
| `/glimpse diff [rev]` | Open jj diff in glimpse for review |
| `/glimpse tickets [filter]` | Open ticket list for triage |

**Aliases:** `/peek` and `/view` behave identically to `/glimpse`. All three registered as commands pointing to the same handler.

**Why `/glimpse` not `/review`:** `/review` already exists (`extensions/review.ts`) for agent-driven code review (PRs, branches, commits — text-based, in-terminal). Glimpse is a different UX paradigm: native window, user-driven visual review with structured feedback loop. Separate namespace avoids conflation.

Each command:
1. Gathers data (tk show, file read, jj diff)
2. Generates HTML with feedback forms + dark mode + system font
3. Opens glimpse window
4. Waits for feedback message
5. Injects feedback into conversation or applies changes directly

### Dependency: glimpseui package

`pi install npm:glimpseui` — or add to nix-managed extensions.

### HTML Template System

Reusable HTML generator functions:
- `renderEpicReview(epicData, children)` — collapsible phases with feedback
- `renderPlanReview(markdown)` — rendered markdown with section annotations
- `renderDiffReview(diffOutput)` — syntax-highlighted diff with hunk comments
- `renderTicketForm(ticketData)` — editable ticket fields
- All templates adapt to `win.info.appearance.darkMode`

### Feedback Flow

```
┌─────────┐     HTML + forms     ┌──────────────┐
│  pi ext │ ──────────────────→  │  glimpse win │
│         │                      │  (WKWebView) │
│         │  ← structured JSON   │              │
│         │   {feedback: [...]}  │  user reviews│
└─────────┘                      └──────────────┘
     │
     ▼
  inject feedback into
  conversation / apply
  changes to tickets
```

## Child Tickets

1. **Install + integrate glimpseui** — `pi install npm:glimpseui`, verify it works, add to nix-managed config if needed
2. **Core extension scaffold** — `extensions/glimpse-review.ts` with command registration, glimpse import, basic open/close lifecycle
3. **Epic/ticket review template** — HTML generator for epic overview with per-phase feedback forms
4. **Plan document review template** — markdown rendering + section-level annotation
5. **Diff review template** — jj diff parsing + syntax-highlighted view with hunk comments
6. **Feedback injection** — wire feedback JSON back into pi conversation or apply to tickets/files
7. **Iteration loop** — after feedback, regenerate + push updated HTML to same window via `setHTML()`
8. **Ticket refinement form** — editable ticket fields (title, description, acceptance criteria) submitted back

## Sources

- [HazAT/glimpse](https://github.com/HazAT/glimpse) — README, API, skill docs
- `skills/glimpse/SKILL.md` — patterns for dialogs, forms, markdown viewers, live streaming
- `src/glimpse.mjs` — `open()`, `prompt()`, `GlimpseWindow` class, `setHTML()`, event model

## Acceptance Criteria

1. `pi install npm:glimpseui` succeeds and glimpse binary compiles on macOS
2. `/review dot-fsxj` opens a native window showing the epic with all 13 children, each with a feedback textarea
3. User adds feedback to 3 phases, clicks Submit — pi agent receives structured JSON with phase IDs and feedback text
4. Agent acknowledges feedback in conversation and can iterate (re-render updated view)
5. `/review-plan ~/.local/share/pi/plans/megadots/megadots-completion-plan.md` renders the plan as formatted HTML with section annotations
6. `/review-diff` shows current jj diff with syntax highlighting
7. All templates respect system dark mode
8. Window closes cleanly on Submit or Escape
9. `just validate home` passes with extension installed


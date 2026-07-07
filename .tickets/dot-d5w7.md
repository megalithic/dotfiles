---
id: dot-d5w7
status: closed
deps: []
links: []
created: 2026-05-07T16:46:15Z
type: feature
priority: 2
assignee: Seth Messer
tags: [ready-for-development]
---

# Enhance preview-html and trim preview skill

Two tracks: enhance the preview-html interactive features, and trim the preview
skill doc to non-obvious content only.

## Track A: preview-html enhancements

Files: bin/preview-html, home/common/programs/pi-coding-agent/extensions/preview.ts,
home/common/programs/pi-coding-agent/extensions/task-pipeline.ts

### A1: Metadata embedding for plan documents

- Add `--meta key=value` repeatable flag to `preview-html`
- Embed metadata as JSON in the HTML (`<script id="pi-meta">`)
- Task pipeline passes `--meta type=plan --meta slug=<slug>` when previewing plans
- JS reads metadata to conditionally render plan-specific UI (e.g., "/tickets" button)

### A2: "/tickets" button for plan documents

- When `meta.type === "plan"`, show a button at bottom of content
- Initially: copies `/tickets {slug}` to clipboard with toast (Submit deferred)
- Later: use Submit mechanism to send directly to pi agent

### A3: Per-section user comments

- Every collapsible `<details class="section">` gets a "User comments" textarea
- Persisted in `state.comments[sectionId]` via localStorage
- Included in responses export alongside decisions and checkbox state

### A4: Conditional FAB visibility

- Hide export/response buttons when no decisions exist AND no decisions answered
  AND no section comments written
- Show as soon as any interaction occurs (decision answered, comment typed)

### A5: Split export into Download + Copy (Submit deferred)

- **Download Responses**: downloads token-efficient markdown as `<slug>-responses.md`
- **Copy Responses**: copies same format to clipboard
- **Submit Responses**: deferred to future ticket (needs RPC/callback design)
- Format: compact markdown optimized for LLM consumption

### A6: Browser priority — add Helium

- Insert `io.helium.helium` after `com.brave.Browser.nightly` in FALLBACK_BROWSER_PRIORITY

## Track B: Trim preview skill

Files: home/common/programs/pi-coding-agent/skills/preview/SKILL.md

- Remove: basic content type examples, simple flag docs, keyboard shortcuts
  (all covered by `/preview --help`)
- Keep: HTML mode details (updated with new features), browser targeting,
  GC, troubleshooting, tmux pane safety rules

## Acceptance Criteria

1. `preview-html --meta type=plan --meta slug=foo doc.md` embeds metadata in HTML
2. Plan documents show "/tickets" button (copies command to clipboard)
3. Every collapsible section has a "User comments" textarea, persisted
4. FAB buttons hidden when no user interaction; visible when any response exists
5. "Download Responses" and "Copy Responses" buttons work with token-efficient format
6. Helium in browser fallback chain after Brave Nightly
7. Preview skill trimmed to non-obvious features
8. `/preview --html` still works (smoke test)
9. `just validate home` passes

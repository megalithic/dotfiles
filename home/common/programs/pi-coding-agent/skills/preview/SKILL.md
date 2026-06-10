---
name: preview
description: Display code, diffs, images, and other content in a tmux pane or popup, OR render markdown as a single-page interactive HTML and open in the default chromium-family browser. Auto-detects nvim/megaterm for floating popups.
tools: Bash
---

# Preview Skill

Use `/preview --help` for basic usage (types, flags, modes, examples). This
document covers non-obvious features, HTML mode, and troubleshooting.

## CRITICAL: Pane Safety Rules

**Never kill or disrupt the pane running pi.** Before killing, closing, or replacing ANY pane:

1. **Identify your own pane first:** `tmux display-message -p '#{pane_id}'` — this is pi's pane. Never kill it.
2. **Before `kill-pane -t X`:** Verify X is not pi's pane ID.
3. **Before sending keys to any pane:** Verify the expected app is actually running there:
   ```bash
   tmux display-message -t "$TARGET" -p '#{pane_current_command}'
   tmux capture-pane -p -t "$TARGET" -S -3
   ```
4. **Never send keys blindly.** If target pane doesn't have the expected process, STOP.
5. **Never assume pane identity persists.** User may close or rearrange panes between commands.

## HTML Mode (`--html`)

Renders markdown as a single-page interactive HTML and opens in a chromium-family
browser. Bypasses tmux entirely.

### When to use

Plans, proposals, research docs, decision documents — anything the user should
scroll, collapse sections, tick checkboxes, answer questions, or comment on.

### Plan document detection

When previewing a `_PLAN.md` file, the extension auto-detects it and passes
`--meta type=plan --meta slug=<slug>` to `preview-html`. This enables:

- **"Create Tickets from Plan" button** at the bottom of the document
- The button copies `/tickets <slug>` to clipboard for pasting into pi

### Interactive features

- **Sticky TOC sidebar** with active-section highlighting (IntersectionObserver)
- **Collapsible h2 sections** — state persisted in localStorage
- **Interactive task checkboxes** — checked state persisted
- **Decision cards** — auto-generated from:
  - Headings matching `Q1:`, `Q:`, `??`, `Decision:`
  - Any h3/h4 under `## Open questions`
  - List items under `## Open questions`
  - Each card: Yes/No/Maybe/Skip radios + free-text notes
- **Per-section user comments** — every collapsible section has a textarea for
  feedback, persisted in localStorage
- **Conditional response buttons** — hidden until user interacts (answers a
  question, writes a comment):
  - **Download Responses** — saves `<slug>-responses.md`
  - **Copy Responses** — copies token-efficient markdown to clipboard

### Response format

Exported responses are compact markdown optimized for LLM consumption:

```markdown
# Responses: <title>

slug: <slug>

## Comments

### <section heading>

<user's comment text>

## Decisions

- **<question>**: <choice> — <notes>

## Tasks

- [x] <completed item>
- [ ] <incomplete item>
```

### Metadata embedding

Pass arbitrary metadata via `--meta key=value` (repeatable). Metadata is
available in the HTML as `DOC_META` (JS object). The preview extension
auto-injects `type=plan` and `slug=<slug>` for `_PLAN.md` files.

### Browser detection (chromium family only)

1. `PI_PREVIEW_BROWSER` env var (bundle id), if set
2. macOS LaunchServices default `http` handler — used if chromium-family
3. Running-app priority: Brave Nightly → Helium → Brave → Chrome → Arc → Edge → Vivaldi
4. Any installed chromium app

Safari, Firefox: NOT supported.

**Window targeting:** opens in the window with the most tabs (heuristic for
primary window). New tab at end, switches focus, brings window to front.

### Output paths and garbage collection

- Default: `~/.local/share/pi/preview/<ts>-<slug>.html` (gc'd > 30 days)
- `--html-ephemeral`: `/tmp/preview-<slug>-<ts>.html` (gc'd > 1 day)
- Override: `PI_PREVIEW_DIR`, `PI_PREVIEW_PERSIST_DAYS`, `PI_PREVIEW_TMP_DAYS`

GC runs automatically on each `preview-html` invocation. Manual:

```bash
preview-html-gc --dry-run    # show what would be pruned
preview-html-gc --quiet      # silent prune
```

### Direct invocation (bypass extension)

```bash
preview-html doc.md                              # render + open
preview-html --no-open doc.md                    # render only
preview-html --ephemeral notes.md                # /tmp output
preview-html --browser com.google.Chrome doc.md  # force browser
preview-html --meta type=plan --meta slug=foo plan.md  # with metadata
```

## Troubleshooting

**"Preview requires tmux"** — run pi inside tmux, or use `--html` mode.

**"preview-ai failed"** — check `which preview-ai` and required tools: `bat`,
`glow`, `jq`, `delta`, `chafa`.

**"no chromium-family browser found"** — install Brave/Chrome/Arc/Edge/Vivaldi,
or set `PI_PREVIEW_BROWSER`.

**Tab opens in wrong window** — script picks window with most tabs. Close other
windows or move tabs to influence targeting.

**Preview pane not appearing** — check tmux window, try `preview-ai diff` manually.

**Image preview broken** — check `which chafa` and terminal image capabilities.

## Related

- `~/.dotfiles/bin/preview-ai` — tmux preview dispatcher
- `~/.dotfiles/bin/preview-html` — HTML render + browser-open (Python)
- `~/.dotfiles/bin/preview-html-gc` — garbage collection

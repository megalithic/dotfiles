# tmux-golden-layout

Golden-ratio focused-pane resizing and a declarative per-window layout API
for tmux. Local, dotfiles-owned plugin with a TPM-compatible structure
(`golden-layout.tmux` entrypoint), implemented in TypeScript and run with Bun.

## Behavior

- Always on. In every ordinary window the focused pane is resized to exactly
  `1/phi` of the window width and height wherever the topology has siblings
  along that axis. It grows and shrinks to the target.
- Unfocused branches divide the remaining space by leaf count; nested
  unfocused groups are equalized.
- Works for horizontal, vertical, repeated-axis, and arbitrarily nested
  layouts: the plugin parses `#{window_layout}`, rebuilds the full tree
  (dimensions, coordinates, separators, checksum), and applies it with a
  single `select-layout`.
- Every computation starts from exact values (1/phi, declared ratios, or an
  immutable manual reference) and the current outer dimensions, so outer
  window resizes and repeated focus changes never accumulate rounding drift.
- A manual pane resize (or any foreign layout change, e.g. another plugin's
  `select-layout`) pauses automation for that window only and shows
  `Auto resize paused for this window; prefix+= to resume`. While paused,
  outer resizes still scale the captured manual reference proportionally.
- `prefix + =` resumes and immediately reapplies the active declaration, or
  golden resizing if none exists.
- Zoomed windows defer all changes; they apply after unzoom.
- Minimum pane sizes derive from topology, pane count, and separators. When
  the golden target cannot fit, the focused pane is clamped to the largest
  legal size; when even minimums cannot fit, the current layout is kept.
- State is keyed by stable window ids via window-scoped `@gl_*` user options
  (they die with the window). Multi-client behavior follows tmux's native
  shared-window semantics under `window-size latest`.

## Options (set before the plugin loads)

| option           | default | meaning                                  |
| ---------------- | ------- | ---------------------------------------- |
| `@gl-enabled`    | `on`    | `off` unregisters hooks on next load     |
| `@gl-min-width`  | `4`     | minimum leaf pane width (cells)          |
| `@gl-min-height` | `2`     | minimum leaf pane height (cells)         |
| `@gl-resume-key` | `=`     | prefix key that resumes a paused window  |
| `@gl-debug`      | `off`   | log to `$TMPDIR/tmux-gl-<uid>/<sock>/log`|

## Declarative API

`bin/gl` is the transport for Nvim, Pi, and other tools. Callers never set
tmux options or marks themselves. All ids are stable tmux ids (`@5`, `%12`).

```sh
gl declare <window-id> '<json>'   # set/replace a declaration (also: '-' = stdin)
gl grid <window-id> [pane-id...]  # even 1/2-row/grid declaration convenience
gl clear <window-id>              # remove declaration, back to golden
gl apply <window-id>              # reapply declaration/golden now
gl pause <window-id>              # pause automation (silent)
gl resume <window-id>             # resume + reapply
gl companion <companion-window> <source-window> <owner-pane>
gl status <window-id>             # JSON debug state
```

Declaration JSON is a recursive topology with exact ratios and ordered pane
ids. The declared pane set must equal the window's pane set; panes are
physically reordered (swap-pane) to match declared order when needed.

```json
{
  "root": {
    "split": "h",
    "ratios": [0.65, 0.35],
    "children": [{ "pane": "%1" }, { "pane": "%2" }]
  }
}
```

Known declarations this supports: Nvim/Pi 65/35; standalone Pi 50/50 with a
nested subagent grid on the right; full-window subagent grids in companion
windows (`gl grid`); Hunk in its own linked companion window (`gl companion`
stores the source-window/owner-pane association).

A declaration suppresses golden focus resizing for that window while it
exists; outer resizes still reapply the declared ratios from their exact
values. A manual pause suppresses both until `prefix + =`.

## Loading

Loaded from `plugins.tmux.conf` with a direct
`run-shell .../golden-layout.tmux` rather than through TPM: TPM's installer
would try to clone it, `prefix+U` would `git pull` inside the dotfiles
checkout, and `prefix+M-u` would delete anything under the plugin path not in
its list. The entrypoint is idempotent (indexed hook slot 188, `bind-key`
replacement) so config reloads are safe.

## Engine notes

- Hooks: `after-select-pane`, `after-split-window`, `after-resize-pane`
  (session table) and `window-layout-changed`, `window-resized` (window
  table), all at index 188, all `run-shell -b`.
- Loop prevention: every applied layout is recorded in a short-lived
  per-window history (`@gl_history`); hook echoes matching the history are
  ignored. Older history entries only count as echoes when the pane set still
  matches `@gl_last_applied`.
- Classification of `window-layout-changed`: topology change -> recompute;
  root dims changed -> outer resize -> recompute/scale; same panes and dims
  with different geometry -> user change -> pause.
- Races: before applying, each event re-fetches window state and aborts if
  layout, dimensions, or (for focus-dependent layouts) the active pane changed
  since the computation; the event that caused the change recomputes on its
  own. tmux itself is not addressed by index anywhere — only `@id`/`%id`.
- `tmux select-layout` maps layout leaves to panes by window order, not by the
  pane ids embedded in the string; declarations therefore reorder panes first
  and golden layouts always preserve the parsed leaf order.

## Tests

```sh
bun test            # all
bun test src/       # unit: parsing, checksum, allocation, scaling
bun test test/      # integration: isolated tmux server on a private socket
```

Integration tests start their own `tmux -S <tmpdir>/sock -f /dev/null`
server; the live server is never touched.

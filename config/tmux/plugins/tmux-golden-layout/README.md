# tmux-golden-layout

Golden-ratio resizing of the focused pane for tmux 3.8 and later. Local,
dotfiles-owned plugin with a TPM-compatible structure (`golden-layout.tmux`
entrypoint), written in TypeScript and run with Bun.

## Behavior

- Always on. In every window the focused pane gets exactly `1/phi` (61.8%)
  of the window width and height wherever it has neighbours along that axis.
- The other branches split the remaining space by pane count. Nested
  unfocused groups are split evenly.
- Works for horizontal, vertical, repeated-axis, and nested layouts. The
  plugin parses `#{window_layout}`, rebuilds the whole tree, and applies it
  with a single `select-layout`.
- Floating panes are left exactly where they are; tiled panes keep resizing
  around them. Focusing a floating pane changes nothing.
- Every computation starts from exact values (1/phi or an immutable manual
  reference) and the current window size, so resizes and repeated focus
  changes never accumulate rounding drift.
- A manual pane resize, or another tool's `select-layout`, pauses automation
  for that window and shows
  `Auto resize paused for this window; prefix+= to resume`. While paused,
  window resizes scale the manual layout proportionally.
- `prefix + =` resumes and reapplies golden resizing immediately.
- Zoomed windows are left alone and settle after unzoom.
- Minimum pane sizes come from the topology and separators. When the golden
  target cannot fit, the focused pane gets the largest legal size; when even
  the minimums cannot fit, the current layout stays.

## Options (set before the plugin loads)

| option           | default | meaning                                   |
| ---------------- | ------- | ----------------------------------------- |
| `@gl-enabled`    | `on`    | `off` unregisters hooks/key on next load  |
| `@gl-min-width`  | `4`     | minimum pane width (cells)                |
| `@gl-min-height` | `2`     | minimum pane height (cells)               |
| `@gl-resume-key` | `=`     | prefix key that resumes a paused window   |
| `@gl-debug`      | `off`   | log to `$TMPDIR/tmux-gl-<uid>/<sock>/log` |

## Loading

`plugins.tmux.conf` loads the entrypoint with `run-shell` instead of TPM.
TPM's installer would try to clone it, `prefix+U` would `git pull` inside the
dotfiles checkout, and `prefix+M-u` would delete anything under the plugin
path not in its list. Re-sourcing is safe: hooks use indexed slot 188 and the
resume key is replaced in place.

## How it works

- Hooks (slot 188, all `run-shell -b gl event '#{hook}' '#{hook_window}'`):
  - `window-pane-changed`: any focus change, including mouse, `last-pane`,
    split, and kill.
  - `window-layout-changed`: splits, kills, window resizes, manual resizes,
    and other tools' layouts.
  - `window-unzoomed`: settle after a zoom.
- Layouts use the tmux 3.8 JSON format. `select-layout` also applies the
  active pane, last-pane order, and floating-pane stacking from the string,
  so the plugin always writes these fields back as read from the current
  layout.
- Each event reads one snapshot of the window. Changes are committed with
  one tmux command list: store the expected state in `@gl_expect`, then
  `if-shell -F` compares it with the live window and only then runs
  `select-layout`. tmux runs the check and the apply back to back, so work
  computed from a stale snapshot is dropped and the newer event's hook
  settles the window instead. No lock files or timers.
- Window options hold the per-window state and vanish with the window:
  `@gl_applied` (last layout applied or accepted), `@gl_paused`, and
  `@gl_ref` (manual layout captured at pause).
- `window-layout-changed` compares the live layout with `@gl_applied`:
  - different pane set or window size: resettle;
  - same tiled geometry: the plugin's own change, ignored;
  - panes only swapped places: resettle;
  - anything else: a manual change, so pause (or refine the paused
    reference).

## Tests

```sh
bun test                  # all tests under tests/
bun run test:unit         # parsing, allocation, scaling
bun run test:integration  # isolated tmux server on a private socket
```

Integration tests start their own `tmux -S <tmpdir>/sock -f /dev/null`
server; the live server is never touched.

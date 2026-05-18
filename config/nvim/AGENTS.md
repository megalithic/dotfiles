# nvim/pinvim AGENTS.md

## User command rubric

Pinvim commands follow a `Pi*` / `Pinvim*` dual-prefix convention.
Short `Pi*` forms are the primary interface. `Pinvim*` forms exist for
discoverability via `:Pinvim` tab-completion. Both always map to the same
handler.

### Categories

| Category | Purpose | Commands | Keymap |
|----------|---------|----------|--------|
| **Inspect** | Read-only state/health/status | `PiInfo`, `PiStatus`, `PiHealth` | — |
| **Connect** | Target selection and lifecycle | `PiTarget`, `PiPrevious`, `PiRestore`, `PiSessions` | `gpR` |
| **Split** | Tmux pane management | `PiPanel`, `PiSplit` | `gpp` |
| **Send** | Deliver context/messages to pi | `PiSend`, `PiPrompt` | `gps`, `gpa` |
| **Compose** | Queue/flush/clear batched context | `PiAdd`, `PiFlush`, `PiClear` | — |

### Command reference

| Command | Args | Range | Desc | Keymap | tmux |
|---------|------|-------|------|--------|------|
| `PiInfo` | — | — | Full state dump: lifecycle, socket, peer, protocol, handshake payload | — | — |
| `PiStatus` | — | — | Concise: socket, source, connected, link_mode, restored, peer, heartbeat | — | — |
| `PiHealth` | — | — | Binary ok/attention: peer id, hello_ack, heartbeat age, socket | — | — |
| `PiTarget` | `?` | — | No arg → show current. Path → set buffer-local target. `auto`/`clear` → reset to discovery | — | — |
| `PiPrevious` | — | — | Switch to previous alive parked target | — | — |
| `PiRestore` | — | — | Restore previous alive parked target (alias of Previous with notify) | `gpR` | — |
| `PiSessions` | — | — | Picker (Snacks/vim.ui) of ranked manifest targets + auto-discover option | — | — |
| `PiPanel` | `!` | — | Ensure pi split visible. `!` toggles (show/hide existing) | — | — |
| `PiSplit` | — | — | Spawn/focus one ephemeral pi in 30% right split; visual `gpp` sends selection immediately | `gpp` | `prefix+p`, `prefix+C-p` |
| `PiSend` | — | ✓ | Send explicit cursor/selection context to linked pi (includes symbol_kind, diagnostics, LSP metadata) | `gps`, `gpa` | — |
| `PiPrompt` | `*` | — | Send raw text prompt. Arg or input | — | — |
| `PiAdd` | — | ✓ | Append selection/file to compose queue | — | — |
| `PiFlush` | `*` | — | Send compose queue as combined prompt. Optional arg = inline prompt | — | — |
| `PiClear` | — | — | Discard compose queue | — | — |

### Keymap prefix: `gp`

All pinvim keymaps live under `gp` (mnemonic: **g**o **p**i).

| Keys | Mode | Action |
|------|------|--------|
| `gpp` | n | Spawn/focus one ephemeral pi split |
| `gpp` | v | Spawn/focus one ephemeral pi split, send selection, focus pi |
| `gpR` | n | Restore previous parked target |
| `gps` | n | Prompt at cursor, then send cursor context + input |
| `gps` | v | Prompt at cursor, then send visual selection + input |
| `gpa` | n | Send cursor context and focus pi |
| `gpa` | v | Send visual selection and focus pi |

### tmux bindings

| Binding | Action |
|---------|--------|
| `prefix+p` | From nvim only: dispatch `gpp` to spawn/focus ephemeral pi split; visual mode sends selection immediately |
| `prefix+C-p` | Same as `prefix+p` (prevents accidental old panel toggle) |

### Design rules

1. **`Pi*` is the user-facing prefix.** `Pinvim*` exists only for `:Pinvim` tab-completion discovery.
2. **No overlap in behavior.** Each command does one thing. Aliases (`PiPrevious`/`PiRestore`) must share a handler, not diverge.
3. **Inspect commands are read-only.** They never mutate connection state or send frames.
4. **Send commands are the only nvim→pi context path.** No implicit streaming.
5. **Compose is explicit batch.** `PiAdd` queues, `PiFlush` delivers, `PiClear` discards. No implicit flush.
6. **Split vs Panel distinction.** `PiSplit` owns one visible ephemeral per nvim instance. `PiPanel` toggles existing parked pane. These are separate workflows.
7. **Keymaps use `gp` prefix.** New keymaps go under `gp` unless there's a collision.
8. **tmux `prefix+p` / `prefix+C-p` = `gpp` in nvim only.** Visual mode sends selection immediately and focuses pi. Shell/pi panes are ignored.

# Pinvim live context audit

## Status

`dot-klla` removed current implicit `live_context` / `editor_state` implementation from nvim and pi.

Current supported nvim→pi context path: explicit send/queue only (`gps`, `:PinvimSend`, `:PiSend`, `PinvimAdd`, `PinvimFlush`).

Future live context work must be redesigned separately: explicit keymap/motion initiated, same tmux window / active handshake only, pi-acknowledged, and visibly represented in the conversation as user-injected nvim context. Implicit mode may return later only behind clear opt-in.

## Architecture

```text
nvim
  config/nvim/after/plugin/pinvim.lua
    thin loader
      ↓
  config/nvim/lua/pinvim.lua
    peer state, socket discovery, hello/heartbeat, explicit send/queue
      ↓ persistent vim.uv.new_pipe()
pi socket
  home/common/programs/pi-coding-agent/extensions/bridge.ts
    transport shim: parses JSON frames, emits pi events, owns no nvim semantics
      ↓ pi.events
pi
  home/common/programs/pi-coding-agent/extensions/pinvim.ts
    owns peer metadata, footer status, commands, explicit context delivery
```

## Message types

| Frame | Direction | Sends user-visible message? | Purpose |
| --- | --- | --- | --- |
| `hello` | nvim → pi | No | Peer identity + capabilities |
| `hello_ack` | pi → nvim | No | Pi peer identity + accepted frame types |
| `heartbeat` | both | No | Freshness/health |
| `explicit_send` | nvim → pi | Yes | User-triggered context send via `gps` / commands |
| `prompt` | nvim → pi | Yes | User-triggered prompt send |
| `editor_state` | nvim → pi | No | Unsupported; bridge returns error directing user to `explicit_send` |

## Explicit send behavior

Current context path is explicit:

- normal mode `gps` → sends cursor context
- visual mode `gps` → sends selection
- `:PinvimSend` / `:PiSend` → sends cursor or range context
- `PinvimAdd` / `PiAdd` → queue file or selection
- `PinvimFlush` / `PiFlush` → send queued context with optional prompt

Explicit nvim sends become normal user messages:

- idle pi session: delivered immediately
- active pi session: delivered as `followUp`
- message includes `User explicitly sent this context from Neovim.`

## Removed behavior

Removed from `config/nvim/lua/pinvim.lua`:

- `live_context` config
- live context timers and pending state
- live context autocmds
- `build_editor_state`
- `push_editor_state`
- `editor_state` / `editor_disconnect` sends

Removed from `home/common/programs/pi-coding-agent/extensions/pinvim.ts`:

- editor state cache
- stale editor-state checks
- hidden `before_agent_start` injection
- `pinvim-live-context` custom hidden message
- legacy `pinvim_legacy:editor_state` handling

Changed in `home/common/programs/pi-coding-agent/extensions/bridge.ts`:

- `hello_ack.accepts` no longer lists `editor_state` or `editor_disconnect`
- `editor_state` / `editor_disconnect` receive clear unsupported response
- `explicit_send`, `prompt`, `hello`, and `heartbeat` remain supported

## Future direction

Future live context research must not restore implicit editor-state sync as current behavior. Candidate design constraints:

- user-triggered keymap/motion starts injection
- same tmux window / active handshake only
- pi acknowledges accepted context
- conversation visibly shows injected nvim context
- implicit mode only behind clear enable/disable option

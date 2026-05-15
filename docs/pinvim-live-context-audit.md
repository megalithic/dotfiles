# Pinvim live context audit

## Status

Superseded by `dot-klla`: current implicit `live_context` / `editor_state` implementation should be removed from both nvim and pi sides.

Current supported nvim→pi context path: explicit send/queue only (`gps`, `:PinvimSend`, `:PiSend`, `PinvimAdd`, `PinvimFlush`).

Automatic live context is currently disabled by default as an interim safety gate, but the next cleanup removes the implementation rather than keeping it dormant.

- nvim gate: `config/nvim/lua/pinvim.lua` sets `live_context.enabled = vim.env.PINVIM_LIVE_CONTEXT == "1"`.
- pi gate: `home/common/programs/pi-coding-agent/extensions/pinvim.ts` only injects hidden live context when `process.env.PINVIM_LIVE_CONTEXT === "1"`.
- Primary path remains explicit send from nvim: `gps`, `:PinvimSend`, or `:PiSend`.

## Architecture

```text
nvim
  config/nvim/after/plugin/pinvim.lua
    thin loader
      ↓
  config/nvim/lua/pinvim.lua
    peer state, socket discovery, hello/heartbeat, explicit send, optional live_context
      ↓ persistent vim.uv.new_pipe()
pi socket
  home/common/programs/pi-coding-agent/extensions/bridge.ts
    transport shim: parses JSON frames, emits pi events, owns no nvim semantics
      ↓ pi.events
pi
  home/common/programs/pi-coding-agent/extensions/pinvim.ts
    owns peer metadata, editor state, footer status, commands, optional hidden context injection
```

## Message types

| Frame | Direction | Sends user-visible message? | Purpose |
| --- | --- | --- | --- |
| `hello` | nvim → pi | No | Peer identity + capabilities |
| `hello_ack` | pi → nvim | No | Pi peer identity + accepted frame types |
| `heartbeat` | both | No | Freshness/health |
| `editor_state` | nvim → pi | No by default | Optional live context state cache |
| `explicit_send` | nvim → pi | Yes | User-triggered context send via `gps` / commands |
| `prompt` | nvim → pi | Yes | User-triggered prompt send |
| `editor_disconnect` | nvim → pi | No | Clear editor state |

## Setup

### Default

No env var set:

```sh
unset PINVIM_LIVE_CONTEXT
```

Behavior:

- `hello` / `hello_ack` / `heartbeat` still run.
- `editor_state` autocmds are not registered.
- pi `before_agent_start` does not inject hidden live context.
- explicit sends still work.

### Opt in

```sh
export PINVIM_LIVE_CONTEXT=1
```

Behavior:

- nvim registers live context autocmds.
- nvim sends debounced `editor_state` frames.
- pi may inject hidden `[NEOVIM LIVE CONTEXT]` before an agent turn if state is fresh.

## Safety controls

### Explicit-send first

Default context path is explicit:

- normal mode `gps` → sends cursor context
- visual mode `gps` → sends selection
- `:PinvimSend` / `:PiSend` → sends cursor or range context

Automatic context requires opt-in env.

### Dual gate

Automatic live context requires both sides to allow it:

- nvim: no `editor_state` autocmds unless `PINVIM_LIVE_CONTEXT=1`
- pi: no hidden `before_agent_start` injection unless `PINVIM_LIVE_CONTEXT=1`

This means stale nvim config or stray `editor_state` frames cannot silently inject context unless pi process is also opted in.

### Debounce

When enabled, nvim sends live context through a timer:

- default debounce: `150ms`
- repeated events collapse into one pending update
- `CursorMoved` only sends while visual selection is active

### Buffer filters

Before sending live context, nvim requires:

- connected socket
- file-backed buffer (`absFile` present)
- normal buffer (`buftype == ""`)

Terminal, help, prompt, nofile, and other special buffers are skipped.

### Size limits

Defaults:

- selection max: `8000` bytes
- buffer text max: `16000` bytes
- full buffer text: disabled by default (`include_buffer_text = false`)

### Freshness

Pi considers editor state stale after `60s`.

Stale state:

- not displayed in footer as current file context
- not injected into agent context

### Delivery behavior

Explicit nvim sends become normal user messages:

- idle pi session: delivered immediately
- active pi session: delivered as `followUp`

Live context, when opted in, is hidden context only:

- custom type: `pinvim-live-context`
- `display: false`
- injected only during `before_agent_start`

## Current decision

Live context was previously enabled by default in `pinvim.lua`. That was unsafe for intended workflow because nvim could send automatic editor state without explicit user action.

Interim fix made in `dot-f6tr`:

- automatic live context disabled by default
- explicit `gps` / `:PinvimSend` remains primary path
- nvim and pi both require `PINVIM_LIVE_CONTEXT=1` for hidden live context
- `/pinvim-info` reports current live context setting and safety notes

Next cleanup in `dot-klla`:

- remove current nvim-side live_context config/timer/autocmd/editor_state code
- remove current pi-side editorState storage and hidden `before_agent_start` injection
- stop treating `editor_state` as supported nvim context transport
- keep explicit send/queue only

Future live context research may reintroduce a different feature only if it is explicit keymap/motion initiated, limited to same-window active handshakes, acknowledged by pi, and visibly represented in the conversation as user-injected nvim context. Implicit mode may exist later only behind a clear enable/disable option.

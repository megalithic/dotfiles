---
id: dot-m8g5
status: in_progress
deps: []
links: []
created: 2026-04-17T14:56:02Z
type: bug
priority: 2
assignee: Seth Messer
tags:
  - ready-for-development
---
# Fix pinvim.ts and pi.lua stale context cleanup when nvim exits

When nvim closes, pinvim.ts keeps showing the last editor state in the footer
until the 5-minute stale timeout expires. No disconnect event is sent from pi.lua
when nvim exits, so the extension has no way to know the editor is gone.

## Observed behavior (2026-04-17)

rx pi session footer showing `nvim: icons.lua L147` with no nvim running anywhere.
`icons.lua` lives in dotfiles (`config/nvim/lua/icons.lua`). No nvim processes
active in any tmux session (confirmed via `ps aux`). State is indefinitely stale —
the 5-minute `STALE_MS` timeout either already passed (footer should be blank but
isn't being re-evaluated), or editor_state was refreshed recently by a now-dead nvim.

Likely scenario: nvim was running in rx tmux session with cwd matching rx.info,
user navigated to `icons.lua` in dotfiles, editor_state sent to rx bridge.
Nvim closed → no disconnect → state stuck forever.

## Files

- `config/nvim/after/plugin/pi.lua` (nvim plugin)
- `home/common/programs/ai/pi-coding-agent/extensions/bridge.ts` (socket server)
- `home/common/programs/ai/pi-coding-agent/extensions/pinvim.ts` (pi extension)

## Root cause

pi.lua has a VimLeavePre autocmd (~line 2270) that calls `connection_disconnect()`
which closes the pipe — but never sends a disconnect message first. bridge.ts
doesn't track which client sockets sent `editor_state`, so when a socket drops
it emits nothing. pinvim.ts has no disconnect handler.

Additionally, `isStale()` is only checked on-demand (in `formatStatus` and
`before_agent_start`). There's no periodic re-evaluation, so the footer text
persists until the next agent turn or status update call — which may never come
if the user isn't actively using pi.

## Implementation plan

### 1. pi.lua — send disconnect before closing pipe

In the existing VimLeavePre autocmd (bottom of file), before calling
`connection_disconnect()`, send `{ type = "editor_disconnect" }` via the
persistent pipe:

```lua
vim.api.nvim_create_autocmd("VimLeavePre", {
  callback = function()
    -- Notify bridge of disconnect BEFORE closing pipe
    if conn.pipe and conn.connected then
      pcall(function()
        conn.pipe:write(vim.json.encode({ type = "editor_disconnect" }) .. "\n")
      end)
    end
    connection_disconnect()
    stop_auto_reload()
    -- ...existing timer cleanup
  end,
})
```

### 2. bridge.ts — handle disconnect message + track editor sockets

**a) Add `editor_disconnect` payload type:**
- Add type guard `isEditorDisconnectPayload`
- In message handler, when received: `pi.events.emit("pinvim:editor_disconnect")`
  and `respondOk(socket)`

**b) Track editor sockets for crash detection:**
- Maintain a `Set<net.Socket>` called `editorSockets`
- When `editor_state` is received, add the socket to the set
- When `editor_disconnect` is received, remove from set
- On socket `close` event: if socket is in `editorSockets`, emit
  `pinvim:editor_disconnect` (handles crash/kill -9 cases)

```typescript
const editorSockets = new Set<net.Socket>();

// In createServer callback:
socket.on("close", () => {
  if (editorSockets.has(socket)) {
    editorSockets.delete(socket);
    pi.events.emit("pinvim:editor_disconnect");
  }
});
```

### 3. pinvim.ts — handle disconnect + reduce stale timeout

**a) Listen for disconnect event:**
```typescript
pi.events.on("pinvim:editor_disconnect", () => {
  editorState = null;
  lastUpdateAt = null;
  updateStatus();
});
```

**b) Reduce `STALE_MS` from 5 minutes to 60 seconds** — safety net for cases
where both explicit disconnect and socket close detection fail.

## Related issue (out of scope)

pi.lua `discover_socket_by_cwd()` second pass picks "any live socket (newest
mtime)" when nvim cwd doesn't match any `.info` manifest. This can route
editor_state to the wrong pi session entirely. Separate ticket needed for
socket routing correctness.

## Acceptance criteria

1. When nvim exits normally, pi footer clears within 2 seconds (not 5 minutes)
2. When nvim crashes or connection drops, pi footer clears within 2 seconds (socket close detection)
3. No stale [NEOVIM LIVE CONTEXT] injected into agent turns after nvim is gone
4. Reconnecting nvim restores the footer as before
5. No regressions in live context sync during normal nvim usage


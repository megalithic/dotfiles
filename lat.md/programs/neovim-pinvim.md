# Neovim and pinvim

This file covers Neovim nightly compatibility plus pinvim, the Neovim↔Pi integration that links the editor to Pi sessions over sockets and an msgpack-RPC editor service.

Pinvim ties together `config/nvim/lua/pinvim.lua`, `home/common/programs/pi-coding-agent/extensions/pinvim.ts`, `bin/pimux`, and tmux.

## Neovim nightly compatibility

Neovim config tracks nightly API changes where small compatibility updates prevent startup warnings and flaky rebuilds.

The local overlay exposes `pkgs.nvim-nightly` from `neovim-nightly-overlay` but disables its build-time checks, because upstream functional tests are flaky in the Darwin Nix sandbox. Autocmd callbacks prefer current `vim.*` APIs over deprecated aliases; yank highlighting uses `vim.hl.hl_op`, not `vim.hl.on_yank`. Escape handling does UI cleanup plus opportunistic autosave, but autosave only runs for real file buffers whose parent directory exists, since forcing `:update` on a missing-path buffer raises `E212`.

## Pinvim registry and identity

Pinvim creates a per-workspace registry under `$PI_STATE_DIR/pinvim/<workspace-hash>/` and exposes it through `:PiInfo` plus `require("pinvim").api.info()`.

The workspace hash comes from the normalized project root, and `parent.id` persists durable parent identity. Each Neovim process gets an `instances/<nvim-instance-id>/` directory with Nvim-owned `main.intent.json`. Main-panel launches use registry-root `main.sock` and root-level `main.intent.json` as the durable parent-owned Pi target; when explicit `PI_SOCKET` or buffer-local targets are absent, that socket is the automatic fast path.

`:PiSplit` allocates an explicit child session under `children/<child-id>/` with a stable child id, dedicated `child.sock`, and an `intent.json` derived from `registry_base_record`. Child sockets never replace the main registry entry and never become automatic default reconnect targets.

Pinvim peer identity carries `parentId`, `workspaceId`, `instanceId`, `registryRoot`, and `role` (`main`, `child`, or `nested`) in hello frames, acknowledgements, and manifests. The Pi extension mirrors those from PINVIM environment when present and rejects mismatched peers before falling back to tmux or root scoring.

Pinvim also exposes a separate Neovim editor service over msgpack-RPC. Nvim stores the address in `PINVIM_NVIM_LISTEN_ADDRESS`, peer frames, and manifests, and reports it through `:PiStatus`, `:PiHealth`, `:PiInfo`, `:PiDoctor`, and `api.info()`. The Pi-side client discovers the address from PINVIM env, peer frames, manifests, or registry files; probes with non-blocking msgpack-RPC; and reports connected/stale/fallback state. When no editor service is connected, Pi reports `peer socket only` fallback instead of injecting guessed context. Pi-side timers and sockets use `unref()` so a missing editor address cannot keep short-lived Pi probes alive.

### Editor-service RPC surface

The editor-service RPC surface lets Pi query or manipulate the active Neovim editor without tmux guessing.

Pi sends msgpack-RPC `nvim_exec_lua` requests to `require("pinvim").api.editor_rpc(method, params)`; the reusable Pi-side client is `globalThis.pinvimEditorService.query(method, params)`. Supported methods stay small and local-only: `status`, `context.current`, `diagnostics.current`, `open_file`, `reveal_file`, `reload_buffer`, `refresh_diagnostics`, and `checktime`.

After successful Pi `edit` and `write` tool calls, `pinvim.ts` asks the editor service to run `reload_buffer` for the changed path. Clean open buffers refresh from disk; dirty buffers stay dirty and Pi surfaces a conflict warning. `/pinvim-context` prints current context through the same path, and `/pinvim-doctor` plus Nvim-side `:PiDoctor` report registry identity, tmux pane, repair candidate, and editor-service state without new discovery side effects.

`pinvim.ts` also shares Pi socket routing with [[pi-coding-agent#Pi coding agent#Session and routing extensions|Pi tell]]. Incoming `pi.tell.v1` messages are persisted, surfaced, delivered as prompts or follow-ups, and acknowledged with async `tell_ack` messages to the sender's `fromSocket`.

## Pinvim visual selection keymaps

Pinvim visual mappings use Neovim `x` mode, so Lua callbacks may run after Visual mode exits.

Selection capture should first try live Visual state, then fall back to `'<` and `'>` marks plus `visualmode()`. Selection-bearing actions (`gpa`, `gps`, `gpp`, `:PiSend`, `:PiAdd`) route through explicit-send payloads. `gpc` / `:PiComment` capture a selection or cursor line plus a typed annotation into the compose queue; `:PiFlush` renders the whole queue as one prompt. Queued comments place an extmark indicator on the first line; re-running `gpc` on a commented line edits it in place, and empty text deletes it. `:PiComments` loads queued comments into quickfix and opens trouble.nvim's `qflist` when available.

`gpa` and `:PiSend` use `delivery = "attach"`, so Pi stores the latest context and injects it once into the next non-extension user prompt. `gps` uses `delivery = "prompt"`, sending context plus prompt immediately and starting a turn. Normal `gpp` opens or focuses a child Pi split and sends cursor/file context; visual `gpp` sends selection context; child context stays prompt-delivered. `<C-p>` toggles the main parent-owned PiPanel, never spawns a child, captures context before the split steals focus, sends it with attach delivery, and does not start a turn by itself.

On restart, parent-owned sessions prefer the registry main socket and never auto-resume old ephemeral or child sockets. Explicit `:PiTarget <socket>` remains the manual override.

### Attach-only context delivery

Pinvim attach delivery separates editor context capture from agent-turn creation.

`explicit_send.delivery = "attach"` is context-only: `pinvim.ts` formats it as `[NEOVIM ATTACHED CONTEXT]`, stores only the latest pending context, updates status, and returns without calling `pi.sendUserMessage`. The next non-extension `input` marks the following `before_agent_start` as user-origin; pending context is then consumed exactly once and injected as a displayed custom `pinvim-context` message. If none exists, Pi asks the editor service for `context.current`, formats it as `[NEOVIM LIVE CONTEXT]`, and injects through the same path. Extension-origin prompts and follow-ups never consume pending context or trigger live lookup. Pending state is short-lived: newer attach sends replace older ones, stale context expires, and shutdown clears it.

### Bidirectional peer repair

Repair is bidirectional, so either Nvim or Pi can reestablish the `hello` / `hello_ack` / heartbeat link after the other side restarts.

Nvim writes `nvim-*.info` manifests under `$PI_STATE_DIR/manifests/` every five seconds with id, cwd, root, pid, tmux session/window/pane, heartbeat time, link mode, socket path, socket source, connected state, and active peer id; `VimLeavePre` cleans it up. When no parent registry identity is present and the active Nvim peer is missing or stale, `pinvim.ts` scans those manifests every two seconds and scores candidates; parent/child sessions with registry identity skip the recurring scan. Candidates are rejected when the pid is dead, the pid is an orphaned `nvim --embed`, the socket path is gone, or the tmux session differs.

Candidate scoring prefers same tmux window, then same cwd or root, then heartbeat freshness, then a matching tmux pane. Non-ephemeral Pi requires the same tmux window so the main parent cannot be stolen; ephemeral Pi is looser. Nested attach-only Pi disables manifest scanning entirely: the wrapper detects nested launches from inherited env plus tmux pane title/command checks, marks them with `PINVIM_NESTED_ATTACH_ONLY=1`, `PINVIM_SESSION_ROLE=nested`, and `PINVIM_LINK_MODE=attach-only`, and unsets `PI_SOCKET` so it cannot bind or unlink the original Nvim-owned socket.

Pi requires a valid hello before accepting any data frame. `peerAllowedForSocket` rejects attach-only nested sessions first, then parent/workspace mismatches; matching parent/workspace identity is accepted before tmux/root scoring so the current parent cannot be stolen. Repair candidate and last repair timestamp appear in `:PiStatus`, `:PiHealth`, `/pinvim-status`, `/pinvim-health`, and `/pinvim-info`, with relation state (`attach-only`, `child`, `parent`, `no-parent`) plus link mode in the doctor and health commands.

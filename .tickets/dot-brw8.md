---
id: dot-brw8
status: closed
deps: []
links: []
created: 2026-05-19T13:22:47Z
type: task
priority: 2
assignee: Seth Messer
parent: dot-jqme
tags: [ready-for-development]
---
# Complete pinvim async transport cleanup across nvim pi and tmux

Complete pinvim async/caching cleanup across nvim, pi extension, and tmux wrapper. A quick fix already deferred initial nvim-side discovery and debounced autocmd refresh/connect, reducing pinvim load from ~136ms and BufEnter from ~117ms to sub-ms. Remaining work should remove or cache sync operations from normal startup/message paths.

Nvim-side findings in config/nvim/lua/pinvim.lua:
- refresh_buffer_state() calls Transport.resolve_socket().
- Transport.resolve_socket() calls ranked_manifest_targets().
- ranked_manifest_targets() still does sync work: vim.fn.glob(manifest_dir .. "/*.info"), vim.fn.readfile(info_path), PID checks, and socket metadata scoring.
- parse_info_manifest() reads manifest files synchronously.
- pid_alive() used os.execute("kill -0 <pid>") before quick wins; replace any remaining shell PID checks with vim.uv.kill(pid, 0) or avoid PID checks until socket connect fails.
- Some tmux paths still use blocking tmux_value()/io.popen.
- ensure_connected() should return immediately if discovery is stale, then connect after async discovery callback.
- Startup path should stay lazy: no socket discovery during M.setup(), only deferred timer or first Pi* command.
- Buffer/Dir refresh should remain debounced and avoid repeated manifest scans per buffer event.

Pi extension findings in home/common/programs/pi-coding-agent/extensions/pinvim.ts:
- detectTmux() uses execSync("tmux display-message ...").
- detectTmux() is used for socket resolution/peer identity/manifest writes/session events.
- writeInfoManifest() uses sync fs operations: existsSync, mkdirSync, writeFileSync.
- Manifest write currently happens on heartbeat path and should be throttled or async.
- Socket server and deliverMessage() should remain non-blocking; manifest updates must not block frame handling.

Tmux/pimux findings in bin/pimux:
- pimux performs many tmux calls for pane/window/socket lifecycle.
- Batch tmux display-message fields where possible.
- Cache session/window/pane values within one invocation.
- Avoid repeated list-panes -s scans when explicit --socket is provided.
- Keep pimux --new detached and return immediately for nvim caller.
- Ensure ephemeral split socket polling in nvim remains async and bounded.

Relevant files:
- config/nvim/lua/pinvim.lua
- home/common/programs/pi-coding-agent/extensions/pinvim.ts
- home/common/programs/pi-coding-agent/extensions/bridge.ts
- bin/pimux

## Acceptance Criteria

1. nvim --headless --startuptime /tmp/nvim-start +qa shows pinvim after/plugin load under 2ms and BufEnter autocommands under 2ms.
2. No synchronous pinvim manifest scan runs during M.setup() in config/nvim/lua/pinvim.lua.
3. Nvim-side pinvim discovery is async or cached so manifest scan, tmux context, PID checks, and socket metadata scoring do not block startup path.
4. ensure_connected() returns immediately when discovery is stale and connects after async/cached discovery resolves.
5. Pi-side pinvim.ts no longer uses execSync on normal message/heartbeat path, or those calls are cached/throttled with clear comments.
6. Pi-side manifest writes are throttled or async and do not block socket frame handling.
7. pimux --new and nvim ephemeral split flow remain detached/async and still spawn/focus a pi split.
8. Existing Pi commands/keymaps still work: PiStatus, PiHealth, PiInfo, PiSplit/gpp, PiSend/gpa, PiPrompt/gps.
9. nvim --headless +qa exits cleanly with no stderr.
10. nvim --headless +'sleep 600m' +qa exits cleanly with no stderr.
11. pinvim protocol smoke or equivalent manual check passes for hello, heartbeat, ping, prompt/explicit_send if available.
12. stylua succeeds on touched Lua files; TypeScript extension formatting/typecheck/build command succeeds if available.
13. Before/after startuptime and pinvim health summary is recorded in ticket notes or commit message.


## Notes

**2026-05-19T14:41:22Z**

Verification snapshot: before ticket notes cited pinvim load ~136ms and BufEnter ~117ms before quick fixes. After async/cache cleanup: nvim --headless --startuptime /tmp/nvim-start +qa shows require('pinvim') 0.267ms, after/plugin/pinvim.lua 0.386ms total / 0.119ms self, BufEnter autocommands 0.121ms, stderr 0 bytes. nvim --headless +qa and nvim --headless +'sleep 600m' +qa both exited code 0 with stderr 0 bytes. Protocol smoke against /Users/seth/.local/state/pi/sockets/pi-mega-dots-eph-1779138150-53644.sock passed ping, hello, heartbeat, prompt, explicit_send.

**2026-05-19T14:41:46Z**

Additional split smoke: detached tmux session ran nvim --headless +'PiSplit' +'sleep 800m' +qa; tmux listed spawned pane running pinvim with π title before cleanup.

**2026-05-19T14:43:33Z**

Summary: moved nvim pinvim discovery to async/cached manifest and tmux paths, made ensure_connected return immediately on stale discovery, removed pi-side execSync from pinvim normal path, throttled async manifest writes, batched pimux tmux lookups, and updated stop-hook/ticket-worker next-ticket recommendations to prefer same epic/plan/dependents/siblings/scope before global fallback.

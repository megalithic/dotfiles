---
id: dot-6d1d
status: in_progress
deps: []
links: []
created: 2026-09-15T20:51:28Z
type: feature
priority: 2
assignee: Seth Messer
---
# Tidewave toolbar inspection and optional IDE Chat routing

Foundational work shared by the primary Tidewave toolbar Inspect workflow and the optional Tidewave IDE Chat -> tmux pi forwarder. From code review of bridge.ts + Hammerspoon interop:
- PERF: detectTmux() spawns 5 execSync tmux calls; runs at startup (resolveSocket) AND every heartbeat (HEARTBEAT_MS=10s). Batch into a single tmux display-message call.
- DEAD CODE: _getModelShortName (bridge.ts) unused + stale hardcoded model names. Remove.
- NEW FIELD: tidewaveConnected in the pi manifest. Gate proven = selectedTools.includes('mcp__tidewave') captured in before_agent_start (live-connection signal, not config-presence). Cache to manifest; refresh on heartbeat.
- Also: worktree-for-port.sh (inverse of phx-port.sh): port -> {pid,root,worktree,session,pgport} JSON, mise elixir template.

Coordinate with dot-gew8 (edits same bridge.ts socket/manifest layer).

## Acceptance Criteria

1. detectTmux() uses a single tmux subprocess call. 2. _getModelShortName removed. 3. manifest includes tidewaveConnected boolean, set from selectedTools mcp__tidewave presence, refreshed on heartbeat. 4. worktree-for-port.sh emits correct JSON for a running worktree. 5. bridge.ts still passes its _test surface / no regressions in socket lifecycle.

## Increment 2: thin ACP forwarder shim (acp.ts)

Dropped the vendored pi-acp adapter and the pidewave.ts conduit in favor of a single dual-role file `config/pi-coding-agent/agent/extensions/acp.ts`:
- CLI role (Tidewave External Agent command, e.g. `bun ~/.pi/agent/extensions/acp.ts`): zero-dep ACP agent (ndjson JSON-RPC 2.0, protocol v1) implementing initialize/authenticate/session·new/session·prompt. Prompt text is forwarded to the handshaken tmux pi via bridge `pi.control.v1 message.send` (follow_up, from=tidewave); one agent_message_chunk reports the outcome; returns end_turn immediately. Input-only: no spawned pi, no response streaming.
- Extension role (pi auto-loads extensions/*.ts): binding-indicator widget only; CLI guarded by argv[1]-is-this-file check.
- Binding source unchanged: ${PI_STATE_DIR}/tidewave/bindings/<worktree-slug>.json written by Hammerspoon Cmd+Shift+C (config/hammerspoon/lib/interop/pidewave.lua).

Verified: bun build clean; scripted ACP session against a fake bridge socket delivers the exact message.send wire format and returns end_turn; extension-mode import registers only session_start/before_agent_start hooks.

Acceptance (increment 2): 6. acp.ts responds to initialize/session·new/session·prompt per ACP v1 and forwards prompt text to the bound pi's bridge socket. DONE. 7. Loading acp.ts as a pi extension has no CLI side effects. DONE. 8. Vendored acp/ dir and pidewave.ts removed. DONE. 9. Live E2E: prompt typed in Tidewave chat on :4300 lands in the handshaken tmux pi. DONE.

E2E findings (2026-09-15): the ACP agent is spawned by the Tidewave IDE app (menu-bar app, 127.0.0.1:9832), not the Phoenix server; /tidewave on the app port is only Tidewave Connect. External Agent registered as "pi (tmux)" with command `/Users/seth/.local/share/mise/installs/bun/latest/bin/bun /Users/seth/.pi/agent/extensions/acp.ts` (persisted in IDE settings). Tidewave wraps prompts in <user_prompt> + <context> blocks; forwarded verbatim. Bound pi must run bridge.ts 843a2cfd+ (older bridges reply "unsupported payload type: control", surfaced in chat). Verified: chat prompt reached a live pi in the sm-spp-enable-auth worktree as a follow_up tell; chat pane showed "✓ Forwarded to provider_portal %487"; indicator widget lit in the bound pi. Cmd+Shift+C writes the binding; without one the optional chat path shows the no-binding error chunk.

## Increment 3: primary Cmd+Shift+C toolbar workflow

The primary workflow is browser inspection, separate from ACP chat forwarding:

1. Focus the tmux pi in the worktree serving Phoenix.
2. Press Cmd+Shift+C.
3. Hammerspoon resolves that worktree's Phoenix port and selects its Helium app tab, not `/tidewave`, `/tidewave/connect`, or the Tidewave IDE on :9832.
4. CDP runs `Page.bringToFront`, Hammerspoon focuses Helium, and the selected tab's Tidewave toolbar enters Inspect mode after the page is visible and ready.

`pidewave.lua` now reuses the previous handshake's exact app URL when available, selects a sole normal app page on the port, and fails closed when multiple unmatched app tabs make selection ambiguous. The chosen URL is stored in the binding for deterministic reuse. Failures notify the user and remain guarded from Hammerspoon crashes. The same binding also supports the optional Tidewave IDE Chat -> `acp.ts` -> tmux pi path, but that path is not involved in the toolbar click.

Acceptance (increment 3): 10. Prefer a saved exact app URL and exclude Tidewave routes. DONE. 11. Fail closed for ambiguous same-port app tabs. DONE. 12. Run `Page.bringToFront`, then focus Helium, wait for a visible complete page and ready toolbar, and click Inspect. DONE. 13. Reload Hammerspoon and validate the live :4300 tab through CDP without synthesizing the final hotkey. DONE. 14. User runs the final Cmd+Shift+C test from the `sm-spp-enable-auth` tmux pi. PENDING.

Automated validation (2026-09-16): `bin/hs-reload` completed; a Lua harness passed Tidewave-route exclusion, unique normal-page selection, exact saved-URL selection, unmatched ambiguity rejection, and duplicate exact-URL rejection. Live CDP found one normal :4300 target at `http://localhost:4300/provider/login`; `Page.bringToFront` returned `{}`, Hammerspoon activated Helium, and the page reported `readyState=complete`, `visibility=visible`, a Tidewave toolbar, and an Inspect button. Review follow-up confirmed robust shell quoting with adversarial PATH values, Hammerspoon resolution of mise's `node` and `tmux`, positive Helium PID ownership of :9223, the unchanged exact URL, and a rendered, enabled, visible Inspect button. The final button click and active-panel confirmation remain a user-run hotkey test.


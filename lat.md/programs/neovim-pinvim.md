# Neovim and pinvim

This file covers Neovim nightly compatibility plus pinvim, the Neovim↔Pi integration that links the editor to Pi sessions over sockets and an msgpack-RPC editor service.

Pinvim ties together `config/nvim/lua/pinvim.lua`, `config/nvim/lua/pinvim/review.lua`, `home/common/programs/pi-coding-agent/extensions/pinvim.ts`, `home/common/programs/pi-coding-agent/extensions/nvim-review.ts`, `bin/pimux`, `bin/pireview`, and tmux.

## Neovim nightly compatibility

Neovim config tracks nightly API changes where small compatibility updates prevent startup warnings and flaky rebuilds.

The local overlay exposes `pkgs.nvim-nightly` from `neovim-nightly-overlay`, overrides its `neovim-src` input to Neovim's moving `nightly` tag, and disables its build-time checks because upstream functional tests are flaky in the Darwin Nix sandbox. Autocmd callbacks prefer current `vim.*` APIs over deprecated aliases; yank highlighting uses `vim.hl.hl_op`, not `vim.hl.on_yank`. Escape handling does UI cleanup plus opportunistic autosave, but autosave only runs for real file buffers whose parent directory exists, since forcing `:update` on a missing-path buffer raises `E212`.

## Pinvim registry and identity

Pinvim creates a per-workspace registry under `$PI_STATE_DIR/pinvim/<workspace-hash>/` and exposes it through `:PiInfo` plus `require("pinvim").api.info()`.

The workspace hash comes from the normalized project root, and `parent.id` persists durable parent identity. Each Neovim process gets an `instances/<nvim-instance-id>/` directory with Nvim-owned `main.intent.json` and `main-<nvim-instance-id>.sock`. Main-panel launches use that instance socket as the durable Nvim-owned Pi target; the root-level `main.intent.json` mirrors the latest panel request for diagnostics, not cross-instance reuse. When explicit `PI_SOCKET` or buffer-local targets are absent, the instance socket is the automatic fast path.

`:PiSplit` allocates an explicit child session under `children/<child-id>/` with a stable child id, dedicated `child.sock`, and an `intent.json` derived from `registry_base_record`. Child sockets never replace the main registry entry and never become automatic default reconnect targets.

Pinvim peer identity carries `pairId`, `parentId`, `workspaceId`, `instanceId`, `registryRoot`, and `role` (`main`, `child`, or `nested`) in hello frames, acknowledgements, and manifests. The Pi extension mirrors those from PINVIM environment when present and rejects mismatched peers before falling back to tmux or root scoring.

Each Neovim process generates one `pairId` in `Registry.setup` (`nvim-<pid>-<hash>`) and exports it as `vim.env.PINVIM_PAIR_ID`. The pair id flows into `build_peer_identity` (hello frames), `registry_base_record` (main intent records), and `write_nvim_peer_manifest` (Nvim manifests), so `api.info()`, manifests, and main intent records all report the same value. Restarting Neovim produces a new pair id; explicit `:PiSplit` child records reuse the parent registry pair id and never overwrite the main pair identity. `bin/pimux` forwards `PINVIM_PAIR_ID` into the Pi pane at launch, and `pinvim.ts` reads it back via `PINVIM_PAIR_ID` so the launched Pi knows which Neovim owns it.

Pinvim also exposes a separate Neovim editor service over msgpack-RPC. Nvim stores the address in `PINVIM_NVIM_LISTEN_ADDRESS`, peer frames, and manifests, and reports it through `:PiStatus`, `:PiHealth`, `:PiInfo`, `:PiDoctor`, and `api.info()`. The Pi-side client discovers the address from PINVIM env, peer frames, manifests, or registry files; probes with non-blocking msgpack-RPC; and reports connected/stale/fallback state. When no editor service is connected, Pi reports `peer socket only` fallback instead of injecting guessed context. Pi-side timers and sockets use `unref()` so a missing editor address cannot keep short-lived Pi probes alive.

Pi's footer status is intentionally compact: the `pinvim` status emits no footer when no Neovim peer is active, but reports one parseable record for stale or connected peers. The custom footer renders a green Neovim icon for a healthy exact `pairId` link, yellow for a non-exact repaired link, and red for stale peers. Attached context replaces the project label with `filename:line` or `filename:start-end`; repair details stay in `/pinvim-status`, `/pinvim-doctor`, and `/pinvim-info`, not the footer.

### Editor-service RPC surface

The editor-service RPC surface lets Pi query or manipulate the active Neovim editor without tmux guessing.

Pi sends msgpack-RPC `nvim_exec_lua` requests to `require("pinvim").api.editor_rpc(method, params)`; the reusable Pi-side client is `globalThis.pinvimEditorService.query(method, params)`. Supported methods stay small and local-only: `status`, `context.current`, `diagnostics.current`, `open_file`, `reveal_file`, `reload_buffer`, `refresh_diagnostics`, and `checktime`.

After successful Pi `edit` and `write` tool calls, `pinvim.ts` asks the editor service to run `reload_buffer` for the changed path. Clean open buffers refresh from disk; dirty buffers stay dirty and Pi surfaces a conflict warning. `/pinvim-context` prints current context through the same path, and `/pinvim-doctor` plus Nvim-side `:PiDoctor` report registry identity, tmux pane, repair candidate, and editor-service state without new discovery side effects.

`pinvim.ts` also shares Pi socket routing with [[pi-coding-agent#Pi coding agent#Session and routing extensions|Pi tell]]. Incoming `pi.tell.v1` messages are persisted, surfaced, delivered as prompts or follow-ups, and acknowledged with async `tell_ack` messages to the sender's `fromSocket`.

## Pinvim visual selection keymaps

Pinvim visual mappings use Neovim `x` mode, so Lua callbacks may run after Visual mode exits.

Selection capture should first try live Visual state, then fall back to `'<` and `'>` marks plus `visualmode()`. Selection-bearing actions (`gpa`, `gps`, `gpp`, `:PiSend`, `:PiAdd`) route through explicit-send payloads. `gpc` / `:PiComment` capture a selection or cursor line plus a typed annotation into the compose queue; `:PiFlush` renders the whole queue as one prompt. Queued comments place an extmark indicator on the first line; re-running `gpc` on a commented line edits it in place, and empty text deletes it. `:PiComments` loads queued comments into quickfix and opens trouble.nvim's `qflist` when available.

`gpa` and `:PiSend` use `delivery = "attach"`, so Pi stores the latest context and injects it once into the next non-extension user prompt. `gps` uses `delivery = "prompt"`, sending context plus prompt immediately and starting a turn. Normal `gpp` opens or focuses a child Pi split and sends cursor/file context; visual `gpp` sends selection context; child context stays prompt-delivered. `<C-p>` toggles the main PiPanel paired to that Neovim instance, never spawns a child, captures context before the split steals focus, sends it with attach delivery, and does not start a turn by itself.

On restart, main sessions prefer their instance main socket and never auto-resume old ephemeral, child, or other-instance sockets. Explicit `:PiTarget <socket>` remains the manual override.

### Attach-only context delivery

Pinvim attach delivery separates editor context capture from agent-turn creation.

`explicit_send.delivery = "attach"` is context-only: `pinvim.ts` formats it as `[NEOVIM ATTACHED CONTEXT]`, stores only the latest pending context, updates status, and returns without calling `pi.sendUserMessage`. The next non-extension `input` marks the following `before_agent_start` as user-origin; pending context is then consumed exactly once and injected as a displayed custom `pinvim-context` message. If none exists, Pi asks the editor service for `context.current`, formats it as `[NEOVIM LIVE CONTEXT]`, and injects through the same path. Extension-origin prompts and follow-ups never consume pending context or trigger live lookup. Pending state is short-lived: newer attach sends replace older ones, stale context expires, and shutdown clears it.

### Strict pinvim pairing

Normal pinvim links are strictly paired: a Pi session belongs to exactly one Neovim, identified by `pairId`. Live Pi socket state in `pinvim.ts` is the ownership authority; the registry and manifests only mirror it for diagnostics.

**Automatic socket resolution (Nvim side).** `Transport.resolve_socket` resolves in order: explicit `PI_SOCKET`, buffer-local `:PiTarget`, the instance main socket, then manifest-ranked candidates limited to the same tmux session. A manifest-ranked candidate is rejected (`manifest-unpaired`) when both sides carry a `pairId` and they differ, so auto-resolution only adopts the exact pair, the instance main socket, or an explicit target. There is no broad cwd/root manifest adoption in the normal path.

**Pi-side claim rules.** Pi requires a valid `hello` before accepting any data frame, and heartbeats before an accepted hello stay rejected. `peerAllowedForSocket` rejects attach-only nested sessions first, then parent/workspace/instance mismatches, then any `pairId` mismatch with a visible `mismatched pair identity` reason (even from the same tmux window). An exact `pairId` match is always accepted, including non-tmux peers and explicit target mode. Without a pair id, an exact parent/workspace registry match is accepted. A same-window score cannot steal a Pi that is still actively paired with a different live peer: such claims are blocked until the current peer is unpaired, gone, or its heartbeat is stale for more than 20 seconds (`STRICT_PAIR_STALE_SECONDS`).

**Manifest discovery is diagnostic/manual only.** Nvim still writes `nvim-*.info` manifests under `$PI_STATE_DIR/manifests/` every five seconds (now including `pairId`); `VimLeavePre` cleans them up. `pinvim.ts` still scans manifests when no parent registry identity is present and the active peer is missing or stale, but the resulting `repairCandidate` is read-only for diagnostics (`/pinvim-doctor`, `/pinvim-status`) — normal flows never auto-adopt a scanned manifest for pairing. Candidates are still rejected when the pid is dead, the pid is an orphaned `nvim --embed`, the socket path is gone, or the tmux session differs. Pair state, relation (`attach-only`, `child`, `parent`, `no-parent`), and link mode appear in `:PiStatus`, `:PiHealth`, `/pinvim-status`, `/pinvim-health`, `/pinvim-info`, and the doctor commands.

**pimux pair-aware reuse.** `bin/pimux` forwards `PINVIM_PAIR_ID` into the Pi pane and uses it for reuse decisions. `socket_pair_id` probes a socket's manifest `pairId`, and `socket_pair_matches` treats a socket as eligible only when there is no local pair id or the manifest pair id matches. Unknown manifest pair ids are ineligible in strict mode. `candidate_sockets` and `find_any_parked_pi_pane` skip panes paired with a different Neovim, while explicit `--socket` targets identify the current Neovim's instance socket instead of a shared workspace socket.

**Ownership neutrality.** `:PiTarget <socket>` is an explicit manual override: it sets the buffer-local target (checked before pair gating in `resolve_socket`) and never rewrites pair ownership. The shade-next `fill_prompt` remote-input path is ownership-neutral — it only prefills the editor and may focus the pane; it never runs `peerAllowedForSocket`, adds to `acceptedSockets`, claims or reclaims the pair, or auto-submits.

### Strict pairing verification checklist

The automated check is `bin/pinvim-protocol-smoke`, run with `bash bin/pinvim-protocol-smoke`. It boots headless Neovim against a mock Pi socket and fails unless the `hello` peer frame carries a non-empty `pairId`.

Cases covered by code review plus manual tmux verification (no full multi-Neovim UI harness exists):

- Exact pair acceptance — covered by `bin/pinvim-protocol-smoke`.
- Unpaired same-window claim — allowed (no active peer, scoring path).
- Stale > 20s / dead pid — same-window claim allowed once the live peer lapses (`STRICT_PAIR_STALE_SECONDS`).
- Live `pairId` mismatch — rejected with `mismatched pair identity`, even in the same window.
- Other window/session — rejected by `scoreNvimCandidate` session/window gating.
- Non-tmux peer — accepted only by exact `pairId` or explicit target mode.
- `:PiTarget` — explicit override that does not rewrite pair ownership.
- `fill_prompt` — prefills only; no claim, reclaim, or auto-submit.

## Worktree-aware PiReview

`config/nvim/lua/pinvim/review.lua` is the Nvim-side review orchestrator. It detects worktree root, branch, upstream, PR metadata, default base, and ticket id, then opens the right review surface for a requested scope.

`:PiReview [scope]` (registered in `config/nvim/lua/pinvim.lua`) and the `<leader>gr{r,u,b,p,t,w}` keymaps dispatch through `require("pinvim.review").run(scope, opts)`:

- `uncommitted` — `diffs.nvim` repository review against `HEAD`, showing staged, unstaged, and untracked current worktree changes.
- `unpushed` — `diffs.nvim` repository review against `@{u}`; falls back to uncommitted with a warning when no upstream exists.
- `branch` — `diffs.nvim` repository review against the PR base ref, or `origin/main`/`main`/`master` as default base.
- `pr` — `:Guh <pr-url>` via `justinmk/guh.nvim` (`config/nvim/lua/plugins/github.lua`); warns when no PR resolves. `guh.nvim` handles GitHub PR/issue/CI review only; local scopes stay on `diffs.nvim`.
- `ticket` — branch or uncommitted scope with ticket metadata attached.
- `worktrees` — `vim.ui.select` picker over `git worktree list --porcelain`, enriched with dirty/staged/untracked counts from `git -C <path> status --porcelain`; selecting a worktree `tcd`s into it and reruns the chosen scope.

`bin/pireview [scope] [worktree-path]` opens the same review in a new tmux window named `review:<branch-or-ticket>` in the current tmux session, starting Nvim with `+PiReview <scope>`. It scrubs inherited `PI_SOCKET`/`PINVIM_PAIR_ID`/`PINVIM_*` env so the new Nvim never steals another Nvim/Pi pair.

### Review metadata in annotation flushes

`require("pinvim.review").metadata()` returns the active review record or nil when no review is active. The record carries `scope`, `worktree`, `branch`, `upstream`, `base`, `pr`, and `ticket`.

`:PiFlush` prepends a concise `Review scope` header from this record before the queued context and comments, so Pi knows which worktree/diff/ticket the annotations belong to. The existing `gpc`, visual `gpc`, `:PiComment`, `:PiComments`, and `:PiClear` primitives are unchanged outside review mode.

### Pi-side `/piview` and `review.open` RPC

`home/common/programs/pi-coding-agent/extensions/nvim-review.ts` registers the `/piview [scope]` Pi command, distinct from the pre-existing `/review` pi-review-loop (`extensions/review.ts`).

`/piview` queries `globalThis.pinvimEditorService` with method `review.open` and `{ scope, cwd }`; the Nvim editor-service handler in `config/nvim/lua/pinvim.lua` delegates to `require("pinvim.review").run`. `/piview` never checks out branches, snapshots files, or scans manifests; it only targets the active paired Nvim.

`pview [scope]` in `home/common/programs/pi-coding-agent/default.nix` launches Pi with `/piview` as the initial command. It never pre-splits Nvim itself; `/piview` owns the review Nvim spawn to avoid duplicate review panes. If the current tmux window already has multiple panes, `pview` first opens a new tmux window so the review split starts from a clean one-pane layout.

## Pi-initiated review spawn

When no Nvim editor service is connected (bare Pi), `/piview` falls back to spawning a review Nvim that pairs back to the originating Pi, instead of bailing.

`spawnReviewNvim` in `extensions/pinvim.ts` (exposed via `globalThis.pinvimEditorService.spawnReviewNvim`) adopts the target worktree's pinvim registry identity so the incoming Nvim peer passes `peerAllowedForSocket` via `exactParentRegistry`:

- `workspace_id = stableHash16(normalizePath(worktreeRoot))`, replicating Nvim's `stable_hash(normalize_path(resolve_root()))` (`sha256` of the realpath, first 16 hex chars).
- It reads or creates `parent.id` under `$PI_STATE_DIR/pinvim/<workspace_id>/` so the spawned Nvim's `Registry.setup` reuses the same id (Nvim reads the file rather than regenerating).
- It sets `process.env.PINVIM_PARENT_ID` and `PINVIM_WORKSPACE_ID` on the Pi, then `tmux split-window -e PI_SOCKET=... -e PINVIM_PARENT_ID=... -e PINVIM_WORKSPACE_ID=... nvim '+PiReview <scope>'` in the worktree root.

Identity adoption is scoped to the spawn: it only runs when the Pi is unpaired, and re-adopts on each spawn so re-targeting a different worktree works. It never alters bare-pi defaults for an already-paired Pi. The deterministic core (hash parity + `parent.id` reuse) is covered by `bin/pinvim-review-spawn-smoke`; the live tmux spawn + paired round-trip is a human gate.

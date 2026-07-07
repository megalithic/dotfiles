# Pi coding agent

This file covers how Pi is packaged, wrapped, configured, and extended in this repo. The module lives at `home/common/programs/pi-coding-agent/`.

## Parallel mise configuration

`mise/config/pi-coding-agent/` is an independent non-nix twin of the Home Manager module for the staged mise migration (`_mise.toml`, inactive until renamed). It is a copy, not shared source: changes must be mirrored manually while both exist.

The mise tree keeps the same behavior with different mechanics: `agent/` holds the managed subset of `~/.pi/agent` applied through `[dotfiles]` symlink and `symlink-each` entries; `bin/` holds plain-bash ports of the `pi`, `pinvim`, `p`, `pview`, `pi-acp`, and `work-tickets` wrappers linked into `~/.local/bin`; `scripts/setup` is the `pi:setup` mise task covering the imperative pieces (sha256-pinned sesame/plannotator installs into `~/.pi/agent/bin`, jq settings merge, local `npm ci && npm run build` of the vendored pi-acp, extension-deps cleanup, first-run `pi update --extensions`). The `pi` wrapper resolves the CLI through `mise x npm:@earendil-works/pi-coding-agent -- pi`, prefers fnox secrets with an opnix fallback, and applies the same live-view widget patch. Disabled entries live in `disabled/` instead of using the `_` name-prefix convention because `symlink-each` links every entry. Session indexers are declared as `[bootstrap.macos.launchd.agents]` in `_mise.toml`.

The mise dotfiles must not be applied while Home Manager still owns `~/.pi/agent/*`; mise re-points HM symlinks and the next `just home` points them back.

## Package source and wrapper

Pi comes from the `pi-nix` flake input (`inputs.pi-nix.packages.${system}.coding-agent`) and is exposed through `programs.pi.coding-agent.package`.

The local wrapper sets `PI_STATE_DIR`, creates socket, manifest, and pinvim state directories, sources OpNix env secrets from `XDG_CONFIG_HOME` when present, adds the Nix-managed Sesame and Plannotator CLIs, `poppler-utils`, and `rtk` to `PATH`, clears the one-shot `PIMUX_FROM_NVIM` marker, and delegates to the packaged Pi binary. The wrapper also duplicates the OpNix `LAT_LLM_*` derivation so non-interactive launches still get lat search config, prepends `$HOME/.pi/agent/bin` to `PATH` so the patched `lat` binary resolves first, and copies the local `patches/pi-bash-live-view/widget.ts` over the installed `pi-bash-live-view` widget when that package is present.

The main module auto-discovers non-underscore-prefixed local `./packages/*.nix`, `.ts` extensions, extension directories, `./agents/*.md`, skill directories under `./skills/`, and `./prompts/*.md`. Prefixing a path with `_` keeps it in source control while disabling it from the active profile.

## Runtime helper packages

Pi runtime helper packages come from `settings.json` package entries and are refreshed by `pi update --extensions` after `just home`.

Current entries include `npm:pi-mcp-adapter`, `npm:pi-web-access`, `npm:pi-subagents`, `npm:pi-caveman`, `npm:@plannotator/pi-extension`, `npm:pi-rtk-optimizer`, `npm:@aliou/pi-synthetic`, and `github:sethmt/pi-bash-live-view`. The old vendored NPM derivations under `packages/` are removed except for `pi-acp`.

The local `pi-bash-live-view` widget patch makes live PTY panes fit rendered lines by display cell width, preserving ANSI escape sequences while trimming wide glyphs, combining marks, zero-width joiners, and variation selectors before padding to the terminal width. This avoids the one-cell overflow crash seen when live output contains wide glyphs or ANSI-colored truncation edges.

## pi-acp adapter

`pi-acp` is vendored at `home/common/programs/pi-coding-agent/packages/pi-acp/` and built from the vendored tree through `packages/pi-acp.nix`, not `fetchFromGitHub` plus patches.

It is an ACP adapter process, not a Pi runtime extension. The main module excludes `pi-acp.nix` from extension auto-symlinking, installs a wrapper in `home.packages`, and links it to `~/.local/bin/pi-acp` so GUI apps such as Tidewave can use a stable command path. The wrapper sets `PI_ACP_PI_COMMAND` to the Nix-managed Pi wrapper and defaults `PI_ACP_ENABLE_EMBEDDED_CONTEXT=true`, `PI_PROFILE=alt`, and `PI_ACP_MODEL_PREFIXES=alt-anthropic,alt-codex`.

Local adapter modifications include ACP MCP HTTP and SSE support, `acp_`-prefixed MCP mirroring into project `.pi/mcp.json`, session-history reattachment through `~/.pi/pi-acp/session-map.json`, adapter-side handling of headless ACP slash-command UX, model-prefix filtering, and normalization of Tidewave `content` fields into ACP `prompt` fields before SDK validation. Normalized inbound lines must be re-encoded with `TextEncoder().encode()`; `new Uint8Array(string)` silently produced empty chunks and stalled Tidewave on "Connecting…".

## Session and routing extensions

The `/answer` extension can be invoked by its slash command, Ctrl+. shortcut, or the internal `trigger:answer` event. The parked `_execute-command` extension is excluded from Home Manager symlinks until re-enabled.

`multi-sub.ts` owns `/subs`, `/pool`, and multi-sub pool or chain failover. When a rate limit rotates the pool while Pi is still processing the failed turn, retrying the same prompt must use `deliverAs: "steer"` or the core session rejects it as already processing.

The `/goal` extension persists one long-running goal in session custom entries, injects it before agent turns, tracks token and elapsed usage, supports pause/resume/clear, enforces optional token budgets, and exposes `get_goal`, `create_goal`, and `update_goal`. Completion requires evidence-based auditing before `update_goal { status: complete }`.

The `/handoff` extension replaces the old file-backed handoff skill: it serializes branch and session-chain context, asks the selected model for a self-contained next-thread prompt, opens a new session with `parentSession`, and uses `newSession({ withSession })` to leave the prompt in the replacement session editor for manual submission.

`resurrect-tag.ts` tags the surrounding tmux pane with the session UUID (pane option `@pi_session_id`) on every `session_start`. `bin/tmux-resurrect-save-pi` (a tmux-resurrect `save_command_strategy`, symlinked into the plugin by `config/tmux/plugins.tmux.conf`) reads the tag at save time so resurrect restores each pi pane exactly via `pinvim --session <uuid>`, falling back to `pinvim -c` for untagged panes.

The `/tell` extension replaces the shell-script tell skill for Pi-to-Pi guidance. It discovers running Pi instances from `PI_STATE_DIR` socket manifests, uses Pi's selector UI when the target hint is ambiguous, sends `pi.tell.v1` JSON over the existing Pi socket, and exposes the `tell_pi` tool so the receiving instance can reply asynchronously. Incoming tell messages are persisted as custom entries, surfaced near the editor through a temporary widget, and mirrored through the same `~/bin/ntfy` path used by the notify extension.

Tell is bidirectional: the sender includes `id` and `fromSocket` in the `pi.tell.v1` payload, and receivers in both `bridge.ts` and [[neovim-pinvim#Neovim and pinvim|pinvim.ts]] send a fire-and-forget `tell_ack` to that socket with the original id and receiver identity. Ack delivery uses a 500ms timeout, never blocks the receiving socket handler, and shows a sender-side notification when the ack arrives.

The task-pipeline commands use repo-scoped plan files under `~/.local/share/pi/plans/$(basename $PWD)/` and treat GRILL, TASK, PLAN, and ticket-context files as one progression. The `geo-workbench.ts` extension is a no-dependency browser UI for image geolocation that exposes `geo_lookup` and expects agents to call `geo_report`.

Session search has two paths: the legacy local `search_sessions` / `read_session` Pi tools from `search-sessions.ts`, and the Nix-managed Sesame CLI plus `sesame` skill. Home Manager installs `sesame`, writes `~/.config/sesame/config.jsonc` for `~/.pi/agent/sessions`, and runs `sesame-session-indexer` as `sesame watch --interval 30` so the SQLite FTS index stays warm.

### Sentinel guardrail rules

`sentinel.ts` is the single source of truth for Pi command guardrails, including former JSON rule tables.

The extension now bundles interactive-command, always-interactive, and tool-correction tables directly; `extensions/sentinel-rules.json` is no longer installed or read at startup. The bundled tables cover interactive jj, docker, kubectl, Nix REPL, database shells, language REPLs, pagers, editors, and preferred-tool rewrites such as `find` to `fd`, `grep` to `rg`, `rm`/`rmdir` to `trash`, and `git` to `jj` inside jj repos.

Specialized guards stay as code because they need context-specific parsing or side effects: jj editor/message flows, nix-managed writes, unsafe `nix build` output, secret tools and gatekeeper scans before push, push/deploy/ssh confirmation, package install confirmation, investigation-only prompts, and pipe/redirect hang prevention.

The redundant `jj split -i` table rule was removed because the hardcoded `jj-split` rule blocks all `jj split` invocations. The disabled ticket-gate config path was removed with the JSON loader; investigation mode remains and blocks write-capable tool calls plus bash write workarounds for imperative `investigate`, `inspect`, or `audit` prompts unless the prompt includes implementation intent or the user grants the existing `override` flow.

The pipe/redirect guard blocks `bash` commands that pipe or redirect risky upstreams unless the call passes a `timeout` between 1 and 300 seconds.

The local `checkpoint.ts` extension is removed from the active profile; checkpoint and main-branch prompting come from the agent harness instead.

`claude-code-use.ts` is a local fork of `@benvargas/pi-claude-code-use` kept aligned with upstream payload fixes while omitting companion-package auto-loading for packages not used here.

### Claude Code subscription compatibility

`claude-code-use.ts` makes Anthropic OAuth requests look like Claude Code use without loading unused companion packages.

It rewrites Anthropic system prompt text from `pi itself`, `pi .md files`, and `pi packages` to CLI-neutral wording, then filters the outbound payload to Claude Code core tools, Anthropic typed tools, and already-MCP-prefixed tools. The OAuth model check intentionally accepts local `alt-anthropic` providers and `anthropic-messages` API models, not only the literal `anthropic` provider.

The local fork keeps upstream `1.0.4` alias behavior for user-configured tools but drops built-in companion package registration for `pi-exa-mcp` and `pi-firecrawl`. Optional config files at `~/.pi/agent/extensions/pi-claude-code-use.json` or `<cwd>/.pi/extensions/pi-claude-code-use.json` may declare `toolAliases` as `[flatToolName, mcpAliasName]` pairs. Project config replaces the top-level global setting by shallow merge.

Configured aliases are refreshed on `session_start` and `before_agent_start`. When an Anthropic OAuth model is active, aliases are auto-activated alongside their flat tool only if that alias tool already exists; user-selected aliases are preserved. On `message_end`, managed MCP alias `toolCall` names are rewritten back to their flat names before Pi resolves execution, while foreign MCP tools pass through untouched.

`pinvim.ts` accepts `fill_prompt` frames from shade-next, sets the Pi editor text through `ctx.ui.setEditorText`, may focus the owning tmux pane, and never calls `sendUserMessage`, so remote fills cannot auto-submit.

## Runtime settings

`home/common/programs/pi-coding-agent/settings.json` is merged during activation.

It drives default provider, enabled models, terminal behavior, subagent model overrides, and multi-sub presets. The default model list includes current OpenCode Go coding models; the `mega` scope exposes the strongest OpenCode Go options alongside Codex, Synthetic, and local models. The `alt` scope includes current Anthropic Opus, Sonnet, and Haiku aliases; planner, reviewer, and oracle default to the latest Opus alias; worker defaults to the latest Sonnet alias; scout and context-builder keep small-model fallbacks before local `llamacpp/gemma4`. The shell command prefix forces noninteractive git behavior and enables tmux image handling through `PI_TMUX_IMAGES=1`.

`custom-footer.ts` replaces the default footer with a starship-backed cwd line plus compact token and model status. The right side of line 2 shows multi-pass routing as `({preset}){provider-or-failover-pool}/{model}/thinking_level`, derived from the `multi-pass` status string. Caveman status is suppressed and MCP status is reduced to ` {active}/{total}`, turning accent-blue when any server is active.

Extension footer statuses should be semantic and compact because `custom-footer.ts` owns separators, colors, and truncation. `pinvim` publishes no footer text until a Neovim peer is active, then sends a `pinvim.v1` record that the footer renders as ` {basename}` for a healthy link or ` {filename:line}` / ` {filename:start-end}` when attached Neovim context is pending. The icon is green for connected, yellow for a repaired 1:1 link, and red for stale peers.

### MCP reconnect error containment

MCP reconnect failures are contained so repeating server errors do not corrupt Pi's interactive TUI output.

`custom-footer.ts` patches `console.error` only for `MCP: Failed to reconnect to <server>:` messages, writes JSON lines to `~/.local/share/pi/logs/pi-mcp-adapter.log`, and suppresses the original console output. The footer exposes the captured failure through an internal `mcp-error` status rendered as red ` {server} {reason}` next to the compact ` n/N` MCP status. Reasons are short labels such as `conn refused`, `timeout`, `dns failed`, `auth failed`, `auth required`, `fetch failed`, and `sse error`. The red error is hidden once the parsed MCP status reports all configured servers connected.

Local Pi models use the `llamacpp` OpenAI-compatible provider at `http://127.0.0.1:18080/v1` with `llamacpp/qwen3.6`, `llamacpp/deepseek14b`, and `llamacpp/gemma4` aliases instead of Ollama or oMLX. Activation removes redundant `package.json`, `package-lock.json`, and `node_modules` from `~/.pi/agent/extensions` because Pi's own resolver handles deps.

Global MCP server config lives in `mcp.json`: command-backed `chrome-devtools`, remote `context7` with `CONTEXT7_API_KEY`, and remote `githits` with bearer auth from `GITHITS_API_KEY`. Local app-backed MCP servers such as Tidewave and Paper are not declared globally unless they are expected to be running, to avoid reconnect noise.

Pi subagent orchestration comes from the `npm:pi-subagents` package; the old local `extensions/subagent/` implementation and vendored `packages/pi-subagents.nix` derivation are removed.

## Nvim review routing

`extensions/nvim-review.ts` registers `/piview [scope] [diff_mode]`, routing paired Neovim review requests through `review.open` editor-service RPC.

Scopes are `uncommitted`, `unpushed`, `branch`, `pr`, `ticket`, and `worktrees`. Diff modes are `status`, `worktree`, `staged`, `unstaged`, and `range`; they are forwarded as `{ scope, cwd, diff_mode }`.

It is distinct from `extensions/review.ts` (the `/review` pi-review-loop, which performs agent-driven checkout/snapshot reviews). `/piview` only targets the active paired Nvim and never scans manifests or steals pairs; when no editor service is connected (bare Pi) it spawns a review Nvim that pairs back (see [[neovim-pinvim#Neovim and pinvim#Pi-initiated review spawn]]). The Nvim-side handler is documented in [[neovim-pinvim#Neovim and pinvim#Worktree-aware PiReview]].

`pview [scope]` is the shell launcher for `/piview`: in a one-pane tmux window it runs `pinvim "/piview ..."` in place, while in a multi-pane window it opens a new tmux window first so the Pi-initiated review Nvim creates exactly one right-side split. Outside tmux it falls back to plain `p`. Fish completion mirrors the `/piview` scope list.

## Preview command

The Pi `/preview` extension is a thin command parser around the `preview-ai` executable.

It accepts mode flags (`tmux-split`, `tmux-float`, `auto`), auto-close, delta, and HTML options, then forwards them to `preview-ai`. Tmux previews require a tmux session and render in a session-scoped pane or popup; HTML mode opens rendered markdown in a browser. Supported types are JSON, markdown, diff, codediff, log, file, image, command, text, and auto-detect. Task-tracker previews are intentionally unsupported.

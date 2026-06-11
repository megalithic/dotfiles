# Pi coding agent

This file covers how Pi is packaged, wrapped, configured, and extended in this repo. The module lives at `home/common/programs/pi-coding-agent/`.

## Package source and wrapper

Pi comes from the `pi-nix` flake input (`inputs.pi-nix.packages.${system}.coding-agent`) and is exposed through `programs.pi.coding-agent.package`.

The local wrapper sets `PI_STATE_DIR`, creates socket, manifest, and pinvim state directories, sources OpNix env secrets from `XDG_CONFIG_HOME` when present, adds `poppler-utils` and `rtk` to `PATH`, clears the one-shot `PIMUX_FROM_NVIM` marker, and delegates to the packaged Pi binary. The wrapper also duplicates the OpNix `LAT_LLM_*` derivation so non-interactive launches still get lat search config, and prepends `$HOME/.pi/agent/bin` to `PATH` so the patched `lat` binary resolves first.

The main module auto-discovers non-underscore-prefixed local `./packages/*.nix`, `.ts` extensions, extension directories, `./agents/*.md`, skill directories under `./skills/`, and `./prompts/*.md`. Prefixing a path with `_` keeps it in source control while disabling it from the active profile.

## Runtime helper packages

Pi runtime helper packages come from `settings.json` package entries and are refreshed by `pi update --extensions` after `just home`.

Current entries include `npm:pi-mcp-adapter`, `npm:pi-web-access`, `npm:pi-subagents`, `npm:pi-caveman`, `npm:pi-rtk-optimizer`, and `npm:@aliou/pi-synthetic`. The old vendored NPM derivations under `packages/` are removed except for `pi-acp`.

## pi-acp adapter

`pi-acp` is vendored at `home/common/programs/pi-coding-agent/packages/pi-acp/` and built from the vendored tree through `packages/pi-acp.nix`, not `fetchFromGitHub` plus patches.

It is an ACP adapter process, not a Pi runtime extension. The main module excludes `pi-acp.nix` from extension auto-symlinking, installs a wrapper in `home.packages`, and links it to `~/.local/bin/pi-acp` so GUI apps such as Tidewave can use a stable command path. The wrapper sets `PI_ACP_PI_COMMAND` to the Nix-managed Pi wrapper and defaults `PI_ACP_ENABLE_EMBEDDED_CONTEXT=true`, `PI_PROFILE=alt`, and `PI_ACP_MODEL_PREFIXES=alt-anthropic,alt-codex`.

Local adapter modifications include ACP MCP HTTP and SSE support, `acp_`-prefixed MCP mirroring into project `.pi/mcp.json`, session-history reattachment through `~/.pi/pi-acp/session-map.json`, adapter-side handling of headless ACP slash-command UX, model-prefix filtering, and normalization of Tidewave `content` fields into ACP `prompt` fields before SDK validation. Normalized inbound lines must be re-encoded with `TextEncoder().encode()`; `new Uint8Array(string)` silently produced empty chunks and stalled Tidewave on "Connecting…".

## Session and routing extensions

The `/answer` extension can be invoked by its slash command, Ctrl+. shortcut, or the internal `trigger:answer` event. The parked `_execute-command` extension is excluded from Home Manager symlinks until re-enabled.

`multi-sub.ts` owns `/subs`, `/pool`, and multi-sub pool or chain failover. When a rate limit rotates the pool while Pi is still processing the failed turn, retrying the same prompt must use `deliverAs: "steer"` or the core session rejects it as already processing.

The `/goal` extension persists one long-running goal in session custom entries, injects it before agent turns, tracks token and elapsed usage, supports pause/resume/clear, enforces optional token budgets, and exposes `get_goal`, `create_goal`, and `update_goal`. Completion requires evidence-based auditing before `update_goal { status: complete }`.

The `/handoff` extension replaces the old file-backed handoff skill: it serializes branch and session-chain context, asks the selected model for a self-contained next-thread prompt, opens a new session with `parentSession`, and leaves the prompt in the editor for manual submission.

The `/tell` extension replaces the shell-script tell skill for Pi-to-Pi guidance. It discovers running Pi instances from `PI_STATE_DIR` socket manifests, uses Pi's selector UI when the target hint is ambiguous, sends `pi.tell.v1` JSON over the existing Pi socket, and exposes the `tell_pi` tool so the receiving instance can reply asynchronously. Incoming tell messages are persisted as custom entries, surfaced near the editor through a temporary widget, and mirrored through the same `~/bin/ntfy` path used by the notify extension.

Tell is bidirectional: the sender includes `id` and `fromSocket` in the `pi.tell.v1` payload, and receivers in both `bridge.ts` and [[neovim-pinvim#Neovim and pinvim|pinvim.ts]] send a fire-and-forget `tell_ack` to that socket with the original id and receiver identity. Ack delivery uses a 500ms timeout, never blocks the receiving socket handler, and shows a sender-side notification when the ack arrives.

The task-pipeline commands use repo-scoped plan files under `~/.local/share/pi/plans/$(basename $PWD)/` and treat GRILL, TASK, PLAN, and ticket-context files as one progression. The `geo-workbench.ts` extension is a no-dependency browser UI for image geolocation that exposes `geo_lookup` and expects agents to call `geo_report`.

`sentinel.ts` loads rules only from `extensions/sentinel-rules.json` at startup; a copied file with another name is inert until renamed or wired in. The hardcoded pipe/redirect hang guard in `sentinel.ts` blocks `bash` commands that pipe or redirect risky upstreams unless the call passes a `timeout` between 1 and 300 seconds. Investigation mode is also enforced in `sentinel.ts`: prompts containing `investigate`, `inspect`, or `audit` without `and fix`/`then fix` block write-capable tool calls and bash write workarounds until the user grants the same `override` flow used by confirm-tier sentinel rules.

The local `checkpoint.ts` extension is removed from the active profile; checkpoint and main-branch prompting come from the agent harness instead.

`pinvim.ts` accepts `fill_prompt` frames from shade-next, sets the Pi editor text through `ctx.ui.setEditorText`, may focus the owning tmux pane, and never calls `sendUserMessage`, so remote fills cannot auto-submit.

## Runtime settings

`home/common/programs/pi-coding-agent/settings.json` is merged during activation.

It drives default provider, enabled models, terminal behavior, subagent model overrides, and multi-sub presets. The `alt` scope includes the newest Anthropic aliases such as `alt-anthropic/claude-fable-5`; planner, reviewer, and oracle default to the latest Opus alias; worker defaults to the latest Sonnet alias; scout and context-builder keep small-model fallbacks before local `llamacpp/gemma4`. The shell command prefix forces noninteractive git behavior and enables tmux image handling through `PI_TMUX_IMAGES=1`.

`custom-footer.ts` replaces the default footer with a starship-backed cwd line plus compact token and model status. The right side of line 2 shows multi-pass routing as `({preset}){provider-or-failover-pool}/{model}/thinking_level`, derived from the `multi-pass` status string. Caveman status is suppressed and MCP status is reduced to ` {active}/{total}`, turning accent-blue when any server is active.

Local Pi models use the `llamacpp` OpenAI-compatible provider at `http://127.0.0.1:18080/v1` with `llamacpp/qwen3.6`, `llamacpp/deepseek14b`, and `llamacpp/gemma4` aliases instead of Ollama or oMLX. Activation removes redundant `package.json`, `package-lock.json`, and `node_modules` from `~/.pi/agent/extensions` because Pi's own resolver handles deps.

Global MCP server config lives in `mcp.json`: command-backed `chrome-devtools`, remote `context7` with `CONTEXT7_API_KEY`, and remote `githits` with bearer auth from `GITHITS_API_KEY`. Local app-backed MCP servers such as Tidewave and Paper are not declared globally unless they are expected to be running, to avoid reconnect noise.

Pi subagent orchestration comes from the `npm:pi-subagents` package; the old local `extensions/subagent/` implementation and vendored `packages/pi-subagents.nix` derivation are removed.

## Preview command

The Pi `/preview` extension is a thin command parser around the `preview-ai` executable.

It accepts mode flags (`tmux-split`, `tmux-float`, `auto`), auto-close, delta, and HTML options, then forwards them to `preview-ai`. Tmux previews require a tmux session and render in a session-scoped pane or popup; HTML mode opens rendered markdown in a browser. Supported types are JSON, markdown, diff, codediff, log, file, image, command, text, and auto-detect. Task-tracker previews are intentionally unsupported.

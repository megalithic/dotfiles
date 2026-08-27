# Pi coding agent

This file covers how Pi is packaged, wrapped, configured, and extended in this repo. The configuration lives at `mise/config/pi-coding-agent/`.

The former Home Manager module (`home/common/programs/pi-coding-agent/`) and vendored `pi-acp` adapter are removed. Current Home Manager generations claim no Pi files.

## Mise-managed configuration

`mise/config/pi-coding-agent/` is the sole owner of Pi configuration, wired through `mise/config/mise/global_config.toml`.

`mise run up` labels each update phase, writes nested mise debug output to `~/.local/state/mise/up.log`, and prints that path when a phase fails. Dotfile application also enables live verbose output so failing paths remain visible.

`agent/` holds the managed subset of `~/.pi/agent` applied through `[dotfiles]` symlink and `symlink-each` entries; `bin/` holds the `pi`, `p`, and `work-tickets` wrappers linked into `~/.local/bin`; `mise/tasks/pi-update` is the `pi:update` mise task covering the imperative pieces (sha256-pinned Plannotator install into `~/.pi/agent/bin` via `scripts/install-pi-tools`, isolated nicknisi/sessions plugin extraction, jq settings merge, extension-deps cleanup, `pi update`, and `pi update --extensions`). The former `pinvim` and `pview` wrappers remain under `disabled/` and are no longer mapped into `~/.local/bin`; active profile resolution now runs through `scripts/resolve-profile.mjs` from `bin/pi`. `setup:pi` / `pi:setup` remain compatibility wrappers. `pi:update --dry-run` previews helper-bin changes, the final merged settings JSON, cleanup targets, and Pi update commands without modifying files. Disabled entries live in `disabled/` instead of using the `_` name-prefix convention because `symlink-each` links every entry.

`lat` resolves from mise's `npm:lat.md` tool. Mise links `~/.pi/agent/bin/lat` to its stable shim because Pi's lat extension tools launch through that agent-local path; no lat override points back to Devenv.

The managed `agent/extensions/lat.ts` passes arguments directly to `execFileSync`, captures child stderr, and reports command failures through tool results. Its lifecycle hooks stay dormant unless the working tree contains `lat.md/`. LAT diagnostics must never write directly into Pi's alternate-screen TUI because they can overwrite the input editor.

`mise/config/mise/global_config.toml` prefers canonical mise registry aliases for user-facing tools and keeps backend-qualified names only when the registry has no alias or a specific package source is required.

## Package source and wrapper

Pi comes from the mise tool `npm:@earendil-works/pi-coding-agent`; the `bin/pi` wrapper resolves the CLI through `mise x`.

`mise x npm:@earendil-works/pi-coding-agent -- pi` prepends the npm tool's own bin dir, so the real binary wins over the wrapper without recursion.

The wrapper sets `PI_STATE_DIR`, creates socket and manifest state directories, exports `PI_BRIDGE_LEGACY_SOCKET=1` so the generic bridge owns Pi-to-Pi `/tell` ingress, prepends `~/.pi/agent/bin`, `~/.local/bin`, mise shims, and `/opt/homebrew/bin` to `PATH` for launch contexts without shell init, and resolves `mise` plus `fnox` before launch. Its empty-array expansions remain compatible with macOS Bash 3.2 under `set -u`, because the shebang selects Bash before the wrapper can prepend Homebrew to `PATH`. It exports only non-secret `LAT_LLM_*` provider metadata; fnox injects `LAT_LLM_KEY` from the Synthetic alias in `mise/config/fnox/config.toml`. The final handoff is `fnox exec --replace -- mise x npm:@earendil-works/pi-coding-agent -- pi`, so non-shell Pi launches receive secrets without sourcing rendered files. `poppler-utils` stays in nix `home/common/packages.nix` on megabookpro (mise's `brew:poppler` covers workbookpro).

The `git-worktrees` skill checks `wt --version` before managing worktrees. When available, it uses the local `wt` Worktrunk wrapper, Worktrunk JSON queries, `mise` project tasks, and generated `.config/wt.toml` templates; raw `git worktree`, copy loops, and manual tmux layouts stay forbidden. It preserves prior manual instructions in `skills/git-worktrees/references/legacy-git-worktrees.md` and uses that reference unchanged only when `wt` is unavailable.

## Runtime helper packages

Pi runtime helper packages come from `settings.json` package entries and are refreshed by `pi update --extensions` (run by `mise run pi:update`).

Current entries include `npm:pi-mcp-adapter`, `npm:pi-web-access`, `git:github.com/amosblomqvist/pi-interactive-subagents`, `git:github.com/amosblomqvist/pi-observational-memory`, `git:github.com/amosblomqvist/pi-dictate`, `npm:pi-caveman`, `npm:@plannotator/pi-extension`, `npm:pi-rtk-optimizer`, `npm:pi-mono-figma`, `npm:pi-mono-btw`, `npm:context-mode`, `npm:pi-elixir`, `npm:pi-lens`, `nm:@ogulcancelik/pi-ssh-tools`, `npm:@juicesharp/rpiv-ask-user-question`, `npm:@juicesharp/rpiv-todo`, `npm:@ff-labs/pi-fff`, and `npm:@hypabolic/pi-hypa`. The old `npm:pi-subagents` package and its `subagents.agentOverrides` settings are removed; `multiSub` remains separate provider-pool configuration.

Managed `worker`, `researcher`, and `scout` definitions in `agent/agents/` override the package-bundled OpenRouter agents. They intentionally omit static models. The Pi wrapper reads `subagentRouting` from `settings.json` after resolving the active profile, then injects the role's model and thinking level when `PI_SUBAGENT_AGENT` is set; an explicit subagent `model` parameter still wins. The `mega` routes use the live-tested `opencode-go/gpt-5.6-luna`, avoiding DeepSeek V4 Flash's China-hosting opt-in. The `alt` routes preserve the prior Sonnet worker/researcher and Codex Luna scout choices. Restricted children cannot use the `my-codex` clone because the subagent extension starts them with global extension discovery disabled.

Observational memory loads globally but stays off per session until `/om on`; it writes session-scoped `.memory/` data only after enablement. Pi Dictate uses Alt+M to start/stop and Alt+N to cancel, with `brew:sox` providing `rec`; fnox injects `DEEPGRAM_API_KEY` from `op://Crypt/deepgram/api_key` into the Pi wrapper environment. Prompt Snippets is copied as a local managed extension at `agent/extensions/prompt-snippets/` with its README and six adjacent snippet files; Alt+S or `/snippets` opens its one-message toggle menu.

The local `pi-bash-live-view` widget patch (kept at `mise/config/pi-coding-agent/patches/pi-bash-live-view/widget.ts`) makes live PTY panes fit rendered lines by display cell width, preserving ANSI escape sequences while trimming wide glyphs, combining marks, zero-width joiners, and variation selectors before padding to the terminal width. This avoided the one-cell overflow crash seen when live output contains wide glyphs or ANSI-colored truncation edges. The `bin/pi` wrapper no longer copies it over the installed widget at launch; the file remains only as reference in case the upstream regression returns.

The `pi-acp` ACP adapter (vendored package, wrapper, `~/.local/bin/pi-acp` link, and pi-update build step) is deleted entirely, not migrated.

## Session and routing extensions

The `/answer` extension can be invoked by its slash command, Ctrl+. shortcut, or the internal `trigger:answer` event.

Pi fullscreen transcript search (`tui.altScreen.search`) keeps Ctrl+Shift+F; the local `files.ts` Finder reveal action moved to Ctrl+Shift+E so no extension shadows that core binding. `files.ts` still owns Ctrl+Shift+O and Ctrl+Shift+R, and `preview.ts` owns Ctrl+Shift+P.

Turned-off extensions (`execute-command`, `pinvim`, and `nvim-review`) live under `disabled/` until re-enabled; the pinvim end-to-end test skill lives there too. Neovim-side pinvim source remains in place, but ordinary Pi no longer loads its socket polling, editor-service RPC, footer updates, or review command.

`multi-sub.ts` owns `/subs`, `/pool`, and multi-sub pool or chain failover. When a rate limit rotates the pool while Pi is still processing the failed turn, retrying the same prompt must use `deliverAs: "steer"` or the core session rejects it as already processing.

As of pi-coding-agent 0.83.x, subscription clones are registered as **native pi-ai `Provider` objects**. The extension loader only aliases four pi-ai specifiers for extensions (`@earendil-works/pi-ai` → `dist/compat.js`, `/compat`, `/oauth` (types-only), `/providers/all`); any other subpath such as `auth/oauth/load` fails to resolve. `registerSub` therefore looks up the builtin provider via `builtinProviders()` from `@earendil-works/pi-ai/providers/all` and calls `pi.registerProvider({...base, id, name, auth: { oauth: base.auth.oauth }, getModels, refreshModels: undefined })`. Clones are OAuth-only (no api-key env fallback, so an env key doesn't make every clone look configured), credentials are stored per provider id so each clone logs in separately, and cloned models carry `provider: <clone name>`. `registerSub`/`cloneModels` are sync; activate-time registration clones the static builtin catalog, and `session_start` re-registers with registry-composed models. Preset entries must use the same canonical model ids exposed by the registry and scope lists, for example `gpt-5.6-sol` rather than `gpt-sol-5.6`.

Earlier, as of pi-coding-agent 0.80.x (pi-ai 0.80.8), the extension was migrated to the then-new SDK APIs:

- **OAuth login flows removed**: pi-ai 0.80.8 removed `anthropicOAuthProvider`, `loginAnthropic`, `refreshAnthropicToken`, and all other runtime OAuth helpers from `@earendil-works/pi-ai/oauth`. `/subs login` points users at pi's built-in `/login`; `/subs logout` works best-effort through the private `ModelRuntime.logout()` behind `ModelRegistry`.
- **Google providers dropped**: `google-gemini-cli` and `google-antigravity` are no longer supported (pi-ai 0.80 dropped those OAuth providers entirely). `PROVIDER_TEMPLATES` now only includes `anthropic`, `openai-codex`, and `github-copilot`, each with just a `displayName` field.
- **`getModels` removed**: pi-ai 0.80 removed the standalone `getModels(provider)` export. All call sites now use `ctx.modelRegistry.getAll().filter((m) => m.provider === provider)` for built-in model lookups.
- **`ModelRegistry.authStorage` removed**: the old `authStorage` property on `ModelRegistry` is gone. A `getAuthStorage(registry)` adapter mimics the old sync interface for the extension and `PoolManager`: `hasAuth` via `getProviderAuthStatus(provider).configured`, `get` always returns `undefined` (no sync credential access), `logout` best-effort via the private `ModelRuntime.logout()`. `collectQuotaAccounts` is async and fills access tokens with `getApiKeyForProvider()`, so the codex quota checker still authenticates; `accountId`/`projectId`/`expires` metadata is no longer available (codex falls back to JWT claims).
- **Quota checker**: only `codexQuotaChecker` remains. Google Gemini and Antigravity quota checkers and all Google-specific helper functions/constants/types were removed (~650 lines).
- **`cloneModels` and `registerSub`**: accept `Model<Api>[]` and `ModelRegistry | undefined` params respectively. With `undefined` (activate time) the static builtin catalog is used.
- **Cross-extension auth sharing**: the scoped/named auth groups (sub entries, pools) are stored in `settings.json` under `multiSub` and cached in `_cachedSubs`. The extension exposes this via the `/subs` command surface and the `PoolManager` class.

The `/goal` extension persists one long-running goal in session custom entries, injects it before agent turns, tracks token and elapsed usage, supports pause/resume/clear, enforces optional token budgets, and exposes `get_goal`, `create_goal`, and `update_goal`. Completion requires evidence-based auditing before `update_goal { status: complete }`.

The `/handoff` extension replaces the old file-backed handoff skill: it serializes branch and session-chain context, asks the selected model for a self-contained next-thread prompt, opens a new session with `parentSession`, and uses `newSession({ withSession })` to leave the prompt in the replacement session editor for manual submission.

`agent-status.ts` publishes this pi's coarse activity state (`idle`/`working`/`asking`/`done`) to `$PI_STATE_DIR/status/pi-{session}-{window}.status` (line `state pid session`) from lifecycle events (`agent_start`, `agent_end`, `input`, `tool_call`/`tool_execution_end` for `ask_user_question`, `error`), modeled on fleet's hook approach. Only interactive tmux pis publish (`ctx.hasUI` + `TMUX`); the file is removed on `session_shutdown` and readers must pid-validate to skip crash leftovers. `bin/ftm` reads these files for its picker status dots.

`resurrect-tag.ts` tags the surrounding tmux pane with the session UUID (pane option `@pi_session_id`) on `session_start` and clears it on `session_shutdown`. Both ftm snapshots and tmux-resurrect use the tag to restore the exact Pi conversation as `pi --session <uuid>`; no restore command invokes pinvim.

The `/tell` extension replaces the shell-script tell skill for Pi-to-Pi guidance. It discovers running Pi instances from `PI_STATE_DIR` socket manifests, ignores ephemeral/dead manifest entries and non-responsive socket-only fallbacks, sends `pi.tell.v1` JSON over the generic `bridge.ts` socket, and exposes the `tell_pi` tool so the receiving instance can reply asynchronously. `bin/pi` enables this bridge directly; bridge has no pinvim heartbeat, peer scan, footer status, or Neovim protocol handling. Incoming tell messages are persisted as custom entries, surfaced near the editor through a temporary widget, and mirrored through the same `~/bin/ntfy` path used by the notify extension.

`/tell` accepts `machine target message` as a remote form, for example `/tell megabookpro mega do something`. Remote routing SSHes to the machine, resolves that machine's `${PI_STATE_DIR:-~/.local/state/pi}/sockets/pi-{session}-{window}.sock`, prefers `agent` then `0` then the first non-ephemeral socket for session-only targets, and sends the same `pi.tell.v1` payload. Local machine prefixes such as `/tell workbookpro mega ...` are normalized back to local target routing. Remote tell payloads omit `fromSocket`; replies use the generated `/tell <origin-machine> <origin-session:window> ...` hint instead of socket ack.

Bridge socket paths follow `${PI_STATE_DIR}/sockets/pi-{session}-{window}.sock`, but macOS limits `sun_path` to 104 bytes and `net.Server.listen()` throws `EINVAL` past it. All three path builders — `agent/extensions/bridge.ts` (`buildSocketPath`), `agent/extensions/tell.ts` (`buildSocketPath`), and `mise/config/hammerspoon/lib/interop/pi.lua` (`socketName`) — share one deterministic shortening scheme: when the full path would exceed 103 bytes, truncate the `{session}-{window}` name to fit and append `-` plus the first 8 hex chars of its sha256. The scheme must stay byte-identical across TS (`node:crypto`) and Lua (`hs.hash.SHA256`) or senders resolve the wrong socket. Tmux identity detection in bridge.ts and tell.ts passes `-t "$TMUX_PANE"` to `tmux display-message`; without it tmux reports the client's active window, which made two Pi instances in one session bind the same socket.

Tell target resolution is fail-closed. Explicit targets must confidently match a reachable live candidate; missing, ambiguous, or busy/unreachable targets return an error instead of falling back. Non-interactive tool calls never open selector UI and report reachable non-current candidates. The originating/current instance is excluded from implicit selection and from loose target matches, preventing loopback; only an exact self target can select it.

Tell is bidirectional: the sender includes `id` and `fromSocket` in the `pi.tell.v1` payload, and the active `bridge.ts` receiver sends a fire-and-forget `tell_ack` to that socket with the original id and receiver identity. The turned-off pinvim receiver keeps equivalent code for any future re-enable. Ack delivery uses a 500ms timeout, never blocks the receiving socket handler, and shows a sender-side notification when the ack arrives.

The task-pipeline commands use repo-scoped plan files under `~/.local/share/pi/plans/$(basename $PWD)/` and treat GRILL, TASK, PLAN, and ticket-context files as one progression. The `geo-workbench.ts` extension is a no-dependency browser UI for image geolocation that exposes `geo_lookup` and expects agents to call `geo_report`.

Session recall uses the `sessions` CLI/MCP server (`github:nicknisi/sessions` mise tool), which indexes Claude Code, Codex, Pi, and OpenCode transcripts on demand for fuzzy resume, context primers, usage reports, and memory mining. No separate Sesame database, local `search_sessions` extension, or launchd indexer is required.

The sessions tool is wired without running `sessions setup` against the real home: setup unconditionally wires every detected client (Claude Code, Cursor, Codex, Pi) and would rewrite the tab-indented managed `mcp.json` with 2-space JSON through the symlink. Instead the `mcpServers.sessions` entry is hand-maintained in `agent/mcp.json`, and `mise run pi:update` extracts the embedded plugin with `SESSIONS_HOME=<throwaway> SESSIONS_DATA_DIR=$HOME/.local/share/sessions sessions setup` (no clients detected under the fake home, so only the plugin copy runs). Its six skills (`context`, `memory`, `recall`, `session-metrics`, `standup`, `weekly-summary`) are exposed to Pi as `sessions-*` symlinks in `agent/skills/` pointing at `~/.local/share/sessions/plugin/skills/*`; re-run the fake-home setup after `mise upgrade` of the sessions tool to refresh them.

### Sentinel guardrail rules

`extensions/sentinel.ts` is active because `agent/extensions/` is `symlink-each`-linked into `~/.pi/agent/extensions`.

Sentinel is the runtime rule source for Pi command guardrails, replacing the former JSON rule file. `extensions/sentinel-rules.json` is no longer installed or read. Debug logging is opt-in through `PI_SENTINEL_DEBUG_LOG` or `PI_SENTINEL_DEBUG`; it writes to a file instead of stdout/stderr so guardrail messages cannot corrupt the TUI editor. When enabled, startup logs 14 conceptual classifier rules instead of expanding every interactive command and preferred-tool entry into separate runtime rules.

The classifier rules are `hard-interactive`, `hard-vcs-editor`, `hard-managed-config-write`, `hard-nix-build-result`, `hard-destructive-system-rm`, `hard-secret-tools`, `hard-gatekeeper-secrets`, `confirm-security-sensitive-bash`, `confirm-remote-effects`, `confirm-package-install`, `confirm-history-destructive`, `confirm-tcc-reset`, `rewrite-preferred-tools`, and `rewrite-builtin-grep`.

The bundled tables still feed those classifiers for interactive jj, Docker, Kubernetes, Nix REPL, database shells, language REPLs, pagers, editors, and preferred-tool rewrites. Rewrites include `find` to `fd`, `grep` to `rg`, `rm`/`rmdir` to `trash`, and `python -m json.tool` to `jq`. Sentinel no longer rewrites `git` to `jj`.

Sentinel has three rule tiers: hard blocks cannot be overridden, confirm blocks can be retried after an explicit override, and rewrite blocks force a preferred tool or safer pattern. The `/sentinel on` and `/sentinel off` commands toggle all Sentinel guardrails for the current session; turning it off clears pending blocked and override state and prepends a red `` marker to the chat input editor until re-enabled. Confirm overrides are single-use, expire after 120s, and are tied to the exact command or write path; `override`, `bypass`, or `force` open UI confirmation when available, while `!override`, `!bypass`, `!force`, and `!!` grant immediately for the last blocked confirm rule.

Sentinel uses a shell-aware parser before rule matching. It strips quoted strings and heredocs, unwraps environment assignments, `sudo`, `command`, `env`, shell `-c` wrappers including `bash -c --`, command substitutions, absolute command paths, and simple `xargs` command forms. This keeps preferred-tool rewrites and safety confirms effective for wrapper forms such as `command grep`, `env grep`, `/bin/grep`, `sudo -n grep`, and `sh -c 'grep ...'`; it remains a UX guardrail, not an OS sandbox.

Specialized guards stay as code because they need context-specific parsing, filesystem checks, or side effects: VCS editor/message flows, managed or symlinked config writes, unsafe `nix build` output, destructive system-removal hard blocks, secret tools and gatekeeper scans before push, security-sensitive bash confirms, sensitive-path write confirms, session write/execute correlation, push/deploy/ssh confirmation, package install confirmation, investigation-only prompts, and pipe/redirect hang prevention. The managed-config guard blocks broad managed config prefixes and symlinks that resolve into `/nix/store/` or `~/.dotfiles/`, steering writes to the owning source path.

Security-sensitive bash confirms cover remote pipe execution through `curl` or `wget`, privilege escalation via `sudo` including absolute paths, persistence hooks, shell-config writes, and system binary installs. Sensitive-path write confirms use path-specific override keys so one approved `write` or `edit` cannot grant a later different path.

Session write/execute correlation records allowed `write`/`edit` targets and asks for override before executing a session-written script whose current contents contain risky patterns such as `curl | bash`, `eval`, recursive delete, `chmod 777`, `sudo`, or persistence hooks. Direct execution (`./script` or absolute path) and shell execution (`sh script`) both resolve against the current working directory before checking the session registry.

Investigation mode remains a guardrail outside the rule table. Prompts that start as imperative `investigate`, `inspect`, `audit`, or `check` block write-capable tool calls plus bash write workarounds unless the prompt includes implementation intent or the user grants the existing override flow.

The pipe/redirect guard blocks `bash` commands that pipe or redirect risky upstreams unless the tool call passes a `timeout` between 1 and 300 seconds. Database shell guards allow explicit noninteractive query forms such as `psql -c`, `mysql -e`, and `sqlite3 DB SQL` while still blocking interactive shells, and editor commands are treated as interactive even when passed file paths.

Package-install confirms cover Homebrew, global package installs, project dependency installs, and one-shot runners such as `npx` and `bunx`; installs under the managed Pi package source directory are allowed so local extension package work can run `npm install` without override. Push, deploy, SSH/SCP/remote-rsync, broad history-changing jj commands, and destructive Git history commands remain confirm-only so the agent cannot perform remote side effects or destructive history changes without explicit user approval.

The local `checkpoint.ts` extension is removed from the active profile; checkpoint and main-branch prompting come from the agent harness instead.

`claude-code-use.ts` is a local fork of `@benvargas/pi-claude-code-use` that renames extension tools on the wire instead of dropping them, omitting companion-package auto-loading for packages not used here.

### Claude Code subscription compatibility

`claude-code-use.ts` makes Anthropic OAuth requests look like Claude Code use without loading unused companion packages.

It rewrites Anthropic system prompt text from `pi itself`, `pi .md files`, and `pi packages` to CLI-neutral wording. Instead of filtering unknown flat tools out of the outbound payload (upstream `1.0.4` behavior), it renames them to `mcp__pi__<name>` so they pass Anthropic's OAuth tool-name classifier while staying visible to the model — the approach from `@zgltyq/pi-provider-claude`. Claude Code core tools, Anthropic typed tools, and already-MCP-prefixed tools pass through untouched; `tool_choice` and historical `tool_use` blocks are remapped to match. The OAuth model check intentionally accepts local `alt-anthropic` providers and `anthropic-messages` API models, not only the literal `anthropic` provider.

On `message_end`, `mcp__pi__*` `toolCall` names are stripped back to their flat names before Pi resolves execution, while foreign MCP tools pass through untouched. The former `toolAliases` config (`pi-claude-code-use.json`) and alias auto-activation are removed: renaming keeps every extension tool visible, so user-maintained alias maps are unnecessary. `PI_CLAUDE_CODE_USE_DISABLE_TOOL_FILTER=1` now disables renaming (flat names pass through), and `PI_CLAUDE_CODE_USE_DEBUG_LOG` still captures before/after payloads.

The turned-off `disabled/extensions/_pinvim.ts` retains the former shade-next `fill_prompt` handling for future reference, but ordinary Pi no longer loads that path.

## Web-search config and agent dir

`web-search.json` (exa provider, non-interactive `auto-summary` curation workflow) is one source file linked to every path pi-web-access may resolve: `~/.pi/web-search.json`, `~/.pi/agent/web-search.json`, and `~/.config/pi/web-search.json`.

The source is `mise/config/pi-coding-agent/web-search.json` (`[dotfiles]` mappings). pi-web-access resolves its config dir as `PI_CODING_AGENT_DIR`, then `$XDG_CONFIG_HOME/pi`, then `~/.pi`, while pi core defaults to `~/.pi/agent` — an unset var plus `XDG_CONFIG_HOME` is how a stray `~/.config/pi/web-search.json` once shadowed the managed config and re-enabled interactive search curation.

`PI_CODING_AGENT_DIR=~/.pi/agent` is set globally through the mise global config `[env]` so extension config resolution matches pi core's default.

## Runtime settings

`mise/config/pi-coding-agent/agent/settings.json` is merged into `~/.pi/agent/settings.json` by `mise run pi:update` (jq deep merge), never symlinked — pi rewrites the runtime file.

It drives default provider, enabled models, terminal behavior, package loading, and multi-sub presets. The default model list includes current OpenCode Go coding models; the `mega` scope exposes the strongest OpenCode Go options alongside Codex, Synthetic, and local models. The `alt` scope includes current Anthropic Opus, Sonnet, and Haiku aliases; planner, reviewer, and oracle default to the latest Opus alias; worker defaults to the latest Sonnet alias; scout and context-builder keep small-model fallbacks before local `llamacpp/gemma4`. The shell command prefix forces noninteractive git behavior and enables tmux image handling through `PI_TMUX_IMAGES=1`.

`custom-footer.ts` replaces the default footer with a starship-backed cwd line plus compact token and model status. The right side of line 2 shows multi-pass routing as `({preset}){provider-or-failover-pool}/{model}/thinking_level`, derived from the `multi-pass` status string. Caveman status is suppressed and MCP status is reduced to `{active}/{total}`, turning accent-blue when any server is active.

Extension footer statuses should be semantic and compact because `custom-footer.ts` owns separators, colors, and truncation. Its legacy `pinvim.v1` formatter is inert while pinvim is turned off because no active extension publishes that status.

### MCP reconnect error containment

MCP reconnect failures are contained so repeating server errors do not corrupt Pi's interactive TUI output.

`custom-footer.ts` patches `console.error` only for `MCP: Failed to reconnect to <server>:` messages, writes JSON lines to `~/.local/share/pi/logs/pi-mcp-adapter.log`, and suppresses the original console output. The footer exposes the captured failure through an internal `mcp-error` status rendered as red ` {server} {reason}` next to the compact ` n/N` MCP status. Reasons are short labels such as `conn refused`, `timeout`, `dns failed`, `auth failed`, `auth required`, `fetch failed`, and `sse error`. The red error is hidden once the parsed MCP status reports all configured servers connected.

Local Pi models use the `llamacpp` OpenAI-compatible provider at `http://127.0.0.1:18080/v1` with `llamacpp/qwen3.6`, `llamacpp/deepseek14b`, and `llamacpp/gemma4` aliases instead of Ollama or oMLX. Activation removes redundant `package.json`, `package-lock.json`, and `node_modules` from `~/.pi/agent/extensions` because Pi's own resolver handles deps.

Global MCP server config lives in `mcp.json`: command-backed `chrome-devtools`, remote `context7` with `CONTEXT7_API_KEY`, remote `githits` with bearer auth from `GITHITS_API_KEY`, command-backed `mise`, and stdio `sessions` (`sessions --mcp`, the nicknisi/sessions cross-tool session search/memory server). Local app-backed MCP servers such as Tidewave and Paper are not declared globally unless they are expected to be running, to avoid reconnect noise.

The `chrome-cdp` skill probes `CDP_PORT`, `CDP_PORT_FILE`, Helium's default port `9223`, then known browser `DevToolsActivePort` files. Each port is validated through `/json/version`, so stale port files do not block discovery.

Pi subagent orchestration comes from `git:github.com/amosblomqvist/pi-interactive-subagents`. It provides tmux-pane async subagents plus bundled `scout`, `researcher`, and `worker` definitions; the old `npm:pi-subagents` package-specific settings are deleted during managed settings merge.

## Nvim review routing

`nvim-review.ts` now lives at `disabled/extensions/_nvim-review.ts` (turned off), so `/piview` and its paired editor-service RPC route are inactive. Neovim-side review source remains for a future re-enable.

Scopes are `uncommitted`, `unpushed`, `branch`, `pr`, `ticket`, and `worktrees`. Diff modes are `status`, `worktree`, `staged`, `unstaged`, and `range`; they are forwarded as `{ scope, cwd, diff_mode }`.

It is distinct from `extensions/review.ts` (the `/review` pi-review-loop, which performs agent-driven checkout/snapshot reviews). `/piview` only targets the active paired Nvim and never scans manifests or steals pairs; when no editor service is connected (bare Pi) it spawns a review Nvim that pairs back (see [[neovim-pinvim#Pi-initiated review spawn]]). The Nvim-side handler is documented in [[neovim-pinvim#Worktree-aware PiReview]].

The former `pview` shell launcher now lives under `disabled/bin/` and is no longer linked into `~/.local/bin`.

## Preview command

The Pi `/preview` extension is a thin command parser around the `preview-ai` executable.

It accepts mode flags (`tmux-split`, `tmux-float`, `auto`), auto-close, delta, and HTML options, then forwards them to `preview-ai`. Tmux previews require a tmux session and render in a session-scoped pane or popup; HTML mode opens rendered markdown in a browser. Supported types are JSON, markdown, diff, codediff, log, file, image, command, text, and auto-detect. Task-tracker previews are intentionally unsupported.

# Pi coding agent - mise-managed configuration

Pi configuration for both hosts, applied through `config/mise/config.toml`
(`[dotfiles]`, `[bootstrap.macos.launchd.agents]`, `update:pi` task).

## Directory layout

```text
home/.pi/
├── agent/               # Managed subset of ~/.pi/agent (linked via [dotfiles])
│   ├── AGENTS.md        # Global agent instructions (was sources/GLOBAL_AGENTS.md)
│   ├── APPEND_SYSTEM.md # Additions to Pi's default system prompt
│   ├── keybindings.json
│   ├── models.json      # Custom model/provider definitions
│   ├── mcp.json         # Global MCP server config
│   ├── settings.json    # Writable source linked to ~/.pi/agent/settings.json
│   ├── configs/         # Extension configs (session-name.json: LLM session titles)
│   ├── extensions/      # .ts extensions (symlink-each into ~/.pi/agent/extensions)
│   ├── skills/          # Skill directories (symlink-each)
│   ├── prompts/         # Prompt templates (symlink-each)
│   └── agents/          # Custom agent .md definitions (symlink-each)
├── scripts/             # Helper installers and setup scripts (not deployed)
└── tests/               # Bun test suites (not deployed)
```

The `pi` and `work-tickets` wrappers live in `home/.local/bin/`.

## Conventions

- Disable an extension, skill, prompt, or agent by prefixing its filename or
  directory with `_`. Their `symlink-each` mappings exclude `_*` path
  components and remove previously managed runtime links on the next apply.
- `agent/settings.json` is linked to `~/.pi/agent/settings.json`. Pi and extension
  settings changes write through to this tracked file. Auth, sessions, installed
  packages, and separate extension state stay outside the repo.
- Plannotator is version+sha256 pinned in `scripts/install-pi-tools` and lands
  in `~/.pi/agent/bin`.
- The `pi` wrapper resolves the actual CLI with `mise which`, runs it under
  `mise x npm:@earendil-works/pi-coding-agent`, injects secrets with
  `fnox exec --replace`, and exports non-secret `LAT_LLM_*` metadata. The
  live-view widget patch is reference-only and is not applied at launch.
- `agent/APPEND_SYSTEM.md` is the only append file. Pi uses a project
  `.pi/APPEND_SYSTEM.md` instead of it, never with it, so template bootstraps
  (`config/mise/tmpls/elixir/scripts/bootstrap-pi.sh`) write generated guidance
  to the gitignored `<project>/.pi/AGENTS.md`. `extensions/project-guidance.ts`
  adds that file to the project context on every run. Disable it with
  `PI_PROJECT_GUIDANCE_DISABLE=1`.
- Extensions that add prompt text set a named
  `event.systemPromptOptions.sections.<name>` (or push to `contextFiles`) in
  `before_agent_start`. Returning `systemPrompt` forces the whole prompt and
  drops changes from extensions that load later.

## Applying

```sh
mise run update:dotfiles               # symlinks (agent files, bin wrappers)
mise run update:pi                     # tools and runtime updates
mise bootstrap launchd apply           # user agents
```

# Pi coding agent - mise-managed configuration

Sole owner of pi configuration (the former Home Manager twin at
`home/common/programs/pi-coding-agent/` was removed when megabookpro moved
onto the mise-managed setup).

Nothing here applies automatically. Application happens through
`config/mise/config.toml` (`[dotfiles]`,
`[bootstrap.macos.launchd.agents]`, `update:pi` task) once that config is active.

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
│   ├── extensions/      # .ts extensions (symlink-each into ~/.pi/agent/extensions)
│   ├── skills/          # Skill directories (symlink-each)
│   ├── prompts/         # Prompt templates (symlink-each)
│   └── agents/          # Custom agent .md definitions (symlink-each)
├── bin/                 # Wrappers linked into ~/.local/bin: pi, p, work-tickets
├── scripts/             # Helper installers and setup scripts
├── patches/             # Reference patches kept for upstream regressions
└── disabled/            # Turned-off wrappers, scripts, and archival files that
                         # are not deployed through agent/* symlink-each mappings
```

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

## Applying

```sh
mise bootstrap dotfiles apply          # symlinks (agent files, bin wrappers)
mise run update:pi                     # tools and runtime updates
mise bootstrap launchd apply           # user agents (currently skipped on
                                       # megabookpro; other com.megadots agents
                                       # would duplicate nix-run services)
```

# Pi Coding Agent — mise-managed configuration

Sole owner of pi configuration (the former Home Manager twin at
`home/common/programs/pi-coding-agent/` was removed when megabookpro moved
onto the mise-managed setup).

Nothing here applies automatically. Application happens through
`config/mise/config.toml` (`[dotfiles]`,
`[bootstrap.macos.launchd.agents]`, `update:pi` task) once that config is active.

## Directory layout

```text
pi-coding-agent/
├── agent/               # Managed subset of ~/.pi/agent (linked via [dotfiles])
│   ├── AGENTS.md        # Global agent instructions (was sources/GLOBAL_AGENTS.md)
│   ├── SYSTEM.md
│   ├── keybindings.json
│   ├── models.json      # Custom model/provider definitions
│   ├── mcp.json         # Global MCP server config
│   ├── settings.json    # NOT linked — merged by mise/scripts/update-pi via jq
│   ├── extensions/      # .ts extensions (symlink-each into ~/.pi/agent/extensions)
│   ├── skills/          # Skill directories (symlink-each)
│   ├── prompts/         # Prompt templates (symlink-each)
│   └── agents/          # Custom agent .md definitions (symlink-each)
├── bin/                 # Wrappers linked into ~/.local/bin: pi, p, work-tickets
├── scripts/             # Helper installers and setup scripts
├── patches/             # pi-bash-live-view widget patch (applied by bin/pi)
└── disabled/            # Turned-off wrappers, scripts, and archival files that
                         # are not deployed through agent/* symlink-each mappings
```

## Conventions

- Disable an extension, skill, prompt, or agent by prefixing its filename or
  directory with `_`. Their `symlink-each` mappings exclude `_*` path
  components and remove previously managed runtime links on the next apply.
- `agent/settings.json` is a merge source, never a symlink target — pi rewrites
  `~/.pi/agent/settings.json` at runtime.
- Plannotator is version+sha256 pinned in `scripts/install-pi-tools` and lands
  in `~/.pi/agent/bin`.
- The `pi` wrapper resolves the actual CLI via
  `mise x npm:@earendil-works/pi-coding-agent -- pi`, sources fnox secrets,
  derives `LAT_LLM_*`, and applies the live-view widget patch.

## Applying

```sh
mise bootstrap dotfiles apply          # symlinks (agent files, bin wrappers)
mise run update:pi                     # tools, settings merge, runtime updates
mise bootstrap launchd apply           # user agents (currently skipped on
                                       # megabookpro; other com.megadots agents
                                       # would duplicate nix-run services)
```

# Pi Coding Agent — mise-managed configuration

Non-nix twin of `home/common/programs/pi-coding-agent/` (the Home Manager
module). Both trees are **independent copies**: while the nix setup is still
active, changes must be mirrored manually to whichever tree you actually run.

Nothing here applies automatically. Application happens through the repo-root
`_mise.toml` (`[dotfiles]`, `[bootstrap.macos.launchd.agents]`, `pi:setup`
task) once that config is activated.

## Directory layout

```
pi-coding-agent/
├── agent/               # Managed subset of ~/.pi/agent (linked via [dotfiles])
│   ├── AGENTS.md        # Global agent instructions (was sources/GLOBAL_AGENTS.md)
│   ├── APPEND_SYSTEM.md
│   ├── keybindings.json
│   ├── models.json      # Custom model/provider definitions
│   ├── mcp.json         # Global MCP server config
│   ├── settings.json    # NOT linked — merged by scripts/setup via jq
│   ├── extensions/      # .ts extensions (symlink-each into ~/.pi/agent/extensions)
│   ├── skills/          # Skill directories (symlink-each)
│   ├── prompts/         # Prompt templates (symlink-each)
│   └── agents/          # Custom agent .md definitions (symlink-each)
├── bin/                 # Wrappers linked into ~/.local/bin: pi, pinvim, p,
│                        # pview, pi-acp, work-tickets
├── scripts/             # setup (pi:setup task), install-pi-tools,
│                        # merge-settings.sh, indexer entrypoints, resolver
├── packages/pi-acp/     # Vendored ACP adapter; built locally by pi:setup
├── patches/             # pi-bash-live-view widget patch (applied by bin/pi)
└── disabled/            # Parked entries (former `_`-prefixed files/dirs).
                         # Move back into agent/* to re-enable.
```

## Conventions

- Disabling an extension/skill: move it into `disabled/` (the nix tree uses a
  `_` name prefix instead; here `symlink-each` would link `_` entries, so they
  must live outside `agent/`).
- `agent/settings.json` is a merge source, never a symlink target — pi rewrites
  `~/.pi/agent/settings.json` at runtime.
- Helper binaries (sesame, plannotator) are version+sha256 pinned in
  `scripts/install-pi-tools` and land in `~/.pi/agent/bin`.
- The `pi` wrapper resolves the actual CLI via
  `mise x npm:@earendil-works/pi-coding-agent -- pi`, sources fnox (or legacy
  opnix) secrets, derives `LAT_LLM_*`, and applies the live-view widget patch.

## Applying

```sh
mise bootstrap dotfiles apply          # symlinks (agent files, bin wrappers)
mise run pi:setup                      # tools, settings merge, pi-acp build
mise bootstrap macos launchd-agents apply  # session indexers
```

Do not apply the dotfiles while Home Manager still owns `~/.pi/agent/*`: mise
re-points HM symlinks, and the next `just home` points them back. Cut over one
machine at a time.

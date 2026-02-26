# config/nvim/ — Neovim configuration

## Overview

Lua-based Neovim config using **lazy.nvim** for plugin management. This config is **out-of-store** (symlinked via `linkConfig`), so changes take effect immediately without nix rebuild.

Nix provides: the neovim package, LSP servers, treesitter parsers, and runtime dependencies.
Lua provides: all configuration, keymaps, and plugin specs.

## Structure

```
init.lua              # Entry point: loads config modules
lazy-lock.json        # Plugin version lockfile

lua/
  config/
    globals.lua       # Global variables, leader key, providers
    options.lua       # vim.opt settings
    keymaps.lua       # Global key mappings
    autocmds.lua      # Autocommands
    commands.lua      # User commands
    lazy.lua          # lazy.nvim bootstrap and setup
    utils.lua         # Utility functions
    icons.lua         # Icon definitions
    
  plugins/
    init.lua          # Plugin index (loads all plugin specs)
    lsp.lua           # LSP configuration
    blink.lua         # Completion (blink.cmp)
    fzf-lua.lua       # Fuzzy finder
    git.lua           # Jujutsu/git integration (fugitive, gitsigns)
    ai.lua            # AI tools (copilot, etc.)
    claudecode.lua    # Claude Code integration
    ...               # One file per plugin or plugin group

  colors/             # Colorscheme definitions
```

## Plugin pattern

Each file in `lua/plugins/` returns a lazy.nvim spec:

```lua
-- lua/plugins/example.lua
return {
  "author/plugin-name",
  event = "VeryLazy",  -- or "BufRead", "InsertEnter", etc.
  dependencies = { "other/plugin" },
  opts = {
    -- Plugin options
  },
  config = function(_, opts)
    require("plugin-name").setup(opts)
    -- Additional setup
  end,
  keys = {
    { "<leader>x", "<cmd>PluginCommand<cr>", desc = "Do thing" },
  },
}
```

## LSP setup

LSP servers are configured in `lua/plugins/lsp.lua`:

- **mason.nvim** installs LSP servers to `$XDG_DATA_HOME/lsp/mason`
- **mason-lspconfig** bridges mason and nvim-lspconfig
- **nvim-lspconfig** configures individual servers

### Adding a new LSP

1. Add to `ensure_installed` list in `lua/plugins/lsp.lua`
2. Add server config if needed (most use defaults)

```lua
-- In lua/plugins/lsp.lua ensure_installed table:
"new-language-server",

-- If custom config needed, add to server_configs:
new_server = {
  settings = { ... }
}
```

### LSP from Nix

Some LSPs come from Nix (e.g., elixir-ls, nil). These are in PATH via nix shell/profile.
Mason handles the rest.

## Completion

Using **blink.cmp** (`lua/plugins/blink.lua`):

- Sources: LSP, snippets, buffer, path
- Configured for fast, non-blocking completion

## Keymaps

Global keymaps in `lua/config/keymaps.lua`.
Plugin-specific keymaps in each plugin spec's `keys` table.

**Leader key:** `<Space>` (set in globals.lua)

**Common patterns:**
- `<leader>f*` — Find/fuzzy (fzf-lua)
- `<leader>g*` — Jujutsu/git operations
- `<leader>l*` — LSP
- `<leader>c*` — Code actions

## Treesitter

Parsers are mostly provided by Nix (`pkgs.vimPlugins.nvim-treesitter.withAllGrammars`).
Config in `lua/plugins/treesitter.lua`.

## AI integration

Multiple AI plugins available:
- `claudecode.lua` — Claude Code integration
- `codecompanion.lua` — Multi-model chat
- `ai.lua` — Copilot and other AI tools

## Common tasks

### Add a new plugin

1. Create `lua/plugins/myplugin.lua`
2. Return a lazy.nvim spec
3. Restart editor or run `:Lazy sync`

### Add a new language

1. LSP: Add server to `ensure_installed` in `lua/plugins/lsp.lua`
2. Treesitter: Usually automatic (Nix provides parsers)
3. Formatting: Add to `lua/plugins/conform.lua`
4. Linting: Add to `lua/plugins/lint.lua`

### Debug plugin loading

```vim
:Lazy profile         " See load times
:Lazy health          " Check plugin status
:checkhealth          " Full health check
```

### Update plugins

```vim
:Lazy update          " Update all plugins
:Lazy sync            " Sync with lockfile
```

## Nix integration

Nix handles:
- Editor package (`pkgs.nvim-nightly` or `pkgs.neovim`)
- Python/Node/Ruby providers for plugins
- Some LSP servers (elixir-ls, nil, etc.)
- Treesitter parsers

Config in `home/common/programs/nvim.nix`:
```nix
programs.neovim = {
  enable = true;
  package = pkgs.nvim-nightly;
  extraPackages = with pkgs; [ ... ];
};
```

The config directory is symlinked:
```nix
xdg.configFile."nvim".source = config.lib.mega.linkConfig "nvim";
```

## Key files to understand

| File | Why it matters |
|------|---------------|
| `init.lua` | Entry point, load order |
| `lua/config/lazy.lua` | Plugin manager bootstrap |
| `lua/config/keymaps.lua` | All global keybindings |
| `lua/plugins/lsp.lua` | LSP server configuration |
| `lua/config/utils.lua` | Helper functions used everywhere |

## Obsidian.nvim + Shade integration

This nvim config integrates with **Shade** (a floating terminal for notes) and **obsidian.nvim**
for a quick-capture workflow. The integration involves multiple components:

### Architecture

```
Hammerspoon (hotkeys) → Shade (Swift app) → Neovim (nvim RPC) → obsidian.nvim
     ↓                       ↓                    ↓
 context.json          context gathering     template substitution
```

### Key files

| File | Purpose |
|------|---------|
| `lua/plugins/obsidian.lua` | obsidian.nvim config, templates, substitutions |
| `lua/config/autocmds.lua` | Auto-link captures to daily note on save |
| `~/.local/state/shade/context.json` | Capture context (app, URL, selection) |
| `$NOTES_HOME/templates/*.md` | Note templates with substitution variables |

### obsidian.nvim fork

This config uses **obsidian-nvim/obsidian.nvim** (community fork), NOT the original
epwalsh/obsidian.nvim. The API has significant differences:

```lua
-- OLD API (epwalsh, deprecated)
local client = require("obsidian").get_client()
client:today()  -- DOES NOT WORK

-- NEW API (obsidian-nvim)
local daily = require("obsidian.daily")
daily.today()  -- Creates today's daily note with template
```

### Template substitutions

Custom substitutions defined in `lua/plugins/obsidian.lua`:

| Variable | Description |
|----------|-------------|
| `{{date_id}}` | YYYYMMDD format for IDs |
| `{{timestamp}}` | ISO8601 timestamp |
| `{{migrated_tasks}}` | Incomplete tasks from previous daily note |
| `{{yesterday_link}}` | Wiki link to previous daily note |
| `{{capture_context}}` | Callout with app/URL/file info |
| `{{capture_selection}}` | Selected text as code block |
| `{{image_filename}}` | For image captures |

### Context file schema

Shade writes context to `~/.local/state/shade/context.json`:

```json
{
  "appType": "browser|terminal|editor|communication|other",
  "appName": "Brave Browser Nightly",
  "bundleID": "com.brave.Browser.nightly",
  "windowTitle": "GitHub - user/repo",
  "url": "https://github.com/user/repo",
  "selection": "selected text here",
  "detectedLanguage": "lua",
  "timestamp": "2026-02-26T09:30:00"
}
```

### Capture workflow

1. User triggers capture (Hyper+Shift+N via Hammerspoon)
2. If Shade not running: Hammerspoon writes bootstrap context, launches Shade
3. Shade gathers full context from target app (selection, URL, etc.)
4. Shade writes context.json
5. Shade sends nvim RPC to open capture template
6. obsidian.nvim creates note with template substitutions reading context.json
7. On save, autocmd appends link to today's daily note

### Daily note auto-linking (autocmds.lua)

When saving a capture note, the autocmd:
1. Extracts the date from capture filename (YYYYMMDDHHMM-descriptor.md)
2. Ensures daily note exists (calls `require("obsidian.daily").today()` if needed)
3. Appends a timestamped wiki link to the daily note's "## Captures" section

### Debugging

```lua
-- Check if obsidian.nvim is loaded
:lua print(vim.inspect(package.loaded["obsidian"]))

-- Test daily note creation
:lua require("obsidian.daily").today()

-- Check context file
:!cat ~/.local/state/shade/context.json

-- Check template substitutions
:ObsidianTemplate capture-text
```

### Common issues

| Issue | Cause | Fix |
|-------|-------|-----|
| `attempt to call field 'today' (a nil value)` | Using old client API | Use `require("obsidian.daily").today()` |
| Context shows Shade as appName | Cold start timing race | Ensure Hammerspoon writes bootstrap context |
| Template variables not substituted | Context file missing/malformed | Check `~/.local/state/shade/context.json` |
| Daily note not created | NOTES_HOME not set | Set `NOTES_HOME` env var |

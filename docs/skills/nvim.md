---
name: nvim
description: Quick reference for working with the neovim configuration in this dotfiles repo. Covers directory structure, plugin patterns, LSP setup, keybinding conventions, and the mega.* global utilities.
tools: Bash, Read, Edit
---

# Neovim Config Quick Reference

## Directory Structure

```
config/nvim/
├── init.lua              # Entry point - loads config modules
├── lazy-lock.json        # Plugin version lock file
├── lua/
│   ├── config/           # Core configuration
│   │   ├── globals.lua   # mega.* global utilities (CHECK THIS)
│   │   ├── options.lua   # vim.opt settings
│   │   ├── keymaps.lua   # Global keybindings
│   │   ├── autocmds.lua  # Autocommands
│   │   ├── commands.lua  # User commands
│   │   ├── lazy.lua      # lazy.nvim bootstrap
│   │   ├── icons.lua     # Icon definitions
│   │   └── utils.lua     # Utility functions
│   ├── plugins/          # Plugin specs (lazy.nvim format)
│   │   ├── init.lua      # Plugin loader
│   │   ├── lsp.lua       # LSP client config
│   │   ├── blink.lua     # Completion (blink.cmp)
│   │   ├── fzf-lua.lua   # Fuzzy finder
│   │   ├── git.lua       # Git integration
│   │   ├── ai.lua        # AI plugins
│   │   └── ...
│   ├── colors/           # Colorscheme utilities
│   └── shade.lua         # Shade.app integration
├── plugin/
│   └── lsp/              # LSP server configs
│       ├── init.lua      # LSP setup orchestration
│       ├── servers.lua   # Per-server configurations
│       ├── diagnostics.lua
│       └── rename.lua
├── after/plugin/         # Post-load customizations
│   ├── statusline.lua
│   ├── statuscolumn.lua
│   └── ...
└── colors/
    └── megaforest.lua    # Custom colorscheme
```

## Global Utilities (`mega.*`)

Defined in `lua/config/globals.lua`, available everywhere:

```lua
-- Logging
mega.D(...)           -- Debug print with file:line info
mega.echo(msg, hl)    -- Echo message
mega.echom(msg, hl)   -- Echo with history

-- Inspection
mega.I(obj)           -- vim.inspect alias
mega.L               -- vim.log.levels alias

-- LSP utilities
mega.lsp.*           -- LSP-related helpers

-- UI
mega.ui.colors       -- Color definitions
mega.ui.theme        -- Theme utilities
```

## Plugin Manager (lazy.nvim)

### Adding a New Plugin

Create/edit file in `lua/plugins/<name>.lua`:

```lua
return {
  "author/plugin-name",
  event = "LazyFile",  -- or "VeryLazy", "BufReadPre", etc.
  dependencies = { "other/plugin" },
  opts = {
    -- plugin options
  },
  config = function(_, opts)
    require("plugin-name").setup(opts)
  end,
}
```

### Plugin Patterns

| Event | When |
|-------|------|
| `LazyFile` | Custom event: BufReadPre/Post/NewFile/WritePre |
| `VeryLazy` | After UI loads |
| `BufReadPre` | Before reading buffer |
| `InsertEnter` | Entering insert mode |

### Local Plugin Development

Plugins from `megalithic/*` are loaded from `~/code/` (see `lazy.lua` dev config).

## LSP Configuration

### Server Setup (`plugin/lsp/servers.lua`)

Each server is a function returning config or `false`:

```lua
expert = function()
  if not U.lsp.is_enabled_elixir_ls("expert") then return false end
  
  return {
    manual_install = true,
    cmd = { "expert", "--stdio" },
    filetypes = { "elixir", "eelixir", "heex", "surface" },
    root_markers = { "mix.exs", ".git" },
  }
end,
```

### Adding a New LSP Server

1. Add server function to `plugin/lsp/servers.lua`
2. Ensure binary is available (via Nix in `home/programs/nvim.nix`)
3. Server auto-registers if function returns config

### LSP Keybindings

Typically in `lua/plugins/lsp.lua` or via `on_attach`:
- `gd` - Go to definition
- `gr` - References
- `K` - Hover
- `<leader>rn` - Rename
- `<leader>ca` - Code action

## Completion (blink.cmp)

Config in `lua/plugins/blink.lua`. Uses:
- LSP completions
- Snippets (LuaSnip)
- Path completion
- Buffer words

## Keybinding Conventions

| Prefix | Purpose |
|--------|---------|
| `<leader>` | Primary actions (space) |
| `g` | "Go to" operations |
| `[` / `]` | Previous/next navigation |
| `<C-*>` | Control shortcuts |
| `<M-*>` | Alt/Meta shortcuts |

## Colorscheme

- Primary: `megaforest` (custom everforest variant)
- Colors defined in `lua/colors/` and `colors/megaforest.lua`
- Set via `vim.g.colorscheme` in init.lua

## Common Tasks

### Check if plugin is loaded
```lua
if package.loaded["plugin-name"] then ... end
```

### Get plugin config
```lua
local config = require("lazy.core.config").plugins["plugin-name"]
```

### Reload module during development
```lua
package.loaded["module.name"] = nil
require("module.name")
```

### Debug LSP
```lua
:LspInfo           -- Show attached clients
:LspLog            -- View LSP logs
vim.lsp.set_log_level("debug")
```

## Files to Check First

| Task | File |
|------|------|
| Global keybindings | `lua/config/keymaps.lua` |
| Vim options | `lua/config/options.lua` |
| Plugin config | `lua/plugins/<plugin>.lua` |
| LSP servers | `plugin/lsp/servers.lua` |
| Colorscheme | `colors/megaforest.lua` |
| Statusline | `after/plugin/statusline.lua` |

## Related

- **nvim agent**: Spawn for deep debugging/exploration
- **Lazy.nvim docs**: https://lazy.folke.io/

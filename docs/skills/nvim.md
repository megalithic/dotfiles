---
name: nvim
description: Comprehensive guide for Neovim configuration in this dotfiles repo. Covers plugin management, LSP debugging, treesitter, keymaps, performance, and troubleshooting decision trees.
tools: Bash, Read, Edit
---

# Neovim Configuration Guide

## Overview

This config uses lazy.nvim for plugin management, native LSP, treesitter for syntax, and blink.cmp for completion. Everything is Lua-based.

**CRITICAL**: Before making changes:
1. Verify NO LSP/diagnostic errors
2. Test changes with `:Lazy reload <plugin>` before full restart
3. Check `:checkhealth` after major changes
4. Performance matters - startup time should be <100ms

## Directory Structure

```
config/nvim/
├── init.lua                 # Entry point - loads config modules
├── lazy-lock.json           # Plugin version lock (don't edit manually)
├── lua/
│   ├── config/              # Core configuration
│   │   ├── globals.lua      # mega.* global utilities (CHECK THIS)
│   │   ├── options.lua      # vim.opt settings
│   │   ├── keymaps.lua      # Global keybindings
│   │   ├── autocmds.lua     # Autocommands
│   │   ├── commands.lua     # User commands
│   │   ├── lazy.lua         # lazy.nvim bootstrap
│   │   ├── icons.lua        # Icon definitions
│   │   ├── utils.lua        # Utility functions
│   │   └── interop.lua      # External app integration (Shade)
│   ├── plugins/             # Plugin specs (lazy.nvim format)
│   │   ├── init.lua         # Plugin loader
│   │   ├── lsp.lua          # LSP client config
│   │   ├── blink.lua        # Completion (blink.cmp)
│   │   ├── fzf-lua.lua      # Fuzzy finder
│   │   ├── git.lua          # Git integration
│   │   ├── ai.lua           # AI plugins (codecompanion, etc.)
│   │   ├── treesitter.lua   # Syntax highlighting
│   │   └── ...              # Other plugins
│   ├── colors/              # Colorscheme utilities
│   │   ├── init.lua         # Color system
│   │   ├── hl.lua           # Highlight definitions
│   │   └── everforest.lua   # Base colors
│   └── shade.lua            # Shade.app integration
├── plugin/
│   └── lsp/                 # LSP server configs
│       ├── init.lua         # LSP setup orchestration
│       ├── servers.lua      # Per-server configurations
│       ├── diagnostics.lua  # Diagnostic settings
│       └── rename.lua       # Rename utilities
├── after/plugin/            # Post-load customizations
│   ├── statusline.lua       # Status line
│   ├── statuscolumn.lua     # Sign/number column
│   ├── filetypes.lua        # Filetype overrides
│   └── ...
└── colors/
    └── megaforest.lua       # Custom colorscheme
```

## Global Utilities (`mega.*`)

Defined in `lua/config/globals.lua`, available everywhere:

```lua
-- Debug printing with file:line info
mega.D(...)              -- Print with location (like P() but better)

-- Logging levels alias
mega.L                   -- vim.log.levels (INFO, WARN, ERROR, etc.)

-- Inspect alias
mega.I                   -- vim.inspect

-- Echo helpers
mega.echo(msg, hl)       -- Echo without history
mega.echom(msg, hl)      -- Echo with history

-- LSP utilities
mega.lsp.*               -- LSP-related helpers

-- UI
mega.ui.colors           -- Color definitions
mega.ui.theme            -- Theme utilities
```

## Decision Tree: What to Check When Things Break

### "Plugin not loading"

```
1. Is plugin in lazy-lock.json?
   └─ Check: cat ~/.config/nvim/lazy-lock.json | rg "plugin-name"
   └─ If not: Run :Lazy sync

2. Is plugin spec correct?
   └─ Check: lua/plugins/<plugin>.lua
   └─ Verify: return statement, dependencies, event triggers

3. Is the event/condition met?
   └─ Common events: VeryLazy, LazyFile, BufReadPre, InsertEnter
   └─ Check: :Lazy show <plugin> to see load condition

4. Is there an error?
   └─ Check: :Lazy log
   └─ Check: :messages

5. Is it disabled?
   └─ Check for: enabled = false, cond = function() return false end
```

### "LSP not working"

```
1. Is LSP server installed?
   └─ Check: :LspInfo
   └─ Check: which <server-binary> (e.g., which lua-language-server)

2. Is server configured for this filetype?
   └─ Check: plugin/lsp/servers.lua for filetypes
   └─ Verify: :set ft? shows expected filetype

3. Is server starting?
   └─ Check: :LspLog (look for errors)
   └─ Check: :lua print(vim.inspect(vim.lsp.get_clients()))

4. Is root directory detected?
   └─ Check: :lua print(vim.lsp.buf.list_workspace_folders())
   └─ Verify: root_markers in server config match project structure

5. Is capability supported?
   └─ Check: :lua print(vim.inspect(vim.lsp.get_clients()[1].server_capabilities))
```

### "Completion not appearing"

```
1. Is blink.cmp loaded?
   └─ Check: :Lazy show blink.cmp

2. Is LSP attached?
   └─ Check: :LspInfo

3. Is completion triggering?
   └─ Try: <C-Space> to manually trigger
   └─ Check: :lua print(require('blink.cmp').is_visible())

4. Are sources configured?
   └─ Check: lua/plugins/blink.lua for sources

5. Is there a debounce issue?
   └─ Try typing slower, or check debounce settings
```

### "Treesitter not highlighting"

```
1. Is parser installed?
   └─ Check: :TSInstallInfo
   └─ Install: :TSInstall <language>

2. Is highlighting enabled?
   └─ Check: :lua print(vim.treesitter.highlighter.active[vim.api.nvim_get_current_buf()])

3. Is filetype correct?
   └─ Check: :set ft?
   └─ Treesitter uses filetype to pick parser

4. Is there a parser error?
   └─ Check: :TSPlayground (see parse errors)
   └─ Check: :InspectTree

5. Is highlight group defined?
   └─ Check: :Inspect (cursor on text)
```

### "Keybinding not working"

```
1. Is keybinding defined?
   └─ Check: :verbose map <key>
   └─ Check: lua/config/keymaps.lua

2. Is it shadowed by plugin?
   └─ Check: :map <key> (shows all mappings)
   └─ Plugin mappings often override global ones

3. Is it buffer-local?
   └─ Check: :verbose map <buffer> <key>
   └─ LSP keymaps are often buffer-local

4. Is mode correct?
   └─ n = normal, i = insert, v = visual, x = visual block
   └─ Use :nmap, :imap, :vmap to check specific modes
```

### "Neovim slow / high startup time"

```
1. Profile startup:
   └─ nvim --startuptime /tmp/startup.log
   └─ cat /tmp/startup.log | sort -k2 -n | tail -20

2. Check lazy loading:
   └─ :Lazy profile
   └─ Look for plugins loading at startup that shouldn't

3. Find slow plugin:
   └─ :Lazy show (check load times)

4. Check LSP:
   └─ LSP indexing can be slow on large projects
   └─ :LspLog for timing info

5. Check treesitter:
   └─ Large files can be slow
   └─ Try: :TSDisable highlight
```

## Plugin Management (lazy.nvim)

### Plugin Spec Structure

```lua
return {
  "author/plugin-name",          -- GitHub repo

  -- Loading conditions (pick one)
  event = "LazyFile",            -- Load on file events
  cmd = "CommandName",           -- Load on command
  keys = { "<leader>x" },        -- Load on keypress
  ft = "lua",                    -- Load for filetype
  lazy = true,                   -- Manual load only

  -- Dependencies
  dependencies = { "other/plugin" },

  -- Configuration
  opts = {                       -- Passed to setup()
    setting = "value",
  },

  -- Or custom config
  config = function(_, opts)
    require("plugin-name").setup(opts)
  end,

  -- Conditional loading
  enabled = function()
    return vim.fn.executable("some-binary") == 1
  end,
  cond = function()
    return not vim.g.vscode
  end,
}
```

### Common Events

| Event | When |
|-------|------|
| `VeryLazy` | After UI loads, idle |
| `LazyFile` | Custom: BufReadPre/Post/NewFile |
| `BufReadPre` | Before reading file |
| `BufReadPost` | After reading file |
| `InsertEnter` | Entering insert mode |
| `CmdlineEnter` | Entering command mode |
| `LspAttach` | LSP client attaches |

### Managing Plugins

```vim
:Lazy                   " Open lazy.nvim UI
:Lazy sync              " Install/update/clean all
:Lazy update            " Update plugins
:Lazy clean             " Remove unused
:Lazy restore           " Restore to lock file
:Lazy profile           " Show startup profile
:Lazy log               " Show log
:Lazy show <plugin>     " Show plugin info
:Lazy reload <plugin>   " Reload plugin config
```

### Lock File Management

```bash
# Check plugin versions
cat ~/.config/nvim/lazy-lock.json | jq .

# Restore specific plugin version
# Edit lazy-lock.json, then :Lazy restore

# Update lock file (after :Lazy update)
# Lock file auto-updates

# Diff lock changes
jj diff lazy-lock.json
```

## LSP Configuration

### Adding a New LSP Server

1. **Install the server** (via Nix in `home/programs/nvim.nix`):
   ```nix
   home.packages = with pkgs; [ lua-language-server ];
   ```

2. **Add server config** in `plugin/lsp/servers.lua`:
   ```lua
   M = {
     lua_ls = {
       settings = {
         Lua = {
           workspace = { checkThirdParty = false },
           telemetry = { enable = false },
         },
       },
     },
   }
   ```

3. **Rebuild** (just rebuild) and restart nvim

### Server Configuration Options

```lua
server_name = {
  -- Basic settings
  cmd = { "server-binary", "--stdio" },
  filetypes = { "lua", "luau" },
  root_markers = { ".git", "stylua.toml" },

  -- Custom capabilities
  capabilities = {
    textDocument = {
      completion = { ... },
    },
  },

  -- Server-specific settings
  settings = {
    ServerName = {
      option = "value",
    },
  },

  -- On attach hook
  on_attach = function(client, bufnr)
    -- Custom keymaps, etc.
  end,

  -- Skip mason
  manual_install = true,
},
```

### LSP Debugging

```vim
:LspInfo                " Show attached clients
:LspLog                 " View LSP logs
:LspRestart             " Restart LSP
:LspStop                " Stop LSP
:LspStart               " Start LSP

" Check capabilities
:lua print(vim.inspect(vim.lsp.get_clients()[1].server_capabilities))

" Check attached clients
:lua print(vim.inspect(vim.lsp.get_clients()))

" Verbose logging
:lua vim.lsp.set_log_level("debug")
```

### Common LSP Issues

| Issue | Cause | Fix |
|-------|-------|-----|
| Server not starting | Binary not found | Check `which <server>` |
| No completions | Capability not enabled | Check server_capabilities |
| Wrong root directory | root_markers not matched | Add markers to config |
| Slow indexing | Large project | Add to ignore patterns |
| Duplicate diagnostics | Multiple servers | Disable one |

## Treesitter Configuration

### Parser Management

```vim
:TSInstall <lang>       " Install parser
:TSInstallInfo          " Show installed parsers
:TSUpdate               " Update all parsers
:TSUninstall <lang>     " Remove parser
```

### Treesitter Modules

```lua
-- In lua/plugins/treesitter.lua
require("nvim-treesitter.configs").setup({
  ensure_installed = { "lua", "vim", "markdown" },

  highlight = {
    enable = true,
    disable = function(lang, buf)
      local max_filesize = 100 * 1024  -- 100 KB
      local ok, stats = pcall(vim.loop.fs_stat, vim.api.nvim_buf_get_name(buf))
      if ok and stats and stats.size > max_filesize then
        return true
      end
    end,
  },

  indent = { enable = true },

  textobjects = {
    select = {
      enable = true,
      keymaps = {
        ["af"] = "@function.outer",
        ["if"] = "@function.inner",
      },
    },
  },
})
```

### Treesitter Debugging

```vim
:InspectTree            " Show syntax tree
:Inspect                " Show highlight groups at cursor
:TSPlayground           " Interactive tree view (if installed)
:TSHighlightCapturesUnderCursor  " Show captures

" Check parser health
:checkhealth nvim-treesitter
```

## Keybinding Conventions

### Prefix System

| Prefix | Purpose |
|--------|---------|
| `<leader>` | Primary actions (space) |
| `g` | "Go to" operations (gd, gr, gi) |
| `[` / `]` | Previous/next navigation |
| `<C-*>` | Control shortcuts |
| `<M-*>` | Alt/Meta shortcuts |
| `<leader>l` | LSP actions |
| `<leader>g` | Git actions |
| `<leader>f` | Find/search |

### Checking Keybindings

```vim
:verbose map <key>      " Show where mapping is defined
:map                    " All mappings
:nmap                   " Normal mode mappings
:imap                   " Insert mode mappings
:vmap                   " Visual mode mappings

" Search mappings
:filter /pattern/ map
```

## Performance Optimization

### Startup Profiling

```bash
# Generate startup log
nvim --startuptime /tmp/startup.log

# Analyze
cat /tmp/startup.log | sort -k2 -n | tail -20

# Profile specific script
nvim --cmd 'profile start /tmp/profile.log' --cmd 'profile file *' +qa
```

### lazy.nvim Profiling

```vim
:Lazy profile           " Show plugin load times

" In lazy config
opts = {
  performance = {
    rtp = {
      disabled_plugins = {
        "gzip", "tarPlugin", "tohtml", "tutor", "zipPlugin",
      },
    },
  },
},
```

### Common Performance Issues

| Issue | Cause | Fix |
|-------|-------|-----|
| Slow startup | Too many plugins at start | Use lazy loading |
| Slow typing | Complex statusline/autocmds | Debounce or simplify |
| Large file slow | Treesitter on big files | Disable for large files |
| LSP slow | Indexing entire project | Configure root/ignore |

## Debugging Commands

```bash
# Check neovim health
nvim +checkhealth

# Start without config
nvim --clean

# Start with minimal config
nvim -u NORC

# Run headless command
nvim --headless -c "lua print('test')" -c "qa"

# Profile startup
nvim --startuptime /tmp/startup.log file.lua

# Debug specific plugin
nvim -c "Lazy load plugin-name" -c "lua print('loaded')"
```

### In-Editor Debugging

```vim
" Messages/errors
:messages

" Verbose mode
:set verbose=9
:set verbosefile=/tmp/nvim-verbose.log

" Lua debugging
:lua print(vim.inspect(someTable))
:lua mega.D(someTable)

" Check option value
:set option?
:lua print(vim.o.option)

" Check variable
:echo g:variable
:lua print(vim.g.variable)

" Autocmd debugging
:autocmd BufReadPost
:verbose autocmd BufReadPost
```

## Discovering Neovim Capabilities

### List Available APIs

```lua
-- All vim.* namespaces
for k, v in pairs(vim) do
  if type(v) == "table" then
    print("vim." .. k)
  end
end

-- Check vim.lsp methods
for k, v in pairs(vim.lsp) do print(k, type(v)) end

-- Check vim.treesitter methods
for k, v in pairs(vim.treesitter) do print(k, type(v)) end
```

### Key vim.* Namespaces

| Namespace | Purpose |
|-----------|---------|
| `vim.api` | Neovim API functions |
| `vim.fn` | Vimscript functions |
| `vim.lsp` | LSP client |
| `vim.treesitter` | Treesitter API |
| `vim.diagnostic` | Diagnostics |
| `vim.keymap` | Keymap management |
| `vim.opt` | Options |
| `vim.g` / `vim.b` | Global/buffer variables |
| `vim.fs` | Filesystem utilities |
| `vim.loop` / `vim.uv` | Libuv bindings |
| `vim.json` | JSON encode/decode |
| `vim.iter` | Iterator utilities |
| `vim.lpeg` | LPeg patterns |

### Reading Neovim Source

```bash
# Clone for reference
git clone https://github.com/neovim/neovim.git /tmp/nvim-source

# Search runtime files
rg "function" /tmp/nvim-source/runtime/lua/vim/

# Check built-in LSP
cat /tmp/nvim-source/runtime/lua/vim/lsp.lua

# Check treesitter
cat /tmp/nvim-source/runtime/lua/vim/treesitter.lua
```

## Known Issues and Limitations

### Neovim Limitations

| Limitation | Reason | Workaround |
|------------|--------|------------|
| No true async UI | Single-threaded | Use vim.schedule |
| LSP can block | Sync requests | Use async methods |
| Large file slow | In-memory buffer | Use `large_file` plugin |
| No native fuzzy | Need plugin | Use fzf-lua, telescope |

### Common Plugin Conflicts

| Conflict | Plugins | Fix |
|----------|---------|-----|
| Duplicate completions | Multiple completion sources | Disable duplicates |
| Statusline fights | Multiple statusline plugins | Keep only one |
| Keymap conflicts | Multiple plugins same key | Remap one |
| Highlight overrides | Colorscheme vs plugin | Load order matters |

### Version-Specific Features

```lua
-- Check Neovim version
local version = vim.version()
if version.major >= 0 and version.minor >= 10 then
  -- Use 0.10+ features
end

-- Check for feature
if vim.lsp.inlay_hint then
  -- Inlay hints available (0.10+)
end
```

## Files to Check First

| Symptom | Check This File |
|---------|-----------------|
| Global keybindings | `lua/config/keymaps.lua` |
| Vim options | `lua/config/options.lua` |
| Plugin config | `lua/plugins/<plugin>.lua` |
| LSP servers | `plugin/lsp/servers.lua` |
| Colorscheme | `colors/megaforest.lua` |
| Statusline | `after/plugin/statusline.lua` |
| Autocommands | `lua/config/autocmds.lua` |
| Commands | `lua/config/commands.lua` |
| Global utils | `lua/config/globals.lua` |

## Self-Discovery Pattern

When you don't know if Neovim can do something:

```
1. Check if API exists:
   └─ :lua print(vim.api.nvim_* ~= nil)
   └─ :help nvim_<TAB>

2. Check help:
   └─ :help feature-name
   └─ :help api

3. Check runtime:
   └─ :echo $VIMRUNTIME
   └─ Look in runtime/lua/vim/

4. Search GitHub:
   └─ https://github.com/neovim/neovim/issues

5. Check plugins:
   └─ https://github.com/rockerBOO/awesome-neovim

6. Ask community:
   └─ https://github.com/neovim/neovim/discussions
   └─ r/neovim
```

## Related Resources

- **nvim Agent**: Spawn for deep debugging/exploration
- **Lazy.nvim Docs**: https://lazy.folke.io/
- **Neovim Docs**: https://neovim.io/doc/
- **Neovim GitHub**: https://github.com/neovim/neovim
- **LSP Config**: https://github.com/neovim/nvim-lspconfig
- **Treesitter**: https://github.com/nvim-treesitter/nvim-treesitter
- **blink.cmp**: https://github.com/Saghen/blink.cmp

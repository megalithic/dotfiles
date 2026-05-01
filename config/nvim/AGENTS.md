# nvim_next Agent Instructions

Modern Neovim configuration targeting nvim 0.12+ with native LSP (no nvim-lspconfig).

## Architecture Overview

```
init.lua                 # Entry point: sets up mega global, loads modules

lua/
├── settings.lua         # Global vim.g settings, theme selection
├── options.lua          # Core vim.opt settings, filetype detection
├── keymaps.lua          # Global keymaps (escape deluxe, navigation)
├── icons.lua            # Centralized icon definitions
├── bootstrap.lua        # Lazy.nvim setup, plugin imports
│
├── langs/               # Language configurations (LSP, formatters, ftplugin)
│   ├── init.lua         # Lang system: loading, merging, caching
│   ├── _example.lua     # Documented example (not loaded)
│   └── *.lua            # Per-language configs (elixir, lua, typescript, etc.)
│
├── lsp/                 # Native LSP setup (no nvim-lspconfig)
│   ├── init.lua         # LSP enable, capabilities, attach handler
│   ├── diagnostics.lua  # Diagnostic config, sign handler, navigation
│   ├── keymaps.lua      # Shared LSP keymaps (gd, gr, K, etc.)
│   └── progress.lua     # LSP progress floating window
│
├── plugins/             # Lazy.nvim plugin specs
│   ├── init.lua         # Core plugins (smart-splits)
│   ├── ai/              # AI integrations (claudecode, copilot)
│   ├── snacks/          # Snacks.nvim (picker, notifier, terminal)
│   ├── lsp/             # LSP plugins (conform, trouble, schemastore)
│   ├── mini/            # Mini.nvim modules
│   └── *.lua            # Other plugins (blink, oil, git, etc.)
│
├── themes/              # Color schemes
│   ├── init.lua         # Theme loader
│   ├── hyper.lua        # Hyper theme
│   └── megaforest.lua   # Megaforest theme
│
└── utils/               # Utility modules (mounted on mega.u)
    ├── init.lua         # Loads all utils
    ├── clipboard.lua    # Clipboard helpers
    ├── fs.lua           # Filesystem helpers
    └── log.lua          # Logging (global `log` table)

after/
├── ftplugin/            # Traditional ftplugin overrides
│   ├── bigfile.lua      # Big file handling
│   ├── elixir.lua       # Elixir-specific overrides
│   └── lua.lua          # Lua-specific overrides
│
└── plugin/              # Auto-loaded after init
    ├── commands.lua     # Global user commands
    ├── cursorline.lua   # Cursorline blink effects (mega.ui.blink_cursorline)
    ├── fastscroll.lua   # Fast scroll mode detection
    ├── megaterm.lua     # Terminal management system (mega.term)
    ├── pi.lua           # Pi coding agent integration (mega.p.pi)
    ├── statuscolumn.lua # Custom statuscolumn
    ├── statusline.lua   # Custom statusline (mega.ui.statusline)
    ├── winbar.lua       # Window bar
    └── windows.lua      # Window management
```

## Load Order

1. `init.lua` - Creates `_G.mega` global namespace
2. `settings.lua` - Theme, disabled plugins, global helpers
3. `utils/` - Utility functions (`mega.u`, `mega.ui`, `log`)
4. `keymaps.lua` - Global keymaps
5. `options.lua` - vim.opt settings
6. `bootstrap.lua` - Lazy.nvim setup, plugin loading
7. `langs.setup()` - ftplugin autocmds
8. `lsp.setup()` - Deferred to VeryLazy event
9. `after/plugin/*.lua` - Loaded after plugins (megaterm, pi, statusline, etc.)

## Global Namespace (`mega`)

```lua
_G.mega = {
  p = {},           -- Plugin-specific tables
  t = {},           -- Theme
  u = {},           -- Utilities (mega.u.falsy, mega.u.empty, etc.)
  ui = {
    icons = {...},           -- From lua/icons.lua
    blink_cursorline = fn,   -- Visual feedback function
    statusline = {...},      -- Statusline module
  },
  term = {...},     -- Terminal manager (mega.term) - from after/plugin/megaterm.lua
}

-- Plugin-specific namespaces (populated by after/plugin/*.lua):
mega.p.pi           -- Pi coding agent integration
mega.p.lazy         -- Lazy.nvim helpers
mega.p.oil          -- Oil file manager
mega.p.snacks       -- Snacks.nvim
mega.p.claudecode   -- Claude Code integration (placeholder)
```

---

## Megaterm System (`after/plugin/megaterm.lua`)

Custom terminal manager with buffer-switching model. One window per position, multiple terminals as switchable buffers.

### Core Concepts

- **Position**: Where terminals appear (`bottom`, `right`, `tab`, `float`)
- **Buffer-switching**: Multiple terminals share one window per position
- **History tracking**: Most recently used terminal is tracked

### Terminal Class

```lua
---@class mega.term.Terminal
---@field buf number          -- Buffer number
---@field win number?         -- Window number (when visible)
---@field job_id number?      -- Job ID for the terminal process
---@field position string     -- "bottom"|"right"|"tab"|"float"
---@field cmd_str string      -- Command string (e.g., "pi", "iex -S mix")
```

### API

```lua
-- Create terminal
mega.term({ cmd = "pi", position = "right", width = 0.30 })
mega.term("htop")  -- Shorthand, uses default position

-- List/get terminals
mega.term.list()              -- All valid terminals
mega.term.get_current()       -- Currently focused terminal
mega.term.get_by_position("right")  -- All terminals in position

-- Control
mega.term.toggle()            -- Toggle most recent terminal
mega.term.cycle()             -- Cycle through terminals in current window

-- Send to terminal
mega.term.send("text")        -- Send to most recent terminal
term:send_line("command")     -- Send with newline
term:send_keys("<C-c>")       -- Send raw keycodes

-- Terminal instance methods
term:show()                   -- Show terminal
term:hide()                   -- Hide terminal
term:toggle()                 -- Toggle visibility
term:close()                  -- Close and cleanup
term:is_valid()               -- Check if buffer valid
term:is_visible()             -- Check if in a window
term:focus()                  -- Focus and enter insert mode
```

### Keymaps

| Key | Mode | Description |
|-----|------|-------------|
| `<C-;>` | n, t | Toggle terminal |
| `<C-'>` | n, t | Cycle terminals in window |
| `<Esc>` | t | Exit terminal mode (shell only, not pi) |
| `<C-q>` | t | Exit terminal mode (pi terminals) |
| `<C-h/j/k/l>` | t | Navigate to adjacent window |
| `<C-x>` | t | Close terminal |
| `q` | n | Close terminal (non-tab) |

### Configuration

```lua
mega.term.setup({
  default_position = "bottom",
  default_height = 15,
  default_width = 80,
  float_config = { ... },
})
```

---

## Pi Integration (`after/plugin/pi.lua`)

Comprehensive integration with pi-coding-agent for sending context, code, and files
from nvim to a running pi agent.

### Usage Scenarios

#### 1. Quick question about code (most common)

Select code visually, then `<localleader>ps` to send with a task prompt:

```
1. Select problematic code in visual mode
2. Press <localleader>ps (space p s)
3. Type task: "why does this throw nil error?"
4. Pi receives: file path, line range, code, and your question
```

#### 2. Send code without prompt (fast iteration)

When iterating quickly and pi already has context:

```
1. Select code
2. Press <localleader>pS (capital S = skip prompt)
3. Code sent immediately with file/line info, no task
```

#### 3. Add file to context before asking

Build up context, then ask:

```
1. Open relevant file
2. Press <localleader>pf to add to context
3. Repeat for other files
4. Select code and <localleader>ps with question
5. Pi sees: tracked files + current selection
```

#### 4. Send to tmux agent (bypass nvim terminal)

When pi is running in a tmux pane, not nvim:

```
1. Select code
2. Press <localleader>pa (a = agent)
3. Sends via socket to tmux pi, skipping nvim terminals
```

#### 5. Include LSP hover info

When type information helps:

```
1. Position cursor on symbol
2. Press <localleader>ph (h = hover)
3. Pi receives: line + LSP hover info (types, docs)
```

#### 6. Multiple pi sessions

Working with multiple pi instances:

```
1. Press <localleader>pn to open session picker
2. Select target (socket or nvim terminal)
3. Future sends go to selected target
4. Or set buffer-local: :PiTarget /tmp/pi-myproject-agent.sock
```

### Architecture

Pi integration operates via Unix socket to tmux pi pane:

```
┌─────────────────────────────────────────────────────────────┐
│                     after/plugin/pi.lua                     │
│                        (mega.p.pi)                          │
├─────────────────────────────────────────────────────────────┤
│  send_selection() / send_cursor() / add_file()              │
│                          │                                  │
│                          ▼                                  │
│              send_payload() → nc -U socket                  │
│                          │                                  │
│                          ▼                                  │
│            tmux-toggle-pi (auto-show pi pane)               │
└─────────────────────────────────────────────────────────────┘
```

### Socket Discovery

Priority order for finding pi socket:

1. `vim.b.pi_target_socket` - Buffer-local explicit target
2. `PI_SOCKET` env var - Explicit override
3. Tmux session: `/tmp/pi-{session}-agent.sock`
4. Tmux session: `/tmp/pi-{session}-*.sock` (first match)
5. Default: `/tmp/pi-default.sock`

### Payload Format

When sending via socket, pi.lua sends JSON:

```json
{
  "type": "selection",
  "file": "/path/to/file.lua",
  "range": [10, 25],
  "selection": "function foo()...",
  "language": "lua",
  "task": "explain this function",
  "lsp": {
    "diagnostics": ["[ERROR] 12:5 undefined variable"],
    "hover": "function foo(): string"
  }
}
```

### Commands

| Command | Description |
|---------|-------------|
| `:PiPanel` | Toggle pi terminal panel |
| `:PiSelection` | Send visual selection to pi |
| `:PiCursor` | Send cursor line to pi |
| `:PiFile [path]` | Add file to pi context |
| `:PiToggle` | Toggle pi pane in tmux |
| `:PiStatus` | Show pi connection status |
| `:PiContext` | Show tracked context files |
| `:PiClearContext` | Clear tracked context |
| `:PiSessions` | Select pi session (picker) |
| `:PiTarget [socket]` | Get/set target socket |
| `:PiLspStart` | Start in-process pi LSP |
| `:PiLspStop` | Stop pi LSP |
| `:PiLspAttach` | Attach pi LSP to buffer |

### Keymaps

| Key | Mode | Description |
|-----|------|-------------|
| `<localleader>pp` | n | Toggle pi panel |
| `<localleader>ps` | v | Send selection (with prompt) |
| `<localleader>pS` | v | Quick send selection (no prompt) |
| `<localleader>pa` | n,v | Send to agent (force tmux socket) |
| `<localleader>pc` | n | Send cursor line |
| `<localleader>ph` | n | Send cursor with hover info |
| `<localleader>pf` | n | Add file to context |
| `<localleader>pt` | n | Toggle tmux pane |
| `<localleader>pi` | n | Show pi status |
| `<localleader>px` | n | Show context files |
| `<localleader>pn` | n | Select pi session |

### Statusline Integration

The statusline (`after/plugin/statusline.lua`) includes a pi segment:

- Shows π icon with session name
- Shows context file count
- Clickable to open session picker

---

## Lang System (`lua/langs/`)

Unified language config - all lang-specific settings in one place per language.

### Lang Config Structure

```lua
-- lua/langs/<lang>.lua
return {
  filetypes = { "elixir", "heex" },       -- Metadata (required for servers)
  
  servers = {                              -- LSP servers (native vim.lsp.config)
    expert = {
      cmd = { "expert", "--stdio" },
      root_markers = { "mix.exs" },        -- Converted to root_dir function
      settings = {...},
      keys = {...},                        -- Per-server keymaps
    },
  },
  
  formatters = { elixir = { "mix" } },    -- conform.nvim formatters
  
  ftplugin = {                             -- Applied on FileType
    elixir = {
      opt = { shiftwidth = 2 },
      keys = {...},
      abbr = {...},
      callback = function(bufnr) end,
    },
  },
  
  repl = {                                 -- REPL config (auto-creates keymaps)
    cmd = "iex -S mix",
    position = "right",
    reload_cmd = "recompile()",
  },
  
  plugins = { { "some/plugin.nvim" } },   -- Lazy specs (auto-collected)
}
```

### Key APIs

```lua
local langs = require("langs")
langs.servers()          -- Returns all LSP configs + server_keys
langs.formatters()       -- Returns formatter configs for conform
langs.ftplugin_configs() -- Returns ftplugin configs
langs.repl_configs()     -- Returns REPL configs by filetype
langs.lazy_specs()       -- Returns plugin specs (used in bootstrap.lua)
langs.inspect("elixir")  -- Debug: show resolved config
langs.list()             -- List all discovered langs
langs.clear_cache()      -- Clear cache (for reloading)
```

### Commands

```vim
:LangInspect <name>     " Show resolved lang config
:LangList               " List all langs
:LangServers            " List all LSP servers
:LangReload             " Reload all lang configs
```

---

## LSP System (`lua/lsp/`)

Native `vim.lsp.config()` and `vim.lsp.enable()` - no nvim-lspconfig.

### Flow

1. `lsp.setup()` registers VeryLazy autocmd
2. On VeryLazy: calls `langs.servers()` to get configs
3. Applies `vim.lsp.config(server, config)` for each
4. Calls `vim.lsp.enable(server_names)`
5. LspAttach autocmd applies shared keymaps + per-server keymaps

### root_markers

Lang configs use `root_markers` for convenience. The lang system converts these
to proper `root_dir` functions for vim.lsp.config.

---

## Plugin System

Uses lazy.nvim with spec imports:

```lua
-- bootstrap.lua
spec = {
  { import = "plugins" },
  { import = "plugins.ai" },
  { import = "plugins.lsp" },
  { import = "plugins.snacks" },
  { import = "plugins.mini" },
  { require("langs").lazy_specs() },  -- Lang-specific plugins
}
```

---

## Key Patterns

### Leaders

- `<leader>` = `,` (comma)
- `<localleader>` = ` ` (space)

### Keymap Conventions

- `<leader>f*` - Find/picker keymaps
- `<leader>g*` - Git keymaps
- `<localleader>p*` - Pi agent keymaps
- `<localleader>r*` - REPL keymaps (from lang configs)
- `<localleader>e*` - Elixir-specific keymaps
- `<localleader>t*` - Test keymaps
- `gd`, `gr`, `K` - LSP keymaps

### Autocmd Groups

- `mega.langs` - ftplugin application
- `mega.lsp.attach` - LSP attach handler
- `mega.lsp.diagnostics` - Diagnostic features
- `mega.lsp.progress` - Progress indicator
- `mega.treesitter` - Treesitter highlighting
- `mega.term` - Megaterm autocmds
- `mega.ui.statusline` - Statusline updates
- `mega.ui.statusline.jj` - Jujutsu status updates

---

## Testing Changes

This is the live config (symlinked to `~/.config/nvim/`). Verify changes by opening `nvim` directly:

```bash
nvim [file]
```

For headless lua sanity checks:

```bash
nvim --headless "+lua print(require('module.path'))" +qa
nvim --headless "+Lazy! sync" +qa
```

---

## Common Tasks

### Adding a new language

1. Create `lua/langs/<lang>.lua` (copy from `_example.lua`)
2. Define servers, formatters, ftplugin as needed
3. Run `:LangReload` to test

### Adding an LSP server

In the relevant `lua/langs/<lang>.lua`:

```lua
servers = {
  myserver = {
    cmd = { "my-server", "--stdio" },
    root_markers = { "config.json", ".git" },
    settings = {...},
  },
}
```

### Debugging

```vim
:LangInspect <name>     " Show resolved lang config
:LangList               " List all langs
:LangServers            " List all LSP servers
:checkhealth            " Run health checks
:Lazy profile           " Plugin load times
:PiStatus               " Pi connection status
```

---

## Don't

- Don't use nvim-lspconfig - we use native vim.lsp.config
- Don't put treesitter config in langs/ - it's in `lua/plugins/treesitter.lua`
- Don't use `vim.tbl_contains` - use `vim.list_contains` (deprecated)
- Don't create CursorMoved autocmds without debouncing
- Don't assume plugins are loaded - use `pcall(require, "plugin")`
- Don't use `opts = {}` for plugins without setup() functions (e.g., treesitter-endwise)

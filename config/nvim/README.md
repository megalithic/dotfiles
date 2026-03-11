# nvim_next

Modern Neovim configuration for 0.12+ with native LSP.

## Features

- **Native LSP** - No nvim-lspconfig dependency, uses `vim.lsp.config()` directly
- **Unified lang configs** - All language settings in one place per language
- **Lazy loading** - Fast startup with lazy.nvim
- **Modern plugins** - Snacks.nvim, blink.cmp, treesitter (main branch)

## Quick Start

```bash
# Clone to nvim_next
git clone <repo> ~/.config/next

# Run with NVIM_APPNAME
NVIM_APPNAME=next nvim
```

## Structure

```
lua/
├── langs/        # Language configs (LSP, formatters, ftplugin)
├── lsp/          # Native LSP setup
├── plugins/      # Lazy.nvim plugin specs
├── themes/       # Color schemes
└── utils/        # Utility functions
```

## Languages

Each language gets a unified config file in `lua/langs/`:

```lua
-- lua/langs/elixir.lua
return {
  filetypes = { "elixir", "heex" },
  servers = {
    expert = { cmd = { "expert", "--stdio" } },
  },
  formatters = { elixir = { lsp_format = "prefer" } },
  ftplugin = {
    elixir = { opt = { shiftwidth = 2 } },
  },
}
```

**Supported:** Elixir, Lua, TypeScript, Nix, Bash, JSON, YAML, HTML, CSS, Markdown, Docker

## Key Bindings

| Key | Action |
|-----|--------|
| `,` | Leader |
| `<Space>` | Local leader |
| `<Esc>` | Clear UI, save buffer |
| `gd` | Go to definition |
| `gr` | References |
| `K` | Hover |
| `<leader>ff` | Find files |
| `<leader>a` | Live grep |
| `<leader>e` | File explorer (Oil) |

## Commands

| Command | Description |
|---------|-------------|
| `:LangInspect [lang]` | Show resolved lang config |
| `:LangList` | List all languages |
| `:LangServers` | List LSP servers |
| `:LangReload` | Reload lang configs |

## Requirements

- Neovim 0.11+ (0.12 recommended)
- ripgrep, fd (for pickers)
- Language servers (installed separately)

## License

MIT

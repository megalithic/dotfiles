# nvim-pack

`nvim-pack` is a native `vim.pack` migration of `config/nvim`.

Launch:

```sh
NVIM_APPNAME=nvim-pack nvim
# after Home Manager activation
np
```

Source of truth:

- Core config comes from `config/nvim`.
- Plugin inventory comes from `config/nvim/lua/plugins/**` and `config/nvim/lua/langs/**`.
- Only the floating pack UI comes from `.local_scripts/mc-nvim/lua/ui/pack_interface.lua`.
- Do not copy the `mc-nvim` plugin list, options, mappings, theme, or UI setup here.

How it works:

- `init.lua` loads only settings, utils, keymaps, and options.
- `plugin/00-pack.lua` starts native `vim.pack` through `lua/pack/init.lua`.
- `plugin/10-core.lua` starts language config, LSP, and `:PackFloat` after pack setup.
- `lua/pack/init.lua` collects plugin specs from the existing `lua/plugins/**` modules,
  converts their repos to `vim.pack.add()`, then runs their `init`/`opts`/`config`/`keys`
  setup. No lazy.nvim is installed or required.

Local dev plugins:

- Repos owned by `megalithic` load live from `~/code/oss/<repo>` when present
  (via `runtimepath`), falling back to git otherwise. Mirrors lazy.nvim `dev` config.
- Currently: `megalithic/fff-snacks.nvim` loads from `~/code/oss/fff-snacks.nvim`.

Treesitter:

- `nvim-treesitter` config installs any missing parsers from the `parsers` list on startup
  (async, background). Use `:TSUpdate` to refresh.

Pack UI:

- `:PackFloat` opens the floating `vim.pack` manager (refresh, update, uninstall, details).
- `:PackFloat!` skips fetching and uses already-fetched refs.

Runtime layout:

- `plugin/*.lua` for startup plugin setup.
- `after/plugin/*.lua` for late overrides.
- `ftplugin/` and `after/ftplugin/` for filetype behavior.
- `lsp/*.lua` and `lua/lsp/**` for native LSP config.
- `nvim-pack-lock.json` for `vim.pack` state.

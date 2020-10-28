-- ┌───────────────────────────────────────────────────────────────────────────┐
-- │                                                                           │
-- │ Setup for Lua-based plugins                                               │
-- │                                                                           │
-- └───────────────────────────────────────────────────────────────────────────┘

-- [ load lsp_config ] ---------------------------------------------------------
local lsp_config_loaded, lsp_config = pcall(function() require('lsp_config') end) -- ok, _return_value
if not lsp_config_loaded then
  print('[ERROR] -> ' .. lsp_config)
end


-- [ nvim-treesitter ] ---------------------------------------------------------
--   See https://github.com/nvim-treesitter/nvim-treesitter

require'nvim-treesitter.configs'.setup({
  ensure_installed = "all", -- one of "all", "maintained" (parsers with maintainers), or a list of languages
  highlight = {
    enable = true,              -- false will disable the whole extension
    disable = { 'c', 'rust', 'lua', 'typescript.tsx', 'typescript', 'tsx' },  -- list of language that will be disabled
  },
})


-- [ formatter.nvim ] ----------------------------------------------------------
--   See https://github.com/mhartington/formatter.nvim

require("format").setup(
  {
    typescript = {
      prettier = function()
        return {
          exe = "prettier",
          args = {"--stdin-filepath", vim.api.nvim_buf_get_name(0), "--single-quote"},
          stdin = true
        }
      end
    },
    javascript = {
      prettier = function()
        return {
          exe = "prettier",
          args = {"--stdin-filepath", vim.api.nvim_buf_get_name(0), "--single-quote"},
          stdin = true
        }
      end
    },
    lua = {
      luafmt = function()
        return {
          exe = "luafmt",
          args = {"--indent-count", 2, "--stdin"},
          stdin = true
        }
      end
    },
    elixir = {
      mix_format = function()
        return {
          exe = "mix format",
          args = {"-", vim.api.nvim_buf_get_name(0)},
          stdin = true
        }
      end
    }
  }
)
vim.fn.nvim_buf_set_keymap(0, 'n', '<leader>F', ':Format<CR>', {noremap=true, silent=true})


-- [ nvim-colorizer.lua ] ------------------------------------------------------
--   See https://github.com/norcalli/nvim-colorizer.lua

local has_colorizer, colorizer = pcall(require, "colorizer")
if not has_colorizer then
  return
end

-- https://github.com/norcalli/nvim-colorizer.lua/issues/4#issuecomment-543682160
colorizer.setup ({
    -- '*',
    -- '!vim',
  -- }, {
    css = {rgb_fn = true},
    scss = {rgb_fn = true},
    sass = {rgb_fn = true},
    stylus = {rgb_fn = true},
    vim = {names = false},
    tmux = {names = false},
    "eelixir",
    "javascript",
    "javascriptreact",
    "typescript",
    "typescriptreact",
    "zsh",
    "sh",
    "conf",
    html = {
      mode = "foreground"
    }
  })


-- [ golden_size ] -------------------------------------------------------------
--   See https://github.com/dm1try/golden_size#tips-and-tricks

local function ignore_by_buftype(types)
  local buftype = vim.api.nvim_buf_get_option(vim.api.nvim_get_current_buf(), "buftype")
  for _, type in pairs(types) do
    if type == buftype then
      return 1
    end
  end
end

local golden_size = require("golden_size")
-- set the callbacks, preserve the defaults
golden_size.set_ignore_callbacks(
  {
    {
      ignore_by_buftype,
      {
        "Undotree",
        "quickfix",
        "nerdtree",
        "current",
        "Vista",
        "LuaTree",
        "nofile"
      }
    },
    {golden_size.ignore_float_windows}, -- default one, ignore float windows
    {golden_size.ignore_by_window_flag} -- default one, ignore windows with w:ignore_gold_size=1
  }
)

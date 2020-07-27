-- Lua setup of many plugin things..
-- ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

-- nvim-colorizer
-- ==============
-- See https://github.com/norcalli/nvim-colorizer.lua
require 'colorizer'.setup {
  css = { rgb_fn = true; };
  scss = { rgb_fn = true; };
  sass = { rgb_fn = true; };
  stylus = { rgb_fn = true; };
  vim = { names = false; };
  tmux = { names = false; };
  'eelixir';
  'javascript';
  'javascriptreact';
  'typescript';
  'typescriptreact';
  'zsh';
  'sh';
  'conf';
  html = {
    mode = 'foreground';
  };
}


-- golden_size
-- ==============
-- See https://github.com/dm1try/golden_size#tips-and-tricks

-- local function ignore_by_buftype(types)
--   local buftype = vim.api.nvim_buf_get_option(vim.api.nvim_get_current_buf(), 'buftype')
--   for _, type in pairs(types) do
--     if type == buftype then
--       return 1
--     end
--   end
-- end

-- local golden_size = require("golden_size")
-- -- set the callbacks, preserve the defaults
-- golden_size.set_ignore_callbacks({
--     { ignore_by_buftype,
--       {
--         'Undotree',
--         'quickfix',
--         'nerdtree',
--         'current',
--         'Vista',
--         'LuaTree',
--         'nofile'
--       }
--     },
--     { golden_size.ignore_float_windows }, -- default one, ignore float windows
--     { golden_size.ignore_by_window_flag }, -- default one, ignore windows with w:ignore_gold_size=1
--   })

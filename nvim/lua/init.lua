-- Lua setup of many things..


-- nvim-colorizer
-- ===
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
  html = {
    mode = 'foreground';
  }
}

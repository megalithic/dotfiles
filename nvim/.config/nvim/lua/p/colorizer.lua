-- [ nvim-colorizer.lua ] ------------------------------------------------------
--   See https://github.com/norcalli/nvim-colorizer.lua

local has_colorizer, colorizer = pcall(require, "colorizer")
if not has_colorizer then
  return
end

-- https://github.com/norcalli/nvim-colorizer.lua/issues/4#issuecomment-543682160
colorizer.setup(
  {
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
  }
)


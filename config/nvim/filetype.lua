if not vim.filetype then
  return
end

vim.g.did_load_filetypes = 0 -- Disable vim-based filetype plugin
vim.g.do_filetype_lua = 1 -- Enable lua-based filetype plugin

vim.filetype.add({
  filename = {
    [".gitignore"] = "conf",
    ["kitty.conf"] = "kitty",
    [".env"] = "sh",
    ["Deskfile"] = "sh",
    ["tsconfig.json"] = "jsonc",
    [".prettierrc"] = "jsonc",
    [".eslintrc"] = "jsonc",
    ["Brewfile"] = "ruby",
    ["Brewfile.mas"] = "ruby",
    ["Brewfile.cask"] = "ruby",
  },
  extension = {
    eslintrc = "json",
    prettierrc = "json",
    conf = "conf",
    mdx = "markdown",
    md = "markdown",
    lexs = "elixir",
    exs = "elixir",
    eex = "eelixir",
  },
  pattern = {
    [".*%.env.*"] = "sh",
    [".*ignore"] = "conf",
    ["*.jst.eco"] = "jst",
    -- ['.*tmux.*conf$'] = 'tmux',
  },
})

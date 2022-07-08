if not vim.filetype then return end

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
    ["NEOGIT_COMMIT_EDITMSG"] = "NeogitCommitMessage",
  },
  extension = {
    json = "jsonc",
    eslintrc = "jsonc",
    prettierrc = "jsonc",
    conf = "conf",
    mdx = "markdown",
    md = "markdown",
    lexs = "elixir",
    exs = "elixir",
    eex = "eelixir",
    keymap = "keymap",
  },
  pattern = {
    [".*%.conf"] = "conf",
    [".*%.theme"] = "conf",
    [".*ignore"] = "conf",
    [".*%.gradle"] = "groovy",
    [".*%.env%..*"] = "env",
    [".*%.jst.eco"] = "jst",
  },
  -- ['.*tmux.*conf$'] = 'tmux',
})

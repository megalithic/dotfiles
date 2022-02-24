if not vim.filetype then
  return
end

vim.g.do_filetype_lua = 1

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
  pattern = {
    -- ["*.env.*"] = "env",
  },
})

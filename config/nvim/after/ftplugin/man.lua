vim.opt_local.signcolumn = "no"
vim.opt_local.number = true
vim.opt_local.relativenumber = true

-- better mnemonic for tag jumping
vim.keymap.set({ "n", "x" }, "gd", "<C-]>", {
  buffer = true,
})

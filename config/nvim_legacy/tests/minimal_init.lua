--- Minimal init for running tests
--- Loads only what's needed for shade.lua tests

-- Add the lua directory to the runtime path
vim.opt.runtimepath:append(vim.fn.expand("~/.dotfiles/config/nvim"))

-- Ensure plenary is available (it's a test dependency)
vim.opt.runtimepath:append(vim.fn.expand("~/.local/share/nvim/lazy/plenary.nvim"))

-- Disable some features for faster test runs
vim.g.loaded_netrw = 1
vim.g.loaded_netrwPlugin = 1

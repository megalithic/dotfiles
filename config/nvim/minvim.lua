_G.minvim = {}

_G.L = vim.log.levels

local map = vim.keymap.set
local pack = vim.pack
local lsp = vim.lsp
local autocmd = vim.api.nvim_create_autocmd
local command = vim.api.nvim_create_user_command
local augroup = vim.api.nvim_create_augroup("mega_minvim", { clear = true })

-- [[ OPTS ]] --------------------------------------------------------------------------------------
vim.o.number = true
vim.o.relativenumber = true
vim.o.signcolumn = "yes"
vim.o.termguicolors = true
vim.o.wrap = false
vim.o.tabstop = 4
vim.o.swapfile = false
vim.g.mapleader = ","
vim.g.maplocalleader = " "
vim.o.winborder = "rounded"
vim.o.clipboard = "unnamedplus"

map("n", "<leader>o", ":update<CR> :source<CR>")
map("n", "<leader>w", ":write<CR>")
map("n", "<leader>q", ":quit<CR>")
map("n", "<localleader><localleader>", "<C-^>", { desc = "last buffer" })
map("n", "H", "^")
map("n", "L", "$")
map({ "v", "x" }, "L", "g_")
map({ "v", "x" }, "H", "g^")
map("n", "0", "^")
map({ "n", "v", "x" }, "<leader>y", "\"+y<CR>")
map({ "n", "v", "x" }, "<leader>d", "\"+d<CR>")
map("n", "<leader>ff", ":Pick files<CR>")
map("n", "<leader>fh", ":Pick help<CR>")
map("n", "<leader>ev", ":Oil vertical=true<CR>")
map("n", "<leader>F", lsp.buf.format)

pack.add({
  { src = "https://github.com/sainnhe/everforest" },
  { src = "https://github.com/rktjmp/lush.nvim" },
  { src = "https://github.com/everviolet/nvim", name = "evergarden" },
  { src = "https://github.com/stevearc/oil.nvim" },
  { src = "https://github.com/echasnovski/mini.pick" },
  { src = "https://github.com/nvim-treesitter/nvim-treesitter", version = "master" },
  { src = "https://github.com/neovim/nvim-lspconfig" },
  { src = "https://github.com/chomosuke/typst-preview.nvim" },
  { src = "https://github.com/vague2k/vague.nvim" },
  { src = "https://github.com/zenbones-theme/zenbones.nvim" },
})

require("mini.pick").setup()
require("nvim-treesitter.configs").setup({
  ensure_installed = {
    "svelte",
    "typescript",
    "javascript",
    "lua",
    "heex",
    "elixir",
    "bash",
    "comment",
    "markdown",
    "markdown_inline",
  },
  auto_install = false,
  highlight = {
    enable = true,
    additional_vim_regex_highlighting = false,
  },
  indent = {
    enable = true,
  },
})
require("oil").setup()
require("vague").setup({ transparent = true })
require("evergarden").setup({
  theme = {
    variant = "spring", -- 'winter'|'fall'|'spring'|'summer'
    accent = "green",
  },
  editor = {
    transparent_background = false,
    sign = { color = "none" },
    float = {
      color = "mantle",
      solid_border = false,
    },
    completion = {
      color = "surface0",
    },
  },
})

lsp.enable({ "lua_ls", "biome", "tinymist", "emmetls" })

vim.schedule(function()
  vim.g.everforest_background = "medium"
  vim.g.everforest_better_performance = 1

  vim.cmd.colorscheme("everforest") -- alts: everforest, vague, forestbones, zenbones, evergarden, etc
  vim.cmd.highlight("statusline guibg=NONE")
end)

command("Up", "silent up | e", {}) -- Quick refresh if Treesitter bugs out

autocmd("LspAttach", {
  group = augroup,
  desc = "Handle lsp attaching to buffer",
  callback = function(evt)
    local client = lsp.get_client_by_id(evt.data.client_id)
    if client and client:supports_method("textDocument/completion") then
      vim.opt.completeopt = { "menu", "menuone", "noinsert", "fuzzy", "popup" }
      -- vim.cmd("set completeopt+=noselect")
      lsp.completion.enable(true, client.id, evt.buf, { autotrigger = true })
      map("i", "<C-y>", function() lsp.completion.get() end, { desc = "[comp] accept selection" })
    end
  end,
})

autocmd("LspDetach", {
  group = augroup,
  desc = "Handle lsp deataching from buffer",
  callback = function(evt) end,
})

autocmd("BufWritePre", {
  group = augroup,
  desc = "Format on save (pre)",
  pattern = "*",
  callback = function(evt) lsp.buf.format({ bufnr = evt.buf }) end,
})

autocmd("PackChanged", {
  desc = "Handle nvim-treesitter updates",
  group = augroup,
  callback = function(evt)
    if evt.data.kind == "update" then
      vim.notify("nvim-treesitter updated, running TSUpdate...", L.INFO)
      ---@diagnostic disable-next-line: param-type-mismatch
      local ok = pcall(vim.cmd, "TSUpdate")
      if ok then
        vim.notify("TSUpdate completed successfully!", L.INFO)
      else
        vim.notify("TSUpdate command not available yet, skipping", L.WARN)
      end
    end
  end,
})

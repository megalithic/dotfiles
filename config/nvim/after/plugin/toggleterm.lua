-- TODO: send visual lines to toggleterm:
--      https://github.com/akinsho/toggleterm.nvim/issues/172
--      https://github.com/rikuma-t/dotfiles/blob/main/.config/nvim/lua/rc/toggleterm.lua#L29-L56 (dynamic resize/toggling)
local toggleterm = require("toggleterm")
toggleterm.setup({
  open_mapping = [[<c-\>]],
  shade_filetypes = {},
  shade_terminals = true,
  shade_factor = 2,
  direction = "horizontal",
  insert_mappings = true,
  start_in_insert = true,
  close_on_exit = true,
  float_opts = {
    border = "rounded",
    winblend = 0,
    highlights = {
      border = "TelescopePromptBorder",
      background = "TelescopePrompt",
    },
  },
  size = function(term)
    if term.direction == "horizontal" then
      return 15
    elseif term.direction == "vertical" then
      return math.floor(vim.o.columns * 0.4)
    end
  end,
  persist_size = false,
  on_open = function(term)
    term.opened = term.opened or false

    if not term.opened then
      if require("mega.utils").root_has_file("Deskfile") then
        term:send("eval $(desk load)")
      end
    end

    term.opened = true
  end,
})

local float_handler = function(term)
  if vim.fn.mapcheck("jk", "t") ~= "" then
    vim.api.nvim_buf_del_keymap(term.bufnr, "t", "jk")
    vim.api.nvim_buf_del_keymap(term.bufnr, "t", "<esc>")
  end
end

local Terminal = require("toggleterm.terminal").Terminal
local htop = Terminal:new({
  cmd = "htop",
  hidden = "true",
  direction = "float",
  on_open = float_handler,
})

local node = Terminal:new({ cmd = "node", hidden = true })
function _NODE_TOGGLE()
  node:toggle()
end

local elixir = Terminal:new({ cmd = "iex -S mix", hidden = true })
function _ELIXIR_TOGGLE()
  elixir:toggle()
end

local lua = Terminal:new({ cmd = "lua", hidden = true })
function _LUA_TOGGLE()
  lua:toggle()
end

local rails = Terminal:new({ cmd = "rails c", hidden = true })
function _RAILS_TOGGLE()
  rails:toggle()
end

local python = Terminal:new({ cmd = "python", hidden = true })
function _PYTHON_TOGGLE()
  python:toggle()
end

mega.command("Htop", function()
  htop:toggle()
end)

local wk = require("which-key")
wk.register({
  t = {
    name = "terminal",
    t = { "<cmd>ToggleTerm direction=horizontal<cr>", "Horizontal" },
    f = { "<cmd>ToggleTerm direction=float<cr>", "Float" },
    h = { "<cmd>ToggleTerm direction=horizontal<cr>", "Horizontal" },
    v = { "<cmd>ToggleTerm size=80 direction=vertical<cr>", "Vertical" },
    l = { "<cmd>lua _LUA_TOGGLE()<cr>", "repl > lua" },
    n = { "<cmd>lua _NODE_TOGGLE()<cr>", "repl > node" },
    p = { "<cmd>lua _PYTHON_TOGGLE()<cr>", "repl > python" },
  },
}, {
  prefix = "<leader>",
})

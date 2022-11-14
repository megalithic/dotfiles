return function()
  -- use our own if we have it enabled
  if vim.g.enabled_plugin["term"] then return end

  local tt = require("toggleterm")
  -- TODO: send visual lines to toggleterm:
  --      https://github.com/akinsho/toggleterm.nvim/issues/172
  --      https://github.com/rikuma-t/dotfiles/blob/main/.config/nvim/lua/rc/toggleterm.lua#L29-L56 (dynamic resize/toggling)
  tt.setup({
    open_mapping = [[<c-\>]],
    shade_filetypes = {},
    shade_terminals = true,
    shade_factor = 2,
    direction = "horizontal",
    persist_mode = true,
    insert_mappings = true,
    winbar = { enabled = false },
    start_in_insert = true,
    close_on_exit = true,
    float_opts = {
      border = mega.get_border(),
      winblend = 0,
      highlights = {
        border = "TmuxPopupNormal",
        background = "TmuxPopupNormal",
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
        if require("mega.utils").root_has_file("Deskfile") then term:send("eval $(desk load)") end
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
  local btop = Terminal:new({
    cmd = "btop",
    hidden = "true",
    direction = "float",
    on_open = float_handler,
  })

  local elixir_iex = Terminal:new({
    cmd = "m",
    hidden = "false",
    direction = "horizontal",
    -- on_open = float_handler,
  })

  mega.command("Btop", function() btop:toggle() end)
  mega.command("Iex", function() elixir_iex:toggle() end)

  nnoremap("<leader>tt", "<cmd>ToggleTerm direction=horizontal<cr>", "toggleterm")
  nnoremap("<leader>tf", "<cmd>ToggleTerm direction=float<cr>", "toggleterm (float)")
  nnoremap("<leader>tv", "<cmd>ToggleTerm direction=vertical<cr>", "toggleterm (vertical)")
  nnoremap("<leader>tp", "<cmd>ToggleTerm direction=tab<cr>", "toggleterm (tab-persistent)")

  function _G.set_terminal_keymaps()
    local opts = { buffer = 0 }
    tmap("<esc>", [[<C-\><C-n>]], opts)
    tmap("<C-h>", [[<Cmd>wincmd h<CR>]], opts)
    tmap("<C-j>", [[<Cmd>wincmd j<CR>]], opts)
    tmap("<C-k>", [[<Cmd>wincmd k<CR>]], opts)
    tmap("<C-l>", [[<Cmd>wincmd l<CR>]], opts)
  end

  -- if you only want these mappings for toggle term use term://*toggleterm#* instead
  vim.cmd("autocmd! TermOpen term://* lua set_terminal_keymaps()")

  -- nnoremap("<leader>tre", "<cmd>TermElixir<cr>", "repl > elixir")
  -- nnoremap("<leader>trr", "<cmd>TermRuby<cr>", "repl > ruby")
  -- nnoremap("<leader>trR", "<cmd>TermRuby!<cr>", "repl > ruby (current file)")
  -- nnoremap("<leader>trl", "<cmd>TermLua<cr>", "repl > lua")
  -- nnoremap("<leader>trn", "<cmd>TermNode<cr>", "repl > node")
  -- nnoremap("<leader>trp", "<cmd>TermPython<cr>", "repl > python")
  --
  -- local has_wk, wk = mega.require("which-key")
  -- if has_wk and not vim.g.enabled_plugin["term"] then
  --   wk.register({
  --     t = {
  --       name = "terminal",
  --       t = { "<cmd>ToggleTerm direction=horizontal<cr>", "Horizontal" },
  --       f = { "<cmd>ToggleTerm direction=float<cr>", "Float" },
  --       h = { "<cmd>ToggleTerm direction=horizontal<cr>", "Horizontal" },
  --       v = { "<cmd>ToggleTerm size=80 direction=vertical<cr>", "Vertical" },
  --     },
  --   }, {
  --     prefix = "<leader>",
  --   })
  -- end
end

-- return function()
--   local fn = vim.fn
--   require('toggleterm').setup({
--     open_mapping = [[<c-\>]],
--     shade_filetypes = { 'none' },
--     direction = 'horizontal',
--     persist_mode = true,
--     insert_mappings = false,
--     start_in_insert = true,
--     winbar = { enabled = as.ui.winbar.enable },
--     highlights = {
--       FloatBorder = { link = 'FloatBorder' },
--       NormalFloat = { link = 'NormalFloat' },
--     },
--     float_opts = {
--       border = as.style.current.border,
--       winblend = 3,
--     },
--     size = function(term)
--       if term.direction == 'horizontal' then
--         return 15
--       elseif term.direction == 'vertical' then
--         return math.floor(vim.o.columns * 0.4)
--       end
--     end,
--   })

--   local float_handler = function(term)
--     if not as.empty(fn.mapcheck('jk', 't')) then
--       vim.keymap.del('t', 'jk', { buffer = term.bufnr })
--       vim.keymap.del('t', '<esc>', { buffer = term.bufnr })
--     end
--   end

--   local Terminal = require('toggleterm.terminal').Terminal

--   local lazygit = Terminal:new({
--     cmd = 'lazygit',
--     dir = 'git_dir',
--     hidden = true,
--     direction = 'float',
--     on_open = float_handler,
--   })

--   local btop = Terminal:new({
--     cmd = 'btop',
--     hidden = true,
--     direction = 'float',
--     on_open = float_handler,
--     highlights = {
--       FloatBorder = { guibg = 'Black', guifg = 'DarkGray' },
--       NormalFloat = { guibg = 'Black' },
--     },
--   })

--   local gh_dash = Terminal:new({
--     cmd = 'gh dash',
--     hidden = true,
--     direction = 'float',
--     on_open = float_handler,
--     float_opts = {
--       height = function() return math.floor(vim.o.lines * 0.8) end,
--       width = function() return math.floor(vim.o.columns * 0.95) end,
--     },
--   })

--   as.nnoremap('<leader>ld', function() gh_dash:toggle() end, 'toggleterm: toggle github dashboard')

--   as.command('Btop', function() btop:toggle() end)

--   as.nnoremap('<leader>lg', function() lazygit:toggle() end, 'toggleterm: toggle lazygit')

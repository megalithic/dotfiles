return {
  "akinsho/toggleterm.nvim",
  cmd = { "ToggleTerm" },
  enabled = false,
  keys = {

    { "<leader>tt", "<cmd>ToggleTerm direction=horizontal<cr>", desc = "toggleterm" },
    { "<leader>tf", "<cmd>ToggleTerm direction=float<cr>", desc = "toggleterm (float)" },
    { "<leader>tv", "<cmd>ToggleTerm direction=vertical<cr>", desc = "toggleterm (vertical)" },
    { "<leader>tp", "<cmd>ToggleTerm direction=tab<cr>", desc = "toggleterm (tab-persistent)" },
  },
  config = function()
    -- use our own if we have it enabled
    if vim.g.enabled_plugin["megaterm"] or vim.g.enabled_plugin["term"] then return end

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

    mega.augroup("AddTerminalMappings", {
      event = { "TermOpen" },
      pattern = { "term://*" },
      command = function()
        if vim.bo.filetype == "" or vim.bo.filetype == "toggleterm" then
          local opts = { silent = false, buffer = 0 }
          tnoremap("<esc>", [[<C-\><C-n>]], opts)
          tnoremap("jk", [[<C-\><C-n>]], opts)
          tnoremap("<C-h>", "<Cmd>wincmd h<CR>", opts)
          tnoremap("<C-j>", "<Cmd>wincmd j<CR>", opts)
          tnoremap("<C-k>", "<Cmd>wincmd k<CR>", opts)
          tnoremap("<C-l>", "<Cmd>wincmd l<CR>", opts)
          tnoremap("]t", "<Cmd>tablast<CR>")
          tnoremap("[t", "<Cmd>tabnext<CR>")
          tnoremap("<S-Tab>", "<Cmd>bprev<CR>")
          tnoremap("<leader><Tab>", "<Cmd>close \\| :bnext<cr>")
        end
      end,
    })

    -- function _G.set_terminal_keymaps()
    --   local opts = { buffer = 0 }
    --   tmap("<esc>", [[<C-\><C-n>]], opts)
    --   tmap("<C-h>", [[<cmd>wincmd h<CR>]], opts)
    --   tmap("<C-j>", [[<cmd>wincmd j<CR>]], opts)
    --   tmap("<C-k>", [[<cmd>wincmd k<CR>]], opts)
    --   tmap("<C-l>", [[<cmd>wincmd l<CR>]], opts)
    -- end
    -- function _G.set_terminal_keymaps()
    --   local opts = { noremap = true, buffer = 0 }
    --   -- vim.keymap.set("t", "<esc>", [[<C-\><C-n>]], opts)
    --   -- vim.keymap.set("t", "jk", [[<C-\><C-n>]], opts)
    --   -- vim.keymap.set("t", "<C-h>", [[<C-\><C-n><C-W>h]], opts)
    --   -- vim.keymap.set("t", "<C-j>", [[<C-\><C-n><C-W>j]], opts)
    --   -- vim.keymap.set("t", "<C-k>", [[<C-\><C-n><C-W>k]], opts)
    --   -- vim.keymap.set("t", "<C-l>", [[<C-\><C-n><C-W>l]], opts)
    --
    --   vim.keymap.set("t", "<C-h>", [[<cmd>wincmd h<CR>]], opts)
    --   vim.keymap.set("t", "<C-j>", [[<cmd>wincmd j<CR>]], opts)
    --   vim.keymap.set("t", "<C-k>", [[<cmd>wincmd k<CR>]], opts)
    --   vim.keymap.set("t", "<C-l>", [[<cmd>wincmd l<CR>]], opts)
    -- end
    -- -- if you only want these mappings for toggle term use term://*toggleterm#* instead
    -- vim.cmd("autocmd! TermOpen term://* lua set_terminal_keymaps()")

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
  end,
}

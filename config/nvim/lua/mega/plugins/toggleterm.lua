return function(plug)
  local tt = plug
  if plug == nil then
    tt = require("toggleterm")
  end

  -- TODO: send visual lines to toggleterm:
  --      https://github.com/akinsho/toggleterm.nvim/issues/172
  --      https://github.com/rikuma-t/dotfiles/blob/main/.config/nvim/lua/rc/toggleterm.lua#L29-L56 (dynamic resize/toggling)
  tt.setup({
    open_mapping = [[<c-\>]],
    shade_filetypes = {},
    shade_terminals = true,
    shade_factor = 2,
    direction = "horizontal",
    insert_mappings = true,
    start_in_insert = true,
    close_on_exit = true,
    float_opts = {
      border = mega.get_border(),
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

  mega.command("Htop", function()
    htop:toggle()
  end)

  local has_wk, wk = mega.safe_require("which-key")
  if has_wk then
    wk.register({
      t = {
        name = "terminal",
        t = { "<cmd>ToggleTerm direction=horizontal<cr>", "Horizontal" },
        f = { "<cmd>ToggleTerm direction=float<cr>", "Float" },
        h = { "<cmd>ToggleTerm direction=horizontal<cr>", "Horizontal" },
        v = { "<cmd>ToggleTerm size=80 direction=vertical<cr>", "Vertical" },
      },
    }, {
      prefix = "<leader>",
    })
  end
end

return function()
  local Hydra = require("hydra")
  local gitsigns = require("gitsigns")

  Hydra({
    hint = [[
 _J_: next hunk   _s_: stage hunk        _d_: show deleted   _b_: blame line
 _K_: prev hunk   _u_: undo stage hunk   _p_: preview hunk   _B_: blame show full
 ^ ^              _S_: stage buffer      ^ ^                 _/_: show base file
 ^
 ^ ^              _<Enter>_: Neogit              _q_: exit
]],
    config = {
      name = "Git Management",
      color = "pink",
      invoke_on_body = true,
      hint = {
        position = "bottom",
        border = "rounded",
      },
      on_enter = function()
        vim.bo.modifiable = false
        gitsigns.toggle_signs(true)
        gitsigns.toggle_linehl(true)
      end,
      on_exit = function()
        gitsigns.toggle_signs(false)
        gitsigns.toggle_linehl(false)
        gitsigns.toggle_deleted(false)
        vim.cmd("echo") -- clear the echo area
      end,
    },
    mode = { "n", "x" },
    body = "<leader>g",
    heads = {
      {
        "J",
        function()
          if vim.wo.diff then
            return "]c"
          end
          vim.schedule(function()
            gitsigns.next_hunk()
          end)
          return "<Ignore>"
        end,
        { expr = true },
      },
      {
        "K",
        function()
          if vim.wo.diff then
            return "[c"
          end
          vim.schedule(function()
            gitsigns.prev_hunk()
          end)
          return "<Ignore>"
        end,
        { expr = true },
      },
      { "s", ":Gitsigns stage_hunk<CR>", { silent = true } },
      { "u", gitsigns.undo_stage_hunk },
      { "S", gitsigns.stage_buffer },
      { "p", gitsigns.preview_hunk },
      { "d", gitsigns.toggle_deleted, { nowait = true } },
      { "b", gitsigns.blame_line },
      {
        "B",
        function()
          gitsigns.blame_line({ full = true })
        end,
      },
      { "/", gitsigns.show, { exit = true } }, -- show the base of the file
      { "<Enter>", "<cmd>Neogit<CR>", { exit = true } },
      { "q", nil, { exit = true, nowait = true } },
      { "<Esc>", nil, { exit = true, nowait = true } },
    },
  }, {
    name = "Window Management",
    hint = [[
 ^^^^^^     Move     ^^^^^^   ^^     Split         ^^^^    Size
 ^^^^^^--------------^^^^^^   ^^---------------    ^^^^-------------
 ^ ^ _k_ ^ ^   ^ ^ _K_ ^ ^    _s_: horizontally    _+_ _-_: height
 _h_ ^ ^ _l_   _H_ ^ ^ _L_    _v_: vertically      _>_ _<_: width
 ^ ^ _j_ ^ ^   ^ ^ _J_ ^ ^    _q_: close           ^ _=_ ^: equalize
 focus^^^^^^   window^^^^^^
 ^ ^ ^ ^ ^ ^   ^ ^ ^ ^ ^ ^    _b_: choose buffer   ^ ^ ^ ^    _<Esc>_
]],
    config = {
      hint = {
        position = "bottom",
        border = "rounded",
      },
      color = "blue",
    },
    mode = "n",
    body = "<C-w>",
    -- invoke_on_body = true,
    heads = {
      -- Move focus
      { "h", "<C-w>h" },
      { "j", "<C-w>j" },
      { "k", "<C-w>k" },
      { "l", "<C-w>l" },
      -- Move window
      { "H", "<Cmd>WinShift left<CR>" },
      { "J", "<Cmd>WinShift down<CR>" },
      { "K", "<Cmd>WinShift up<CR>" },
      { "L", "<Cmd>WinShift right<CR>" },
      -- Split
      { "s", "<C-w>s" },
      { "v", "<C-w>v" },
      { "q", "<Cmd>try | close | catch | endtry<CR>", { desc = "close window" } },
      -- Size
      { "+", "<C-w>+" },
      { "-", "<C-w>-" },
      { ">", "2<C-w>>", { desc = "increase width" } },
      { "<", "2<C-w><", { desc = "decrease width" } },
      { "=", "<C-w>=", { desc = "equalize" } },
      --
      { "b", "<Cmd>BufExplorer<CR>", { exit = true, desc = "choose buffer" } },
      { "<Esc>", nil, { exit = true } },
    },
  })
end

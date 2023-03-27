local function linker() return require("gitlinker") end
local function neogit() return require("neogit") end
local function browser_open() return { action_callback = require("gitlinker.actions").open_in_browser } end
return {
  {
    "lewis6991/gitsigns.nvim",
    event = { "BufReadPre", "BufNewFile" },
    opts = {
      signs = {
        add = { hl = "GitSignsAdd", text = "▎" }, -- alts: ┃, │, ▌, ▎ 🮉
        change = { hl = "GitSignsChange", text = "▎" }, -- alts: ║▎
        delete = { hl = "GitSignsDelete", text = "┊" }, -- alts: ▎▎
        topdelete = { hl = "GitSignsDelete", text = "" }, -- alts: ▌
        changedelete = { hl = "GitSignsChange", text = "▌" },
        untracked = { hl = "GitSignsAdd", text = "│" },
      },
      current_line_blame = not vim.fn.getcwd():match("dotfiles"),
      current_line_blame_formatter = " <author>, <author_time> · <summary>",
      preview_config = {
        border = mega.get_border(),
      },
      on_attach = function(bufnr)
        local gs = package.loaded.gitsigns

        -- local function map(mode, l, r, desc) vim.keymap.set(mode, l, r, { buffer = bufnr, desc = desc }) end
        local function bmap(mode, l, r, opts)
          opts = opts or {}
          opts.buffer = bufnr
          vim.keymap.set(mode, l, r, opts)
        end

        mega.nmap("<leader>hu", gs.undo_stage_hunk, { desc = "git(hunk): undo stage" })
        mega.nmap("<leader>hp", gs.preview_hunk_inline, { desc = "git(hunk): preview hunk inline" })
        -- mega.nmap("<leader>hp", gs.preview_hunk, { desc = "git: preview hunk" })
        mega.nmap("<leader>hb", gs.toggle_current_line_blame, { desc = "git(hunk): toggle current line blame" })
        mega.nmap("<leader>hd", gs.toggle_deleted, { desc = "git(hunk): show deleted lines" })
        mega.nmap("<leader>hw", gs.toggle_word_diff, { desc = "git(hunk): toggle word diff" })
        mega.nmap("<localleader>gw", gs.stage_buffer, { desc = "git: stage entire buffer" })
        mega.nmap("<localleader>gre", gs.reset_buffer, { desc = "git: reset entire buffer" })
        mega.nmap("<localleader>gbl", gs.blame_line, { desc = "git: blame current line" })
        mega.nmap("<leader>lm", function() gs.setqflist("all") end, {
          desc = "git: list modified in quickfix",
        })
        -- Navigation
        bmap("n", "[c", function()
          if vim.wo.diff then return "[c" end
          vim.schedule(function() gs.prev_hunk() end)
          return "<Ignore>"
        end, { expr = true, desc = "git: prev hunk" })
        bmap("n", "]c", function()
          if vim.wo.diff then return "]c" end
          vim.schedule(function() gs.next_hunk() end)
          return "<Ignore>"
        end, { expr = true, desc = "git: next hunk" })

        -- Actions
        bmap({ "n", "v" }, "<leader>hs", ":Gitsigns stage_hunk<CR>", { desc = "git: stage hunk" })
        bmap({ "n", "v" }, "<leader>hr", ":Gitsigns reset_hunk<CR>", { desc = "git: reset hunk" })

        -- Text object
        bmap({ "o", "x" }, "ih", ":<C-U>Gitsigns select_hunk<CR>", { desc = "git: select hunk" })

        mega.nmap("[h", function()
          vim.schedule(function() gs.prev_hunk() end)
          return "<Ignore>"
        end, { expr = true, desc = "go to previous git hunk" })
        mega.nmap("]h", function()
          vim.schedule(function() gs.next_hunk() end)
          return "<Ignore>"
        end, { expr = true, desc = "go to next git hunk" })
      end,
    },
  },
  {
    "TimUntersberger/neogit",
    cmd = "Neogit",
    dependencies = { "nvim-lua/plenary.nvim" },
    keys = {
      { "<localleader>gs", function() neogit().open() end, desc = "neogit: open status buffer" },
      { "<localleader>gc", function() neogit().open({ "commit" }) end, desc = "neogit: open commit buffer" },
      { "<localleader>gl", function() neogit().popups.pull.create() end, desc = "neogit: open pull popup" },
      { "<localleader>gp", function() neogit().popups.push.create() end, desc = "neogit: open push popup" },
    },
    config = function()
      neogit().setup({
        disable_signs = false,
        disable_hint = true,
        disable_commit_confirmation = true,
        disable_builtin_notifications = true,
        disable_insert_on_commit = false,
        signs = {
          section = { "", "" }, -- "", ""
          item = { "▸", "▾" },
          hunk = { "樂", "" },
        },
        integrations = {
          diffview = true,
        },
      })

      mega.augroup("Neogit", {
        pattern = "NeogitPushComplete",
        callback = neogit().close,
      })
    end,
  },
  {
    "sindrets/diffview.nvim",
    cmd = { "DiffviewOpen", "DiffviewClose", "DiffviewToggleFiles", "DiffviewFocusFiles", "DiffviewFileHistory" },
    keys = {
      { "<localleader>gd", "<Cmd>DiffviewOpen<CR>", desc = "diffview: open", mode = "n" },
      { "gh", [[:'<'>DiffviewFileHistory<CR>]], desc = "diffview: file history", mode = "v" },
      {
        "<localleader>gh",
        "<Cmd>DiffviewFileHistory<CR>",
        desc = "diffview: file history",
        mode = "n",
      },
    },
    opts = {
      default_args = { DiffviewFileHistory = { "%" } },
      enhanced_diff_hl = true,
      hooks = {
        diff_buf_read = function()
          local opt = vim.opt_local
          opt.wrap, opt.list, opt.relativenumber = false, false, false
          opt.colorcolumn = ""
        end,
      },
      keymaps = {
        view = { q = "<Cmd>DiffviewClose<CR>" },
        file_panel = { q = "<Cmd>DiffviewClose<CR>" },
        file_history_panel = { q = "<Cmd>DiffviewClose<CR>" },
      },
    },
  },
  {
    "akinsho/git-conflict.nvim",
    lazy = false,
    opts = {
      disable_diagnostics = true,
    },
  },
  {
    "ruifm/gitlinker.nvim",
    dependencies = "nvim-lua/plenary.nvim",
    keys = {
      {
        "<localleader>gu",
        function() linker().get_buf_range_url("n") end,
        desc = "gitlinker: copy line to clipboard",
      },
      {
        "<localleader>gu",
        function() linker().get_buf_range_url("v") end,
        desc = "gitlinker: copy range to clipboard",
      },
      {
        "<localleader>go",
        function() linker().get_repo_url(browser_open()) end,
        desc = "gitlinker: open in browser",
      },
      {
        "<localleader>go",
        function() linker().get_buf_range_url("n", browser_open()) end,
        desc = "gitlinker: open current line in browser",
      },
      {
        "<localleader>go",
        function() linker().get_buf_range_url("v", browser_open()) end,
        desc = "gitlinker: open current selection in browser",
      },
    },
    opts = {
      mappings = nil,
    },
  },
}

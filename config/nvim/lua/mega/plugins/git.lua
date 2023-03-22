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

        mega.nmap("<leader>hu", gs.undo_stage_hunk, { desc = "git: undo stage" })
        mega.nmap("<leader>hp", gs.preview_hunk_inline, { desc = "git: preview hunk inline" })
        -- mega.nmap("<leader>hp", gs.preview_hunk, { desc = "git: preview hunk" })
        mega.nmap("<leader>hb", gs.toggle_current_line_blame, { desc = "git: toggle current line blame" })
        mega.nmap("<leader>hd", gs.toggle_deleted, { desc = "git: show deleted lines" })
        mega.nmap("<leader>hw", gs.toggle_word_diff, { desc = "git: toggle word diff" })
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
      { "<localleader>gs", function() require("neogit").open() end, "open status buffer" },
      { "<localleader>gc", function() require("neogit").open({ "commit" }) end, "open commit buffer" },
      { "<localleader>gl", function() require("neogit").popups.pull.create() end, "open pull popup" },
      { "<localleader>gp", function() require("neogit").popups.push.create() end, "open push popup" },
    },
    config = function()
      require("neogit").setup({
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
        callback = require("neogit").close,
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
      { "<localleader>gu", mode = "n" },
      { "<localleader>gu", mode = "v" },
      "<localleader>go",
      "<leader>gH",
      { "<localleader>go", mode = "n" },
      { "<localleader>go", mode = "v" },
    },
    config = function()
      require("gitlinker").setup({ mappings = nil })

      local function linker() return require("gitlinker") end
      local function browser_open() return { action_callback = require("gitlinker.actions").open_in_browser } end
      mega.nnoremap(
        "<localleader>gu",
        function() linker().get_buf_range_url("n") end,
        "gitlinker: copy line to clipboard"
      )
      mega.vnoremap(
        "<localleader>gu",
        function() linker().get_buf_range_url("v") end,
        "gitlinker: copy range to clipboard"
      )
      mega.nnoremap(
        "<localleader>go",
        function() linker().get_repo_url(browser_open()) end,
        "gitlinker: open in browser"
      )
      mega.nnoremap("<leader>gH", function() linker().get_repo_url(browser_open()) end, "gitlinker: open in browser")
      mega.nnoremap(
        "<localleader>go",
        function() linker().get_buf_range_url("n", browser_open()) end,
        "gitlinker: open current line in browser"
      )
      mega.vnoremap(
        "<localleader>go",
        function() linker().get_buf_range_url("v", browser_open()) end,
        "gitlinker: open current selection in browser"
      )
    end,
  },
}

local function linker() return require("gitlinker") end
local function neogit() return require("neogit") end
local function browser_open() return { action_callback = require("gitlinker.actions").open_in_browser } end
local git_keys = {}

if vim.g.gitter == "neogit" then
  git_keys = {
    { "<leader>G", function() require("neogit").open() end, desc = "neogit: open status buffer" },
    {
      "<localleader>gc",
      function() require("neogit").open({ "commit", "-v" }) end,
      desc = "neogit: open commit buffer",
    },
    { "<localleader>gl", function() require("neogit").popups.pull.create() end, desc = "neogit: open pull popup" },
    { "<localleader>gp", function() require("neogit").popups.push.create() end, desc = "neogit: open push popup" },
    {
      "<localleader>gbb",
      function()
        local line = vim.api.nvim_win_get_cursor(0)[1]
        local line_range = line .. "," .. line

        local annotation =
          vim.fn.systemlist("git annotate -M --porcelain " .. vim.fn.expand("%:p") .. " -L" .. line_range)[1]
        if vim.v.shell_error ~= 0 then
          vim.notify(annotation, vim.log.levels.ERROR)
          return
        end

        local ref = vim.split(annotation, " ")[1]
        if ref == "0000000000000000000000000000000000000000" then
          vim.notify("Not committed yet", vim.log.levels.WARN)
          return
        end

        local commit_view = require("neogit.buffers.commit_view").new(ref, false)
        commit_view:open()
      end,
      desc = "git: view full line blame commit",
    },
  }
elseif vim.g.gitter == "fugitive" then
  git_keys = {
    { "<leader>G", "<cmd>Git<cr>", desc = "git: open status buffer" },
    {
      "<localleader>gc",
      "<cmd>tabn|Git commit<cr>",
      desc = "git: open commit buffer",
    },
    {
      "<localleader>gp",
      "<cmd>Git push<cr>",
      desc = "git: push commit(s)",
    },
    -- { "<localleader>gl", function() require("neogit").popups.pull.create() end, desc = "neogit: open pull popup" },
    -- { "<localleader>gp", function() require("neogit").popups.push.create() end, desc = "neogit: open push popup" },
    -- {
    --   "<localleader>gbb",
    --   function()
    --     local line = vim.api.nvim_win_get_cursor(0)[1]
    --     local line_range = line .. "," .. line
    --
    --     local annotation =
    --       vim.fn.systemlist("git annotate -M --porcelain " .. vim.fn.expand("%:p") .. " -L" .. line_range)[1]
    --     if vim.v.shell_error ~= 0 then
    --       vim.notify(annotation, vim.log.levels.ERROR)
    --       return
    --     end
    --
    --     local ref = vim.split(annotation, " ")[1]
    --     if ref == "0000000000000000000000000000000000000000" then
    --       vim.notify("Not committed yet", vim.log.levels.WARN)
    --       return
    --     end
    --
    --     local commit_view = require("neogit.buffers.commit_view").new(ref, false)
    --     commit_view:open()
    --   end,
    --   desc = "git: view full line blame commit",
    -- },
  }
end

return {
  {
    "lewis6991/gitsigns.nvim",
    event = { "BufReadPre", "BufNewFile" },
    opts = {
      -- experimental things -----------
      _extmark_signs = vim.g.enabled_plugin["statuscolumn"],
      _inline2 = true,
      _signs_staged_enable = false,
      -- -------------------------------
      signs = {
        add = { hl = "GitSignsAdd", culhl = "GitSignsAddCursorLine", numhl = "GitSignsAddNum", text = "▕" }, -- alts: ▕, ▎, ┃, │, ▌, ▎ 🮉
        change = {
          hl = "GitSignsChange",
          culhl = "GitSignsChangeCursorLine",
          numhl = "GitSignsChangeNum",
          text = "▕",
        }, -- alts: ▎║▎
        delete = {
          hl = "GitSignsDelete",
          culhl = "GitSignsDeleteCursorLine",
          numhl = "GitSignsDeleteNum",
          text = "🮉",
        }, -- alts: ┊▎▎
        topdelete = { hl = "GitSignsDelete", text = "🮉" }, -- alts: ▌ ▄▀
        changedelete = { hl = "GitSignsChange", text = "🮉" }, -- alts: ▌
        untracked = { hl = "GitSignsAdd", text = "▕" }, -- alts: ┆ ▕
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

        mega.nmap("<localleader>hu", gs.undo_stage_hunk, { desc = "git(hunk): undo stage" })
        mega.nmap("<localleader>hr", gs.reset_hunk, { desc = "git(hunk): reset hunk" })
        mega.nmap("<localleader>hp", gs.preview_hunk_inline, { desc = "git(hunk): preview hunk inline" })
        -- mega.nmap("<leader>hp", gs.preview_hunk, { desc = "git: preview hunk" })
        mega.nmap("<localleader>hd", gs.toggle_deleted, { desc = "git(hunk): show deleted lines" })
        mega.nmap("<localleader>hw", gs.toggle_word_diff, { desc = "git(hunk): toggle word diff" })
        mega.nmap("<localleader>gw", gs.stage_buffer, { desc = "git: stage entire buffer" })
        mega.nmap("<localleader>gre", gs.reset_buffer, { desc = "git: reset entire buffer" })
        mega.nmap("<localleader>grh", gs.reset_hunk, { desc = "git: reset hunk" })
        mega.nmap("<localleader>gbt", gs.toggle_current_line_blame, { desc = "git: toggle current line blame" })
        mega.nmap("<localleader>gbl", gs.blame_line, { desc = "git: view current line blame" })
        mega.nmap("<leader>gm", function() gs.setqflist("all") end, {
          desc = "git: list modified in quickfix",
        })
        mega.nmap("<leader>gd", function() gs.diffthis() end, {
          desc = "git: diff this",
        })
        mega.nmap("<leader>gD", function() gs.diffthis("~") end, {
          desc = "git: diff this against ~",
        })
        -- Navigation
        bmap("n", "[h", function()
          if vim.wo.diff then return "[c" end
          vim.schedule(function() gs.prev_hunk() end)
          return "<Ignore>"
        end, { expr = true, desc = "git: prev hunk" })
        bmap("n", "]h", function()
          if vim.wo.diff then return "]c" end
          vim.schedule(function() gs.next_hunk() end)
          return "<Ignore>"
        end, { expr = true, desc = "git: next hunk" })

        -- Actions
        bmap({ "n", "v" }, "<localleader>hs", ":Gitsigns stage_hunk<CR>", { desc = "git: stage hunk" })
        bmap({ "n", "v" }, "<localleader>gs", ":Gitsigns stage_hunk<CR>", { desc = "git: stage hunk" })
        bmap({ "n", "v" }, "<localleader>hr", ":Gitsigns reset_hunk<CR>", { desc = "git: reset hunk" })
        bmap({ "n", "v" }, "<localleader>gu", ":Gitsigns reset_hunk<CR>", { desc = "git: reset hunk" })

        -- Text object
        bmap({ "o", "x" }, "ih", ":<C-U>Gitsigns select_hunk<CR>", { desc = "git: select hunk" })

        -- mega.nmap("[h", function()
        --   vim.schedule(function() gs.prev_hunk() end)
        --   return "<Ignore>"
        -- end, { expr = true, desc = "go to previous git hunk" })
        -- mega.nmap("]h", function()
        --   vim.schedule(function() gs.next_hunk() end)
        --   return "<Ignore>"
        -- end, { expr = true, desc = "go to next git hunk" })
      end,
    },
  },
  {
    "tpope/vim-fugitive",
    cmd = "Git",
    keys = git_keys,
  },
  {
    "rhysd/committia.vim",
    -- event = "BufReadPre COMMIT_EDITMSG",
    init = function()
      -- See: https://github.com/rhysd/committia.vim#variables
      vim.g.committia_min_window_width = 30
      vim.g.committia_edit_window_width = 100
    end,
    config = function()
      vim.g.committia_hooks = {
        edit_open = function()
          vim.cmd.resize(25)
          local opts = {
            buffer = vim.api.nvim_get_current_buf(),
            silent = true,
          }
          local function map(mode, lhs, rhs) vim.keymap.set(mode, lhs, rhs, opts) end
          map("n", "q", "<cmd>quit<CR>")
          map("i", "<C-d>", "<Plug>(committia-scroll-diff-down-half)")
          map("i", "<C-u>", "<Plug>(committia-scroll-diff-up-half)")
          map("i", "<C-f>", "<Plug>(committia-scroll-diff-down-page)")
          map("i", "<C-b>", "<Plug>(committia-scroll-diff-up-page)")
          map("i", "<C-j>", "<Plug>(committia-scroll-diff-down)")
          map("i", "<C-k>", "<Plug>(committia-scroll-diff-up)")
        end,
      }
    end,
  },
  {
    "NeogitOrg/neogit",
    cmd = "Neogit",
    dependencies = { "nvim-lua/plenary.nvim" },
    -- commit = "b89ef391d20f45479e92bd4190e444c9ec9163a3",
    keys = git_keys,
    config = function()
      neogit().setup({
        disable_signs = false,
        disable_hint = true,
        disable_commit_confirmation = true,
        disable_builtin_notifications = true,
        disable_insert_on_commit = false,
        signs = {
          section = { "", "" }, -- "󰁙", "󰁊"
          item = { "▸", "▾" },
          hunk = { "󰐕", "󰍴" },
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
    event = { "BufReadPre", "BufWritePre" },
    config = function()
      require("git-conflict").setup({
        disable_diagnostics = true,
      })

      mega.augroup("GitConflicts", {
        {
          event = { "User" },
          pattern = { "GitConflictDetected" },
          command = function(args)
            vim.g.git_conflict_detected = true
            mega.nnoremap(
              "cq",
              "<cmd>GitConflictListQf<CR>",
              { desc = "git-conflict: send conflicts to qf", buffer = args.buf }
            )
            mega.nnoremap(
              "[c",
              "<cmd>GitConflictPrevConflict<CR>|zz",
              { desc = "git-conflict: prev conflict", buffer = args.buf }
            )
            mega.nnoremap(
              "]c",
              "<cmd>GitConflictNextConflict<CR>|zz",
              { desc = "git-conflict: next conflict", buffer = args.buf }
            )
            mega.notify(fmt("%s Conflicts detected.", mega.icons.lsp.error))

            vim.defer_fn(function()
              vim.diagnostic.disable(args.buf)
              vim.lsp.stop_client(vim.lsp.get_clients())

              local ok, gd = pcall(require, "garbage-day.utils")
              if ok then gd.stop_lsp() end
              vim.diagnostic.hide()
            end, 250)
          end,
        },
        {
          event = { "User" },
          pattern = { "GitConflictResolved" },
          command = function(args)
            mega.notify(fmt("%s All conflicts resolved!", mega.icons.lsp.ok))
            vim.defer_fn(function()
              vim.diagnostic.enable(args.buf)
              vim.cmd("LspStart")
              vim.g.git_conflict_detected = false

              local ok, gd = pcall(require, "garbage-day.utils")
              if ok then
                local stopped_lsp_clients = gd.stop_lsp()
                gd.start_lsp(stopped_lsp_clients)
              end
              vim.diagnostic.show()
            end, 250)
          end,
        },
      })
    end,
  },
  {
    "f-person/git-blame.nvim",
    cmd = {
      "GitBlameOpenCommitURL",
      "GitBlameOpenFileURL",
      "GitBlameCopyCommitURL",
      "GitBlameCopyFileURL",
      "GitBlameCopySHA",
    },
    keys = {
      { "<localleader>gB", "<Cmd>GitBlameOpenCommitURL<CR>", desc = "git blame: open commit url", mode = "n" },
    },
    init = function() vim.g.gitblame_enabled = 0 end,
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
        mode = { "v" },
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
        mode = { "v" },
      },
    },
    opts = {
      mappings = nil,
    },
  },
}

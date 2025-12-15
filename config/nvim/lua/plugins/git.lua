local icons = Icons

local git_keys = {}
vim.g.gitter = "neogit"

if vim.g.gitter == "neogit" then
  git_keys = {
    {
      "<leader>gS",
      function() require("neogit").open() end,
      desc = "neogit: open status buffer",
    },
    {
      "<leader>gg",
      function() require("neogit").open() end,
      desc = "neogit: open status buffer",
    },
    {
      "<localleader>gc",
      function() require("neogit").open({ "commit", "-v" }) end,
      desc = "neogit: open commit buffer",
    },
    {
      "<localleader>gl",
      function() require("neogit").popups.pull.create() end,
      desc = "neogit: pull commit(s)",
    },
    {
      "<localleader>gp",
      function() require("neogit").popups.push.create() end,
      desc = "neogit: push commit(s)",
    },
    {
      "<leader>gf",
      function() require("neogit").action("log", "log_current", { "--", vim.fn.expand("%") })() end,
      desc = "neogit: git log for file",
    },
    {
      "<leader>gf",
      function()
        local file = vim.fn.expand("%")
        vim.cmd([[execute "normal! \<ESC>"]])
        local line_start = vim.fn.getpos("'<")[2]
        local line_end = vim.fn.getpos("'>")[2]

        require("neogit").action("log", "log_current", { "-L" .. line_start .. "," .. line_end .. ":" .. file })()
      end,
      desc = "neogit: git log for selection",
      mode = "v",
    },
    {
      "<leader>gbc",
      function()
        local current_file = vim.loop.fs_realpath(vim.api.nvim_buf_get_name(0))
        if current_file then
          local result = vim
            .system({ "git", "blame", "-L" .. vim.fn.line(".") .. "," .. vim.fn.line("."), current_file }, { text = true })
            :wait()

          local commit_sha, _ = result.stdout:gsub("%s.*$", "")
          vim.cmd("DiffviewOpen " .. commit_sha .. "^.." .. commit_sha)
        end
      end,
      desc = "git: blame commit",
    },
    {
      "<localleader>gbl",
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
      desc = "neogit: view full line blame commit",
    },
  }
elseif vim.g.gitter == "fugitive" then
  git_keys = {
    { "<leader>gS", "<cmd>Git<cr>", desc = "git: open status buffer" },
    { "<leader>gg", "<cmd>Git<cr>", desc = "git: open status buffer" },
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
    {
      "<localleader>gl",
      "<cmd>Git pull<cr>",
      desc = "git: pull commit(s)",
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
    "esmuellert/vscode-diff.nvim",
    dependencies = { "MunifTanjim/nui.nvim" },
    cmd = "CodeDiff",
  },
  {
    "nvim-mini/mini.diff",
    version = false,
    config = function()
      vim.schedule(function()
        require("mini.diff").setup({
          view = {
            -- Visualization style. Possible values are 'sign' and 'number'.
            -- Default: 'number' if line numbers are enabled, 'sign' otherwise.
            style = "sign",

            -- Signs used for hunks with 'sign' view
            signs = { add = "", change = "", delete = "" },

            -- Priority of used visualization extmarks
            priority = 1,
          },
        })
      end)

      -- Keymaps
      local nmap_localleader = function(suffix, rhs, desc)
        vim.keymap.set("n", "<localleader>" .. suffix, rhs, { desc = desc })
      end
      local nmap_leader = function(suffix, rhs, desc) vim.keymap.set("n", "<Leader>" .. suffix, rhs, { desc = desc }) end

      nmap_localleader("gd", "<Cmd>lua MiniDiff.toggle_overlay()<CR>", "git: toggle diff overlay")
    end,

    -- keys = {
    --   {
    --     "<localleader>gd",
    --     function() MiniDiff.toggle_overlay() end,
    --     "Toggle Diff Overlay",
    --   },
    -- },
  },
  {
    "julienvincent/hunk.nvim",
    cmd = { "DiffEditor" },
    config = function() require("hunk").setup() end,
  },
  -- Here is a more advanced example where we pass configuration
  -- options to `gitsigns.nvim`. This is equivalent to the following Lua:
  --    require('gitsigns').setup({ ... })
  --
  -- See `:help gitsigns` to understand what the configuration keys do
  { -- Adds git related signs to the gutter, as well as utilities for managing changes
    "lewis6991/gitsigns.nvim",
    opts = {
      -- signs = {
      --   add = { text = "+" },
      --   change = { text = "~" },
      --   delete = { text = "_" },
      --   topdelete = { text = "‾" },
      --   changedelete = { text = "~" },
      -- },

      signs = {
        add = {
          -- hl = "GitSignsAdd",
          -- culhl = "GitSignsAddCursorLine",
          -- numhl = "GitSignsAddNum",
          text = icons.git.add,
        }, -- alts: ▕, ▎, ┃, │, ▌, ▎ 🮉
        change = {
          -- hl = "GitSignsChange",
          -- culhl = "GitSignsChangeCursorLine",
          -- numhl = "GitSignsChangeNum",
          text = icons.git.change,
        }, -- alts: ▎║▎
        delete = {
          -- hl = "GitSignsDelete",
          -- culhl = "GitSignsDeleteCursorLine",
          -- numhl = "GitSignsDeleteNum",
          text = icons.git.delete,
        }, -- alts: ┊▎▎
        topdelete = {
          -- hl = "GitSignsDelete",
          text = icons.git.topdelete,
        }, -- alts: ▌ ▄▀
        changedelete = {
          -- hl = "GitSignsChange",
          text = icons.git.changedelete,
        }, -- alts: ▌
        untracked = {
          -- hl = "GitSignsAdd",
          text = icons.git.untracked,
        }, -- alts: ┆ ▕
        signs_staged = {
          change = { text = "┋" },
          delete = { text = "🢒" },
        },
      },
      current_line_blame = false, -- not vim.fn.getcwd():match("dotfiles") and not vim.fn.getcwd():match("canonize"),
      current_line_blame_formatter = " <author>, <author_time> · <summary>",
      current_line_blame_opts = {
        virt_text = true,
        virt_text_pos = "right_align", -- 'eol' | 'overlay' | 'right_align'
        delay = 500,
        ignore_whitespace = false,
        virt_text_priority = 100,
      },
      preview_config = {
        border = vim.g.border,
      },
      on_attach = function(bufnr)
        local gs = package.loaded.gitsigns

        local function map(mode, l, r, opts) vim.keymap.set(mode, l, r, opts) end
        local function nmap(l, r, desc) map("n", l, r, { desc = desc }) end
        local function bmap(l, r, desc) map("n", l, r, { buffer = bufnr, desc = desc }) end
        local function hmap(l, r, desc) map({ "n", "v" }, l, r, { buffer = bufnr, desc = desc }) end

        nmap("<leader>gm", function() gs.setqflist("all") end, "git: list modified in quickfix")

        map("n", "[h", function()
          if vim.wo.diff then return "[c" end
          vim.schedule(function() gs.nav_hunk("prev") end)
          return "<Ignore>"
        end, { expr = true, desc = "git: prev hunk" })
        map("n", "]h", function()
          if vim.wo.diff then return "]c" end
          vim.schedule(function() gs.nav_hunk("next") end)
          return "<Ignore>"
        end, { expr = true, desc = "git: next hunk" })

        hmap("<localleader>hs", gs.stage_hunk, "git(hunk): stage hunk")
        hmap("<localleader>hu", gs.undo_stage_hunk, "git(hunk): undo stage")
        hmap("<localleader>hr", gs.reset_hunk, "git(hunk): reset hunk")
        hmap("<localleader>hp", gs.preview_hunk, "git(hunk): preview hunk")

        hmap("<localleader>hd", gs.toggle_deleted, "git(hunk): show deleted lines")
        hmap("<localleader>hw", gs.toggle_word_diff, "git(hunk): toggle word diff")

        hmap("<localleader>gs", gs.stage_hunk, "git(hunk): stage hunk")
        map("x", "<localleader>gs", function() gs.stage_hunk({ vim.fn.line("."), vim.fn.line("v") }) end)
        hmap("<localleader>gr", gs.reset_hunk, "git(hunk): reset hunk")
        map("x", "<localleader>gr", function() gs.reset_hunk({ vim.fn.line("."), vim.fn.line("v") }) end)
        hmap("<localleader>gu", gs.undo_stage_hunk, "git(hunk): undo staged hunk")
        map("x", "<localleader>gu", function() gs.undo_stage_hunk({ vim.fn.line("."), vim.fn.line("v") }) end)

        bmap("<localleader>gS", gs.stage_buffer, "git: stage buffer")
        bmap("<localleader>gR", gs.reset_buffer, "git: reset buffer")

        -- bmap("<localleader>gd", function() gs.diffthis() end, "git: diff this")
        bmap("<localleader>gD", function() gs.diffthis("~") end, "git: diff this against ~")

        -- Text object
        map({ "o", "x" }, "ih", ":<C-U>Gitsigns select_hunk<CR>", { desc = "git: select hunk" })
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
      vim.g.committia_use_singlecolumn = "always"
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
          map("n", "q", "<cmd>cquit!<CR>")
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
    branch = "master",
    dependencies = { "nvim-lua/plenary.nvim" },
    -- commit = "b89ef391d20f45479e92bd4190e444c9ec9163a3",
    keys = git_keys,
    opts = {
      disable_signs = false,
      disable_hint = true,
      disable_commit_confirmation = true,
      disable_builtin_notifications = true,
      disable_insert_on_commit = false,
      fetch_after_checkout = true,
      signs = {
        section = { "", "" }, -- "󰁙", "󰁊"
        item = { "▸", "▾" },
        hunk = { "󰐕", "󰍴" },
      },
      integrations = {
        diffview = true,
        mini_pick = true,
      },
      graph_style = "kitty",
      process_spinner = "true",
    },
    config = function(_, opts)
      require("neogit").setup(opts)

      Augroup("Neogit", {
        pattern = "NeogitPushComplete",
        callback = require("neogit").close,
      })
    end,
  },
  {
    "sindrets/diffview.nvim",
    cmd = { "DiffviewOpen", "DiffviewClose", "DiffviewToggleFiles", "DiffviewFocusFiles", "DiffviewFileHistory" },
    keys = {
      {
        "<leader>gd",
        function()
          vim.g.disable_autoresize = true
          vim.cmd("ToggleAutoResize")
          vim.cmd("DiffviewOpen")
        end,
        desc = "diffview: open",
        mode = "n",
      },
      { "gh", [[:'<'>DiffviewFileHistory<CR>]], desc = "diffview: file history", mode = "v" },
      {
        "<localleader>gh",
        "<Cmd>DiffviewFileHistory<CR>",
        desc = "diffview: file history",
        mode = "n",
      },
      -- { "<localleader>gb", "<cmd>DiffviewFileHistory %<cr>", desc = "Show git history", mode = { "n", "x" } },
      -- { "<localleader>gb", ":DiffviewFileHistory<cr>", desc = "Show git history", mode = { "v" } },
    },
    opts = {
      default_args = { DiffviewFileHistory = { "%" } },
      enhanced_diff_hl = true,
      hooks = {
        diff_buf_read = function()
          local opt = vim.opt_local
          opt.wrap = false
          opt.list = false
          opt.relativenumber = false
          opt.colorcolumn = ""
        end,
      },
      file_panel = {
        listing_style = "tree",
        tree_options = {
          flatten_dirs = true,
          folder_statuses = "only_folded",
        },
        win_config = function()
          local editor_width = vim.o.columns
          return {
            -- position = "left",
            -- width = editor_width >= 247 and 45 or 35,
            -- width = 100,
            -- width = editor_width >= 247 and 45 or 35,
            type = "split",
            position = "right",
            width = 50,
          }
        end,
      },
      file_history_panel = {
        log_options = {
          git = {
            single_file = {
              diff_merges = "first-parent",
              follow = true,
            },
            multi_file = {
              diff_merges = "first-parent",
            },
          },
        },
        win_config = {
          position = "bottom",
          height = 16,
        },
      },
      keymaps = {
        -- view = { q = "<Cmd>DiffviewClose<CR>" },
        -- disable_defaults = false, -- Disable the default keymaps
        view = {
          -- The `view` bindings are active in the diff buffers, only when the current
          -- tabpage is a Diffview.
          { "n", "q", "<Cmd>DiffviewClose<CR>", { desc = "close diffview" } },
          -- { "n", "<tab>", require("diffview.actions").select_next_entry, { desc = "Open the diff for the next file" } },
          -- { "n", "<s-tab>", require("diffview.actions").select_prev_entry, { desc = "Open the diff for the previous file" } },
          -- { "n", "[F", require("diffview.actions").select_first_entry, { desc = "Open the diff for the first file" } },
          -- { "n", "]F", require("diffview.actions").select_last_entry, { desc = "Open the diff for the last file" } },
          -- { "n", "gf", require("diffview.actions").goto_file_edit, { desc = "Open the file in the previous tabpage" } },
          -- { "n", "<C-w><C-f>", require("diffview.actions").goto_file_split, { desc = "Open the file in a new split" } },
          -- { "n", "<C-w>gf", require("diffview.actions").goto_file_tab, { desc = "Open the file in a new tabpage" } },
          -- { "n", "<leader>e", require("diffview.actions").focus_files, { desc = "Bring focus to the file panel" } },
          -- { "n", "<leader>b", require("diffview.actions").toggle_files, { desc = "Toggle the file panel." } },
          -- { "n", "g<C-x>", require("diffview.actions").cycle_layout, { desc = "Cycle through available layouts." } },
          -- { "n", "[x", require("diffview.actions").prev_conflict, { desc = "In the merge-tool: jump to the previous conflict" } },
          -- { "n", "]x", require("diffview.actions").next_conflict, { desc = "In the merge-tool: jump to the next conflict" } },
          -- { "n", "<leader>co", require("diffview.actions").conflict_choose("ours"), { desc = "Choose the OURS version of a conflict" } },
          -- { "n", "<leader>ct", require("diffview.actions").conflict_choose("theirs"), { desc = "Choose the THEIRS version of a conflict" } },
          -- { "n", "<leader>cb", require("diffview.actions").conflict_choose("base"), { desc = "Choose the BASE version of a conflict" } },
          -- { "n", "<leader>ca", require("diffview.actions").conflict_choose("all"), { desc = "Choose all the versions of a conflict" } },
          -- { "n", "dx", require("diffview.actions").conflict_choose("none"), { desc = "Delete the conflict region" } },
          -- { "n", "<leader>cO", require("diffview.actions").conflict_choose_all("ours"), { desc = "Choose the OURS version of a conflict for the whole file" } },
          -- {
          --   "n",
          --   "<leader>cT",
          --   require("diffview.actions").conflict_choose_all("theirs"),
          --   { desc = "Choose the THEIRS version of a conflict for the whole file" },
          -- },
          -- { "n", "<leader>cB", require("diffview.actions").conflict_choose_all("base"), { desc = "Choose the BASE version of a conflict for the whole file" } },
          -- { "n", "<leader>cA", require("diffview.actions").conflict_choose_all("all"), { desc = "Choose all the versions of a conflict for the whole file" } },
          -- { "n", "dX", require("diffview.actions").conflict_choose_all("none"), { desc = "Delete the conflict region for the whole file" } },
        },
        file_panel = { q = "<Cmd>DiffviewClose<CR>" },
        file_history_panel = { q = "<Cmd>DiffviewClose<CR>" },
      },
    },
  },
  {
    "megalithic/git-conflict.nvim",
    event = { "BufReadPre", "BufWritePre" },
    opts = {
      disable_diagnostics = true,
      disable_mappings = true,
      list_opener = "copen", -- command or function to open the conflicts list
      highlights = { -- They must have background color, otherwise the default color will be used
        incoming = "GitConflictIncoming",
        current = "GitConflictCurrent",
        ancestor = "GitConflictAncestor",
      },
    },
    config = function(_, opts)
      local conflict = require("git-conflict")
      conflict.setup(opts)
      Augroup("GitConflicts", {
        {
          event = { "User" },
          pattern = { "GitConflictDetected" },
          command = function(args)
            vim.b[args.buf].git_conflict_detected = true

            nnoremap("co", "<Plug>(git-conflict-ours)", { desc = "git-[c]onflict: resolve with [o]urs/current" })
            nnoremap("cc", "<Plug>(git-conflict-ours)", { desc = "git-[c]onflict: resolve with [c]urrent/ours" })
            nnoremap("ct", "<Plug>(git-conflict-theirs)", { desc = "git-[c]onflict: resolve with [t]heirs/incoming" })
            nnoremap("ci", "<Plug>(git-conflict-theirs)", { desc = "git-[c]onflict: resolve with [i]ncoming/theirs" })
            nnoremap("cb", "<Plug>(git-conflict-both)", { desc = "git-[c]onflict: resolve with [b]oth" })
            nnoremap("c0", "<Plug>(git-conflict-none)", { desc = "git-[c]onflict: no resolution" })
            nnoremap("cn", "<Plug>(git-conflict-none)", { desc = "git-[c]onflict: resolve [n]othing" })
            nnoremap("cq", "<cmd>GitConflictListQf<CR>", { desc = "git-[c]onflict: send conflicts to [q]f" })
            nnoremap("[c", function()
              conflict.find_prev("ours")
              vim.schedule_wrap(function()
                vim.cmd.norm("zz")
                pcall(mega.blink_cursorline)
              end)
            end, { desc = "git-[c]onflict: prev conflict" })
            nnoremap("]c", function()
              conflict.find_next("ours")
              vim.schedule_wrap(function()
                vim.cmd.norm("zz")
                pcall(mega.blink_cursorline)
              end)
            end, { desc = "git-[c]onflict: next conflict" })

            if pcall(require, "fidget") then vim.cmd("Fidget suppress true") end
            mega.notify(string.format("%s Conflicts detected.", icons.lsp.error))
          end,
        },
        {
          event = { "User" },
          pattern = { "GitConflictResolved" },
          command = function(args)
            vim.b[args.buf].git_conflict_detected = false
            if pcall(require, "fidget") then vim.cmd("Fidget suppress false") end
            mega.notify(string.format("%s All conflicts resolved!", icons.lsp.ok))
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
    "linrongbin16/gitlinker.nvim",
    dependencies = "nvim-lua/plenary.nvim",
    cmd = { "GitLink" },
    keys = {
      {
        "<localleader>go",
        "<cmd>GitLink!<cr>",
        desc = "gitlinker: open in browser",
        mode = { "n", "v" },
      },
      {
        "<localleader>gO",
        "<cmd>GitLink<cr>",
        desc = "gitlinker: copy to clipboard",
        mode = { "n", "v" },
      },
      {
        "<localleader>gb",
        "<cmd>GitLink! blame<cr>",
        desc = "gitlinker: blame in browser",
        mode = { "n", "v" },
      },
      {
        "<localleader>gB",
        "<cmd>GitLink blame<cr>",
        desc = "gitlinker: copy blame to clipboard",
        mode = { "n", "v" },
      },
    },
    opts = {
      -- print message in command line
      message = true,

      -- highlights the linked line(s) by the time in ms
      -- disable highlight by setting a value equal or less than 0
      highlight_duration = 500,

      -- user command
      command = {
        -- to copy link to clipboard, use: 'GitLink'
        -- to open link in browser, use bang: 'GitLink!'
        -- to use blame router, use: 'GitLink blame' and 'GitLink! blame'
        name = "GitLink",
        desc = "Generate git permanent link",
      },
      mappings = nil,
      debug = true,
      file_log = true,
    },
  },
  -- {
  --   cond = false,
  --   "Juksuu/worktrees.nvim",
  --   event = "VeryLazy",
  --   keys = {
  --     {
  --       "<leader>gww",
  --       "<cmd>lua require('telescope').extensions.worktrees.list_worktrees()<cr>",
  --       desc = "git-worktree: switch worktree",
  --       -- mode = { "n", "v" },
  --     },
  --     {
  --       "<leader>gwn",
  --       "<cmd>GitWorktreeCreate<cr>",
  --       desc = "git-worktree: create worktree",
  --     },
  --     {
  --       "<leader>gwc",
  --       "<cmd>GitWorktreeCreateExisting<cr>",
  --       desc = "git-worktree: create existing worktree",
  --     },
  --   },
  --   config = function()
  --     -- telescope.load_extension("git_worktree")
  --     require("worktrees").setup({})
  --     require("telescope").load_extension("worktrees")
  --   end,
  -- },
  -- {
  --   -- "mgierada/git-worktree.nvim",
  --   -- branch = "adapt-for-telescope-api-changes",

  --   "awerebea/git-worktree.nvim", -- Temporary switch to fork
  --   branch = "main",
  --   event = "VeryLazy",
  --   keys = {
  --     {
  --       "<leader>gww",
  --       function() require("telescope").extensions.git_worktree.git_worktrees(mega.picker.dropdown({ path_display = {} })) end,
  --       desc = "git-worktree: switch worktree",
  --     },
  --     {
  --       "<leader>gwc",
  --       function() require("telescope").extensions.git_worktree.create_git_worktree() end,
  --       desc = "git-worktree: create worktree",
  --     },
  --   },
  --   opts = {},
  --   config = function()
  --     local wt = require("git-worktree")
  --     require("telescope").load_extension("git_worktree")
  --     wt.on_tree_change(function(op, metadata)
  --       if op == wt.Operations.Switch then
  --         vim.notify("Switched from " .. metadata.prev_path .. " to " .. metadata.path)
  --       elseif op == wt.Operations.Create then
  --         vim.notify("Worktree created: " .. metadata.path .. " for branch " .. metadata.branch .. " with upstream " .. metadata.upstream)
  --       elseif op == wt.Operations.Delete then
  --         vim.notify("Worktree deleted: " .. metadata.path)
  --       end
  --     end)
  --   end,
  -- },
}

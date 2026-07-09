return {
  {
    "esmuellert/codediff.nvim",
    cond = function()
      local root = vim.fs.root(0, { ".jj", ".git" }) or vim.uv.cwd()
      return vim.uv.fs_stat(root .. "/.git") ~= nil and vim.uv.fs_stat(root .. "/.jj") == nil
    end,
    dependencies = { "MunifTanjim/nui.nvim" },
    cmd = "CodeDiff",
    event = "VeryLazy",
    keys = {
      -- Workspace level
      { "<leader>gwd", "<cmd>CodeDiff<cr>", desc = "Workspace [D]iff (CodeDiff)" },
      { "<leader>gwD", "<cmd>CodeDiff main<cr>", desc = "Workspace [D]iff main (CodeDiff)" },

      -- Document level
      { "<leader>gdd", "<cmd>CodeDiff file HEAD<cr>", desc = "Document [D]iff (CodeDiff)" },
      { "<leader>gdD", "<cmd>CodeDiff file main<cr>", desc = "Document [D]iff main (CodeDiff)" },

      -- {
      --   "<leader>wgb",
      --   function()
      --     vim.ui.input({ prompt = "Compare against branch: " }, function(branch)
      --       if branch and branch ~= "" then vim.cmd("CodeDiff " .. branch) end
      --     end)
      --   end,
      --   desc = "Compare [B]ranch (CodeDiff)",
      -- },
      --
      -- { "<leader>wgpm", "<cmd>CodeDiff merge<cr>", desc = "[M]erge conflicts (CodeDiff)" },
    },
    opts = {
      char_brightness = 1, -- disable auto-adjustment
      diff = {
        layout = "inline",
      },
      explorer = {
        view_mode = "tree",
      },
      keymaps = {
        view = {
          quit = "q",
          toggle_explorer = "<leader>b",
          focus_explorer = "<leader>e",
          next_hunk = "]c",
          prev_hunk = "[c",
          next_file = "]f",
          prev_file = "[f",
          diff_get = "do",
          diff_put = "dp",
          open_in_prev_tab = "gf",
          close_on_open_in_prev_tab = false,
          toggle_stage = "-",
          hunk_textobject = "ih",
          show_help = "g?",
          align_move = "gm",
          toggle_layout = "t",
        },
        explorer = {
          select = "<CR>",
          hover = "K",
          refresh = "R",
          open_in_prev_tab = "gf",
          toggle_view_mode = "i",
          stage_all = "S",
          unstage_all = "U",
          restore = "X",
          toggle_changes = "gu",
          toggle_staged = "gs",
          fold_open = "zo",
          fold_open_recursive = "zO",
          fold_close = "zc",
          fold_close_recursive = "zC",
          fold_toggle = "za",
          fold_toggle_recursive = "zA",
          fold_open_all = "zR",
          fold_close_all = "zM",
        },
        history = {
          select = "<CR>",
          toggle_view_mode = "i",
          fold_open = "zo",
          fold_open_recursive = "zO",
          fold_close = "zc",
          fold_close_recursive = "zC",
          fold_toggle = "za",
          fold_toggle_recursive = "zA",
          fold_open_all = "zR",
          fold_close_all = "zM",
        },
        conflict = {
          accept_incoming = "<leader>ct",
          accept_current = "<leader>co",
          accept_both = "<leader>cb",
          discard = "<leader>cx",
          next_conflict = "]x",
          prev_conflict = "[x",
          diffget_incoming = "2do",
          diffget_current = "3do",
        },
      },
    },
    config = function(_, opts)
      require("codediff").setup(opts)

      -- Hook into set_tab_keymap to re-apply local integrations on CodeDiff
      -- buffers after CodeDiff installs tab-local mappings.
      local lifecycle = require("codediff.ui.lifecycle")
      local orig_set_tab_keymap = lifecycle.set_tab_keymap

      local function remove_which_key_g_trigger(bufnr, mode)
        for _, map in ipairs(vim.api.nvim_buf_get_keymap(bufnr, mode)) do
          if map.lhs == "g" and map.desc == "which-key-trigger" then
            pcall(vim.api.nvim_buf_del_keymap, bufnr, mode, "g")
            return
          end
        end
      end

      local function apply_pinvim_comment_keymaps(session)
        local ok, pinvim = pcall(require, "pinvim")
        if not (ok and pinvim.api and pinvim.api.compose_comment) then return end

        local seen = {}
        for _, bufnr in ipairs({ session.original_bufnr, session.modified_bufnr }) do
          if bufnr and not seen[bufnr] and vim.api.nvim_buf_is_valid(bufnr) then
            seen[bufnr] = true
            remove_which_key_g_trigger(bufnr, "n")
            remove_which_key_g_trigger(bufnr, "x")
            vim.keymap.set("n", "gpc", function() pinvim.api.compose_comment() end, {
              buffer = bufnr,
              desc = "pinvim comment on cursor line (queued)",
              noremap = true,
              silent = true,
              nowait = true,
            })
            vim.keymap.set("x", "gpc", function() pinvim.api.compose_comment({ range = true }) end, {
              buffer = bufnr,
              desc = "pinvim comment on selection (queued)",
              noremap = true,
              silent = true,
              nowait = true,
            })
          end
        end
      end

      lifecycle.set_tab_keymap = function(tabpage, mode, lhs, rhs, keymap_opts)
        orig_set_tab_keymap(tabpage, mode, lhs, rhs, keymap_opts)

        local active_diffs = require("codediff.ui.lifecycle.session").get_active_diffs()
        local session = active_diffs[tabpage]
        if not session then return end

        apply_pinvim_comment_keymaps(session)

        if lhs ~= "gf" or mode ~= "n" then return end

        local explorer = session.explorer
        if not explorer or not explorer.bufnr or not vim.api.nvim_buf_is_valid(explorer.bufnr) then return end

        vim.keymap.set("n", "gf", function()
          local node = explorer.tree:get_node()
          if not node or not node.data or not node.data.path then return end
          if node.data.type == "group" or node.data.type == "directory" then return end

          local full_path = explorer.git_root and (explorer.git_root .. "/" .. node.data.path) or node.data.path

          local current_tab = vim.api.nvim_get_current_tabpage()
          local tabs = vim.api.nvim_list_tabpages()
          local current_idx
          for i, tab in ipairs(tabs) do
            if tab == current_tab then
              current_idx = i
              break
            end
          end

          local target_tab
          if current_idx and current_idx > 1 then
            target_tab = tabs[current_idx - 1]
          else
            vim.cmd("tabnew")
            target_tab = vim.api.nvim_get_current_tabpage()
            vim.cmd("tabmove 0")
          end

          if vim.api.nvim_get_current_tabpage() ~= target_tab then vim.api.nvim_set_current_tabpage(target_tab) end

          pcall(vim.cmd, "edit " .. vim.fn.fnameescape(full_path))
        end, {
          buffer = explorer.bufnr,
          desc = "Open file in previous tab",
          noremap = true,
          silent = true,
          nowait = true,
        })
      end
    end,
  },
}

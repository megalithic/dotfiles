return {
  {
    "folke/snacks.nvim",
    priority = 1000,
    opts = {
      bigfile = {
        enable = true,
        setup = function(ctx)
          vim.g.disable_autoformat = true
          vim.schedule(function() vim.bo[ctx.buf].syntax = ctx.ft end)
        end,
      },
      -- skip loading plugins when writing to a not yet existing file
      quickfile = { enabled = true },
      picker = {
        win = {
          -- input window
          input = {
            keys = {
              ["<Esc>"] = { "close", mode = { "n", "i" } },
              -- ["<CR>"] = { "edit_vsplit", mode = { "i", "n" } },
              -- ["<c-e>"] = { "confirm", mode = { "i", "n" } },
            },
            wo = { foldcolumn = "0" },
          },
          list = {
            wo = { foldcolumn = "0" },
            keys = {
              ["<CR>"] = { "edit_vsplit" },
              ["<c-e>"] = { "confirm" },
            },
          },
          preview = { wo = { foldcolumn = "0" } },
        },
        layout = { preset = "ivy" },
        smart = {
          multi = { "buffers", "recent", "files" },
          format = "file", -- use `file` format for all sources
          matcher = {
            cwd_bonus = true, -- boost cwd matches
            frecency = true, -- use frecency boosting
            sort_empty = true, -- sort even when the filter is empty
          },
          transform = "unique_file",
        },
        undo = {
          finder = "vim_undo",
          format = "undo",
          preview = "diff",
          confirm = "item_action",
          win = {
            preview = { wo = { number = false, relativenumber = false, signcolumn = "no" } },
            input = {
              keys = {
                ["<c-y>"] = { "yank_add", mode = { "n", "i" } },
                ["<c-s-y>"] = { "yank_del", mode = { "n", "i" } },
              },
            },
          },
          actions = {
            yank_add = { action = "yank", field = "added_lines" },
            yank_del = { action = "yank", field = "removed_lines" },
          },
          icons = { tree = { last = "┌╴" } }, -- the tree is upside down
          diff = {
            ctxlen = 4,
            ignore_cr_at_eol = true,
            ignore_whitespace_change_at_eol = true,
            indent_heuristic = true,
          },
        },
      },
      explorer = {},
    },
    keys = function()
      local Snacks = require("snacks")
      -- local function with_title(opts, extra)
      --   extra = extra or {}
      --   local path = opts.cwd or opts.path or extra.cwd or extra.path or nil
      --   local title = ""
      --   local buf_path = vim.fn.expand("%:p:h")
      --   local cwd = vim.fn.getcwd()
      --   if extra["title"] ~= nil then
      --     title = fmt("%s (%s):", extra.title, vim.fs.basename(path or vim.uv.cwd() or ""))
      --   else
      --     if path ~= nil and buf_path ~= cwd then
      --       title = require("plenary.path"):new(buf_path):make_relative(cwd)
      --     else
      --       title = vim.fn.fnamemodify(cwd, ":t")
      --     end
      --   end

      --   return vim.tbl_extend("force", opts, {
      --     win = { title = title },
      --   }, extra or {})
      -- end

      local function desc(d) return "[+pick (snacks)] " .. d end
      return {
        {
          "<leader>ff",
          function()
            local title = "smartly find files"
            -- Snacks.picker.smart(with_title({ title = title }))
            Snacks.picker.smart()
          end,
          desc = desc("find files (smart)"),
        },
        {
          "<leader>fu",
          function() Snacks.picker.undo() end,
          desc = desc("undo"),
        },
        {
          "<leader>a",
          function() Snacks.picker.undo() end,
          desc = desc("undo"),
        },
        {
          "ga",
          function() Snacks.picker.grep() end,
          desc = "Grep",
        },
        {
          "<leader>A",
          function() Snacks.picker.grep_word() end,
          desc = "Visual selection or word",
          mode = { "n", "x" },
        },
        {
          "gA",
          function() Snacks.picker.grep_word() end,
          desc = "Visual selection or word",
          mode = { "n", "x" },
        },
        -- {
        --   "<leader>,",
        --   function()
        --     Snacks.picker.buffers()
        --   end,
        --   desc = "Buffers",
        -- },
        -- {
        --   "<leader>/",
        --   function()
        --     Snacks.picker.grep()
        --   end,
        --   desc = "Grep",
        -- },
        -- {
        --   "<leader>:",
        --   function()
        --     Snacks.picker.command_history()
        --   end,
        --   desc = "Command History",
        -- },
        -- {
        --   "<leader>n",
        --   function()
        --     Snacks.picker.notifications()
        --   end,
        --   desc = "Notification History",
        -- },
        -- {
        --   "<leader>e",
        --   function()
        --     Snacks.explorer()
        --   end,
        --   desc = "File Explorer",
        -- },
        -- -- find
        -- {
        --   "<leader>fb",
        --   function()
        --     Snacks.picker.buffers()
        --   end,
        --   desc = "Buffers",
        -- },
        -- {
        --   "<leader>fc",
        --   function()
        --     Snacks.picker.files({ cwd = vim.fn.stdpath("config") })
        --   end,
        --   desc = "Find Config File",
        -- },
        -- {
        --   "<leader>ff",
        --   function()
        --     Snacks.picker.files()
        --   end,
        --   desc = "Find Files",
        -- },
        -- {
        --   "<leader>fg",
        --   function()
        --     Snacks.picker.git_files()
        --   end,
        --   desc = "Find Git Files",
        -- },
        -- {
        --   "<leader>fp",
        --   function()
        --     Snacks.picker.projects()
        --   end,
        --   desc = "Projects",
        -- },
        -- {
        --   "<leader>fr",
        --   function()
        --     Snacks.picker.recent()
        --   end,
        --   desc = "Recent",
        -- },
        -- -- git
        -- {
        --   "<leader>gb",
        --   function()
        --     Snacks.picker.git_branches()
        --   end,
        --   desc = "Git Branches",
        -- },
        -- {
        --   "<leader>gl",
        --   function()
        --     Snacks.picker.git_log()
        --   end,
        --   desc = "Git Log",
        -- },
        -- {
        --   "<leader>gL",
        --   function()
        --     Snacks.picker.git_log_line()
        --   end,
        --   desc = "Git Log Line",
        -- },
        -- {
        --   "<leader>gs",
        --   function()
        --     Snacks.picker.git_status()
        --   end,
        --   desc = "Git Status",
        -- },
        -- {
        --   "<leader>gS",
        --   function()
        --     Snacks.picker.git_stash()
        --   end,
        --   desc = "Git Stash",
        -- },
        -- {
        --   "<leader>gd",
        --   function()
        --     Snacks.picker.git_diff()
        --   end,
        --   desc = "Git Diff (Hunks)",
        -- },
        -- {
        --   "<leader>gf",
        --   function()
        --     Snacks.picker.git_log_file()
        --   end,
        --   desc = "Git Log File",
        -- },
        -- -- Grep
        -- {
        --   "<leader>sb",
        --   function()
        --     Snacks.picker.lines()
        --   end,
        --   desc = "Buffer Lines",
        -- },
        -- {
        --   "<leader>sB",
        --   function()
        --     Snacks.picker.grep_buffers()
        --   end,
        --   desc = "Grep Open Buffers",
        -- },
        -- -- search
        -- {
        --   '<leader>s"',
        --   function()
        --     Snacks.picker.registers()
        --   end,
        --   desc = "Registers",
        -- },
        -- {
        --   "<leader>s/",
        --   function()
        --     Snacks.picker.search_history()
        --   end,
        --   desc = "Search History",
        -- },
        -- {
        --   "<leader>sa",
        --   function()
        --     Snacks.picker.autocmds()
        --   end,
        --   desc = "Autocmds",
        -- },
        -- {
        --   "<leader>sb",
        --   function()
        --     Snacks.picker.lines()
        --   end,
        --   desc = "Buffer Lines",
        -- },
        -- {
        --   "<leader>sc",
        --   function()
        --     Snacks.picker.command_history()
        --   end,
        --   desc = "Command History",
        -- },
        -- {
        --   "<leader>sC",
        --   function()
        --     Snacks.picker.commands()
        --   end,
        --   desc = "Commands",
        -- },
        -- {
        --   "<leader>sd",
        --   function()
        --     Snacks.picker.diagnostics()
        --   end,
        --   desc = "Diagnostics",
        -- },
        -- {
        --   "<leader>sD",
        --   function()
        --     Snacks.picker.diagnostics_buffer()
        --   end,
        --   desc = "Buffer Diagnostics",
        -- },
        -- {
        --   "<leader>sh",
        --   function()
        --     Snacks.picker.help()
        --   end,
        --   desc = "Help Pages",
        -- },
        -- {
        --   "<leader>sH",
        --   function()
        --     Snacks.picker.highlights()
        --   end,
        --   desc = "Highlights",
        -- },
        -- {
        --   "<leader>si",
        --   function()
        --     Snacks.picker.icons()
        --   end,
        --   desc = "Icons",
        -- },
        -- {
        --   "<leader>sj",
        --   function()
        --     Snacks.picker.jumps()
        --   end,
        --   desc = "Jumps",
        -- },
        -- {
        --   "<leader>sk",
        --   function()
        --     Snacks.picker.keymaps()
        --   end,
        --   desc = "Keymaps",
        -- },
        -- {
        --   "<leader>sl",
        --   function()
        --     Snacks.picker.loclist()
        --   end,
        --   desc = "Location List",
        -- },
        -- {
        --   "<leader>sm",
        --   function()
        --     Snacks.picker.marks()
        --   end,
        --   desc = "Marks",
        -- },
        -- {
        --   "<leader>sM",
        --   function()
        --     Snacks.picker.man()
        --   end,
        --   desc = "Man Pages",
        -- },
        -- {
        --   "<leader>sp",
        --   function()
        --     Snacks.picker.lazy()
        --   end,
        --   desc = "Search for Plugin Spec",
        -- },
        -- {
        --   "<leader>sq",
        --   function()
        --     Snacks.picker.qflist()
        --   end,
        --   desc = "Quickfix List",
        -- },
        -- {
        --   "<leader>sR",
        --   function()
        --     Snacks.picker.resume()
        --   end,
        --   desc = "Resume",
        -- },
        -- {
        --   "<leader>su",
        --   function()
        --     Snacks.picker.undo()
        --   end,
        --   desc = "Undo History",
        -- },
        -- {
        --   "<leader>uC",
        --   function()
        --     Snacks.picker.colorschemes()
        --   end,
        --   desc = "Colorschemes",
        -- },
        -- -- LSP
        -- {
        --   "gd",
        --   function()
        --     Snacks.picker.lsp_definitions()
        --   end,
        --   desc = "Goto Definition",
        -- },
        -- {
        --   "gD",
        --   function()
        --     Snacks.picker.lsp_declarations()
        --   end,
        --   desc = "Goto Declaration",
        -- },
        -- {
        --   "gr",
        --   function()
        --     Snacks.picker.lsp_references()
        --   end,
        --   nowait = true,
        --   desc = "References",
        -- },
        -- {
        --   "gI",
        --   function()
        --     Snacks.picker.lsp_implementations()
        --   end,
        --   desc = "Goto Implementation",
        -- },
        -- {
        --   "gy",
        --   function()
        --     Snacks.picker.lsp_type_definitions()
        --   end,
        --   desc = "Goto T[y]pe Definition",
        -- },
        -- {
        --   "<leader>ss",
        --   function()
        --     Snacks.picker.lsp_symbols()
        --   end,
        --   desc = "LSP Symbols",
        -- },
        -- {
        --   "<leader>sS",
        --   function()
        --     Snacks.picker.lsp_workspace_symbols()
        --   end,
        --   desc = "LSP Workspace Symbols",
        -- },
      }
    end,
  },
}

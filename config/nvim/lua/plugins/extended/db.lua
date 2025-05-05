local map = vim.keymap.set

return {
  {
    "kristijanhusak/vim-dadbod-ui",
    keys = {
      { "<leader>D", "<Cmd>DBUIToggle<CR>", desc = "db: ui toggle", mode = "n" },
    },
    dependencies = {
      { "tpope/vim-dadbod", lazy = true },
      { "kristijanhusak/vim-dadbod-completion", ft = { "dbee", "sql", "mysql", "plsql" }, lazy = true },
    },
    cmd = {
      "DBUI",
      "DBUIToggle",
      "DBUIAddConnection",
      "DBUIFindBuffer",
    },
    init = function()
      vim.g.db_ui_save_location = vim.g.db_ui_path
      vim.g.db_ui_tmp_query_location = "~/code/queries"
      vim.g.db_ui_auto_execute_table_helpers = 1
      vim.g.db_ui_default_query = "select * from \"{table}\" limit 20 desc;"
      vim.g.db_ui_table_helpers = {
        postgresql = {
          ["List"] = "select * from \"{table}\" limit 10",
        },
      }

      vim.g.db_ui_hide_schemas = { "pg_catalog", "pg_toast_temp.*", "crdb_internal", "information_schema", "pg_extension" }
      vim.g.db_ui_force_echo_notifications = 1
      vim.g.db_ui_show_database_icon = 1
      vim.g.db_ui_auto_execute_table_helpers = 1
      vim.g.db_ui_show_help = 1
      vim.g.db_ui_debug = 1
      vim.g.db_ui_win_position = "left"
      vim.g.db_ui_use_nerd_fonts = 1
      vim.g.db_ui_use_nvim_notify = 1
    end,
  },
  {
    "kndndrj/nvim-dbee",
    dependencies = {
      "MunifTanjim/nui.nvim",
    },
    keys = {
      { "<leader>d", "<Cmd>Dbee<CR>", desc = "dbee: ui toggle", mode = "n" },
    },
    cmd = {
      "Dbee",
    },
    build = function() require("dbee").install() end,
    opts = {
      sources = {
        require("dbee.sources").MemorySource:new({
          {
            name = "localhost",
            type = "postgres",
            url = "postgresql:///"
              .. (vim.env.PGDATABASE or "postgres")
              .. "?host="
              .. (vim.env.PGHOST or "localhost")
              .. "&port="
              .. (vim.env.PGPORT or "5432")
              .. "&sslmode="
              .. (vim.env.PGSSLMODE or "disable"),
          },
        }),
        require("dbee.sources").EnvSource:new("DBEE_CONNECTIONS"),
        require("dbee.sources").FileSource:new(vim.fn.stdpath("config") .. "/.dbee_persistence.json"),
      },
      call_log = {
        window_options = {
          number = false,
          relativenumber = false,
          signcolumn = "no",
        },
      },
      drawer = {
        disable_help = true,
        window_options = {
          number = false,
          relativenumber = false,
          signcolumn = "no",
        },
      },
      editor = {
        mappings = {
          { key = "gx", mode = "v", action = "run_selection" },
          -- { key = "<s-cr>", mode = "n", action = "run_file" },
          -- {
          --   action = "run_selection",
          --   key = "<C-M>",
          --   mode = "x",
          --   opts = { noremap = true, nowait = true, expr = true },
          -- },
        },
      },
      result = {
        mappings = {
          { action = "cancel_call", key = "<C-c>", mode = "" },
          { action = "page_next", key = "<C-n>", mode = "" },
          { action = "page_prev", key = "<C-p>", mode = "" },
          { action = "yank_current_json", key = "yaj", mode = "n" },
          { action = "yank_selection_json", key = "yaj", mode = "v" },
          { action = "yank_all_json", key = "yaJ", mode = "" },
          { action = "yank_current_csv", key = "yac", mode = "n" },
          { action = "yank_selection_csv", key = "yac", mode = "v" },
          { action = "yank_all_csv", key = "yaC", mode = "" },
        },
        window_options = {
          number = false,
          relativenumber = false,
          signcolumn = "no",
        },
      },
    },
    config = function(_, opts)
      local has_db, db = pcall(require, "dbee")

      if has_db then
        map("n", "gx", function()
          local ts = vim.treesitter
          local parsers = require("nvim-treesitter.parsers")
          local bufnr = vim.api.nvim_get_current_buf()
          local lang = parsers.get_buf_lang(bufnr)
          if not lang or not parsers.has_parser(lang) then return end

          local parser = parsers.get_parser(bufnr, lang)
          local tree = parser:parse()[1]
          local root = tree:root()

          local cursor_row = vim.api.nvim_win_get_cursor(0)[1] - 1

          local query = ts.query.parse(
            lang,
            [[
    (comment) @comment
    (statement) @statement
  ]]
          )

          for id, node in query:iter_captures(root, bufnr, cursor_row, cursor_row + 1) do
            local name = query.captures[id]
            local start_row, start_col, end_row, end_col = node:range()

            if name == "comment" then
              local text = ts.get_node_text(node, bufnr)
              local marker, content = text:match("^(%-%-)%s?(.*)")
              if marker and content then
                -- ignore deletes when we're comment out
                if content:lower():match("^delete%s") then return end

                local marker_len = #marker
                local space_adjust = text:match("^%-%-%s") and 1 or 0
                local comment_start_col = start_col + marker_len + space_adjust
                local comment_end_col = comment_start_col + #content

                vim.api.nvim_win_set_cursor(0, { start_row + 1, comment_start_col })
                vim.cmd("normal! v")
                vim.api.nvim_win_set_cursor(0, { start_row + 1, comment_end_col })
                vim.defer_fn(function() require("dbee.api").ui.editor_do_action("run_selection") end, 100)
                return
              end
            elseif name == "statement" then
              vim.api.nvim_win_set_cursor(0, { start_row + 1, start_col })
              vim.cmd("normal! v")
              vim.api.nvim_win_set_cursor(0, { end_row + 1, end_col })
              vim.defer_fn(function() require("dbee.api").ui.editor_do_action("run_selection") end, 100)
              return
            end
          end
        end, { desc = "dbee: execute current line" })
      end
      db.setup(opts)
    end,
  },
}

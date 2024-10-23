return {
  {
    "kristijanhusak/vim-dadbod-ui",
    keys = {
      { "<leader>D", "<Cmd>DBUIToggle<CR>", desc = "db: ui toggle", mode = "n" },
    },
    dependencies = {
      { "tpope/vim-dadbod", lazy = true },
      { "kristijanhusak/vim-dadbod-completion", ft = { "sql", "mysql", "plsql" }, lazy = true },
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
      -- vim.g.db_ui_save_location = "~/Dropbox/dbui"
      vim.g.db_ui_auto_execute_table_helpers = 1
      -- vim.g.dbs = {
      --   canonize = "postgres://seth@localhost:5432/canonize_dev",
      --   bellhop = "postgres://postgres:postgres@127.0.0.10:5432/bellhop_dev",
      --   retriever = "postgres://postgres:postgres@127.0.0.10:5432/retriever_dev",
      -- }
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
}

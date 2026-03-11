local map = vim.keymap.set

-- M.dbPath = os.getenv("XDG_DATA_HOME") or (os.getenv("HOME") .. "/.local/share")
-- local dbee_json_config = vim.fn.stdpath("data") .. "/dbee/dbee_persistence.json"
local dbee_json_config = vim.fn.stdpath("config") .. "/.dbee_persistence.json"

local get_default_connection_for_cwd = function(default_id)
  local function root_pattern(bufnr, markers)
    markers = markers == nil and { ".git" } or markers
    markers = type(markers) == "string" and { markers } or markers

    local fname = vim.api.nvim_buf_get_name(bufnr)
    local matches = vim.fs.find(markers, { upward = true, limit = 2, path = fname })
    local child_or_root_path, maybe_umbrella_path = unpack(matches)

    local found_root = vim.fs.dirname(maybe_umbrella_path or child_or_root_path)

    return vim.fn.fnamemodify(found_root, ":t")
  end

  local function find_matching_id()
    local config_path = dbee_json_config
    local cwd = vim.uv.cwd()
    cwd = root_pattern(0, { "mix.exs", "package.json", "shell.nix", ".git" })

    -- Check if file exists
    if vim.fn.filereadable(config_path) == 0 then return nil end

    -- Read file content
    local file = io.open(config_path, "r")
    if not file then return nil end

    local content = file:read("*all")
    file:close()

    -- Parse JSON
    local ok, data = pcall(vim.json.decode, content)
    if not ok or not data then return nil end

    -- Collect matching IDs with priority
    local matches = {}

    if type(data) == "table" then
      for _, item in pairs(data) do
        if type(item) == "table" and item.id then
          -- Check if the id contains or matches the current working directory
          if string.find(item.id, cwd, 1, true) or string.find(cwd, item.id, 1, true) then
            table.insert(matches, item.id)
          end
        end
      end
    end

    if #matches == 0 then return default_id end

    local match = default_id

    for _, id in ipairs(matches) do
      if string.find(id, "_local", 1, true) then
        match = id
      elseif string.find(id, "_prod", 1, true) then
        match = id
      end
    end

    return match
  end

  local matching_id = find_matching_id()

  return matching_id ~= nil, matching_id
end

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
      vim.g.db_ui_auto_execute_table_helpers = 1
      vim.g.db_ui_default_query = 'select * from "{table}" limit 20 desc;'
      vim.g.db_ui_table_helpers = {
        postgresql = {
          ["List"] = 'select * from "{table}" limit 10',
        },
      }

      vim.g.db_ui_hide_schemas =
        { "pg_catalog", "pg_toast_temp.*", "crdb_internal", "information_schema", "pg_extension" }
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
    dev = true,
    "megalithic/nvim-dbee",
    dependencies = {
      "MunifTanjim/nui.nvim",
    },
    keys = {
      {
        "<leader>d",
        function()
          local dbee = require("dbee")
          dbee.toggle()

          if dbee.is_open() then
            local _, default_connection = get_default_connection_for_cwd("director_local")
            local local_notes = dbee.api.ui.editor_namespace_get_notes(default_connection)

            if local_notes and #local_notes > 0 then pcall(dbee.api.ui.editor_set_current_note, local_notes[1].id) end
          end
        end,
        desc = "dbee: ui toggle",
        mode = "n",
      },
    },
    cmd = {
      "Dbee",
    },
    ft = { "sql", "dbee" },
    build = function() require("dbee").install() end,
    config = function()
      local has_db, dbee = pcall(require, "dbee")
      if has_db then
        local _has_default_connection, default_connection = get_default_connection_for_cwd("director_local")

        local opts = {
          default_connection = default_connection,
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
            require("dbee.sources").FileSource:new(dbee_json_config),
            require("dbee.sources").MemorySource:new({
              {
                id = "hs",
                name = "Hammerspoon",
                type = "sqlite", -- type of database driver
                url = "~/.local/share/hammerspoon/hammerspoon.db",
              },
            }),
            require("dbee.sources").MemorySource:new({
              {
                id = "hs_notifications",
                name = "Hammerspoon Notifications",
                type = "sqlite", -- type of database driver
                url = "~/.local/share/hammerspoon/notifications.db",
              },
            }),
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
            directory = vim.g.db_ui_path .. "/dbee",
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
            page_size = 50,
            focus_result = false,
            window_options = {
              number = false,
              relativenumber = false,
              signcolumn = "no",
            },
          },
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
        }

        local function execute_query()
          local utils = require("dbee.utils")

          local ts = vim.treesitter
          local parsers = require("nvim-treesitter.parsers")
          local bufnr = vim.api.nvim_get_current_buf()
          local ft = vim.bo[bufnr].filetype
          if ft ~= "sql" then return end

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

          -- local query, srow, erow = utils.query_under_cursor(bufnr)
          -- if query ~= "" then
          --   -- highlight the statement that will be executed
          --   local ns_id = vim.api.nvim_create_namespace("dbee_query_highlight")
          --   vim.api.nvim_buf_clear_namespace(bufnr, ns_id, 0, -1)
          --   vim.api.nvim_buf_set_extmark(bufnr, ns_id, srow, 0, {
          --     end_row = erow + 1,
          --     end_col = 0,
          --     hl_group = "DiffText",
          --     priority = 100,
          --   })

          --   -- vim.api.nvim_win_set_cursor(0, { start_row + 1, start_col })
          --   -- vim.cmd("normal! v")
          --   -- vim.api.nvim_win_set_cursor(0, { end_row + 1, end_col })
          --   -- vim.defer_fn(function() require("dbee.api").ui.editor_do_action("run_selection") end, 100)

          --   -- remove highlighting after delay
          --   vim.defer_fn(function() vim.api.nvim_buf_clear_namespace(bufnr, ns_id, 0, -1) end, 750)
          -- end

          for id, node in query:iter_captures(root, bufnr, cursor_row, cursor_row + 1) do
            local name = query.captures[id]
            local srow, scol, erow, ecol = node:range()

            local ns_id = vim.api.nvim_create_namespace("db_query_highlight")
            vim.api.nvim_buf_clear_namespace(bufnr, ns_id, 0, -1)

            vim.api.nvim_buf_set_extmark(bufnr, ns_id, srow, 0, {
              end_row = erow + 1,
              end_col = 0,
              hl_group = "DiffText",
              priority = 100,
            })

            if name == "comment" then
              local text = ts.get_node_text(node, bufnr)
              local marker, content = text:match("^(%-%-)%s?(.*)")
              if marker and content then
                -- ignore deletes when we're comment out
                if content:lower():match("^delete%s") then return end

                local marker_len = #marker
                local space_adjust = text:match("^%-%-%s") and 1 or 0
                local comment_start_col = scol + marker_len + space_adjust
                local comment_end_col = comment_start_col + #content

                vim.api.nvim_win_set_cursor(0, { srow + 1, comment_start_col })
                vim.cmd("normal! v")
                vim.api.nvim_win_set_cursor(0, { srow + 1, comment_end_col })

                vim.defer_fn(function() require("dbee.api").ui.editor_do_action("run_selection") end, 100)

                vim.defer_fn(function() vim.api.nvim_buf_clear_namespace(bufnr, ns_id, 0, -1) end, 250)

                break
              end
            elseif name == "statement" then
              vim.api.nvim_win_set_cursor(0, { srow + 1, scol })
              vim.cmd("normal! v")
              vim.api.nvim_win_set_cursor(0, { erow + 1, ecol })
              vim.defer_fn(function() require("dbee.api").ui.editor_do_action("run_selection") end, 100)

              vim.defer_fn(function() vim.api.nvim_buf_clear_namespace(bufnr, ns_id, 0, -1) end, 250)
              break
            end
          end
        end

        -- local function visual_selection()
        --   -- return to normal mode ('< and '> become available only after you exit visual mode)
        --   local key = vim.api.nvim_replace_termcodes("<esc>", true, false, true)
        --   vim.api.nvim_feedkeys(key, "x", false)

        --   local _, srow, scol, _ = unpack(vim.fn.getpos("'<"))
        --   local _, erow, ecol, _ = unpack(vim.fn.getpos("'>"))
        --   if ecol > 200000 then ecol = 20000 end
        --   if srow < erow or (srow == erow and scol <= ecol) then
        --     return srow - 1, scol - 1, erow - 1, ecol
        --   else
        --     return erow - 1, ecol - 1, srow - 1, scol
        --   end
        -- end

        -- local get_visual_selection = function()
        --   local mode = vim.api.nvim_get_mode().mode
        --   local opts = {}
        --   if mode == "v" or mode == "V" or mode == "\22" then opts.type = mode end
        --   return vim.fn.getregion(vim.fn.getpos("v"), vim.fn.getpos("."), opts)
        -- end

        map({ "n", "x" }, "gx", execute_query, { desc = "dbee: execute current query" })
        map({ "n" }, "g==", function()
          vim.defer_fn(function() require("dbee.api").ui.editor_do_action("run_under_cursor") end, 100)
        end, { desc = "dbee: run query under cursor" })

        map({ "x", "v" }, "yuc", function()
          vim.cmd("normal! y")

          local copiedContent = vim.fn.getreg("+")
          local values = vim.split(require("config.utils").strim(copiedContent), "%s+")
          local csv_values = vim.iter(values):filter(function(v) return v ~= "" and v ~= nil end)
          csv_values = table.concat(values, ",")

          vim.fn.setreg("+", csv_values)
        end, { desc = "yank visual selection to csv formatted register" })

        -- map({ "n" }, "ypc", function()
        --   local copiedContent = vim.fn.getreg("+")
        --   local values = vim.split(require("config.utils").strim(copiedContent), "%s+")
        --   local csv_values = vim.iter(values):filter(function(v) return v ~= "" and v ~= nil end)
        --   csv_values = table.concat(values, ",")

        --   vim.fn.setreg("+", csv_values)
        --   vim.cmd("normal! \"+p")
        -- end, { desc = "paste visual selection as csv formatted" })

        dbee.setup(opts)
      end
    end,
  },
}

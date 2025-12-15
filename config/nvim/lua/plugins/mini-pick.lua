local MiniConf = {}

-- https://github.com/echasnovski/mini.nvim/blob/2e38ed16c2ced64bcd576986ccad4b18e2006e18/doc/mini-pick.txt#L650-L660
MiniConf.win_config = {
  helix = function()
    local height = math.floor(0.4 * vim.o.lines)
    local width = math.floor(0.4 * vim.o.columns)
    return {
      relative = "laststatus",
      anchor = "NW",
      height = height,
      width = width,
      row = 0,
      col = 0,
    }
  end,
  cursor = function()
    return {
      relative = "cursor",
      anchor = "NW",
      row = 0,
      col = 0,
      height = 50,
      width = 16,
    }
  end,
  center_small = function()
    local height = math.floor(0.40 * vim.o.lines)
    local width = math.floor(0.40 * vim.o.columns)
    return {
      -- 3 - Center small window
      border = "rounded",
      anchor = "NW",
      height = height,
      width = width,
      row = math.floor(0.5 * (vim.o.lines - height)),
      col = math.floor(0.5 * (vim.o.columns - width)),
      -- relative = "editor",
    }
  end,
}

function MiniConf.smart_picker()
  local MiniFuzzy = require("mini.fuzzy")
  local MiniVisits = require("mini.visits")

  local visit_paths = MiniVisits.list_paths()
  local current_file = vim.fn.expand("%")
  local cwd = vim.fn.getcwd()

  -- Get alternative file for priority boost
  local alt_file = vim.fn.expand("#")

  -- Get oldfiles scoped to current working directory
  local oldfiles = {}
  for _, file in ipairs(vim.v.oldfiles) do
    local abs_path = vim.fn.fnamemodify(file, ":p")
    if vim.startswith(abs_path, cwd) then table.insert(oldfiles, vim.fn.fnamemodify(file, ":.")) end
  end

  MiniPick.builtin.files(nil, {
    source = {
      match = function(stritems, indices, query)
        -- Concatenate prompt to a single string
        local prompt = vim.pesc(table.concat(query))

        -- If ignorecase is on and there are no uppercase letters in prompt,
        -- convert paths to lowercase for matching purposes
        local convert_path = function(str) return str end
        if vim.o.ignorecase and string.find(prompt, "%u") == nil then
          convert_path = function(str) return string.lower(str) end
        end

        local current_file_cased = convert_path(current_file)
        local alt_file_rel = alt_file ~= "" and vim.fn.fnamemodify(alt_file, ":.") or nil
        local alt_file_cased = alt_file_rel and convert_path(alt_file_rel) or nil

        -- Create lookup tables for priority files
        local oldfiles_lookup = {}
        for index, file_path in ipairs(oldfiles) do
          oldfiles_lookup[convert_path(file_path)] = index
        end

        local visits_lookup = {}
        for index, path in ipairs(visit_paths) do
          local key = vim.fn.fnamemodify(path, ":.")
          visits_lookup[convert_path(key)] = index
        end

        local result = {}
        for _, index in ipairs(indices) do
          local path = stritems[index]
          local path_cased = convert_path(path)
          local match_score = prompt == "" and 0 or MiniFuzzy.match(prompt, path).score

          if match_score >= 0 then
            local score

            -- Current file gets ranked last
            if path_cased == current_file_cased then
              score = 999999
              -- Alt file gets highest priority
            elseif alt_file_cased and path_cased == alt_file_cased then
              score = match_score - 10000
              -- Oldfiles get second priority
            elseif oldfiles_lookup[path_cased] then
              score = match_score - 1000 + oldfiles_lookup[path_cased]
              -- Visit paths get third priority
            elseif visits_lookup[path_cased] then
              score = match_score + visits_lookup[path_cased]
              -- Everything else
            else
              score = match_score + 100000
            end

            table.insert(result, {
              index = index,
              score = score,
            })
          end
        end

        table.sort(result, function(a, b) return a.score < b.score end)

        return vim.tbl_map(function(val) return val.index end, result)
      end,
    },
  })
end

return {
  "nvim-mini/mini.pick",
  cond = false,
  opts = {
    delay = {
      busy = 30,
      async = 10,
    },

    mappings = {
      caret_left = "<Left>",
      caret_right = "<Right>",

      choose = "",
      choose_in_vsplit = "<CR>",
      -- choose_in_vsplit = "<C-v>",
      choose_in_split = "<C-s>",
      choose_in_tabpage = "<C-t>",
      choose_marked = "<C-q>",
      -- REF: https://github.com/diego-velez/nvim/blob/master/lua/plugins/mini_pick.lua

      -- another_choose = {
      --   char = "<CR>",
      --   func = function()
      --     local choose_mapping = MiniPick.get_picker_opts().mappings.choose
      --     vim.api.nvim_input(choose_mapping)
      --   end,
      -- },

      delete_char = "<BS>",
      delete_char_right = "<Del>",
      delete_left = "<C-u>",
      delete_word = "<C-w>",

      mark = "<C-x>",
      mark_all = "<C-a>",

      move_down = "<C-n>",
      move_start = "<C-g>",
      move_up = "<C-p>",

      paste = "",
      refine = "<C-r>",
      refine_marked = "",

      scroll_down = "<C-f>",
      scroll_left = "<C-Left>",
      scroll_right = "<C-Right>",
      scroll_up = "<C-b>",

      stop = "<Esc>",

      toggle_info = "<S-Tab>",
      toggle_preview = "<Tab>",
    },

    options = {
      use_cache = false,
    },

    -- source = {
    --   items = nil,
    --   name = nil,
    --   cwd = nil,
    --
    --   match = nil,
    --   preview = nil,
    --   show = function(buf_id, items, query, opts)
    --     picker.default_show(
    --       buf_id,
    --       items,
    --       query,
    --       vim.tbl_deep_extend("force", { show_icons = false, icons = {} }, opts or {})
    --     )
    --   end,
    --
    --   choose = nil,
    --   choose_marked = nil,
    -- },

    window = {
      config = MiniConf.win_config.helix,
      prompt_prefix = "󰁔 ",
      prompt_caret = "|",
    },
  },

  config = function(_, opts)
    -- REF: fancy full-buffer preview window:
    -- https://github.com/SylvanFranklin/.config/issues/14#issuecomment-3289525083
    local setup_target_win_preview = function(args)
      local opts = MiniPick.get_picker_opts()
      local show, preview, choose = opts.source.show, opts.source.preview, opts.source.choose

      -- Prepare preview and initial buffers
      local preview_buf_id = vim.api.nvim_create_buf(false, true)
      local win_target = MiniPick.get_picker_state().windows.target
      local init_target_buf = vim.api.nvim_win_get_buf(win_target)
      vim.api.nvim_win_set_buf(win_target, preview_buf_id)

      -- Hook into source's methods
      opts.source.show = function(...)
        show(...)

        local cur_item = MiniPick.get_picker_matches().current
        if cur_item == nil then return end

        preview(preview_buf_id, cur_item)
      end

      local needs_init_buf_restore = true
      opts.source.choose = function(...)
        -- vim.print(MiniPick.get_picker_opts().mappings.choose)
        needs_init_buf_restore = false
        choose(...)
      end

      MiniPick.set_picker_opts(opts)

      -- Set up buffer cleanup
      local cleanup = function(args)
        if needs_init_buf_restore then vim.api.nvim_win_set_buf(win_target, init_target_buf) end
        if vim.api.nvim_buf_is_valid(preview_buf_id) then vim.api.nvim_buf_delete(preview_buf_id, { force = true }) end
      end

      vim.api.nvim_create_autocmd("User", { pattern = "MiniPickStop", once = true, callback = cleanup })
    end
    -- vim.api.nvim_create_autocmd("User", { pattern = "MiniPickStart", callback = setup_target_win_preview })

    local preview = function(buf_id, item) return MiniPick.default_preview(buf_id, item, { line_position = "center" }) end

    opts = vim.tbl_deep_extend("force", opts, { source = { preview = preview } })
    require("mini.pick").setup(opts)

    -- vim.ui.select = function(items, select_opts, on_choice)
    --   local start_opts = { hinted = { enable = true, use_autosubmit = true } }
    --   return MiniPick.ui_select(items, select_opts, on_choice, start_opts)
    -- end

    -- Using primarily for code action
    -- See https://github.com/echasnovski/mini.nvim/discussions/1437
    -- Customize with fourth argument inside a function wrapper
    vim.ui.select = function(items, select_opts, on_choice)
      local start_opts = { window = { config = MiniConf.win_config.cursor() } }
      return MiniPick.ui_select(items, select_opts, on_choice, start_opts)
    end

    MiniPick.registry.frecency = MiniConf.smart_picker

    -- Use proper slash depending on OS
    local parent_dir_pattern = vim.fn.has("win32") == 1 and "([^\\/]+)([\\/])" or "([^/]+)(/)"

    -- Shorten a folder's name
    local shorten_dirname = function(name, path_sep)
      local first = vim.fn.strcharpart(name, 0, 1)
      first = first == "." and vim.fn.strcharpart(name, 0, 2) or first
      return first .. path_sep
    end

    -- Shorten one path
    -- WARN: This can only be called for MiniPick
    local make_short_path = function(path)
      local win_id = MiniPick.get_picker_state().windows.main
      local buf_width = vim.api.nvim_win_get_width(win_id)
      local char_count = vim.fn.strchars(path)
      -- Do not shorten the path if it is not needed
      if char_count < buf_width then return path end

      local shortened_path = path:gsub(parent_dir_pattern, shorten_dirname)
      char_count = vim.fn.strchars(shortened_path)
      -- Return only the filename when the shorten path still overflows
      if char_count >= buf_width then return shortened_path:match(parent_dir_pattern) end

      return shortened_path
    end

    -- Shorten file paths by default
    local show_short_files = function(buf_id, items_to_show, query)
      local short_items_to_show = vim.tbl_map(make_short_path, items_to_show)
      -- TODO: Instead of using default show, replace in order to highlight proper folder and add icons back
      MiniPick.default_show(buf_id, short_items_to_show, query)
    end

    ---@class DVTMiniFiles
    ---@field shorten_dirname boolean
    ---@param local_opts DVTMiniFiles | nil
    ---@param opts table | nil
    MiniPick.registry.files = function(local_opts, opts)
      local_opts = local_opts or {}
      local_opts = vim.tbl_extend("force", local_opts, { shorten_dirname = false })
      if local_opts.shorten_dirname then
        opts = opts or {
          source = { show = show_short_files },
        }
      else
        opts = opts or {}
      end

      MiniPick.builtin.files(local_opts, opts)
    end

    -- Show highlight in buf_lines picker
    -- See https://github.com/echasnovski/mini.nvim/discussions/988#discussioncomment-10398788
    local ns_digit_prefix = vim.api.nvim_create_namespace("cur-buf-pick-show")
    local show_cur_buf_lines = function(buf_id, items, query, opts)
      if items == nil or #items == 0 then return end

      -- Show as usual
      MiniPick.default_show(buf_id, items, query, opts)

      -- Move prefix line numbers into inline extmarks
      local lines = vim.api.nvim_buf_get_lines(buf_id, 0, -1, false)
      local digit_prefixes = {}
      for i, l in ipairs(lines) do
        local _, prefix_end, prefix = l:find("^(%s*%d+│)")
        if prefix_end ~= nil then
          digit_prefixes[i], lines[i] = prefix, l:sub(prefix_end + 1)
        end
      end

      vim.api.nvim_buf_set_lines(buf_id, 0, -1, false, lines)
      for i, pref in pairs(digit_prefixes) do
        local opts = { virt_text = { { pref, "MiniPickNormal" } }, virt_text_pos = "inline" }
        vim.api.nvim_buf_set_extmark(buf_id, ns_digit_prefix, i - 1, 0, opts)
      end

      -- Set highlighting based on the curent filetype
      local ft = vim.bo[items[1].bufnr].filetype
      local has_lang, lang = pcall(vim.treesitter.language.get_lang, ft)
      local has_ts, _ = pcall(vim.treesitter.start, buf_id, has_lang and lang or ft)
      if not has_ts and ft then vim.bo[buf_id].syntax = ft end
    end

    MiniPick.registry.buf_lines = function()
      -- local local_opts = { scope = 'current', preserve_order = true } -- use preserve_order
      local local_opts = { scope = "current" }
      MiniExtra.pickers.buf_lines(local_opts, { source = { show = show_cur_buf_lines } })
    end

    -- Open LSP picker for the given scope
    ---@param scope "declaration" | "definition" | "document_symbol" | "implementation" | "references" | "type_definition" | "workspace_symbol"
    ---@param autojump boolean? If there is only one result it will jump to it.
    MiniPick.registry.LspPicker = function(scope, autojump)
      ---@return string
      local function get_symbol_query() return vim.fn.input("Symbol: ") end

      if not autojump then
        local opts = { scope = scope }

        if scope == "workspace_symbol" then opts.symbol_query = get_symbol_query() end

        MiniExtra.pickers.lsp(opts)
        return
      end

      ---@param opts vim.lsp.LocationOpts.OnList
      local function on_list(opts)
        vim.fn.setqflist({}, " ", opts)

        if #opts.items == 1 then
          vim.cmd.cfirst()
        else
          MiniExtra.pickers.list({ scope = "quickfix" }, {
            source = { name = opts.title },
            window = {
              config = function()
                local height = math.floor(0.618 * vim.o.lines)
                local width = math.floor(0.618 * vim.o.columns)
                return {
                  relative = "cursor",
                  anchor = "NW",
                  height = height,
                  width = width,
                  row = 0,
                  col = 0,
                }
              end,
            },
          })
        end
      end

      if scope == "references" then
        vim.lsp.buf.references(nil, { on_list = on_list })
        return
      end

      if scope == "workspace_symbol" then
        vim.lsp.buf.workspace_symbol(get_symbol_query(), { on_list = on_list })
        return
      end

      vim.lsp.buf[scope]({ on_list = on_list })
    end

    ---@class FFFItem
    ---@field name string
    ---@field path string
    ---@field relative_path string
    ---@field size number
    ---@field modified number
    ---@field total_frecency_score number
    ---@field modification_frecency_score number
    ---@field access_frecency_score number
    ---@field git_status string

    ---@class PickerItem
    ---@field text string
    ---@field path string
    ---@field score number

    ---@class FFFPickerState
    ---@field current_file_cache string
    local state = {}

    -- vim.api.nvim_set_hl(0, "FFFileScore", { fg = require("dracula").colors().yellow })
    local ns_id = vim.api.nvim_create_namespace("MiniPick.FFFiles.Picker")

    ---@param query string|nil
    ---@return PickerItem[]
    local function find(query)
      local file_picker = require("fff.file_picker")

      query = query or ""
      ---@type FFFItem[]
      local fff_result = file_picker.search_files(query, 100, 4, state.current_file_cache, false)

      local items = {}
      for _, fff_item in ipairs(fff_result) do
        local item = {
          text = fff_item.relative_path,
          path = fff_item.path,
          score = fff_item.total_frecency_score,
        }
        table.insert(items, item)
      end

      return items
    end

    ---@param items PickerItem[]
    local function show(buf_id, items)
      local icon_data = {}

      -- Show items
      local items_to_show = {}
      for i, item in ipairs(items) do
        local icon, hl, _ = MiniIcons.get("file", item.text)
        icon_data[i] = { icon = icon, hl = hl }

        items_to_show[i] = string.format("%s %s %d", icon, item.text, item.score)
      end
      vim.api.nvim_buf_set_lines(buf_id, 0, -1, false, items_to_show)

      vim.api.nvim_buf_clear_namespace(buf_id, ns_id, 0, -1)

      local icon_extmark_opts = { hl_mode = "combine", priority = 200 }
      for i, item in ipairs(items) do
        -- Highlight Icons
        icon_extmark_opts.hl_group = icon_data[i].hl
        icon_extmark_opts.end_row, icon_extmark_opts.end_col = i - 1, 1
        vim.api.nvim_buf_set_extmark(buf_id, ns_id, i - 1, 0, icon_extmark_opts)

        -- Highlight score
        local col = #items_to_show[i] - #tostring(item.score) - 3
        icon_extmark_opts.hl_group = "FFFileScore"
        icon_extmark_opts.end_row, icon_extmark_opts.end_col = i - 1, #items_to_show[i]
        vim.api.nvim_buf_set_extmark(buf_id, ns_id, i - 1, col, icon_extmark_opts)
      end
    end

    local function fffiles_run(local_opts)
      local_opts = local_opts or {}
      local default_opts = { cwd = vim.uv.cwd() }
      local_opts = vim.tbl_extend("force", default_opts, local_opts)

      -- Setup fff.nvim
      local file_picker = require("fff.file_picker")
      if not file_picker.is_initialized() then
        local setup_success = file_picker.setup()
        if not setup_success then
          vim.notify("Could not setup fff.nvim", vim.log.levels.ERROR)
          return
        end
      end

      -- Cache current file to deprioritize in fff.nvim
      if not state.current_file_cache then
        local current_buf = vim.api.nvim_get_current_buf()
        if current_buf and vim.api.nvim_buf_is_valid(current_buf) then
          local current_file = vim.api.nvim_buf_get_name(current_buf)
          if current_file ~= "" and vim.fn.filereadable(current_file) == 1 then
            local relative_path = vim.fs.relpath(local_opts.cwd, current_file)
            state.current_file_cache = relative_path
          else
            state.current_file_cache = nil
          end
        end
      end

      -- Start picker
      local name = "FFFiles"
      local using_different_cwd = local_opts.cwd ~= default_opts.cwd
      if using_different_cwd then name = name .. string.format(" (%s)", local_opts.cwd) end
      MiniPick.start({
        source = {
          name = name,
          cwd = local_opts.cwd,
          items = find,
          match = function(_, _, query)
            local items = find(table.concat(query))
            MiniPick.set_picker_items(items, { do_match = false })
          end,
          show = show,
        },
      })

      state.current_file_cache = nil -- Reset cache
    end

    MiniPick.registry.fffiles = fffiles_run

    -- local align_grep_results = function(buf_id, items, query, opts)
    --   -- HACK: `items` is an array of strings with \0 byte separators, cannot use strdisplaywidth.
    --   local original = vim.fn.strdisplaywidth
    --   vim.fn.strdisplaywidth = string.len
    --   items = MiniAlign.align_strings(items, {
    --     justify_side = { "left", "right", "right" },
    --     merge_delimiter = { "", " ", "", " ", "" },
    --     split_pattern = "%z",
    --   })
    --   vim.fn.strdisplaywidth = original
    --   MiniPick.default_show(buf_id, items, query, opts)
    -- end
    -- MiniPick.registry.grep_live_align = function()
    --   MiniPick.builtin.grep_live({}, { source = { show = align_grep_results } })
    -- end

    local sep = package.config:sub(1, 1)
    -- local function truncate_path(path)
    --   local parts = vim.split(path, sep)
    --   if #parts > 2 then
    --     parts = { parts[1], "…", parts[#parts] }
    --   end
    --   return table.concat(parts, sep)
    -- end

    local function map_gsub(items, pattern, replacement)
      return vim.tbl_map(function(item)
        item, _ = string.gsub(item, pattern, replacement)
        return item
      end, items)
    end

    local show_align_on_null = function(buf_id, items, query, opts)
      -- Shorten the pathname to keep the width of the picker window to something
      -- a bit more reasonable for longer pathnames.
      -- items = map_gsub(items, '^%Z+', truncate_path)

      -- Because items is an array of blobs (contains a NUL byte), align_strings
      -- will not work because it expects strings. So, convert the NUL bytes to a
      -- unique (hopefully) separator, then align, and revert back.
      items = map_gsub(items, "%z", "#|#")
      items = MiniAlign.align_strings(items, {
        justify_side = { "left", "right", "right" },
        merge_delimiter = { "", " ", "", " ", "" },
        split_pattern = "#|#",
      })
      items = map_gsub(items, "#|#", "\0")
      MiniPick.default_show(buf_id, items, query, opts)
    end

    local ns = vim.api.nvim_create_namespace("DVT MiniPickRanges")
    vim.keymap.set({ "s", "v", "x" }, "<leader><space>", function()
      D(require("config.utils").get_selected_text())
      -- local show = function(buf_id, items, query)
      --   local hl_groups = {}
      --   items = vim.tbl_map(function(item)
      --     -- Get all items as returned by ripgrep
      --     local path, row, column, str = string.match(item, "^([^|]*)|([^|]*)|([^|]*)|(.*)$")
      --
      --     path = vim.fs.basename(path)
      --
      --     -- Trim text found
      --     str = string.gsub(str, "^%s*(.-)%s*$", "%1")
      --
      --     local icon, hl = MiniIcons.get("file", path)
      --     table.insert(hl_groups, hl)
      --
      --     return string.format("%s %s|%s|%s| %s", icon, path, row, column, str)
      --   end, items)
      --
      --   MiniPick.default_show(buf_id, items, query, { show_icons = false })
      --
      --   -- Add color to icons
      --   local icon_extmark_opts = { hl_mode = "combine", priority = 210 }
      --   for i = 1, #hl_groups do
      --     icon_extmark_opts.hl_group = hl_groups[i]
      --     icon_extmark_opts.end_row, icon_extmark_opts.end_col = i - 1, 1
      --     vim.api.nvim_buf_set_extmark(buf_id, ns, i - 1, 0, icon_extmark_opts)
      --   end
      -- end
      --
      -- local set_items_opts = { do_match = false, querytick = 0 }
      -- local process
      -- local match = function(_, _, query)
      --   pcall(vim.loop.process_kill, process)
      --   if #query == 0 then
      --     return MiniPick.set_picker_items({}, set_items_opts)
      --   end
      --
      --   local command = {
      --     "rg",
      --     "--column",
      --     "--line-number",
      --     "--no-heading",
      --     "--field-match-separator",
      --     "|",
      --     "--no-follow",
      --     "--color=never",
      --     "--",
      --     table.concat(query),
      --   }
      --   process = MiniPick.set_picker_items_from_cli(
      --     command,
      --     { set_items_opts = set_items_opts, spawn_opts = { cwd = vim.uv.cwd() } }
      --   )
      -- end
      --
      -- local choose = function(item)
      --   local path, row, column = string.match(item, "^([^|]*)|([^|]*)|([^|]*)|.*$")
      --   local chosen = {
      --     path = path,
      --     lnum = tonumber(row),
      --     col = tonumber(column),
      --   }
      --   MiniPick.default_choose(chosen)
      -- end
      --
      -- MiniPick.start({
      --   source = {
      --     name = "Live Grep",
      --     items = {},
      --     match = match,
      --     show = show,
      --     choose = choose,
      --   },
      -- })
    end, { desc = "[S]earch [G]rep" })

    vim.keymap.set(
      "n",
      "<leader>a",
      function()
        MiniPick.builtin.grep_live({}, {
          source = { show = show_align_on_null },
        })
      end,
      { desc = "grep live" }
    )

    vim.keymap.set({ "n" }, "<leader>A", function()
      local pattern = vim.fn.expand("<cword>")
      --
      vim.defer_fn(function() MiniPick.set_picker_query({ pattern }) end, 25)

      MiniPick.builtin.grep_live({}, {
        source = { show = show_align_on_null },
        -- window = { config = { width = vim.o.columns } },
      })
    end, { desc = "grep cursor" })

    vim.keymap.set({ "x", "s", "v" }, "<leader>A", function()
      local pattern = require("config.utils").get_visual_selection()

      vim.defer_fn(function() MiniPick.set_picker_query({ pattern }) end, 25)

      MiniPick.builtin.grep_live({}, {
        source = { show = show_align_on_null },
      })
    end, { desc = "grep selection" })

    vim.keymap.set("n", "<leader>ff", MiniPick.registry.frecency, { desc = "find smart files" })
    -- vim.keymap.set("n", "<leader><space>", function()
    --   if pcall(require, "fff") then
    --     MiniPick.registry.fffiles()
    --   else
    --     MiniPick.registry.files()
    --   end
    -- end, { desc = "find files" }) -- See https://github.com/echasnovski/mini.nvim/discussions/1873

    vim.keymap.set(
      "n",
      "<leader>fh",
      function() MiniPick.builtin.help({ default_split = "vertical" }) end,
      { desc = "[S]earch [H]elp" }
    )

    vim.keymap.set(
      "n",
      "<leader>lsd",
      function() MiniExtra.pickers.lsp({ scope = "document_symbol" }) end,
      { desc = "[S]earch [S]ymbols" }
    )

    vim.keymap.set(
      "n",
      "<leader>lsw",
      function() MiniExtra.pickers.lsp({ scope = "workspace_symbol" }) end,
      { desc = "[S]earch [S]ymbols" }
    )

    vim.keymap.set(
      "n",
      "gr",
      function() MiniExtra.pickers.lsp({ scope = "references" }) end,
      { desc = "[S]earch [R]eferences" }
    )

    vim.keymap.set("n", "<leader>sH", function() MiniExtra.pickers.history() end, { desc = "[S]earch [H]istory" })

    vim.keymap.set("n", "<leader>sd", function() MiniExtra.pickers.diagnostic() end, { desc = "[S]earch [D]iagnostic" })

    vim.keymap.set("n", "<leader><leader>", function() MiniPick.builtin.buffers() end, { desc = "[S]earch [B]uffers" })

    -- vim.keymap.set("n", "<leader>n", function()
    --   vim.cmd.tabnew()
    --   MiniNotify.show_history()
    -- end, { desc = "[N]otification History" })
    --
    -- vim.keymap.set("n", "<leader>sC", function()
    --   MiniExtra.pickers.colorschemes(nil, nil)
    -- end, { desc = "[S]earch [C]olorscheme" })

    vim.keymap.set("n", "z=", function()
      local word = vim.fn.expand("<cword>")
      MiniExtra.pickers.spellsuggest(nil, {
        window = {
          config = function()
            local height = math.floor(0.2 * vim.o.lines)
            local width = math.floor(math.max(vim.fn.strdisplaywidth(word) + 2, 20))
            return {
              relative = "cursor",
              anchor = "NW",
              height = height,
              width = width,
              row = 1, -- I want to see <cword>
              col = -1, -- Aligned nicely with <cword>
            }
          end,
        },
      })
    end, { desc = "Show spellings suggestions" })
  end,
}

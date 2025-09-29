-- if true then return {} end
local SETTINGS = require("config.options")

if not SETTINGS or not Keymap or not Augroup then return {} end

return {
  { "nvim-mini/mini.jump", enabled = false, version = false, opts = {} },
  { "nvim-mini/mini.icons", version = false },
  {
    "nvim-mini/mini.indentscope",
    config = function()
      require("mini.indentscope").setup({
        symbol = SETTINGS.indent_scope_char,
        mappings = {
          goto_top = "[[",
          goto_bottom = "]]",
        },
        draw = {
          delay = 0,
          animation = function() return 0 end,
        },
        options = { try_as_border = true, border = "both", indent_at_cursor = true },
      })

      Augroup("mini.indentscope", {
        {
          event = "FileType",
          pattern = {
            "help",
            "alpha",
            "dashboard",
            "neo-tree",
            "Trouble",
            "lazy",
            "mason",
            "fzf",
            "dirbuf",
            "terminal",
            "fzf-lua",
            "fzflua",
            "megaterm",
            "nofile",
            "terminal",
            "megaterm",
            "lsp-installer",
            "SidebarNvim",
            "lspinfo",
            "markdown",
            "help",
            "startify",
            "packer",
            "NeogitStatus",
            "oil",
            "DirBuf",
            "markdown",
          },
          command = function() vim.b.miniindentscope_disable = true end,
        },
      })
    end,
  },
  {
    enabled = false,
    "nvim-mini/mini.pick",
    version = false,
    -- lazy = false,
    dependencies = {
      {
        "dmtrKovalenko/fff.nvim",
        -- build = "cargo build --release",
        build = function(args)
          local function build_fff(args)
            local cmd = { "rustup", "run", "nightly", "cargo", "build", "--release" }
            local opts = { cwd = args.path, text = true }

            vim.notify("Building " .. args.name, vim.log.levels.INFO)

            local output = vim.system(cmd, opts):wait()
            if output.code ~= 0 then
              vim.notify("Failed to build fff.nvim", vim.log.levels.ERROR)
              vim.notify(output.stderr, vim.log.levels.ERROR)
            else
              vim.notify(args.name .. " Built", vim.log.levels.INFO)
            end
          end

          build_fff(args)
        end,
        opts = { -- (optional)
          debug = {
            enabled = true, -- we expect your collaboration at least during the beta
            show_scores = true, -- to help us optimize the scoring system, feel free to share your scores!
          },
        },
        -- No need to lazy-load with lazy.nvim.
        -- This plugin initializes itself lazily.
        lazy = false,
        -- keys = {
        --   {
        --     "ff", -- try it if you didn't it is a banger keybinding for a picker
        --     function() require("fff").find_files() end,
        --     desc = "FFFind files",
        --   },
        -- },
      },
    },
    config = function()
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

      require("mini.pick").setup({
        delay = {
          busy = 1,
        },

        mappings = {
          caret_left = "<Left>",
          caret_right = "<Right>",

          choose = "<C-y>",
          choose_in_split = "<C-h>",
          choose_in_vsplit = "<C-v>",
          choose_in_tabpage = "<C-t>",
          choose_marked = "<C-q>",

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

          refine = "<C-CR>",
          refine_marked = "",

          scroll_down = "<C-f>",
          scroll_left = "<C-Left>",
          scroll_right = "<C-Right>",
          scroll_up = "<C-b>",

          stop = "<Esc>",

          toggle_info = "<S-Tab>",
          toggle_preview = "<Tab>",

          another_choose = {
            char = "<CR>",
            func = function()
              local choose_mapping = MiniPick.get_picker_opts().mappings.choose
              vim.api.nvim_input(choose_mapping)
            end,
          },
          actual_paste = {
            char = "<C-r>",
            func = function()
              local content = vim.fn.getreg("+")
              if content ~= "" then
                local current_query = MiniPick.get_picker_query() or {}
                table.insert(current_query, content)
                MiniPick.set_picker_query(current_query)
              end
            end,
          },
        },

        options = {
          use_cache = false,
        },

        window = {
          config = function()
            local height = math.floor(0.5 * vim.o.lines)
            local width = vim.o.columns
            return {
              relative = "laststatus",
              anchor = "NW",
              height = height,
              width = width,
              row = 0,
              col = 0,
            }
          end,
          prompt_prefix = "󰁔 ",
          prompt_caret = " ",
        },
      })

      -- Using primarily for code action
      -- See https://github.com/nvim-mini/mini.nvim/discussions/1437
      vim.ui.select = MiniPick.ui_select

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
      -- See https://github.com/nvim-mini/mini.nvim/discussions/988#discussioncomment-10398788
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

      -- todo-comments picker section
      local show_todo = function(buf_id, entries, query, opts)
        MiniPick.default_show(buf_id, entries, query, opts)

        -- Add highlighting to every line in the buffer
        for line, entry in ipairs(entries) do
          for _, hl in ipairs(entry.hl) do
            local start = { line - 1, hl[1][1] }
            local finish = { line - 1, hl[1][2] }
            vim.hl.range(buf_id, ns_digit_prefix, hl[2], start, finish, { priority = vim.hl.priorities.user + 1 })
          end
        end
      end

      -- MiniPick.registry.todo = function()
      --   require("todo-comments.search").search(function(results)
      --     -- Don't do anything if there are no todos in the project
      --     if #results == 0 then return end

      --     local Config = require("todo-comments.config")
      --     local Highlight = require("todo-comments.highlight")

      --     for i, entry in ipairs(results) do
      --       -- By default, mini.pick uses the path item when an item is choosen to open it
      --       entry.path = entry.filename
      --       entry.filename = nil

      --       local relative_path = string.gsub(entry.path, vim.fn.getcwd() .. "/", "")
      --       local display = string.format("%s:%s:%s ", relative_path, entry.lnum, entry.col)
      --       local text = entry.text
      --       local start, finish, kw = Highlight.match(text)

      --       entry.hl = {}

      --       if start then
      --         kw = Config.keywords[kw] or kw
      --         local icon = Config.options.keywords[kw].icon or " "
      --         display = icon .. display
      --         table.insert(entry.hl, { { 0, #icon }, "TodoFg" .. kw })
      --         text = vim.trim(text:sub(start))

      --         table.insert(entry.hl, {
      --           { #display, #display + finish - start + 2 },
      --           "TodoBg" .. kw,
      --         })
      --         table.insert(entry.hl, {
      --           { #display + finish - start + 1, #display + finish + 1 + #text },
      --           "TodoFg" .. kw,
      --         })
      --         entry.text = display .. " " .. text
      --       end

      --       results[i] = entry
      --     end

      --     MiniPick.start({ source = { name = "Find Todo", show = show_todo, items = results } })
      --   end)
      -- end

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

      local ns_id = vim.api.nvim_create_namespace("MiniPick FFFiles Picker")
      -- vim.api.nvim_set_hl(0, "FFFileScore", { fg = require("dracula").colors().yellow })

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

      local function run(local_opts)
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

      MiniPick.registry.fffiles = run

      vim.keymap.set("n", "<leader>sf", function() MiniPick.registry.fffiles() end, { desc = "[S]earch [F]iles" }) -- See https://github.com/nvim-mini/mini.nvim/discussions/1873
    end,
  },
  {
    "nvim-mini/mini.surround",
    keys = {
      { "S", mode = { "x" } },
      "ys",
      "ds",
      "cs",
    },
    config = function()
      require("mini.surround").setup({
        mappings = {
          add = "ys",
          delete = "ds",
          replace = "cs",
          find = "",
          find_left = "",
          highlight = "",
          update_n_lines = "",
        },
      })

      Keymap("x", "S", [[:<C-u>lua MiniSurround.add('visual')<CR>]])
      Keymap("n", "yss", "ys_", { noremap = false })
    end,
  },
  {
    "nvim-mini/mini.hipatterns",
    opts = function()
      local hi = require("mini.hipatterns")
      return {

        -- Highlight standalone "FIXME", "ERROR", "HACK", "TODO", "NOTE", "WARN", "REF"
        highlighters = {
          fixme = { pattern = "%f[%w]()FIXME()%f[%W]", group = "MiniHipatternsFixme" },
          error = { pattern = "%f[%w]()ERROR()%f[%W]", group = "MiniHipatternsError" },
          hack = { pattern = "%f[%w]()HACK()%f[%W]", group = "MiniHipatternsHack" },
          warn = { pattern = "%f[%w]()WARN()%f[%W]", group = "MiniHipatternsWarn" },
          todo = { pattern = "%f[%w]()TODO()%f[%W]", group = "MiniHipatternsTodo" },
          note = { pattern = "%f[%w]()NOTE()%f[%W]", group = "MiniHipatternsNote" },
          ref = { pattern = "%f[%w]()REF()%f[%W]", group = "MiniHipatternsRef" },
          refs = { pattern = "%f[%w]()REFS()%f[%W]", group = "MiniHipatternsRef" },
          due = { pattern = "%f[%w]()@@%f![%W]", group = "MiniHipatternsDue" },

          hex_color = hi.gen_highlighter.hex_color({ priority = 2000 }),
          shorthand = {
            pattern = "()#%x%x%x()%f[^%x%w]",
            group = function(_, _, data)
              ---@type string
              local match = data.full_match
              local r, g, b = match:sub(2, 2), match:sub(3, 3), match:sub(4, 4)
              local hex_color = "#" .. r .. r .. g .. g .. b .. b

              return MiniHipatterns.compute_hex_color_group(hex_color, "bg")
            end,
            extmark_opts = { priority = 2000 },
          },
        },

        tailwind = {
          enabled = true,
          ft = {
            "astro",
            "css",
            "heex",
            "html",
            "html-eex",
            "javascript",
            "javascriptreact",
            "rust",
            "svelte",
            "typescript",
            "typescriptreact",
            "vue",
            "elixir",
            "phoenix-html",
            "heex",
          },
          -- full: the whole css class will be highlighted
          -- compact: only the color will be highlighted
          style = "full",
        },
      }
    end,
    config = function(_, opts) require("mini.hipatterns").setup(opts) end,
  },
  {
    "nvim-mini/mini.ai",
    keys = {
      { "a", mode = { "o", "x" } },
      { "i", mode = { "o", "x" } },
    },
    config = function()
      local ai = require("mini.ai")
      local gen_spec = ai.gen_spec
      ai.setup({
        n_lines = 500,
        search_method = "cover_or_next",
        custom_textobjects = {
          o = gen_spec.treesitter({
            a = { "@block.outer", "@conditional.outer", "@loop.outer" },
            i = { "@block.inner", "@conditional.inner", "@loop.inner" },
          }, {}),
          f = gen_spec.treesitter({ a = "@function.outer", i = "@function.inner" }, {}),
          c = gen_spec.treesitter({ a = "@class.outer", i = "@class.inner" }, {}),
          -- t = { "<(%w-)%f[^<%w][^<>]->.-</%1>", "^<.->%s*().*()%s*</[^/]->$" }, -- deal with selection without the carriage return
          t = { "<([%p%w]-)%f[^<%p%w][^<>]->.-</%1>", "^<.->().*()</[^/]->$" },

          -- scope
          s = gen_spec.treesitter({
            a = { "@function.outer", "@class.outer", "@testitem.outer" },
            i = { "@function.inner", "@class.inner", "@testitem.inner" },
          }),
          S = gen_spec.treesitter({
            a = { "@function.name", "@class.name", "@testitem.name" },
            i = { "@function.name", "@class.name", "@testitem.name" },
          }),
        },
        mappings = {
          around = "a",
          inside = "i",

          around_next = "an",
          inside_next = "in",
          around_last = "al",
          inside_last = "il",

          goto_left = "",
          goto_right = "",
        },
      })
    end,
  },
  {
    "nvim-mini/mini.pairs",
    enabled = false,
    opts = {
      modes = { insert = true, command = false, terminal = false },
      -- skip autopair when next character is one of these
      skip_next = [=[[%w%%%'%[%"%.%`%$]]=],
      -- skip autopair when the cursor is inside these treesitter nodes
      skip_ts = { "string" },
      -- skip autopair when next character is closing pair
      -- and there are more closing pairs than opening pairs
      skip_unbalanced = true,
      -- better deal with markdown code blocks
      markdown = true,
    },
  },
  {
    "nvim-mini/mini.clue",
    event = "VeryLazy",
    opts = function()
      local ok, clue = pcall(require, "mini.clue")
      if not ok then return end
      -- REF: https://github.com/ahmedelgabri/dotfiles/blob/main/config/nvim/lua/plugins/mini.lua#L314
      -- Clues for a-z/A-Z marks.
      local function mark_clues()
        local marks = {}
        vim.list_extend(marks, vim.fn.getmarklist(vim.api.nvim_get_current_buf()))
        vim.list_extend(marks, vim.fn.getmarklist())

        return vim
          .iter(marks)
          :map(function(mark)
            local key = mark.mark:sub(2, 2)

            -- Just look at letter marks.
            if not string.match(key, "^%a") then return nil end

            -- For global marks, use the file as a description.
            -- For local marks, use the line number and content.
            local desc
            if mark.file then
              desc = vim.fn.fnamemodify(mark.file, ":p:~:.")
            elseif mark.pos[1] and mark.pos[1] ~= 0 then
              local line_num = mark.pos[2]
              local lines = vim.fn.getbufline(mark.pos[1], line_num)
              if lines and lines[1] then desc = string.format("%d: %s", line_num, lines[1]:gsub("^%s*", "")) end
            end

            if desc then return {
              mode = "n",
              keys = string.format("`%s", key),
              desc = desc,
            } end
          end)
          :totable()
      end

      -- Clues for recorded macros.
      local function macro_clues()
        local res = {}
        for _, register in ipairs(vim.split("abcdefghijklmnopqrstuvwxyz", "")) do
          local keys = string.format("\"%s", register)
          local ok, desc = pcall(vim.fn.getreg, register, 1)
          if ok and desc ~= "" then
            table.insert(res, { mode = "n", keys = keys, desc = desc })
            table.insert(res, { mode = "v", keys = keys, desc = desc })
          end
        end

        return res
      end

      return {
        triggers = {
          -- Leader triggers
          { mode = "n", keys = "<leader>" },
          { mode = "x", keys = "<leader>" },

          { mode = "n", keys = "<localleader>" },
          { mode = "x", keys = "<localleader>" },

          { mode = "n", keys = "<C-x>", desc = "+task toggling" },
          -- Built-in completion
          { mode = "i", keys = "<C-x>" },

          -- `g` key
          { mode = "n", keys = "g", desc = "+go[to]" },
          { mode = "x", keys = "g", desc = "+go[to]" },

          -- Marks
          { mode = "n", keys = "'" },
          { mode = "n", keys = "`" },
          { mode = "x", keys = "'" },
          { mode = "x", keys = "`" },

          -- Registers
          { mode = "n", keys = "\"" },
          { mode = "x", keys = "\"" },
          { mode = "i", keys = "<C-r>" },
          { mode = "c", keys = "<C-r>" },

          -- Window commands
          { mode = "n", keys = "<C-w>" },

          -- `z` key
          { mode = "n", keys = "z" },
          { mode = "x", keys = "z" },

          -- mini.surround
          { mode = "n", keys = "S", desc = "+treesitter" },

          -- Operator-pending mode key
          { mode = "o", keys = "a" },
          { mode = "o", keys = "i" },

          -- Moving between stuff.
          { mode = "n", keys = "[" },
          { mode = "n", keys = "]" },
        },

        clues = {
          { mode = "n", keys = "<leader>e", desc = "+explore/edit files" },
          { mode = "n", keys = "<leader>f", desc = "+find (" .. "default" .. ")" },
          { mode = "n", keys = "<leader>t", desc = "+terminal" },
          { mode = "n", keys = "<leader>r", desc = "+repl" },
          { mode = "n", keys = "<leader>l", desc = "+lsp" },
          { mode = "n", keys = "<leader>n", desc = "+notes" },
          { mode = "n", keys = "<leader>g", desc = "+git" },
          { mode = "n", keys = "<leader>p", desc = "+plugins" },
          { mode = "n", keys = "<leader>z", desc = "+zk" },
          { mode = "n", keys = "<localleader>g", desc = "+git" },
          { mode = "n", keys = "<localleader>h", desc = "+git hunk" },
          { mode = "n", keys = "<localleader>t", desc = "+test" },
          { mode = "n", keys = "<localleader>s", desc = "+spell" },
          { mode = "n", keys = "<localleader>d", desc = "+debug" },
          { mode = "n", keys = "<localleader>y", desc = "+yank" },

          { mode = "n", keys = "[", desc = "+prev" },
          { mode = "n", keys = "]", desc = "+next" },

          clue.gen_clues.builtin_completion(),
          clue.gen_clues.g(),
          clue.gen_clues.marks(),
          clue.gen_clues.registers(),
          clue.gen_clues.windows(),
          clue.gen_clues.z(),

          mark_clues,
          macro_clues,
        },
        window = {
          -- Floating window config
          config = function(bufnr)
            local max_width = 0
            for _, line in ipairs(vim.api.nvim_buf_get_lines(bufnr, 0, -1, false)) do
              max_width = math.max(max_width, vim.fn.strchars(line))
            end

            -- Keep some right padding.
            max_width = max_width + 2

            return {
              border = "rounded",
              -- Dynamic width capped at 45.
              width = math.min(45, max_width),
            }
          end,

          -- Delay before showing clue window
          delay = 300,

          -- Keys to scroll inside the clue window
          scroll_down = "<C-d>",
          scroll_up = "<C-u>",
        },
      }
    end,
  },
}

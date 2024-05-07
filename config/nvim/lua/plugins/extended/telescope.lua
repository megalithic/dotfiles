return {
  {
    "nvim-telescope/telescope.nvim",
    event = "VimEnter",
    dependencies = {
      "nvim-lua/plenary.nvim",
      {
        "ten3roberts/window-picker.nvim",
        name = "window-picker",
        config = function()
          local picker = require("window-picker")
          picker.setup()
          picker.pick_window = function()
            return picker.select({ hl = "WindowPicker", prompt = "Pick window: " }, function(winid) return winid or nil end)
          end
        end,
      },
      { -- If encountering errors, see telescope-fzf-native README for installation instructions
        "nvim-telescope/telescope-fzf-native.nvim",

        -- `build` is used to run some command when the plugin is installed/updated.
        -- This is only run then, not every time Neovim starts up.
        build = "make",

        -- `cond` is a condition used to determine whether this plugin should be
        -- installed and loaded.
        cond = function() return vim.fn.executable("make") == 1 end,
      },

      "natecraddock/telescope-zf-native.nvim",
      "nvim-telescope/telescope-file-browser.nvim",
      "fdschmidt93/telescope-egrepify.nvim",
      "fdschmidt93/telescope-corrode.nvim",
      {
        "danielfalk/smart-open.nvim",
        branch = "0.2.x",
        dependencies = { "kkharji/sqlite.lua", { "nvim-telescope/telescope-fzf-native.nvim", build = "make" } },
      },

      -- "danielvolchek/tailiscope.nvim"
      "nvim-telescope/telescope-live-grep-args.nvim",
      "debugloop/telescope-undo.nvim",
      "folke/trouble.nvim",
      { "nvim-telescope/telescope-ui-select.nvim" },

      -- Useful for getting pretty icons, but requires a Nerd Font.
      { "nvim-tree/nvim-web-devicons", enabled = vim.g.have_nerd_font },
      -- { "altermo/telescope-nucleo-sorter.nvim", build = "cargo build --release" },
    },
    config = function()
      mega.picker = {
        find_files = nil,
        grep = nil,
        startup = nil,
        ivy = nil,
        dropdown = nil,
      }

      local fmt = string.format
      local map = vim.keymap.set
      local telescope = require("telescope")
      local transform_mod = require("telescope.actions.mt").transform_mod
      local actions = require("telescope.actions")
      local action_state = require("telescope.actions.state")
      local action_set = require("telescope.actions.set")
      local lga_actions = require("telescope-live-grep-args.actions")
      local previewers = require("telescope.previewers")
      local Job = require("plenary.job")
      local current_fn = nil

      require("mega.autocmds").augroup("Telescope", {
        {
          desc = "Telescope preview formatting",
          event = { "User" },
          pattern = { "TelescopePreviewerLoaded" },
          command = "setlocal number wrap numberwidth=5 norelativenumber nocursorline",
        },
        {
          -- HACK color parent as comment
          -- CAVEAT interferes with other Telescope Results that display for spaces
          event = { "FileType" },
          -- REF: https://github.com/nvim-telescope/telescope.nvim/issues/2014
          desc = "Telescope search results formatting for pretty results",
          pattern = { "TelescopeResults", "TelescopePrompt", "TelescopePreview" },
          -- pattern = { "TelescopeResults", "TelescopePrompt", "TelescopePreview" },
          command = function()
            vim.fn.matchadd("TelescopeParent", "\t\t.*$")
            vim.api.nvim_set_hl(0, "TelescopeParent", { link = "Comment" })
          end,
        },
      })

      local new_maker = function(filepath, bufnr, opts)
        filepath = vim.fn.expand(filepath)
        Job:new({
          command = "file",
          args = { "--mime-type", "-b", filepath },
          on_exit = function(j)
            local mime_type = vim.split(j:result()[1], "/")[1]
            if mime_type == "text" then
              previewers.buffer_previewer_maker(filepath, bufnr, opts)
            else
              -- maybe we want to write something to the buffer here
              vim.schedule(function() vim.api.nvim_buf_set_lines(bufnr, 0, -1, false, { "BINARY" }) end)
            end
          end,
        }):sync()
      end

      -- Set current folder as prompt title
      local function with_title(opts, extra)
        extra = extra or {}
        local path = opts.cwd or opts.path or extra.cwd or extra.path or nil
        local title = ""
        local buf_path = vim.fn.expand("%:p:h")
        local cwd = vim.fn.getcwd()
        if extra["title"] ~= nil then
          title = fmt("%s (%s):", extra.title, vim.fs.basename(vim.loop.cwd() or ""))
        else
          if path ~= nil and buf_path ~= cwd then
            title = require("plenary.path"):new(buf_path):make_relative(cwd)
          else
            title = vim.fn.fnamemodify(cwd, ":t")
          end
        end

        return vim.tbl_extend("force", opts, {
          prompt_title = title,
        }, extra or {})
      end

      local function extensions(name) return require("telescope").extensions[name] end

      local ts = setmetatable({}, {
        __index = function(_, key)
          return function(topts)
            local get_selection = function()
              local rv = vim.fn.getreg("v")
              local rt = vim.fn.getregtype("v")
              vim.cmd([[noautocmd silent normal! "vy]])
              local selection = vim.fn.getreg("v")
              vim.fn.setreg("v", rv, rt)
              return vim.split(selection, "\n")
            end

            local builtin = require("telescope.builtin")
            local mode = vim.api.nvim_get_mode().mode
            topts = topts or {}
            if mode == "v" or mode == "V" or mode == "" then topts.default_text = table.concat(get_selection()) end
            if key == "grepify" or key == "egrepify" then
              extensions("egrepify").egrepify(with_title(topts, { title = "live grep (egrepify)" }))
            elseif key == "undo" then
              extensions("undo").undo(with_title(topts, { title = "undo" }))
            elseif key == "smart_open" or key == "smart" then
              extensions("smart_open").smart_open(with_title(topts, { title = "smartly find files" }))
            elseif key == "grep" or key == "live_grep" then
              extensions("live_grep_args").live_grep_args(with_title(topts, { title = "live grep args" }))
            elseif key == "corrode" then
              extensions("corrode").corrode(with_title(topts, { title = "find files (corrode)" }))
            elseif key == "find_files" or key == "fd" then
              -- extensions("corrode").corrode(with_title(topts, { title = "find files (corrode)" }))
              builtin[key](with_title(topts, { title = "find files" }))
            else
              builtin[key](topts)
            end
          end
        end,
      })

      local function get_border(opts)
        opts = vim.tbl_deep_extend("force", opts or {}, {
          borderchars = {
            { "", "", "", "", "", "", "", "" },
            prompt = { "", "", "", "", "", "", "", "" },
            results = { "", "", "", "", "", "", "", "" },
            preview = { "", "", "", "", "", "", "", "" },
            -- { " ", " ", " ", " ", " ", " ", " ", " " },
            -- prompt = { " ", " ", " ", " ", " ", " ", " ", " " },
            -- results = { " ", " ", " ", " ", " ", " ", " ", " " },
            -- preview = { " ", " ", " ", " ", " ", " ", " ", " " },
            -- prompt = { "─", "│", " ", "│", "┌", "┐", "│", "│" },
            -- results = { "─", "│", "─", "│", "├", "┤", "┘", "└" },
            -- preview = { "─", "│", "─", "│", "┌", "┐", "┘", "└" },
          },
        })

        return opts
      end

      local function stopinsert(callback)
        return function(prompt_bufnr)
          vim.cmd.stopinsert()
          vim.schedule(function() callback(prompt_bufnr) end)
        end
      end

      local function dropdown(opts)
        opts = vim.tbl_deep_extend("force", opts or {}, {})
        return require("telescope.themes").get_dropdown(get_border(opts))
      end
      mega.dropdown = dropdown

      local function ivy(opts)
        opts = vim.tbl_deep_extend("force", opts or {}, { layout_config = { height = 0.3 } })
        return require("telescope.themes").get_ivy(get_border(opts))
      end
      mega.ivy = ivy

      local grep = function(...) ts.live_grep(ivy(...)) end
      mega.picker.grep = grep

      -- Gets the root dir from either:
      -- * connected lsp
      -- * .git from file
      -- * .git from cwd
      -- * cwd
      ---@param opts? table
      local find_files = function(opts)
        opts = vim.tbl_deep_extend("force", opts or {}, {})
        local picker = opts and opts["picker"] or "find_files"
        local theme = opts and opts["theme"] or "ivy"
        local bufnr = vim.api.nvim_get_current_buf()
        local fn = vim.api.nvim_buf_get_name(bufnr)

        current_fn = fn
        -- opts.cwd = require("mega.utils").get_root()
        -- vim.notify(fmt("current project files root: %s", opts.cwd), vim.log.levels.DEBUG, { title = "telescope" })
        -- local picker = ts["find_files"]

        if theme == "ivy" then
          ts[picker](ivy(opts))
        elseif theme == "dropdown" then
          ts[picker](dropdown(opts))
        else
          ts[picker](opts)
        end
      end
      mega.picker.find_files = find_files

      mega.picker.startup = function(bufnr)
        mega.picker.find_files({
          theme = "dropdown",
          hidden = true,
          no_ignore = false,
          previewer = false,
          prompt_title = "",
          preview_title = "",
          results_title = "",
          layout_config = { prompt_position = "top" },
          -- FIXME: this simply will not work; unable to override defaults
          mappings = {
            i = {
              ["<cr>"] = stopinsert(function(pb)
                multi(pb, "edit")
                vim.schedule(function() vim.api.nvim_buf_delete(bufnr + 1, { force = true }) end)
              end),
            },
            n = {
              ["<cr>"] = function(pb)
                multi(pb, "vnew")
                vim.schedule(function() vim.api.nvim_buf_delete(bufnr + 1, { force = true }) end)
              end,
            },
          },
        })
      end

      local fd_find_command = { "fd", "--type", "f", "--hidden", "--no-ignore-vcs", "--strip-cwd-prefix" }
      local rg_find_command = {
        "rg",
        "--files",
        "--no-ignore-vcs",
        "--no-heading",
        "--hidden",
        "--with-filename",
        "--column",
        "--smart-case",
        -- "--ignore-file",
        -- (Path.join(vim.env.HOME, ".dotfiles", "misc", "tool-ignores")),
        "--iglob",
        "!.git",
      }

      local find_files_cmd = fd_find_command
      local grep_files_cmd = {
        "rg",
        "--hidden",
        "--no-ignore-vcs",
        "--no-heading",
        "--with-filename",
        "--line-number",
        "--column",
        "--smart-case",
        "--color=never",
        "--fixed-strings",
        "--trim",
      }

      local function multi(pb, verb, open_selection_under_cursor)
        open_selection_under_cursor = open_selection_under_cursor or false
        local methods = {
          ["vnew"] = "select_vertical",
          ["new"] = "select_horizontal",
          ["edit"] = "select_default",
          ["tabnew"] = "select_tab",
        }
        local select_action = methods[verb]
        local picker = action_state.get_current_picker(pb)
        local selections = picker:get_multi_selection()
        local num_selections = #selections

        -- NOTE: optionally send to qf:
        -- https://github.com/olimorris/dotfiles/blob/main/.config/nvim/lua/Oli/plugins/telescope.lua#L103-L121
        if open_selection_under_cursor or current_fn == nil or num_selections == 0 then
          actions[select_action](pb)
        else
          if current_fn ~= nil then -- is it a file -> open it as well:
            vim.cmd(fmt("%s %s", "edit!", current_fn))
            current_fn = nil
          end
        end

        for _, p in pairs(selections) do
          if p.path ~= nil then -- is it a file -> open it as well:
            vim.cmd(fmt("%s %s", verb, p.path))
          end
        end

        -- if num_selections > 1 then
        --   actions.send_selected_to_qflist(pb)
        --   actions.open_qflist()
        -- else
        --   actions.file_edit(pb)
        -- end
      end

      local function file_extension_filter(prompt)
        -- if prompt starts with escaped @ then treat it as a literal
        if (prompt):sub(1, 2) == "\\@" then return { prompt = prompt:sub(2) } end

        local result = vim.split(prompt, " ", {})
        -- if prompt starts with, for example:
        --    prompt: @lua <search_term>
        -- then only search files ending in *.lua
        if #result == 2 and result[1]:sub(1, 1) == "@" and (#result[1] == 2 or #result[1] == 3 or #result[1] == 4) then
          print(result[2], result[1]:sub(2))
          return { prompt = result[2] .. "." .. result[1]:sub(2) }
        else
          return { prompt = prompt }
        end
      end

      local function filename_first(_, path)
        local tail = vim.fs.basename(path)
        local parent = vim.fs.dirname(path)
        if parent == "." then return tail end
        return string.format("%s\t\t%s", tail, parent)
      end

      telescope.setup({
        -- You can put your default mappings / updates / etc. in here
        --  All the info you're looking for is in `:help telescope.setup()`
        --
        defaults = {
          theme = "ivy",
          dynamic_preview_title = true,
          selection_strategy = "reset",
          scroll_strategy = "limit",
          sorting_strategy = "ascending",
          path_display = { "truncate" },
          color_devicons = true,
          file_previewer = require("telescope.previewers").vim_buffer_cat.new,
          grep_previewer = require("telescope.previewers").vim_buffer_vimgrep.new,
          qflist_previewer = require("telescope.previewers").vim_buffer_qflist.new,
          layout_strategy = "horizontal",
          layout_config = {
            prompt_position = "top",
          },
          -- buffer_previewer_maker = new_maker,
          -- preview = {
          --   mime_hook = function(filepath, bufnr, opts)
          --     local is_image = function(fp)
          --       local image_extensions = { "png", "jpg" } -- Supported image formats
          --       local split_path = vim.split(fp:lower(), ".", { plain = true })
          --       local extension = split_path[#split_path]
          --       return vim.tbl_contains(image_extensions, extension)
          --     end
          --
          --     if is_image(filepath) then
          --       local term = vim.api.nvim_open_term(bufnr, {})
          --       local function send_output(_, data, _)
          --         vim.pprint(data)
          --         for _, d in ipairs(data) do
          --           vim.api.nvim_chan_send(term, d .. "\r\n")
          --         end
          --       end
          --       vim.fn.jobstart({
          --         "catimg",
          --         filepath, -- Terminal image viewer command
          --       }, { on_stdout = send_output, stdout_buffered = true, pty = true })
          --     else
          --       require("telescope.previewers.utils").set_preview_message(bufnr, opts.winid, "Binary cannot be previewed")
          --     end
          --   end,
          -- },
          mappings = {
            i = {
              ["<esc>"] = require("telescope.actions").close,
              -- ['<cr>'] = require('telescope.actions').select_vertical,
              ["<c-v>"] = stopinsert(function(pb) multi(pb, "vnew") end),
              ["<c-s>"] = stopinsert(function(pb) multi(pb, "new") end),
              ["<c-o>"] = stopinsert(function(pb) multi(pb, "edit") end),
              ["<c-z>"] = actions.toggle_selection,
              ["<c-r>"] = actions.to_fuzzy_refine,
              ["<c-n>"] = actions.move_selection_next,
              ["<c-p>"] = actions.move_selection_previous,
              -- ["<c-t>"] = require("trouble.sources.telescope").open,
              ["<c-down>"] = function(...) return actions.cycle_history_next(...) end,
              ["<c-up>"] = function(...) return actions.cycle_history_prev(...) end,
              ["<c-q>"] = actions.smart_send_to_qflist + actions.open_qflist,
              ["<c-a>"] = { "<Home>", type = "command" },
              ["<c-e>"] = { "<End>", type = "command" },
              ["<tab>"] = actions.toggle_selection,
              ["<S-Cr>"] = function(prompt_bufnr)
                -- Use nvim-window-picker to choose the window by dynamically attaching a function

                local cur_picker = action_state.get_current_picker(prompt_bufnr)
                cur_picker.get_selection_window = function(picker, _)
                  local picked_window_id = require("window-picker").pick_window() or vim.api.nvim_get_current_win()
                  -- Unbind after using so next instance of the picker acts normally
                  picker.get_selection_window = nil
                  return picked_window_id
                end

                return action_set.edit(prompt_bufnr, "edit")
              end,
            },
            n = {
              -- ["<cr>"] = function(pb) multi(pb, "vnew") end,
              -- ["<c-v>"] = function(pb) multi(pb, "vnew") end,
              -- ["<c-s>"] = function(pb) multi(pb, "new") end,
              -- ["<c-o>"] = function(pb) multi(pb, "edit") end,
            },
          },
          results_title = false,
          prompt_prefix = " ",
          selection_caret = " ",
          entry_prefix = "  ",
          multi_icon = "󰛄 ",
          winblend = 0,
          vimgrep_arguments = grep_files_cmd,
        },
        file_ignore_patterns = {
          ".DS_Store",
          "%.DS_Store",
          "%.csv",
          "%.jpg",
          "%.jpeg",
          "%.png",
          -- "%.svg",
          "%.otf",
          "%.ttf",
          "%.lock",
          "__pycache__",
          "%.sqlite3",
          "%.ipynb",
          "vendor",
          "^.git/",
          "node%_modules/.*",
          "^site-packages/",
          "%.yarn/.*",
          "^dotbot",
        },
        pickers = {
          lsp_definitions = ivy({}),
          buffers = dropdown({}),
          highlights = ivy({}),
          find_files = ivy({
            path_display = filename_first,
            find_command = find_files_cmd,
            on_input_filter_cb = file_extension_filter,
            mappings = {
              i = {
                ["<cr>"] = stopinsert(function(pb)
                  -- actions.select_vertical(pb)
                  multi(pb, "vnew")
                end),
                ["<c-v>"] = stopinsert(function(pb)
                  multi(pb, "vnew")
                  -- actions.select_vertical(pb)
                end),
                ["<c-s>"] = stopinsert(function(pb)
                  multi(pb, "new")
                  -- actions.select_horizontal(pb)
                end),
                ["<c-o>"] = stopinsert(function(pb)
                  multi(pb, "edit")
                  -- actions.select_default(pb)
                end),
              },
            },
          }),
          grep_string = ivy({}),
          live_grep = ivy({
            mappings = {
              i = {
                ["<cr>"] = stopinsert(function(pb)
                  multi(pb, "vnew")
                  -- actions.select_vertical(pb)
                end),
                ["<C-f>"] = actions.to_fuzzy_refine,
                ["<C-s>"] = actions.to_fuzzy_refine,
              },
            },
            on_input_filter_cb = function(prompt)
              -- if prompt starts with escaped @ then treat it as a literal
              if (prompt):sub(1, 2) == "\\@" then return { prompt = prompt:sub(2):gsub("%s", ".*") } end
              -- if prompt starts with, for example, @rs
              -- only search files that end in *.rs
              local result = string.match(prompt, "@%a*%s")
              if not result then
                return {
                  prompt = prompt:gsub("%s", ".*"),
                  updated_finder = require("telescope.finders").new_job(
                    function(new_prompt)
                      return vim.tbl_flatten({
                        require("telescope.config").values.vimgrep_arguments,
                        "--",
                        new_prompt,
                      })
                    end,
                    require("telescope.make_entry").gen_from_vimgrep({}),
                    nil,
                    nil
                  ),
                }
              end

              local result_len = #result

              result = result:sub(2)
              result = vim.trim(result)

              if result == "js" or result == "ts" then result = string.format("{%s,%sx}", result, result) end

              return {
                prompt = prompt:sub(result_len + 1):gsub("%s", ".*"),
                updated_finder = require("telescope.finders").new_job(
                  function(new_prompt)
                    return vim.tbl_flatten({
                      require("telescope.config").values.vimgrep_arguments,
                      string.format("-g*.%s", result),
                      "--",
                      new_prompt,
                    })
                  end,
                  require("telescope.make_entry").gen_from_vimgrep({}),
                  nil,
                  nil
                ),
              }
            end,
          }),
          lsp_references = ivy({
            -- mappings = {
            --   i = {
            --     ["<cr>"] = stopinsert(function(pb)
            --       -- multi(pb, 'vnew')
            --       actions.select_vertical(pb)
            --     end),
            --   },
            -- },
          }),
        },
        extensions = {
          fzf = {
            fuzzy = true,
            override_generic_sorter = true,
            override_file_sorter = true,
            case_mode = "smart_case",
          },
          smart_open = {
            show_scores = false,
            ignore_patterns = { "*.git/*", "*/tmp/*" },
            match_algorithm = "fzf",
            disable_devicons = false,
            -- open_buffer_indicators = { previous = "👀", others = "🙈" },
            cwd_only = true,
            mappings = {
              i = {
                ["<cr>"] = stopinsert(function(pb) multi(pb, "vnew") end),
                ["<esc>"] = require("telescope.actions").close,
                ["<c-v>"] = stopinsert(function(pb) multi(pb, "vnew") end),
                ["<c-s>"] = stopinsert(function(pb) multi(pb, "new") end),
                ["<c-o>"] = stopinsert(function(pb) multi(pb, "edit") end),
                ["<tab>"] = actions.toggle_selection,
              },
            },
          },
          live_grep_args = {
            auto_quoting = true, -- enable/disable auto-quoting
            -- define mappings, e.g.
            mappings = { -- extend mappings
              i = {
                ["<c-r>"] = lga_actions.quote_prompt(),
                ["<c-i>"] = lga_actions.quote_prompt({ postfix = " --iglob " }),
                ["<c-t>"] = lga_actions.quote_prompt({ postfix = " -t " }),
                ["<esc>"] = require("telescope.actions").close,
                ["<c-v>"] = stopinsert(function(pb) multi(pb, "vnew") end),
                ["<c-s>"] = stopinsert(function(pb) multi(pb, "new") end),
                ["<c-o>"] = stopinsert(function(pb) multi(pb, "edit") end),
                ["<cr>"] = stopinsert(function(pb) multi(pb, "vnew") end),
                ["<tab>"] = actions.toggle_selection + actions.move_selection_next,
              },
              n = {
                ["<esc>"] = require("telescope.actions").close,
                ["<c-v>"] = function(pb) multi(pb, "vnew") end,
                ["<c-s>"] = function(pb) multi(pb, "new") end,
                ["<c-o>"] = function(pb) multi(pb, "edit") end,
                ["<cr>"] = function(pb) multi(pb, "vnew") end,
              },
            },
            -- ... also accepts theme settings, for example:
            theme = "ivy", -- use dropdown theme
            -- theme = { }, -- use own theme spec
            -- layout_config = { mirror=true }, -- mirror preview pane
          },
          ["ui-select"] = {
            require("telescope.themes").get_dropdown(),
          },
        },
      })

      -- Enable Telescope extensions if they are installed
      telescope.load_extension("undo")
      telescope.load_extension("ui-select")
      telescope.load_extension("live_grep_args")
      telescope.load_extension("file_browser")
      telescope.load_extension("fzf")
      telescope.load_extension("egrepify")
      telescope.load_extension("corrode")
      telescope.load_extension("smart_open")
      -- telescope.load_extension("nucleo")
      -- telescope.load_extension("zf-native")

      local builtin = require("telescope.builtin")
      map("n", "<leader>ff", function() mega.picker.find_files({ picker = "smart_open" }) end, { desc = "[f]ind [f]iles" })
      map("n", "<leader>fh", ts.help_tags, { desc = "[f]ind [h]elp" })
      map("n", "<leader>fk", ts.keymaps, { desc = "[f]ind [k]eymaps" })
      -- map("n", "<leader>fs", ts.builtin, { desc = "[f]ind [f]elect Telescope" })
      map("n", "<leader>a", mega.picker.grep, { desc = "grep (live)" })
      -- map("n", "<leader>A", ts.grep_string, { desc = "grep (under cursor)" })
      map("n", "<leader>A", function() mega.picker.grep({ default_text = vim.fn.expand("<cword>") }) end, { desc = "grep (under cursor)" })
      map({ "v", "x" }, "<leader>A", function()
        local pattern = require("mega.utils").get_visual_selection()
        mega.picker.grep({ default_text = pattern })
      end, { desc = "grep (selection)" })

      map("n", "<leader>fd", ts.diagnostics, { desc = "[S]earch [D]iagnostics" })
      map("n", "<leader>fc", function() mega.picker.find_files({ picker = "smart_open", cwd = vim.fn.stdpath("config") }) end, { desc = "[f]ind in [c]onfig" })
      map("n", "<leader>fr", ts.resume, { desc = "[S]earch [R]esume" })
      map("n", "<leader>f.", ts.oldfiles, { desc = "[S]earch Recent Files (\".\" for repeat)" })
      map("n", "<leader><leader>", ts.buffers, { desc = "[ ] Find existing buffers" })

      -- Slightly advanced example of overriding default behavior and theme
      map("n", "<leader>/", function()
        -- You can pass additional configuration to Telescope to change the theme, layout, etc.
        builtin.current_buffer_fuzzy_find(require("telescope.themes").get_dropdown({
          winblend = 10,
          previewer = false,
        }))
      end, { desc = "[/] Fuzzily search in current buffer" })

      -- Shortcut for searching your Neovim configuration files
    end,
  },
}

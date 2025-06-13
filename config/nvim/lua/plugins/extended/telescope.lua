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

      "nvim-telescope/telescope-file-browser.nvim",
      { "fdschmidt93/telescope-egrepify.nvim" },
      "fdschmidt93/telescope-corrode.nvim",
      {
        "danielfalk/smart-open.nvim",
        branch = "0.2.x", -- NOTE: we're stuck here because `main` breaks keymaps
        dependencies = { "kkharji/sqlite.lua", { "nvim-telescope/telescope-fzf-native.nvim", build = "make" } },
      },

      -- "danielvolchek/tailiscope.nvim"
      "nvim-telescope/telescope-live-grep-args.nvim",
      "debugloop/telescope-undo.nvim",
      "folke/trouble.nvim",
      { "nvim-telescope/telescope-ui-select.nvim" },
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
      local map = function(mode, lhs, rhs, desc)
        if type(desc) == "table" then desc = desc[1] end
        vim.keymap.set(mode, lhs, rhs, { desc = fmt("[+%s] %s", vim.g.picker, desc) })
      end
      local telescope = require("telescope")
      local transform_mod = require("telescope.actions.mt").transform_mod
      local actions = require("telescope.actions")
      local egrep_actions = require("telescope._extensions.egrepify.actions")
      local undo_actions = require("telescope-undo.actions")
      local action_state = require("telescope.actions.state")
      local action_set = require("telescope.actions.set")
      local lga_actions = require("telescope-live-grep-args.actions")
      local previewers = require("telescope.previewers")
      local Job = require("plenary.job")
      local current_fn = nil

      require("config.autocmds").augroup("Telescope", {
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
        -- {
        --   event = { "FileType" },
        --   -- REF: https://github.com/chrisgrieser/.config/blob/main/nvim/lua/funcs/telescope-backdrop.lua
        --   desc = "Telescope search results formatting for pretty results",
        --   pattern = { "TelescopePrompt" },
        --   command = function(ctx)
        --     local backdropName = "TelescopeBackdrop"
        --     local blend = 90
        --
        --     local telescopeBufnr = ctx.buf
        --
        --     -- `Telescope` apparently do not set a zindex, so it uses the default value
        --     -- of `nvim_open_win`, which is 50: https://neovim.io/doc/user/api.html#nvim_open_win()
        --     local telescopeZindex = 50
        --
        --     local bufnr = vim.api.nvim_create_buf(false, true)
        --     local winnr = vim.api.nvim_open_win(bufnr, false, {
        --       relative = "editor",
        --       row = 0,
        --       col = 0,
        --       width = vim.o.columns,
        --       height = vim.o.lines,
        --       focusable = false,
        --       style = "minimal",
        --       zindex = telescopeZindex - 1, -- ensure it's below the reference window
        --     })
        --
        --     vim.api.nvim_set_hl(0, backdropName, { bg = "#000000", default = true })
        --     vim.wo[winnr].winhighlight = "Normal:" .. backdropName
        --     vim.wo[winnr].winblend = blend
        --     vim.bo[bufnr].buftype = "nofile"
        --     vim.bo[bufnr].filetype = backdropName
        --
        --     -- close backdrop when the reference buffer is closed
        --     vim.api.nvim_create_autocmd({ "WinClosed", "BufLeave" }, {
        --       once = true,
        --       buffer = telescopeBufnr,
        --       callback = function()
        --         if vim.api.nvim_win_is_valid(winnr) then vim.api.nvim_win_close(winnr, true) end
        --         if vim.api.nvim_buf_is_valid(bufnr) then vim.api.nvim_buf_delete(bufnr, { force = true }) end
        --       end,
        --     })
        --   end,
        -- },
      })

      -- REF: https://github.com/tjdevries/config.nvim/blob/master/lua/custom/telescope/multi-ripgrep.lua
      -- local function multi_rg(opts)
      --   local conf = require("telescope.config").values
      --   local finders = require("telescope.finders")
      --   local make_entry = require("telescope.make_entry")
      --   local pickers = require("telescope.pickers")
      --
      --   local flatten = vim.tbl_flatten
      --
      --   -- i would like to be able to do telescope
      --   -- and have telescope do some filtering on files and some grepping
      --
      --   -- return function(opts)
      --   opts = opts or {}
      --   opts.cwd = opts.cwd and vim.fn.expand(opts.cwd) or vim.loop.cwd()
      --   opts.shortcuts = opts.shortcuts
      --     or {
      --       ["l"] = "*.lua",
      --       ["v"] = "*.vim",
      --       ["n"] = "*.{vim,lua}",
      --       ["c"] = "*.c",
      --       ["r"] = "*.rs",
      --       ["g"] = "*.go",
      --     }
      --   opts.pattern = opts.pattern or "%s"
      --
      --   local custom_grep = finders.new_async_job({
      --     command_generator = function(prompt)
      --       if not prompt or prompt == "" then return nil end
      --
      --       local prompt_split = vim.split(prompt, "  ")
      --
      --       local args = { "rg" }
      --       if prompt_split[1] then
      --         table.insert(args, "-e")
      --         table.insert(args, prompt_split[1])
      --       end
      --
      --       if prompt_split[2] then
      --         table.insert(args, "-g")
      --
      --         local pattern
      --         if opts.shortcuts[prompt_split[2]] then
      --           pattern = opts.shortcuts[prompt_split[2]]
      --         else
      --           pattern = prompt_split[2]
      --         end
      --
      --         table.insert(args, string.format(opts.pattern, pattern))
      --       end
      --
      --       return flatten({
      --         args,
      --         { "--color=never", "--no-heading", "--with-filename", "--line-number", "--column", "--smart-case" },
      --       })
      --     end,
      --     entry_maker = make_entry.gen_from_vimgrep(opts),
      --     cwd = opts.cwd,
      --   })
      --
      --   pickers
      --     .new(opts, {
      --       debounce = 100,
      --       prompt_title = "Live Grep (with shortcuts)",
      --       finder = custom_grep,
      --       previewer = conf.grep_previewer(opts),
      --       sorter = require("telescope.sorters").empty(),
      --     })
      --     :find()
      --   -- end
      -- end

      -- Set current folder as prompt title
      local function with_title(opts, extra)
        extra = extra or {}
        local path = opts.cwd or opts.path or extra.cwd or extra.path or nil
        local title = ""
        local buf_path = vim.fn.expand("%:p:h")
        local cwd = vim.fn.getcwd()
        if extra["title"] ~= nil then
          title = fmt("%s (%s):", extra.title, vim.fs.basename(path or vim.uv.cwd() or ""))
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

      local function get_border(opts)
        opts = vim.tbl_deep_extend("force", opts or {}, {
          borderchars = {
            -- { "", "", "", "", "", "", "", "" },
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
      mega.picker.dropdown = dropdown

      local function ivy(opts)
        opts = vim.tbl_deep_extend("force", opts or {}, {
          disable_devicons = true,
          layout_config = { height = 0.3 },
        })
        return require("telescope.themes").get_ivy(get_border(opts))
      end
      mega.picker.ivy = ivy

      local function fuse(opts)
        local Layout = require("nui.layout")
        local Popup = require("nui.popup")

        local telescope = require("telescope")
        local TSLayout = require("telescope.pickers.layout")

        local function make_popup(options)
          local popup = Popup(options)
          function popup.border:change_title(title) popup.border.set_text(popup.border, "top", title) end
          return TSLayout.Window(popup)
        end

        return {
          disable_devicons = true,
          layout_strategy = "flex",
          layout_config = {
            horizontal = {
              size = {
                width = "90%",
                height = "60%",
              },
            },
            vertical = {
              size = {
                width = "90%",
                height = "90%",
              },
            },
          },
          create_layout = function(picker)
            local border = {
              results = {
                top_left = "┌",
                top = "─",
                top_right = "┬",
                right = "│",
                bottom_right = "",
                bottom = "",
                bottom_left = "",
                left = "│",
              },
              results_patch = {
                minimal = {
                  top_left = "┌",
                  top_right = "┐",
                },
                horizontal = {
                  top_left = "┌",
                  top_right = "┬",
                },
                vertical = {
                  top_left = "├",
                  top_right = "┤",
                },
              },
              prompt = {
                top_left = "├",
                top = "─",
                top_right = "┤",
                right = "│",
                bottom_right = "┘",
                bottom = "─",
                bottom_left = "└",
                left = "│",
              },
              prompt_patch = {
                minimal = {
                  bottom_right = "┘",
                },
                horizontal = {
                  bottom_right = "┴",
                },
                vertical = {
                  bottom_right = "┘",
                },
              },
              preview = {
                top_left = "┌",
                top = "─",
                top_right = "┐",
                right = "│",
                bottom_right = "┘",
                bottom = "─",
                bottom_left = "└",
                left = "│",
              },
              preview_patch = {
                minimal = {},
                horizontal = {
                  bottom = "─",
                  bottom_left = "",
                  bottom_right = "┘",
                  left = "",
                  top_left = "",
                },
                vertical = {
                  bottom = "",
                  bottom_left = "",
                  bottom_right = "",
                  left = "│",
                  top_left = "┌",
                },
              },
            }

            local results = make_popup({
              focusable = false,
              border = {
                style = border.results,
                text = {
                  top = picker.results_title,
                  top_align = "center",
                },
              },
              win_options = {
                winhighlight = "Normal:Normal",
              },
            })

            local prompt = make_popup({
              enter = true,
              border = {
                style = border.prompt,
                text = {
                  top = picker.prompt_title,
                  top_align = "center",
                },
              },
              win_options = {
                winhighlight = "Normal:Normal",
              },
            })

            local preview = make_popup({
              focusable = false,
              border = {
                style = border.preview,
                text = {
                  top = picker.preview_title,
                  top_align = "center",
                },
              },
            })

            local box_by_kind = {
              vertical = Layout.Box({
                Layout.Box(preview, { grow = 1 }),
                Layout.Box(results, { grow = 1 }),
                Layout.Box(prompt, { size = 3 }),
              }, { dir = "col" }),
              horizontal = Layout.Box({
                Layout.Box({
                  Layout.Box(results, { grow = 1 }),
                  Layout.Box(prompt, { size = 3 }),
                }, { dir = "col", size = "50%" }),
                Layout.Box(preview, { size = "50%" }),
              }, { dir = "row" }),
              minimal = Layout.Box({
                Layout.Box(results, { grow = 1 }),
                Layout.Box(prompt, { size = 3 }),
              }, { dir = "col" }),
            }

            local function get_box()
              local strategy = picker.layout_strategy
              if strategy == "vertical" or strategy == "horizontal" then return box_by_kind[strategy], strategy end

              local height, width = vim.o.lines, vim.o.columns
              local box_kind = "horizontal"
              if width < 100 then
                box_kind = "vertical"
                if height < 40 then box_kind = "minimal" end
              end
              return box_by_kind[box_kind], box_kind
            end

            local function prepare_layout_parts(layout, box_type)
              layout.results = results
              results.border:set_style(border.results_patch[box_type])

              layout.prompt = prompt
              prompt.border:set_style(border.prompt_patch[box_type])

              if box_type == "minimal" then
                layout.preview = nil
              else
                layout.preview = preview
                preview.border:set_style(border.preview_patch[box_type])
              end
            end

            local function get_layout_size(box_kind) return picker.layout_config[box_kind == "minimal" and "vertical" or box_kind].size end

            local box, box_kind = get_box()
            local layout = Layout({
              relative = "editor",
              position = "50%",
              size = get_layout_size(box_kind),
            }, box)

            layout.picker = picker
            prepare_layout_parts(layout, box_kind)

            local layout_update = layout.update
            function layout:update()
              local box, box_kind = get_box()
              prepare_layout_parts(layout, box_kind)
              layout_update(self, { size = get_layout_size(box_kind) }, box)
            end

            return TSLayout(layout)
          end,
        }
      end

      -- https://github.com/nvim-telescope/telescope.nvim/wiki/Configuration-Recipes#fused-layout
      local function big_ivy(opts)
        opts = vim.tbl_deep_extend("force", opts or {}, {
          disable_devicons = true,
          -- layout_config = { height = 0.5 },
          layout_config = {
            height = 0.6,
            -- height = vim.o.lines, -- maximally available lines
            width = vim.o.columns, -- maximally available columns
          },
        })
        return require("telescope.themes").get_ivy(get_border(opts))
      end

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
              extensions("undo").undo(big_ivy(with_title(topts, { title = "undo" })))
            elseif key == "smart_open" or key == "smart" then
              -- FIXME: if we have a title in topts, use that title with the default title
              local title = "smartly find files"
              -- if topts.title ~= nil then title = fmt("smartly find files (%s)", topts.title) end
              extensions("smart_open").smart_open(with_title(topts, { title = title }))
            elseif key == "grep" or key == "live_grep" then
              extensions("live_grep_args").live_grep_args(with_title(topts, { title = "live grep args" }))
            elseif key == "corrode" then
              extensions("corrode").corrode(with_title(topts, { title = "find files (corrode)" }))
            -- elseif key == "multi_rg" then
            --   multi_rg(with_title(topts, { title = "multi_rg" }))
            elseif key == "find_files" or key == "fd" then
              -- extensions("corrode").corrode(with_title(topts, { title = "find files (corrode)" }))
              builtin[key](with_title(topts, { title = "find files" }))
            else
              if topts["theme"] ~= nil then
                builtin[key](topts)
              else
                builtin[key](ivy(topts))
              end
            end
          end
        end,
      })

      -- local grep = function(...) ts.live_grep(ivy(...)) end
      local function grep(opts)
        opts = vim.tbl_deep_extend("force", opts or {}, {})
        local picker = opts and opts["picker"] or "live_grep"
        local theme = opts and opts["theme"] or "ivy"
        local bufnr = vim.api.nvim_get_current_buf()
        local fn = vim.api.nvim_buf_get_name(bufnr)

        current_fn = fn
        -- opts.cwd = require("config.utils").get_root()
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
      mega.picker.grep = grep

      -- Gets the root dir from either:
      -- * connected lsp
      -- * .git from file
      -- * .git from cwd
      -- * cwd
      ---@param opts? table
      local function find_files(opts)
        opts = vim.tbl_deep_extend("force", opts or {}, {})
        local picker = opts and opts["picker"] or "find_files"
        local theme = opts and opts["theme"] or "ivy"
        local bufnr = vim.api.nvim_get_current_buf()
        local fn = vim.api.nvim_buf_get_name(bufnr)

        current_fn = fn
        -- opts.cwd = require("config.utils").get_root()
        -- vim.notify(fmt("current project files root: %s", opts.cwd), vim.log.levels.DEBUG, { title = "telescope" })
        -- local picker = ts["find_files"]

        if theme == "ivy" then
          ts[picker](ivy(opts))
        elseif theme == "dropdown" then
          ts[picker](dropdown(opts))
        elseif theme == "fuse" then
          ts[picker](fuse(opts))
        else
          ts[picker](opts)
        end
      end
      mega.picker.find_files = find_files

      local function flash(prompt_bufnr)
        require("flash").jump({
          pattern = "^",
          label = { after = { 0, 0 } },
          search = {
            mode = "search",
            exclude = {
              function(win) return vim.bo[vim.api.nvim_win_get_buf(win)].filetype ~= "TelescopeResults" end,
            },
          },
          action = function(match)
            local picker = require("telescope.actions.state").get_current_picker(prompt_bufnr)
            picker:set_selection(match.pos[1] - 1)
          end,
        })
      end

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
          color_devicons = false,
          disable_devicons = true,
          selection_strategy = "reset",
          scroll_strategy = "limit",
          sorting_strategy = "ascending",
          path_display = { "filename_first, truncate" },
          -- file_previewer = previewers.cat.new,
          -- grep_previewer = previewers.cat.new,
          -- qflist_previewer = previewers.cat.new,

          -- file_previewer = previewers.vim_buffer_cat.new,
          -- grep_previewer = previewers.vim_buffer_vimgrep.new,
          -- qflist_previewer = previewers.vim_buffer_qflist.new,
          layout_strategy = "horizontal",
          results_title = false,
          prompt_prefix = " ",
          selection_caret = " ",
          entry_prefix = "  ",
          multi_icon = "󰛄 ",
          winblend = 0,
          border = {
            --   prompt = { 0, 0, 0, 0 },
            --   results = { 0, 0, 0, 0 },
            --   preview = { 0, 0, 0, 0 },
            prompt = { 0, 1, 1, 1 },
            results = { 1, 1, 1, 1 },
            preview = { 1, 1, 1, 1 },
          },
          -- borderchars = {
          --   prompt = { " ", " ", "─", "│", "│", " ", "─", "└" },
          --   results = { "─", " ", " ", "│", "┌", "─", " ", "│" },
          --   preview = { "─", "│", "─", "│", "┬", "┐", "┘", "┴" },
          -- },
          borderchars = get_border().border_chars,
          vimgrep_arguments = grep_files_cmd,
          -- NOTE: https://github.com/bangalcat/nvim/blob/main/lua/plugins/telescope.lua#L61
          get_selection_window = function()
            local wins = vim.api.nvim_list_wins()
            table.insert(wins, 1, vim.api.nvim_get_current_win())
            for _, win in ipairs(wins) do
              local buf = vim.api.nvim_win_get_buf(win)
              if vim.bo[buf].buftype == "" then return win end
            end
            return 0
          end,
          layout_config = {
            prompt_position = "top",
          },
          mappings = {
            i = {
              ["<esc>"] = require("telescope.actions").close,
              -- ['<cr>'] = require('telescope.actions').select_vertical,
              ["<c-v>"] = stopinsert(function(pb) multi(pb, "vnew") end),
              ["<c-s>"] = stopinsert(function(pb) flash(pb) end),
              -- ["<c-s>"] = stopinsert(function(pb) multi(pb, "new") end),

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
              -- ["<tab>"] = actions.toggle_selection,
              ["<tab>"] = actions.toggle_selection + actions.move_selection_next,
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
          buffers = dropdown({
            mappings = {
              n = {
                ["d"] = require("telescope.actions").delete_buffer,
              },
            },
          }),
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
                ["<C-r>"] = actions.to_fuzzy_refine,
                -- ["<C-s>"] = actions.to_fuzzy_refine,
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
                      return vim
                        .iter({
                          require("telescope.config").values.vimgrep_arguments,
                          "--",
                          new_prompt,
                        })
                        :flatten()
                        :totable()
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
                    return vim
                      .iter({
                        require("telescope.config").values.vimgrep_arguments,
                        string.format("-g*.%s", result),
                        "--",
                        new_prompt,
                      })
                      :flatten()
                      :totable()
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
          undo = {
            use_delta = true,
            side_by_side = true,
            layout_strategy = "vertical",
            layout_config = {
              -- preview_height = 0.8,
              height = 0.6,
            },
            mappings = {
              i = {
                -- ["<cr>"] = undo_actions.yank_additions,
                -- ["<S-cr>"] = undo_actions.yank_deletions,
                -- ["<C-cr>"] = undo_actions.restore,
                ["<C-u>"] = undo_actions.restore,
                ["<C-y>"] = undo_actions.yank_additions,
                ["<C-d>"] = undo_actions.yank_deletions,
              },
              n = {
                ["y"] = undo_actions.yank_additions,
                ["d"] = undo_actions.yank_deletions,
                ["u"] = undo_actions.restore,
              },
            },
          },
          smart_open = {
            show_scores = false,
            ignore_patterns = { "*.git/*", "*/tmp/*", "." },
            match_algorithm = "fzf",
            disable_devicons = true,
            color_devicons = false,
            -- open_buffer_indicators = { previous = "👀", others = "🙈" },
            cwd_only = true,
            mappings = {
              i = {
                ["<cr>"] = stopinsert(function(pb) multi(pb, "vnew") end),
                ["<esc>"] = actions.close,
                ["<c-v>"] = stopinsert(function(pb) multi(pb, "vnew") end),
                ["<c-s>"] = stopinsert(function(pb) multi(pb, "new") end),
                ["<c-o>"] = stopinsert(function(pb) multi(pb, "edit") end),
                -- ["<tab>"] = actions.toggle_selection,
                ["<tab>"] = actions.toggle_selection + actions.move_selection_next,
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
                ["<esc>"] = actions.close,
                ["<c-v>"] = stopinsert(function(pb) multi(pb, "vnew") end),
                ["<c-s>"] = stopinsert(function(pb) multi(pb, "new") end),
                ["<c-o>"] = stopinsert(function(pb) multi(pb, "edit") end),
                ["<cr>"] = stopinsert(function(pb) multi(pb, "vnew") end),
                ["<tab>"] = actions.toggle_selection + actions.move_selection_next,
              },
              n = {
                ["<esc>"] = actions.close,
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
          egrepify = {
            -- intersect tokens in prompt ala "str1.*str2" that ONLY matches
            -- if str1 and str2 are consecutively in line with anything in between (wildcard)
            AND = true, -- default
            permutations = false, -- opt-in to imply AND & match all permutations of prompt tokens
            lnum = true, -- default, not required
            lnum_hl = "EgrepifyLnum", -- default, not required, links to `Constant`
            col = false, -- default, not required
            col_hl = "EgrepifyCol", -- default, not required, links to `Constant`
            title = true, -- default, not required, show filename as title rather than inline
            filename_hl = "EgrepifyFile", -- default, not required, links to `Title`
            results_ts_hl = true, -- set to true if you want results ts highlighting, may increase latency!
            -- suffix = long line, see screenshot
            -- EXAMPLE ON HOW TO ADD PREFIX!
            prefixes = {
              -- ADDED ! to invert matches
              -- example prompt: ! sorter
              -- matches all lines that do not comprise sorter
              -- rg --invert-match -- sorter
              ["!"] = {
                flag = "invert-match",
              },
              -- HOW TO OPT OUT OF PREFIX
              -- ^ is not a default prefix and safe example
              ["^"] = false,
            },
            -- default mappings
            mappings = {
              i = {
                -- toggle prefixes, prefixes is default
                ["<C-z>"] = egrep_actions.toggle_prefixes,
                -- toggle AND, AND is default, AND matches tokens and any chars in between
                ["<C-a>"] = egrep_actions.toggle_and,
                -- toggle permutations, permutations of tokens is opt-in
                ["<C-r>"] = egrep_actions.toggle_permutations,
              },
            },
          },
          git_worktree = {
            theme = "ivy", -- use dropdown theme
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

      -- keys
      if vim.g.picker == "telescope" then
        local builtin = require("telescope.builtin")
        map("n", "<leader>ff", function() mega.picker.find_files({ picker = "smart_open", theme = "ivy" }) end, "[f]ind [f]iles")
        map("n", "<leader>fh", ts.help_tags, { "[f]ind [h]elp" })
        map("n", "<leader>fa", ts.autocommands, { "[f]ind [a]utocommands" })
        map("n", "<leader>fk", ts.keymaps, { "[f]ind [k]eymaps" })
        -- map("n", "<leader>fs", ts.builtin, {  "[f]ind [f]elect Telescope" })
        -- map("n", "<leader>fg", ts.egrepify, {  "egrepify (live)" })
        map("n", "<leader>fg", function() mega.picker.grep({ picker = "egrepify" }) end, { "[f]ind e[g]repify" })

        -- vim.keymap.set('n', '<leader>fw', function ()
        --   egrepify(
        --     themes.get_ivy({ default_text = vim.fn.expand("<cword>") })
        --   )
        -- end, { desc = '[f]ind [w]ord under cursor'})
        -- vim.keymap.set('v', '<leader>fw', function ()
        --   egrepify(
        --     themes.get_ivy({
        --       default_text = get_visual_selection(),
        --       layout_config = {
        --         height = 30,
        --       },
        --     })
        --   )
        -- end, { desc = '[f]ind select [w]ord'})

        -- vim.keymap.set("n", "<leader>fl", function()
        --   egrepify(themes.get_ivy({
        --     layout_config = {
        --       height = 30,
        --     }
        --   }))
        -- end)

        -- map("n", "<leader>fg", ts.multi_rg, {  "multi-rg (live)" })
        map("n", "<leader>a", mega.picker.grep, { "grep (live)" })
        -- map("n", "<leader>A", ts.grep_string, {  "grep (under cursor)" })
        map("n", "<leader>A", function() mega.picker.grep({ default_text = vim.fn.expand("<cword>") }) end, { "grep (under cursor)" })
        map({ "v", "x" }, "<leader>A", function()
          local pattern = require("config.utils").get_visual_selection()
          mega.picker.grep({ default_text = pattern })
        end, { "grep (selection)" })

        map("n", "<leader>fu", ts.undo, { "[f]ind [u]ndo" })
        -- map("n", "<leader>fd", ts.diagnostics, {  "[f]ind [d]iagnostics" })
        map("n", "<leader>fd", function() mega.picker.find_files({ picker = "smart_open", cwd = vim.g.dotfiles_path }) end, { "[f]ind in [d]otfiles" })
        map("n", "<leader>fc", function() mega.picker.find_files({ picker = "smart_open", cwd = vim.fn.stdpath("config") }) end, { "[f]ind in [c]onfig" })
        map(
          "n",
          "<leader>fp",
          function() mega.picker.find_files({ picker = "smart_open", cwd = vim.fn.expand(vim.g.code_path), title = "in ~/code" }) end,
          { "[f]ind in ~/code [p]rojects" }
        )
        map("n", "<leader>fr", ts.resume, { "[f]ind [r]esume" })
        map("n", "<leader>f.", ts.oldfiles, { "[f]ind recent files" })
        map("n", "gb", function() ts.buffers({ theme = "dropdown", sort_mru = true, ignore_current_buffer = true }) end, { "find existing buffers" })
        map("n", ",,", function() ts.buffers({ theme = "dropdown", sort_mru = true, ignore_current_buffer = true }) end, { "find existing buffers" })

        -- Slightly advanced example of overriding default behavior and theme
        map("n", "<leader>/", function()
          -- You can pass additional configuration to Telescope to change the theme, layout, etc.
          builtin.current_buffer_fuzzy_find(require("telescope.themes").get_dropdown({
            winblend = 10,
            previewer = false,
          }))
        end, { "[/] Fuzzily search in current buffer" })
        map("n", "<leader>fn", function() mega.picker.find_files({ picker = "smart_open", cwd = vim.g.notes_path }) end, { "[f]ind in [n]otes" })
        map("n", "<leader>nf", function() mega.picker.find_files({ picker = "smart_open", cwd = vim.g.notes_path }) end, { "[f]ind in [n]otes" })

        -- Shortcut for searching your Neovim configuration files
      end
    end,
  },
}

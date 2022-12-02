-- REF:
-- - https://github.com/fdschmidt93/dotfiles/blob/master/nvim/.config/nvim/lua/fds/plugins/telescope/init.lua
return function()
  local telescope = require("telescope")

  local function setup_custom_actions(actions, builtin)
    local transform_mod = require("telescope.actions.mt").transform_mod
    return transform_mod({
      jump_to_symbol = function(prompt_bufnr)
        actions.file_edit(prompt_bufnr)
        local valid_clients = #vim.tbl_filter(
          function(client) return client.server_capabilities.documentSymbolProvider end,
          vim.lsp.get_active_clients()
        ) > 0
        if valid_clients and vim.lsp.buf.server_ready() then return builtin.lsp_document_symbols() end
        return builtin.current_buffer_tags()
      end,
      jump_to_line = function(prompt_bufnr)
        actions.file_edit(prompt_bufnr)
        vim.defer_fn(function() vim.api.nvim_feedkeys(":", "n", true) end, 100)
      end,
    })
  end

  local builtin = require("telescope.builtin")
  local actions = require("telescope.actions")
  local previewers = require("telescope.previewers")
  local lga_actions = require("telescope-live-grep-args.actions")
  local themes = require("telescope.themes")
  local action_state = require("telescope.actions.state")
  local custom_actions = setup_custom_actions(actions, builtin)

  local fd_find_command = { "fd", "--type", "f", "--no-ignore-vcs", "--strip-cwd-prefix" }
  local rg_find_command = {
    "rg",
    "--files",
    "--no-ignore-vcs",
    "--hidden",
    "--no-heading",
    "--with-filename",
    "--column",
    "--smart-case",
    -- "--ignore-file",
    -- (Path.join(vim.env.HOME, ".dotfiles", "misc", "tool-ignores")),
    "--iglob",
    "!.git",
  }

  local find_files_cmd = rg_find_command
  local grep_files_cmd = {
    "rg",
    "--hidden",
    "--no-ignore-vcs",
    "--no-heading",
    "--with-filename",
    "--line-number",
    "--column",
    "--smart-case",
  }

  mega.augroup("TelescopePreviews", {
    {
      event = { "User" },
      pattern = { "TelescopePreviewerLoaded" },
      command = "setlocal number wrap numberwidth=5 norelativenumber",
    },
  })

  local function get_border(opts)
    return vim.tbl_deep_extend("force", opts or {}, {
      borderchars = {
        { " ", " ", " ", " ", " ", " ", " ", " " },
        prompt = { " ", " ", " ", " ", " ", " ", " ", " " },
        results = { " ", " ", " ", " ", " ", " ", " ", " " },
        preview = { " ", " ", " ", " ", " ", " ", " ", " " },
        -- prompt = { "─", "│", " ", "│", "┌", "┐", "│", "│" },
        -- results = { "─", "│", "─", "│", "├", "┤", "┘", "└" },
        -- preview = { "─", "│", "─", "│", "┌", "┐", "┘", "└" },
      },
    })
  end

  -- TODO: support multiple file opens
  -- https://github.com/b0o/nvim-conf/blob/8abde1b6a1e728747af165f813308e4dea24a76f/lua/user/plugin/telescope.lua
  -- https://github.com/nvim-telescope/telescope.nvim/issues/1048#issuecomment-1225975038

  -- Based on https://github.com/nvim-telescope/telescope.nvim/issues/1048#issuecomment-1225975038
  local function multiopen(method)
    return function(prompt_bufnr)
      local edit_file_cmd_map = {
        vertical = "vsplit",
        horizontal = "split",
        tab = "tabedit",
        default = "edit",
      }
      local edit_buf_cmd_map = {
        vertical = "vert sbuffer",
        horizontal = "sbuffer",
        tab = "tab sbuffer",
        default = "buffer",
      }
      local picker = action_state.get_current_picker(prompt_bufnr)
      local multi_selection = picker:get_multi_selection()

      if #multi_selection > 1 then
        require("telescope.pickers").on_close_prompt(prompt_bufnr)
        pcall(vim.api.nvim_set_current_win, picker.original_win_id)

        for i, entry in ipairs(multi_selection) do
          local filename, row, col

          if entry.path or entry.filename then
            filename = entry.path or entry.filename

            row = entry.row or entry.lnum
            col = vim.F.if_nil(entry.col, 1)
          elseif not entry.bufnr then
            local value = entry.value
            if not value then return end

            if type(value) == "table" then value = entry.display end

            local sections = vim.split(value, ":")

            filename = sections[1]
            row = tonumber(sections[2])
            col = tonumber(sections[3])
          end

          local entry_bufnr = entry.bufnr

          if entry_bufnr then
            if not vim.api.nvim_buf_get_option(entry_bufnr, "buflisted") then
              vim.api.nvim_buf_set_option(entry_bufnr, "buflisted", true)
            end
            local command = i == 1 and "buffer" or edit_buf_cmd_map[method]
            pcall(vim.cmd, string.format("%s %s", command, vim.api.nvim_buf_get_name(entry_bufnr)))
          else
            local command = i == 1 and "edit" or edit_file_cmd_map[method]
            if vim.api.nvim_buf_get_name(0) ~= filename or command ~= "edit" then
              filename = require("plenary.path"):new(vim.fn.fnameescape(filename)):normalize(vim.loop.cwd())
              pcall(vim.cmd, string.format("%s %s", command, filename))
            end
          end

          if row and col then pcall(vim.api.nvim_win_set_cursor, 0, { row, col - 1 }) end
        end
      else
        actions["select_" .. method](prompt_bufnr)
      end
    end
  end

  local conditional_buffer_preview = function(filepath, bufnr, opts)
    opts = opts or {}
    local max_filesize = 50 * 1024

    filepath = vim.fn.expand(filepath)
    vim.loop.fs_stat(filepath, function(_, stat)
      if not stat then return end
      if stat.size > max_filesize then
        return
      else
        previewers.buffer_previewer_maker(filepath, bufnr, opts)
      end
    end)
  end

  ---@param opts table
  ---@return table
  local function dropdown(opts) return themes.get_dropdown(get_border(opts)) end

  local function ivy(opts) return themes.get_ivy(get_border(opts)) end

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

  local function stopinsert(callback)
    return function(prompt_bufnr)
      vim.cmd.stopinsert()
      -- callback(prompt_bufnr)
      vim.schedule(function() callback(prompt_bufnr) end)
    end
  end

  telescope.setup({
    defaults = {
      set_env = { ["TERM"] = vim.env.TERM, ["COLORTERM"] = "truecolor" },
      border = {},
      borderchars = { " ", " ", " ", " ", " ", " ", " ", " " },
      -- borderchars = { "─", "│", "─", "│", "┌", "┐", "┘", "└" },
      winblend = 0,
      prompt_prefix = "  ",
      selection_caret = "» ", -- ❯
      cycle_layout_list = { "flex", "horizontal", "vertical", "bottom_pane", "center" },
      mappings = {
        i = {
          ["<c-q>"] = actions.send_selected_to_qflist,
          -- ["<c-l>"] = actions.send_to_qflist,
          ["<c-c>"] = function() vim.cmd.stopinsert() end,
          ["<esc>"] = actions.close,
          -- ["<cr>"] = actions.select_vertical,
          ["<CR>"] = stopinsert(multiopen("vertical")),
          ["<c-o>"] = stopinsert(multiopen("default")),
          ["<c-s>"] = stopinsert(multiopen("horizontal")),
          ["<c-b>"] = actions.preview_scrolling_up,
          ["<c-f>"] = actions.preview_scrolling_down,
          ["<c-u>"] = actions.preview_scrolling_up, -- alts: ["<c-u>"] = false
          ["<c-d>"] = actions.preview_scrolling_down,
          -- ["<c-e>"] = layout_actions.toggle_preview,
          ["<c-/>"] = actions.which_key,
          ["<Tab>"] = actions.toggle_selection,
          ["<C-s>"] = custom_actions.jump_to_symbol,
          ["<C-l>"] = custom_actions.jump_to_line,
        },
        n = {
          ["<c-q>"] = actions.send_selected_to_qflist,
          ["<c-l>"] = actions.send_to_qflist,
          ["<C-c>"] = actions.close,
        },
      },
      file_ignore_patterns = {
        -- "%.png",
        -- "%.jpg",
        -- "%.jpeg",
        -- "%.gif",
        "%.webp",
        "%.otf",
        "%.ttf",
        vim.g.is_remote_dev and "^apps/pages/fixture/vcr_cassettes/*.json" or "",
      },
      -- :help telescope.defaults.path_display
      path_display = { "absolute", "truncate" },
      layout_strategy = "flex",
      layout_config = {
        width = 0.65,
        height = 0.6,
        horizontal = {
          preview_width = 0.45,
        },
        cursor = { -- FIXME: this does not change the size of the cursor layout
          width = 0.4,
          height = function(self, _, max_lines) -- was 0.5
            local results = #self.finder.results
            return (results <= max_lines and results or max_lines - 10) + 4
          end,
        },
        bottom_pane = {
          height = 0.5,
          preview_cutoff = 120,
          preview_width = 0.65,
          prompt_position = "top",
        },
      },
      dynamic_preview_title = true,
      results_title = false,
      selection_strategy = "reset",
      sorting_strategy = "descending",
      use_less = true,
      color_devicons = false,
      -- file_previewer = previewers.cat.new,
      -- grep_previewer = previewers.cat.new,
      -- qflist_previewer = previewers.cat.new,
      buffer_preview_maker = conditional_buffer_preview,
      preview = {
        treesitter = {
          enable = true,
          -- disable = { "heex", "svg", "json", "json5", "jsonc" },
        },
        mime_hook = function(filepath, bufnr, opts)
          local is_image = function(filepath)
            local image_extensions = { "png", "jpg", "jpeg", "gif" } -- Supported image formats
            local split_path = vim.split(filepath:lower(), ".", { plain = true })
            local extension = split_path[#split_path]
            return vim.tbl_contains(image_extensions, extension)
          end
          if is_image(filepath) then
            local term = vim.api.nvim_open_term(bufnr, {})
            local function send_output(_, data, _)
              for _, d in ipairs(data) do
                vim.api.nvim_chan_send(term, d .. "\r\n")
              end
            end

            vim.fn.jobstart({
              "viu",
              "-w",
              "40",
              "-b",
              filepath,
            }, {
              on_stdout = send_output,
              stdout_buffered = true,
            })
          else
            require("telescope.previewers.utils").set_preview_message(bufnr, opts.winid, "Binary cannot be previewed")
          end
        end,
      },
      vimgrep_arguments = grep_files_cmd,
    },
    extensions = {
      live_grep_args = {
        auto_quoting = true, -- enable/disable auto-quoting
        mappings = {
          i = {
            ["<c-y>"] = lga_actions.quote_prompt({ postfix = " -t" }),
            -- ["<c-q>"] = lga_actions.quote_prompt(),
            -- ["<c-l>g"] = lga_actions.quote_prompt({ postfix = " --iglob " }),
            -- ["<c-l>t"] = lga_actions.quote_prompt({ postfix = " -t" }),
            -- ["<c-l>n"] = lga_actions.quote_prompt({ postfix = " --no-ignore " }),
          },
        },
      },
    },
    pickers = {
      buffers = dropdown({
        sort_mru = true,
        sort_lastused = true,
        show_all_buffers = true,
        ignore_current_buffer = true,
        previewer = false,
        theme = "dropdown",
        mappings = {
          i = { ["<c-x>"] = "delete_buffer" },
          n = { ["<c-x>"] = "delete_buffer" },
        },
      }),
      oldfiles = dropdown({
        on_input_filter_cb = file_extension_filter,
      }),
      grep_string = ivy({
        -- only sort top 50 entries
        temp__scrolling_limit = 50,
      }),
      live_grep = ivy({
        max_results = 500,
        file_ignore_patterns = { ".git/", "%.lock" },
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
      current_buffer_fuzzy_find = dropdown({
        previewer = false,
        shorten_path = false,
      }),
      lsp_code_actions = {
        theme = "cursor",
      },
      colorscheme = {
        enable_preview = true,
      },
      find_files = {
        hidden = true,
        find_command = find_files_cmd,
        on_input_filter_cb = file_extension_filter,
        -- on_input_filter_cb = function(prompt)
        --   if prompt:sub(#prompt) == "@" then
        --     vim.schedule(function()
        --       local prompt_bufnr = vim.api.nvim_get_current_buf()
        --       actions.select_default(prompt_bufnr)
        --       require("telescope.builtin").current_buffer_fuzzy_find()
        --       -- properly enter prompt in insert mode
        --       vim.cmd([[normal! A]])
        --     end)
        --   else
        --     local find_colon = string.find(prompt, ":")
        --     if find_colon then
        --       local ret = string.sub(prompt, 1, find_colon - 1)
        --       vim.schedule(function()
        --         local prompt_bufnr = vim.api.nvim_get_current_buf()
        --         local picker = action_state.get_current_picker(prompt_bufnr)
        --         local lnum = tonumber(prompt:sub(find_colon + 1))
        --         if type(lnum) == "number" then
        --           local win = picker.previewer.state.winid
        --           local bufnr = picker.previewer.state.bufnr
        --           local line_count = vim.api.nvim_buf_line_count(bufnr)
        --           vim.api.nvim_win_set_cursor(win, { math.max(1, math.min(lnum, line_count)), 0 })
        --         end
        --       end)
        --       return { prompt = ret }
        --     end
        --   end
        -- end,
        -- attach_mappings = function()
        --   actions.select_default:enhance({
        --     post = function()
        --       -- if we found something, go to line
        --       local prompt = action_state.get_current_line()
        --       local find_colon = string.find(prompt, ":")
        --       if find_colon then
        --         local lnum = tonumber(prompt:sub(find_colon + 1))
        --         vim.api.nvim_win_set_cursor(0, { lnum, 0 })
        --       end
        --     end,
        --   })
        --   return true
        -- end,
      },
      keymaps = dropdown({
        layout_config = {
          height = 18,
          width = 0.5,
        },
      }),
      git_branches = dropdown({}),
      git_bcommits = {
        layout_config = {
          horizontal = {
            preview_width = 0.55,
          },
        },
      },
      git_commits = {
        layout_config = {
          horizontal = {
            preview_width = 0.55,
          },
        },
      },
      reloader = dropdown({}),
      file_browser = {
        theme = "ivy",
        -- disables netrw and use telescope-file-browser in its place
        hijack_netrw = true,
        mappings = {
          ["i"] = {},
          ["n"] = {},
        },
      },
    },
  })

  --- NOTE: this must be required after setting up telescope
  --- otherwise the result will be cached without the updates
  --- from the setup call
  local builtin = require("telescope.builtin")

  local function builtins() builtin.builtin({ include_extensions = true }) end

  local function delta_opts(opts, is_buf)
    local previewers = require("telescope.previewers")
    local delta = previewers.new_termopen_previewer({
      get_command = function(entry)
        local args = {
          "git",
          "-c",
          "core.pager=delta",
          "-c",
          "delta.side-by-side=false",
          "diff",
          entry.value .. "^!",
        }
        if is_buf then vim.list_extend(args, { "--", entry.current_file }) end
        return args
      end,
    })
    opts = opts or {}
    opts.previewer = {
      delta,
      previewers.git_commit_message.new(opts),
    }
    return opts
  end

  local function delta_git_commits(opts) builtin.git_commits(delta_opts(opts)) end

  local function delta_git_bcommits(opts) builtin.git_bcommits(delta_opts(opts, true)) end

  local function project_files(opts)
    -- if not pcall(builtin.git_files, opts) then
    --   builtin.find_files(opts)
    -- end
    builtin.find_files(ivy(opts))
  end

  local function dotfiles()
    builtin.find_files({
      prompt_title = "~ dotfiles ~",
      cwd = mega.dirs.dots,
      file_ignore_patterns = {
        ".git/.*",
        "dotbot/.*",
        "config/zsh/plugins/.*",
      },
    })
  end

  local function zmk_config()
    builtin.find_files({
      prompt_title = "~ zmk-config ~",
      cwd = vim.fn.expand("~/code/zmk-config"),
    })
  end

  local function qmk_config()
    builtin.find_files({
      prompt_title = "~ qmk-config ~",
      cwd = vim.fn.expand("~/code/megalithic_qmk/keyboards/atreus62/keymaps/megalithic/"),
    })
  end

  local function privates()
    builtin.find_files({
      prompt_title = "~ privates ~",
      cwd = mega.dirs.privates,
    })
  end

  local function luasnips() require("telescope").extensions.luasnip.luasnip(dropdown({})) end
  local function workspaces()
    require("telescope").extensions.workspaces.workspaces(dropdown({
      mappings = {
        i = {
          -- FIXME: this is not working as expected
          ["<CR>"] = actions.select_default,
        },
      },
    }))
  end
  -- local function live_grep_args(opts) telescope.extensions.live_grep_args.live_grep_args(ivy(opts)) end
  local function installed_plugins()
    builtins.find_files({
      prompt_title = "Installed plugins",
      cwd = vim.fn.stdpath("data") .. "/site/pack/packer",
    })
  end

  -- telescope-mappings
  nmap("<leader>fB", builtins, "builtins")
  nmap("<leader>fb", builtin.buffers, "opened buffers")
  -- nmap("<leader>fb", builtin.current_buffer_fuzzy_find, "fuzzy find current buffer")
  nmap("<leader>fd", dotfiles, "dotfiles")
  nmap("<leader>fp", privates, "privates")
  nmap("<leader>fz", zmk_config, "zmk-config")
  nmap("<leader>fq", qmk_config, "qmk-config")
  nmap("<leader>ff", project_files, "find/git files")

  nmap("<leader>fgc", delta_git_commits, "commits")
  nmap("<leader>fgC", delta_git_bcommits, "buffer commits")
  nmap("<leader>fgb", builtin.git_branches, "branches")

  nmap("<leader>fL", luasnips, "luasnip: available snippets")
  nmap("<leader>fM", builtin.man_pages, "man pages")
  nmap("<leader>fm", builtin.oldfiles, "oldfiles (mru)")
  nmap("<leader>fk", builtin.keymaps, "keymaps")
  nmap("<leader>fP", installed_plugins, "installed plugins")
  -- nmap("<leader>fo", builtin.buffers, "opened buffers")
  nmap("<leader>fr", builtin.resume, "resume last picker")
  nmap("<leader>fs", builtin.live_grep, "live grep string")
  -- nmap("<leader>fa", builtin.live_grep, "live grep string")
  -- nmap("<leader>fa", "<cmd>lua require('telescope').extensions.live_grep_args.live_grep_args()<CR>", "live grep args")
  nmap("<leader>fw", workspaces, "open workspaces")

  nmap("<leader>fvh", builtin.highlights, "highlights")
  nmap("<leader>fva", builtin.autocommands, "autoccommands")
  nmap("<leader>fvo", builtin.vim_options, "options")
  nmap("<leader>f?", builtin.help_tags, "help")
  nmap("<leader>fh", builtin.help_tags, "help")

  nmap("<leader>lD", builtin.diagnostics, "telescope: diagnostics")
  nmap("<leader>ld", builtin.lsp_definitions, "telescope: definitions")
  nmap("<leader>ltd", builtin.lsp_type_definitions, "telescope: type definitions")
  nmap("<leader>lr", builtin.lsp_references, "telescope: references")
  -- nmap("<leader>li", builtin.lsp_implementations, "telescope: implementations")
  nmap("<leader>ls", builtin.lsp_document_symbols, "telescope: document symbols")
  nmap("<leader>lS", builtin.lsp_workspace_symbols, "telescope: workspace symbols")
  nmap("<leader>lw", builtin.lsp_dynamic_workspace_symbols, "telescope: dynamic workspace symbols")

  nmap("<leader>a", builtin.live_grep, "live grep")
  nmap("<leader>A", builtin.grep_string, "grep under cursor")
  -- nmap("<leader>a", live_grep_args, "live grep args")
  -- nmap("<leader>a", "<cmd>lua require('telescope.builtin').live_grep()<cr>", "live grep for a word")
  nmap("<leader>A", [[<cmd>lua require('telescope.builtin').grep_string()<cr>]], "grep for word under cursor")
  vmap(
    "<leader>A",
    [[y:lua require("telescope.builtin").grep_string({ search = '<c-r>"' })<cr>]],
    "grep for visual selection"
  )
end

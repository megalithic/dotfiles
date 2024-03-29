-- TODO:
-- https://github.com/seblj/dotfiles/blob/master/nvim/lua/config/telescope.lua#L143
-- investigate MRU:  https://github.com/yutkat/dotfiles/blob/main/.config/nvim/lua/rc/pluginconfig/telescope.lua#LL241C1-L344C4

local keys = {}

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
      if key == "grepify" then
        require("telescope").extensions.egrepify.egrepify(with_title(topts, { title = "egrepify" }))
      elseif key == "undo" then
        require("telescope").extensions.undo.undo(topts)
      elseif key == "grep" then
        require("telescope").extensions.live_grep_args.live_grep_args(with_title(topts, { title = "live grep args" }))
      elseif key == "fd" then
        require("telescope").extensions.corrode.corrode(with_title(topts, { title = "find files" }))
      elseif key == "find_files" then
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
  "--trim",
}
local current_fn = nil

local function dropdown(opts)
  opts = vim.tbl_deep_extend("force", opts or {}, {})
  return require("telescope.themes").get_dropdown(get_border(opts))
end

local function ivy(opts)
  opts = vim.tbl_deep_extend("force", opts or {}, { layout_config = { height = 0.3 } })
  return require("telescope.themes").get_ivy(get_border(opts))
end
-- Gets the root dir from either:
-- * connected lsp
-- * .git from file
-- * .git from cwd
-- * cwd
---@param opts? table
local function find_files(opts)
  opts = opts or {}
  local theme = opts["theme"] or "ivy"
  local bufnr = vim.api.nvim_get_current_buf()
  local fn = vim.api.nvim_buf_get_name(bufnr)
  current_fn = fn
  -- opts.cwd = require("mega.utils").get_root()
  -- vim.notify(fmt("current project files root: %s", opts.cwd), vim.log.levels.DEBUG, { title = "telescope" })
  if theme == "ivy" then
    ts.find_files(ivy(opts))
  elseif theme == "dropdown" then
    ts.find_files(dropdown(opts))
  else
    ts.find_files(opts)
  end
  -- require("telescope").extensions.smart_open.smart_open(ivy(opts))
end

local function stopinsert(callback)
  return function(prompt_bufnr)
    vim.cmd.stopinsert()
    vim.schedule(function() callback(prompt_bufnr) end)
  end
end

-- REF: https://github.com/nvim-telescope/telescope.nvim/issues/416
local function multi(pb, verb, open_selection_under_cursor)
  open_selection_under_cursor = open_selection_under_cursor or false
  local methods = {
    ["vnew"] = "select_vertical",
    ["new"] = "select_horizontal",
    ["edit"] = "select_default",
  }
  local select_action = methods[verb]
  local actions = require("telescope.actions")
  local action_state = require("telescope.actions.state")
  local picker = action_state.get_current_picker(pb)
  local selections = picker:get_multi_selection()
  local num_selections = #selections

  -- NOTE: optionally send to qf:
  -- https://github.com/olimorris/dotfiles/blob/main/.config/nvim/lua/Oli/plugins/telescope.lua#L103-L121
  if open_selection_under_cursor or current_fn == nil or num_selections == 0 then
    actions[select_action](pb)
  else
    if current_fn ~= nil then -- is it a file -> open it as well:
      vim.cmd(string.format("%s %s", "edit!", current_fn))
      current_fn = nil
    end
  end

  for _, p in pairs(selections) do
    if p.path ~= nil then -- is it a file -> open it as well:
      vim.cmd(string.format("%s %s", verb, p.path))
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

local function extensions(name) return require("telescope").extensions[name] end

if vim.g.picker == "telescope" then
  mega.augroup("Telescope", {
    {
      -- HACK color parent as comment
      -- CAVEAT interferes with other Telescope Results that display for spaces
      event = { "FileType" },
      pattern = "TelescopeResults",
      command = function()
        vim.fn.matchadd("TelescopeParent", "\t\t.*$")
        vim.api.nvim_set_hl(0, "TelescopeParent", { link = "Comment" })
      end,
    },
  })
  local has_wk, wk = mega.require("which-key")
  if has_wk then
    wk.register({
      f = {
        name = "telescope",
        g = {
          name = "git",
        },
        l = {
          name = "lsp",
        },
      },
    }, {
      prefix = "<leader>",
    })
  end

  mega.find_files = find_files
  mega.grep = function(...) ts.grep(ivy(...)) end

  keys = {
    { "<leader>ff", mega.find_files, desc = "find files" },
    {
      "<leader>a",
      mega.grep,
      desc = "live grep",
    },
    {
      "<leader>U",
      function() ts.undo(ivy({})) end,
      desc = "undo",
    },
    {
      "<leader>fh",
      function() ts.help_tags(ivy({})) end,
      desc = "help",
    },
    {
      "<leader>A",
      function() mega.grep({ default_text = vim.fn.expand("<cword>") }) end,
      desc = "grep under cursor",
    },
    {
      "<leader>A",
      function()
        local pattern = require("mega.utils").get_visual_selection()
        mega.grep({ default_text = pattern })
      end,
      desc = "grep visual selection",
      mode = "v",
    },
    {
      "<leader>fb",
      function() ts.buffers(dropdown({})) end,
      desc = "find open buffers",
    },
    {
      "<leader>fn",
      function() mega.find_files({ path = vim.g.notes_path }) end,
      desc = "browse: notes",
    },
  }

  _G.picker = {
    telescope = {
      find_files = mega.find_files,
      grep = mega.grep,
      dropdown = dropdown,
      -- TODO: add impl
      cursor_dropdown = dropdown,
      ivy = ivy,
      border = get_border,
      startup = function(args)
        local arg = vim.api.nvim_eval("argv(0)")
        if
          not vim.g.started_by_firenvim
          and (not vim.env.TMUX_POPUP and vim.env.TMUX_POPUP ~= 1)
          and not vim.tbl_contains({ "NeogitStatus" }, vim.bo[args.buf].filetype)
          and (arg and (vim.fn.isdirectory(arg) == 0 and arg == ""))
        then
          mega.augroup("TelescopeStartup", {
            event = { "BufEnter" },
            command = function(args) dd(args) end,
          })
          -- Open file browser if argument is a folder
          -- REF: https://github.com/protiumx/.dotfiles/blob/main/stow/nvim/.config/nvim/lua/config/telescope.lua#L50
          find_files({
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
                  dd("i -cr'ing")
                  multi(pb, "edit")
                  vim.api.nvim_buf_delete(1, { force = true })
                end),
              },
              n = {
                ["<cr>"] = function(pb)
                  dd("n -cr'ing")
                  multi(pb, "vnew")
                  vim.api.nvim_buf_delete(args.buf + 1, { force = true })
                end,
              },
            },
          })
        end
      end,
    },
  }
end

return {
  "nvim-telescope/telescope.nvim",
  cmd = { "Telescope" },
  dependencies = {
    "natecraddock/telescope-zf-native.nvim",
    { "nvim-telescope/telescope-fzf-native.nvim", build = "make" },

    "nvim-telescope/telescope-file-browser.nvim",
    "fdschmidt93/telescope-egrepify.nvim",
    "megalithic/telescope-corrode.nvim",
    -- {
    --   "danielfalk/smart-open.nvim",
    --   dependencies = { "kkharji/sqlite.lua", { "nvim-telescope/telescope-fzf-native.nvim", build = "make" } },
    -- },

    -- "danielvolchek/tailiscope.nvim"
    "nvim-telescope/telescope-live-grep-args.nvim",
    "debugloop/telescope-undo.nvim",
    "folke/trouble.nvim",
  },
  keys = keys,
  config = function()
    mega.augroup("TelescopePreviews", {
      {
        event = { "User" },
        pattern = { "TelescopePreviewerLoaded" },
        command = "setlocal number wrap numberwidth=5 norelativenumber",
      },
    })

    local telescope = require("telescope")
    local transform_mod = require("telescope.actions.mt").transform_mod
    local actions = require("telescope.actions")
    local lga_actions = require("telescope-live-grep-args.actions")
    local action_state = require("telescope.actions.state")

    telescope.setup({
      defaults = {
        dynamic_preview_title = true,
        -- selection_strategy = "reset",
        -- use_less = true,
        color_devicons = true,
        file_previewer = require("telescope.previewers").vim_buffer_cat.new,
        grep_previewer = require("telescope.previewers").vim_buffer_vimgrep.new,
        qflist_previewer = require("telescope.previewers").vim_buffer_qflist.new,
        layout_strategy = "horizontal",
        layout_config = {
          prompt_position = "top",
        },
        sorting_strategy = "ascending",
        mappings = {
          i = {
            ["<esc>"] = require("telescope.actions").close,
            ["<c-v>"] = stopinsert(function(pb) multi(pb, "vnew") end),
            ["<c-s>"] = stopinsert(function(pb) multi(pb, "new") end),
            ["<c-o>"] = stopinsert(function(pb) multi(pb, "edit") end),
            ["<c-z>"] = actions.toggle_selection,
            ["<c-r>"] = actions.to_fuzzy_refine,
            ["<c-n>"] = actions.move_selection_next,
            ["<c-p>"] = actions.move_selection_previous,
            ["<c-t>"] = require("trouble.sources.telescope").open,
            ["<c-down>"] = function(...) return actions.cycle_history_next(...) end,
            ["<c-up>"] = function(...) return actions.cycle_history_prev(...) end,
            ["<c-q>"] = actions.smart_send_to_qflist + actions.open_qflist,
            ["<c-a>"] = { "<Home>", type = "command" },
            ["<c-e>"] = { "<End>", type = "command" },
          },
          n = {
            ["<cr>"] = function(pb) multi(pb, "vnew") end,
            ["<c-v>"] = function(pb) multi(pb, "vnew") end,
            ["<c-s>"] = function(pb) multi(pb, "new") end,
            ["<c-o>"] = function(pb) multi(pb, "edit") end,
          },
        },
        -- path_display = function(_, path)
        --   local filename = path:gsub(vim.pesc(vim.loop.cwd()) .. "/", ""):gsub(vim.pesc(vim.fn.expand("$HOME")), "~")
        --   local tail = require("telescope.utils").path_tail(filename)
        --   local folder = vim.fn.fnamemodify(filename, ":h")
        --   if folder == "." then return tail end
        --
        --   return string.format("%s  —  %s", tail, folder)
        -- end,
        results_title = false,
        prompt_prefix = " ",
        selection_caret = " ",
        entry_prefix = "  ",
        multi_icon = "󰛄 ",
        winblend = 0,
        vimgrep_arguments = grep_files_cmd,
      },
      file_ignore_patterns = {
        ".git/",
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
        "node_modules",
        "dotbot",
      },
      extensions = {
        fzf = {
          fuzzy = true,
          override_generic_sorter = true,
          override_file_sorter = true,
          case_mode = "smart_case",
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
        -- TODO: using fzf-native while using smart_open..
        -- ["zf-native"] = {
        --   file = {
        --     enable = true,
        --     highlight_results = true,
        --     match_filename = true,
        --   },
        --   generic = {
        --     enable = true,
        --     highlight_results = true,
        --     match_filename = false,
        --   },
        -- },
        -- FIXME: multi doesn't work, nor my preferred select mappings
        -- smart_open = {
        --   show_scores = true,
        --   match_algorithm = "fzf",
        --   disable_devicons = false,
        --   cwd_only = true,
        --   max_unindexed = 50000,
        --   ignore_patterns = {
        --     "*.git/*",
        --     "*/tmp/",
        --     "*/vendor/",
        --     "*/dist/*",
        --     "*/declarations/*",
        --     "*/node_modules/*",
        --   },
        --   mappings = {
        --     i = {
        --       ["<esc>"] = require("telescope.actions").close,
        --       ["<cr>"] = stopinsert(function(pb) multi(pb, "vnew") end),
        --       ["<c-v>"] = stopinsert(function(pb) multi(pb, "vnew") end),
        --       ["<c-s>"] = stopinsert(function(pb) multi(pb, "new") end),
        --       ["<c-o>"] = stopinsert(function(pb) multi(pb, "edit") end),
        --     },
        --     n = {
        --       ["<cr>"] = function(pb) multi(pb, "vnew") end,
        --       ["<c-v>"] = function(pb) multi(pb, "vnew") end,
        --       ["<c-s>"] = function(pb) multi(pb, "new") end,
        --       ["<c-o>"] = function(pb) multi(pb, "edit") end,
        --     },
        --   },
        -- },
        corrode = {
          fd_cmd = find_files_cmd,
          rg_cmd = grep_files_cmd,
          AND = true,
          mappings = {
            i = {
              ["<cr>"] = stopinsert(function(pb) multi(pb, "vnew") end),
              ["<esc>"] = require("telescope.actions").close,
              ["<c-v>"] = stopinsert(function(pb) multi(pb, "vnew") end),
              ["<c-s>"] = stopinsert(function(pb) multi(pb, "new") end),
              ["<c-o>"] = stopinsert(function(pb) multi(pb, "edit") end),
              ["<c-z>"] = actions.toggle_selection,
              ["<c-r>"] = actions.to_fuzzy_refine,
              ["<c-n>"] = actions.move_selection_next,
              ["<c-p>"] = actions.move_selection_previous,
              ["<c-t>"] = require("trouble.sources.telescope").open,
              ["<c-down>"] = function(...) return actions.cycle_history_next(...) end,
              ["<c-up>"] = function(...) return actions.cycle_history_prev(...) end,
              ["<c-q>"] = actions.smart_send_to_qflist + actions.open_qflist,
              ["<c-a>"] = { "<Home>", type = "command" },
              ["<c-e>"] = { "<End>", type = "command" },
            },
            n = {
              ["<cr>"] = function(pb) multi(pb, "vnew") end,
              ["<c-v>"] = function(pb) multi(pb, "vnew") end,
              ["<c-s>"] = function(pb) multi(pb, "new") end,
              ["<c-o>"] = function(pb) multi(pb, "edit") end,
            },
          },
        },
        egrepify = {
          results_ts_hl = true,
          AND = true,
          lnum = true, -- default, not required
          lnum_hl = "EgrepifyLnum", -- default, not required
          col = false, -- default, not required
          col_hl = "EgrepifyCol", -- default, not required
          filename_hl = "@title.emphasis",
          title_suffix_hl = "Comment",
          prefixes = {
            ["!"] = {
              flag = "invert-match",
            },
          },
          mappings = {
            i = {
              ["<esc>"] = require("telescope.actions").close,
              ["<c-v>"] = stopinsert(function(pb) multi(pb, "vnew") end),
              ["<c-s>"] = stopinsert(function(pb) multi(pb, "new") end),
              ["<c-o>"] = stopinsert(function(pb) multi(pb, "edit") end),
              ["<cr>"] = stopinsert(function(pb) multi(pb, "vnew") end),
              ["<tab>"] = actions.toggle_selection + actions.move_selection_next,
              ["<c-a>"] = { "<Home>", type = "command" }, -- overrides default: egrep_actions.toggle_and,
              ["<c-e>"] = { "<End>", type = "command" },
            },
          },
        },
        undo = {
          side_by_side = true,
          use_delta = true,
          -- use_custom_command = { "bash", "-c", "echo '$DIFF' | delta" },
          mappings = {
            i = {
              ["<cr>"] = function() require("telescope-undo.actions").restore() end,
            },
          },
        },
      },
      pickers = {
        find_files = {
          find_command = find_files_cmd,
          on_input_filter_cb = file_extension_filter,
          mappings = {
            i = {
              ["<cr>"] = stopinsert(function(pb) multi(pb, "vnew") end),
            },
          },
        },
        live_grep = ivy({
          mappings = {
            i = {
              ["<cr>"] = stopinsert(function(pb) multi(pb, "vnew") end),
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
          mappings = {
            i = {
              ["<cr>"] = stopinsert(function(pb) multi(pb, "vnew") end),
            },
          },
        }),
      },
    })

    telescope.load_extension("undo")
    telescope.load_extension("live_grep_args")
    telescope.load_extension("file_browser")
    telescope.load_extension("fzf")
    telescope.load_extension("egrepify")
    telescope.load_extension("corrode")
    -- telescope.load_extension("zf-native")
    -- telescope.load_extension("smart_open")
  end,
}

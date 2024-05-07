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
        extensions("undo").undo(topts)
      elseif key == "smart" then
        extensions("smart_open").smart_open(with_title(topts, { title = "smartly find files" }))
      elseif key == "grep" then
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

local function stopinsert(callback)
  return function(prompt_bufnr)
    vim.cmd.stopinsert()
    vim.schedule(function() callback(prompt_bufnr) end)
  end
end

local t = require("telescope")
local action_state = require("telescope.actions.state")
local action_utils = require("telescope.actions.utils")

local function single_or_multi_select(prompt_bufnr)
  local current_picker = action_state.get_current_picker(prompt_bufnr)
  local has_multi_selection = (next(current_picker:get_multi_selection()) ~= nil)

  if has_multi_selection then
    local results = {}
    action_utils.map_selections(prompt_bufnr, function(selection) table.insert(results, selection[1]) end)

    -- load the selections into buffers list without switching to them
    for _, filepath in ipairs(results) do
      -- not the same as vim.fn.bufadd!
      vim.cmd.badd({ args = { filepath } })
    end

    require("telescope.pickers").on_close_prompt(prompt_bufnr)

    -- switch to newly loaded buffers if on an empty buffer
    if vim.fn.bufname() == "" and not vim.bo.modified then
      vim.cmd.bwipeout()
      vim.cmd.buffer(results[1])
    end
    return
  end

  -- if does not have multi selection, open single file
  require("telescope.actions").file_edit(prompt_bufnr)
end

-- local function with_multiselect_mapping()
--   -- @TODO tbl extend
--   return {
--     i = {
--       ["<CR>"] = single_or_multi_select,
--     },
--   }
-- end

-- REF: https://github.com/nvim-telescope/telescope.nvim/issues/416
-- REF: https://github.com/davidosomething/dotfiles/blob/dev/nvim/lua/dko/plugins/telescope.lua#L23-L66
local function multi(pb, verb, open_selection_under_cursor)
  open_selection_under_cursor = open_selection_under_cursor or false
  local methods = {
    ["vnew"] = "select_vertical",
    ["new"] = "select_horizontal",
    ["edit"] = "select_default",
    ["tabnew"] = "select_tab",
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
    -- print(result[2], result[1]:sub(2))
    return { prompt = result[2] .. "." .. result[1]:sub(2) }
  else
    return { prompt = prompt }
  end
end

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

  local grep = function(...) ts.grep(ivy(...)) end

  -- Gets the root dir from either:
  -- * connected lsp
  -- * .git from file
  -- * .git from cwd
  -- * cwd
  ---@param opts? table
  local find_files = function(opts)
    opts = opts or {}
    local theme = opts["theme"] or "ivy"
    local bufnr = vim.api.nvim_get_current_buf()
    local fn = vim.api.nvim_buf_get_name(bufnr)

    current_fn = fn
    -- opts.cwd = require("mega.utils").get_root()
    -- vim.notify(fmt("current project files root: %s", opts.cwd), vim.log.levels.DEBUG, { title = "telescope" })
    local picker = ts.find_files

    if theme == "ivy" then
      picker(ivy(opts))
    elseif theme == "dropdown" then
      picker(dropdown(opts))
    else
      picker(opts)
    end
  end

  keys = {
    -- { "<leader>ff", find_files, desc = "find files" },
    { "<leader>ff", function() ts.smart(ivy({})) end, desc = "smart find files" },
    {
      "<leader>a",
      grep,
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
      function() grep({ default_text = vim.fn.expand("<cword>") }) end,
      desc = "grep under cursor",
    },
    {
      "<leader>A",
      function()
        local pattern = require("mega.utils").get_visual_selection()
        grep({ default_text = pattern })
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
      function() find_files({ path = vim.g.notes_path }) end,
      desc = "browse: notes",
    },
  }

  _G.picker = {
    telescope = {
      find_files = find_files,
      grep = grep,
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
            command = function(args) print(vim.inspect(args)) end,
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
                  multi(pb, "edit")
                  vim.api.nvim_buf_delete(1, { force = true })
                end),
              },
              n = {
                ["<cr>"] = function(pb)
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

    local egrepify_title_suffix = string.format(" %s", string.rep("󰇘", 1000)) -- alts: ⣿ ░ ─ ⋮󰇘󱗿󱗽󱗼󱥸󱗾
    local function filename_first(_, path)
      local tail = vim.fs.basename(path)
      local parent = vim.fs.dirname(path)
      if parent == "." then return tail end
      return string.format("%s\t\t%s", tail, parent)
    end

    telescope.setup({
      defaults = {
        theme = "ivy",
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
        smart_open = {
          cwd_only = true,
          show_scores = false,
          ignore_patterns = { "*.git/*", "*/tmp/*" },
          match_algorithm = "fzf",
          disable_devicons = false,
          open_buffer_indicators = { previous = "👀", others = "🙈" },
          mappings = {
            i = {
              ["<cr>"] = stopinsert(function(pb) multi(pb, "vnew") end),
              ["<esc>"] = require("telescope.actions").close,
              ["<c-v>"] = stopinsert(function(pb) multi(pb, "vnew") end),
              ["<c-s>"] = stopinsert(function(pb) multi(pb, "new") end),
              ["<c-o>"] = stopinsert(function(pb) multi(pb, "edit") end),
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
          -- results_ts_hl = true, -- #PR23
          permutations = false,
          AND = true,
          lnum = true, -- default, not required
          lnum_hl = "EgrepifyLnum", -- default, not required
          col = true, -- default, not required
          col_hl = "EgrepifyCol", -- default, not required
          filename_hl = "@title.emphasis",
          title = false,
          title_suffix = nil, --egrepify_title_suffix,
          title_suffix_hl = nil, --"EgrepifySuffix",
          prefixes = {
            ["!"] = {
              flag = "invert-match",
            },
            ["#"] = {
              -- filter for file suffixes
              -- #$REMAINDER
              -- # is caught prefix
              -- `input` becomes $REMAINDER
              -- in the above example #lua,md -> input: lua,md
              flag = "glob",
              cb = function(input) return string.format([[*.{%s}]], input) end,
            },
            -- filter for (partial) folder names
            -- example prompt: >conf $MY_PROMPT
            -- searches with ripgrep prompt $MY_PROMPT in paths that have "conf" in folder
            -- i.e. rg --glob="**/conf*/**" -- $MY_PROMPT
            [">"] = {
              flag = "glob",
              cb = function(input) return string.format([[**/{%s}*/**]], input) end,
            },
            -- filter for (partial) file names
            -- example prompt: &egrep $MY_PROMPT
            -- searches with ripgrep prompt $MY_PROMPT in paths that have "egrep" in file name
            -- i.e. rg --glob="*egrep*" -- $MY_PROMPT
            ["&"] = {
              flag = "glob",
              cb = function(input) return string.format([[*{%s}*]], input) end,
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
              ["<c-r>"] = actions.to_fuzzy_refine,
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
        highlights = ivy({}),
        find_files = {
          find_command = find_files_cmd,
          path_display = filename_first,
          on_input_filter_cb = file_extension_filter,
          mappings = {
            i = {
              ["<cr>"] = stopinsert(function(pb) multi(pb, "vnew") end),
              ["<c-v>"] = stopinsert(function(pb) multi(pb, "vnew") end),
              ["<c-s>"] = stopinsert(function(pb) multi(pb, "new") end),
              ["<c-o>"] = stopinsert(function(pb) multi(pb, "edit") end),
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
    telescope.load_extension("smart_open")
    -- telescope.load_extension("zf-native")
  end,
}

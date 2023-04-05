local function get_border(border_opts)
  return vim.tbl_deep_extend("force", border_opts or {}, {
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
end
_G.telescope_get_border = get_border

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

local function dropdown(opts) return require("telescope.themes").get_dropdown(get_border(opts)) end

local function ivy(opts) return require("telescope.themes").get_ivy(get_border(opts)) end
_G.telescope_ivy = ivy

-- Gets the root dir from either:
-- * connected lsp
-- * .git from file
-- * .git from cwd
-- * cwd
---@param opts? table
local function project_files(opts)
  opts = opts or {}
  -- opts.cwd = require("mega.utils").get_root()
  -- vim.notify(fmt("current project files root: %s", opts.cwd), vim.log.levels.DEBUG, { title = "telescope" })
  require("telescope.builtin").find_files(ivy(opts))
end

local function multiopen(prompt_bufnr, method)
  local actions = require("telescope.actions")
  local action_state = require("telescope.actions.state")
  local cmd_map = {
    vertical = "vsplit",
    horizontal = "split",
    default = "vsplit",
    -- default = "edit",
  }
  local picker = action_state.get_current_picker(prompt_bufnr)
  local multi_selection = picker:get_multi_selection()

  if #multi_selection > 1 then
    require("telescope.pickers").on_close_prompt(prompt_bufnr)
    pcall(vim.api.nvim_set_current_win, picker.original_win_id)

    for i, entry in ipairs(multi_selection) do
      -- opinionated use-case
      local cmd = i == 1 and "edit" or cmd_map[method]
      vim.cmd(string.format("%s %s", cmd, entry.value))
    end
  else
    actions["select_" .. method](prompt_bufnr)
  end
end

local function multi_open(prompt_bufnr, method)
  local actions = require("telescope.actions")
  -- local transform_mod = require("telescope.actions.mt").transform_mod
  local action_state = require("telescope.actions.state")
  -- local action_layout = require("telescope.actions.layout")

  local edit_file_cmd_map = {
    vertical = "vsplit",
    horizontal = "split",
    tab = "tabedit",
    default = "vsplit",
    -- default = "edit",
  }
  local edit_buf_cmd_map = {
    vertical = "vert sbuffer",
    horizontal = "sbuffer",
    tab = "tab sbuffer",
    default = "vert sbuffer",
    -- default = "buffer",
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

local function stopinsert(callback)
  return function(prompt_bufnr)
    vim.cmd.stopinsert()
    vim.schedule(function() callback(prompt_bufnr) end)
  end
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

return {
  "nvim-telescope/telescope.nvim",
  cmd = { "Telescope" },
  dependencies = {
    { "molecule-man/telescope-menufacture" },
    "natecraddock/telescope-zf-native.nvim",
    "nvim-telescope/telescope-file-browser.nvim",
    "fdschmidt93/telescope-egrepify.nvim",
    -- "danielvolchek/tailiscope.nvim"
    {
      "danielfalk/smart-open.nvim",
      config = true,
      dependencies = { "kkharji/sqlite.lua" },
    },
  },
  keys = {
    { "<leader>ff", project_files, desc = "find files" },
    {
      "<leader>a",
      function() require("telescope").extensions.egrepify.egrepify(ivy({})) end,
      desc = "live grep",
    },
    {
      "<leader>A",
      function() extensions("menufacture").grep_string(ivy({})) end,
      desc = "grep under cursor",
    },
    {
      "<leader>A",
      function()
        local pattern = require("mega.utils").get_visual_selection()
        extensions("menufacture").grep_string(ivy({ search = pattern }))
      end,
      desc = "grep visual selection",
      mode = "v",
    },
    {
      "<leader>fl",
      function()
        extensions("menufacture").find_files(ivy({
          cwd = require("lazy.core.config").options.root,
        }))
      end,
      desc = "find plugin file",
    },
    {
      "<leader>fb",
      function() require("telescope.builtin").buffers(dropdown({})) end,
      desc = "find open buffers",
    },
    {
      "<leader>fn",
      function() extensions("file_browser").file_browser(ivy({ path = vim.g.obsidian_vault_path })) end,
      desc = "browse: obsidian notes",
    },
  },
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

    local custom_actions = transform_mod({
      multi_selection_open_vertical = function(prompt_bufnr) multi_open(prompt_bufnr, "vertical") end,
      multi_selection_open_horizontal = function(prompt_bufnr) multi_open(prompt_bufnr, "horizontal") end,
      multi_selection_open = function(prompt_bufnr) multi_open(prompt_bufnr, "vertical") end,
    })

    local previewers = require("telescope.previewers")
    local Job = require("plenary.job")
    local new_maker = function(filepath, bufnr, opts)
      opts = opts or {}
      Job:new({
        command = "file",
        args = { "--mime-type", "-b", filepath },
        on_exit = function(j)
          local mime_type = vim.split(j:result()[1], "/")[1]
          if mime_type == "text" or mime_type == "application" then
            previewers.buffer_previewer_maker(filepath, bufnr, opts)
          else
            vim.schedule(function() vim.api.nvim_buf_set_lines(bufnr, 0, -1, false, { "BINARY" }) end)
          end
        end,
      }):sync()

      local path = vim.fn.expand(filepath)
      vim.loop.fs_stat(filepath, function(_, stat)
        if not stat then return end
        if stat.size > 100000 then
          return
        else
          previewers.buffer_previewer_maker(path, bufnr, opts)
        end
      end)
    end

    telescope.setup({
      defaults = {
        dynamic_preview_title = true,
        results_title = false,
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
            ["<cr>"] = stopinsert(custom_actions.multi_selection_open_vertical),
            ["<c-v>"] = stopinsert(custom_actions.multi_selection_open_vertical),
            ["<c-s>"] = stopinsert(custom_actions.multi_selection_open_horizontal),
            ["<c-o>"] = stopinsert(custom_actions.multi_selection_open),
            ["<C-z>"] = actions.toggle_selection,
            ["<c-t>"] = function(...) return require("trouble.providers.telescope").smart_open_with_trouble(...) end,
            ["<C-Down>"] = function(...) return require("telescope.actions").cycle_history_next(...) end,
            ["<C-Up>"] = function(...) return require("telescope.actions").cycle_history_prev(...) end,
          },
          n = {
            ["<cr>"] = custom_actions.multi_selection_open_vertical,
            ["<c-v>"] = custom_actions.multi_selection_open_vertical,
            ["<c-s>"] = custom_actions.multi_selection_open_horizontal,
            ["<c-o>"] = custom_actions.multi_selection_open,
          },
        },
        prompt_prefix = " ",
        selection_caret = " ",
        entry_prefix = "  ",
        winblend = 0,
        vimgrep_arguments = grep_files_cmd,
        buffer_previewer_maker = new_maker,
      },
      extensions = {
        ["zf-native"] = {
          file = {
            enable = true,
            highlight_results = true,
            match_filename = true,
          },
          generic = {
            enable = true,
            highlight_results = true,
            match_filename = false,
          },
        },
        menufacture = {
          mappings = {
            main_menu = { [{ "i", "n" }] = "<C-y>" },
          },
        },
        egrepify = {
          lnum = true, -- default, not required
          lnum_hl = "EgrepifyLnum", -- default, not required
          col = false, -- default, not required
          col_hl = "EgrepifyCol", -- default, not required
          title_hl = "@title.emphasis",
          title_suffix_hl = "Comment",
          -- EXAMPLE PREFIX!
          prefixes = {
            ["!"] = {
              flag = "invert-match",
            },
          },
        },
      },
      pickers = {
        find_files = {
          find_command = find_files_cmd,
          on_input_filter_cb = file_extension_filter,
          -- previewer = require("telescope.previewers.term_previewer").new_termopen_previewer({
          --   get_command = function(entry) return { "preview", require("telescope.from_entry").path(entry) } end,
          -- }),
        },
        live_grep = ivy({
          -- max_results = 500,
          -- file_ignore_patterns = { ".git/", "%.lock" },
          mappings = {
            i = {
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
        lsp_references = ivy({}),
      },
    })

    telescope.load_extension("file_browser")
    telescope.load_extension("menufacture")
    telescope.load_extension("zf-native")
    telescope.load_extension("smart_open")
    telescope.load_extension("egrepify")
    -- telescope.load_extension("noice")
  end,
}

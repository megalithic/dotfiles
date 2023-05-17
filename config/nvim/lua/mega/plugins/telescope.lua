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

local get_selection = function()
  local rv = vim.fn.getreg("v")
  local rt = vim.fn.getregtype("v")
  vim.cmd([[noautocmd silent normal! "vy]])
  local selection = vim.fn.getreg("v")
  vim.fn.setreg("v", rv, rt)
  return vim.split(selection, "\n")
end

-- telescope
local ts = setmetatable({}, {
  __index = function(_, key)
    return function(topts)
      local mode = vim.api.nvim_get_mode().mode
      topts = topts or {}
      if mode == "v" or mode == "V" or mode == "" then topts.default_text = table.concat(get_selection()) end
      if key == "grep" then
        require("telescope").extensions.egrepify.egrepify(topts)
      else
        local builtin = require("telescope.builtin")
        builtin[key](topts)
      end
    end
  end,
})

local function dropdown(opts) return require("telescope.themes").get_dropdown(get_border(opts)) end

local function ivy(opts) return require("telescope.themes").get_ivy(get_border(opts)) end
_G.telescope_ivy = ivy

-- Gets the root dir from either:
-- * connected lsp
-- * .git from file
-- * .git from cwd
-- * cwd
---@param opts? table
local current_fn = nil
local function project_files(opts)
  local bufnr = vim.api.nvim_get_current_buf()
  local fn = vim.api.nvim_buf_get_name(bufnr)
  current_fn = fn
  opts = opts or {}
  -- opts.cwd = require("mega.utils").get_root()
  -- vim.notify(fmt("current project files root: %s", opts.cwd), vim.log.levels.DEBUG, { title = "telescope" })
  ts.find_files(ivy(opts))
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

  if open_selection_under_cursor or current_fn == nil then
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
  enabled = vim.g.picker == "telescope",
  dependencies = {
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
      function() ts.grep(ivy({})) end,
      desc = "live grep",
    },
    {
      "<leader>A",
      function() ts.grep(ivy({ default_text = vim.fn.expand("<cword>") })) end,
      desc = "grep under cursor",
    },
    {
      "<leader>A",
      function()
        local pattern = require("mega.utils").get_visual_selection()
        ts.grep(ivy({ default_text = pattern }))
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
            ["<cr>"] = stopinsert(function(pb) multi(pb, "vnew") end),
            ["<c-v>"] = stopinsert(function(pb) multi(pb, "vnew") end),
            ["<c-s>"] = stopinsert(function(pb) multi(pb, "new") end),
            ["<c-o>"] = stopinsert(function(pb) multi(pb, "edit") end),
            ["<c-z>"] = actions.toggle_selection,
            ["<c-r>"] = actions.to_fuzzy_refine,
            ["<c-t>"] = require("trouble.providers.telescope").smart_open_with_trouble,
            ["<c-down>"] = function(...) return require("telescope.actions").cycle_history_next(...) end,
            ["<c-up>"] = function(...) return require("telescope.actions").cycle_history_prev(...) end,
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
        -- buffer_previewer_maker = new_maker,
        preview = {
          mime_hook = function(filepath, bufnr, opts)
            local is_image = function(fp)
              local image_extensions = { "png", "jpg" } -- Supported image formats
              local split_path = vim.split(fp:lower(), ".", { plain = true })
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
                "catimg",
                filepath, -- Terminal image viewer command
              }, { on_stdout = send_output, stdout_buffered = true, pty = true })
            else
              require("telescope.previewers.utils").set_preview_message(bufnr, opts.winid, "Binary cannot be previewed")
            end
          end,
        },
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
        egrepify = {
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
    telescope.load_extension("zf-native")
    telescope.load_extension("smart_open")
    telescope.load_extension("egrepify")
    -- telescope.load_extension("noice")
  end,
}

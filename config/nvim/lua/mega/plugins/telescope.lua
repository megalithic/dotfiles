local function get_border(border_opts)
  return vim.tbl_deep_extend("force", border_opts or {}, {
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
    default = "edit",
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

local M = {
  "nvim-telescope/telescope.nvim",
  cmd = { "Telescope" },

  dependencies = {
    "natecraddock/telescope-zf-native.nvim",
    "nvim-telescope/telescope-file-browser.nvim",
    -- "danielvolchek/tailiscope.nvim"
    -- "danielfalk/smart-open.nvim"
  },
  keys = {
    { "<C-p>", project_files, desc = "Find File" },
    -- { "<leader>ff", project_files, desc = "find files" },
    -- {
    --   "<leader>a",
    --   function() require("telescope.builtin").live_grep(ivy({})) end,
    --   desc = "live grep",
    -- },
    -- {
    --   "<leader>A",
    --   function() require("telescope.builtin").grep_string(ivy({})) end,
    --   desc = "grep under cursor",
    -- },
    -- {
    --   "<leader>A",
    --   function()
    --     local pattern = require("mega.utils").get_visual_selection()
    --     require("telescope.builtin").grep_string(ivy({ search = pattern }))
    --   end,
    --   desc = "grep visual selection",
    --   mode = "v",
    -- },
    {
      "<leader>fl",
      function()
        require("telescope.builtin").find_files(ivy({
          cwd = require("lazy.core.config").options.root,
        }))
      end,
      desc = "find plugin file",
    },
    -- {
    --   "<leader>fb",
    --   function() require("telescope.builtin").buffers(dropdown({})) end,
    --   desc = "find open buffers",
    -- },
    {
      "<leader>fn",
      function() require("telescope").extensions.file_browser.file_browser(ivy({ path = vim.g.obsidian_vault_path })) end,
      desc = "browse: obsidian notes",
    },
  },
  config = function()
    local telescope = require("telescope")
    local transform_mod = require("telescope.actions.mt").transform_mod
    local actions = require("telescope.actions")

    local custom_actions = transform_mod({
      multi_selection_open_vertical = function(prompt_bufnr) multiopen(prompt_bufnr, "vertical") end,
      multi_selection_open_horizontal = function(prompt_bufnr) multiopen(prompt_bufnr, "horizontal") end,
      multi_selection_open = function(prompt_bufnr) multiopen(prompt_bufnr, "default") end,
    })

    telescope.setup({
      defaults = {
        dynamic_preview_title = true,
        results_title = false,
        -- selection_strategy = "reset",
        -- use_less = true,
        color_devicons = false,
        layout_strategy = "horizontal",
        layout_config = {
          prompt_position = "top",
        },
        sorting_strategy = "ascending",
        mappings = {
          i = {
            ["<esc>"] = require("telescope.actions").close,
            ["<cr>"] = stopinsert(custom_actions.multi_selection_open_vertical),
            ["<c-s>"] = stopinsert(custom_actions.multi_selection_open_horizontal),
            ["<c-o>"] = stopinsert(custom_actions.multi_selection_open),
            ["<c-t>"] = function(...) return require("trouble.providers.telescope").open_with_trouble(...) end,
            ["<C-Down>"] = function(...) return require("telescope.actions").cycle_history_next(...) end,
            ["<C-Up>"] = function(...) return require("telescope.actions").cycle_history_prev(...) end,
          },
          n = {
            ["<cr>"] = custom_actions.multi_selection_open_vertical,
            ["<c-s>"] = custom_actions.multi_selection_open_horizontal,
            ["<c-o>"] = custom_actions.multi_selection_open,
          },
        },
        prompt_prefix = " ",
        selection_caret = " ",
        winblend = 0,

        vimgrep_arguments = grep_files_cmd,
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
      },
      pickers = {
        find_files = {
          find_command = find_files_cmd,
          on_input_filter_cb = file_extension_filter,
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
      },
    })

    telescope.load_extension("file_browser")
    telescope.load_extension("zf-native")
  end,
}

return M

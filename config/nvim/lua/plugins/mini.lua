local M = {}
-- ============================================================================
-- MiniPick Configuration
-- ============================================================================

function M.icons()
  require("mini.icons").setup({
    file = {
      [".eslintrc.js"] = { glyph = "󰱺", hl = "MiniIconsYellow" },
      [".node-version"] = { glyph = "", hl = "MiniIconsGreen" },
      [".prettierrc"] = { glyph = "", hl = "MiniIconsPurple" },
      [".yarnrc.yml"] = { glyph = "", hl = "MiniIconsBlue" },
      ["eslint.config.js"] = { glyph = "󰱺", hl = "MiniIconsYellow" },
      ["package.json"] = { glyph = "", hl = "MiniIconsGreen" },
      ["tsconfig.json"] = { glyph = "", hl = "MiniIconsAzure" },
      ["tsconfig.build.json"] = { glyph = "", hl = "MiniIconsAzure" },
      ["yarn.lock"] = { glyph = "", hl = "MiniIconsBlue" },
    },
  })
end
function M.extra() require("mini.extra").setup() end
function M.visits() require("mini.visits").setup() end

-- Window configuration for picker
M.win_config = {
  -- Small picker in bottom-left corner of editor
  left_corner = function()
    return {
      relative = "editor",
      anchor = "SW",
      height = math.floor(0.25 * vim.o.lines),
      width = math.floor(0.4 * vim.o.columns),
      border = "single",
      row = vim.o.lines - 1,
      col = 0,
    }
  end,

  -- Picker at bottom of current buffer window
  buf_bottom = function()
    local window_height = vim.api.nvim_win_get_height(0)
    local height = math.floor(0.25 * window_height)

    local window_width = vim.api.nvim_win_get_width(0)
    local border_width = 2

    local width
    if window_width >= 165 then
      width = math.floor(0.5 * vim.o.columns)
    else
      width = window_width - border_width
    end

    return {
      relative = "win",
      height = height,
      border = "solid",
      width = width,
      row = math.floor(window_height - 1),
      col = 0,
    }
  end,
}

--- Smart file picker with intelligent prioritization
---
--- Combines multiple sources (alternative file, recent files, visited paths, all files)
--- into a single picker with weighted scoring for better file navigation.
---
--- Priority order (lower score = higher priority):
--- 1. Alternative file (#) - heavily prioritized for quick switching
--- 2. Recent files (oldfiles) - files recently opened in cwd
--- 3. Visited paths (mini.visits) - frequently accessed files
--- 4. All other files - general fallback
---
--- Current file is always ranked last to avoid accidental re-selection.
function M.smart_picker()
  local MiniPick = require("mini.pick")
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

function M.pick()
  local MiniPick = require("mini.pick")
  local MiniExtra = require("mini.extra")

  MiniPick.setup({
    mappings = {
      scroll_down = "<C-d>",
      scroll_left = "<C-h>",
      scroll_right = "<C-l>",
      scroll_up = "<C-u>",
    },
    window = {
      config = M.win_config.buf_bottom,
      prompt_caret = "█",
      prompt_prefix = "  ",
    },
  })

  MiniPick.registry.frecency = M.smart_picker

  -- Custom picker: modified + untracked files (all changed files) with diff preview
  MiniPick.registry.git_changed = function()
    local git_root = vim.fn.systemlist("git rev-parse --show-toplevel")[1]
    if vim.v.shell_error ~= 0 then
      vim.notify("Not in a git repository", vim.log.levels.ERROR)
      return
    end

    local modified = vim.fn.systemlist("git ls-files --modified")
    local untracked = vim.fn.systemlist("git ls-files --others --exclude-standard")

    local items = {}
    local status_lookup = {}
    local seen = {}

    for _, file in ipairs(modified) do
      if not seen[file] then
        seen[file] = true
        table.insert(items, file)
        status_lookup[file] = "modified"
      end
    end

    for _, file in ipairs(untracked) do
      if not seen[file] then
        seen[file] = true
        table.insert(items, file)
        status_lookup[file] = "untracked"
      end
    end

    MiniPick.start({
      source = {
        items = items,
        name = "Git Changed",
        cwd = git_root,
        preview = function(buf_id, item)
          local lines
          if status_lookup[item] == "modified" then
            lines = vim.fn.systemlist({ "git", "-C", git_root, "diff", "--", item })
          else
            -- Untracked: show as new file diff
            lines = vim.fn.systemlist({ "git", "-C", git_root, "diff", "--no-index", "/dev/null", item })
          end

          if #lines == 0 then lines = { "No diff available" } end

          vim.api.nvim_buf_set_lines(buf_id, 0, -1, false, lines)
          vim.bo[buf_id].filetype = "diff"
        end,
      },
    })
  end

  -- Use MiniPick for vim.ui.select
  vim.ui.select = MiniPick.ui_select

  local map = vim.keymap.set

    -- stylua: ignore start
    -- General
    -- map("n", "<leader>ff",    MiniPick.registry.frecency, { desc = "Pick file" })
    -- map("n", "<leader>.",           function() MiniPick.builtin.resume() end, { desc = "Resume Picker" })
    -- map("n", "<leader>;",           function() MiniExtra.pickers.commands() end, { desc = "Commands" })
    -- map("n", "<leader>:",           function() MiniExtra.pickers.history({ scope = ":" }) end, { desc = "Command History" })
    -- map("n", "<leader>'",           function() MiniExtra.pickers.registers() end, { desc = "Registers" })
    --
    -- -- App
    -- map("n", "<leader>aa",          function() MiniExtra.pickers.commands() end, { desc = "[A]ctions" })
    -- map("n", "<leader>ar",          function() MiniExtra.pickers.oldfiles() end, { desc = "[R]ecent Documents (Anywhere)" })
    -- map("n", "<leader>at",          function() MiniExtra.pickers.colorschemes() end, { desc = "[T]hemes" })
    -- map("n", "<leader>ahh",         function() MiniExtra.pickers.hl_groups() end, { desc = "[H]ightlights" })
    -- map("n", "<leader>ahk",         function() MiniExtra.pickers.keymaps() end, { desc = "[K]eymaps" })
    -- map("n", "<leader>aht",         function() MiniPick.builtin.help() end, { desc = "[T]ags" })
    -- map("n", "<leader>as",          function() MiniPick.builtin.files(nil, { source = { cwd = vim.fn.expand("$HOME") .. "/repos/nikbrunner/dots" }}) end, { desc = "[S]ettings (Dots)" })
    --
    -- -- Workspace
    -- map("n", "<leader>wd",          MiniPick.registry.frecency, { desc = "[D]ocument" })
    -- map("n", "<leader>wr",          function() MiniExtra.pickers.oldfiles({ current_dir = true }) end, { desc = "[R]ecent Documents" })
    -- map("n", "<leader>wt",          function() MiniPick.builtin.grep_live() end, { desc = "[T]ext" })
    -- map("n", "<leader>ww",          function() MiniPick.builtin.grep({ pattern = vim.fn.expand("<cword>") }) end, { desc = "[W]ord" })
    -- map("n", "<leader>wm",          MiniPick.registry.git_changed, { desc = "[M]odified Documents" })
    -- map("n", "<leader>wc",          function() MiniExtra.pickers.git_hunks() end, { desc = "[C]hanges" })
    -- map("n", "<leader>ws",          function() MiniExtra.pickers.lsp({ scope = "workspace_symbol" }) end, { desc = "[S]ymbols" })
    -- map("n", "<leader>wvb",         function() MiniExtra.pickers.git_branches() end, { desc = "[B]ranches" })
    -- map("n", "<leader>wvh",         function() MiniExtra.pickers.git_commits() end, { desc = "[H]istory" })
    -- map("n", "<leader>wj",          function() MiniExtra.pickers.list({ scope = "jump" }) end, { desc = "[J]umps" })
    -- map("n", "<leader>wp",          function() MiniExtra.pickers.diagnostic() end, { desc = "[P]roblems" })
    --
    -- -- Document
    -- map("n", "<leader>dt",          function() MiniExtra.pickers.buf_lines({ scope = "current" }) end, { desc = "[T]ext" })
    -- map("n", "<leader>ds",          function() MiniExtra.pickers.lsp({ scope = "document_symbol" }) end, { desc = "[S]ymbols" })
    -- map("n", "<leader>dp",          function() MiniExtra.pickers.diagnostic({ scope = "current" }) end, { desc = "[P]roblems" })

    -- Symbol
    map("n", "sr",                  function() MiniExtra.pickers.lsp({ scope = "references" }) end, { desc = "[R]eferences" })
    map("n", "si",                  function() MiniExtra.pickers.lsp({ scope = "implementation" }) end, { desc = "[I]mplementations" })
  -- stylua: ignore end
end

-- ============================================================================
-- MiniFiles Configuration
-- ============================================================================

function M.files()
  local MiniFiles = require("mini.files")

  MiniFiles.setup({
    mappings = {
      show_help = "g?",
      close = "q",
      go_in = "<CR>",
      go_in_plus = "<CR>",
      go_out = "-",
      go_out_plus = "_",
      mark_goto = "'",
      mark_set = "m",
      reset = "<BS>",
      reveal_cwd = "@",
      synchronize = "=",
      trim_left = "<",
      trim_right = ">",
    },
    options = {
      use_as_default_explorer = false,
    },
    windows = {
      max_number = 3,
      preview = true,
      width_focus = 50,
      width_nofocus = 25,
      width_preview = 65,
    },
  })

  -- Override global winborder for MiniFiles
  vim.api.nvim_create_autocmd("User", {
    pattern = "MiniFilesWindowOpen",
    callback = function(args)
      local config = vim.api.nvim_win_get_config(args.data.win_id)
      config.border = "single"
      vim.api.nvim_win_set_config(args.data.win_id, config)
    end,
  })

  -- Split keymaps
  local map_split = function(buf_id, lhs, direction)
    local rhs = function()
      local cur_target = MiniFiles.get_explorer_state().target_window
      local new_target = vim.api.nvim_win_call(cur_target, function()
        vim.cmd(direction .. " split")
        return vim.api.nvim_get_current_win()
      end)
      MiniFiles.set_target_window(new_target)
      MiniFiles.go_in({ close_on_file = true })
    end
    local desc = "Split " .. direction
    vim.keymap.set("n", lhs, rhs, { buffer = buf_id, desc = desc })
  end

  vim.api.nvim_create_autocmd("User", {
    pattern = "MiniFilesBufferCreate",
    callback = function(args)
      local buf_id = args.data.buf_id
      map_split(buf_id, "<C-v>", "belowright vertical")
      map_split(buf_id, "<C-s>", "belowright horizontal")
      map_split(buf_id, "<C-t>", "tab")
    end,
  })

  -- LSP rename integration with Snacks
  vim.api.nvim_create_autocmd("User", {
    pattern = "MiniFilesActionRename",
    callback = function(event) Snacks.rename.on_rename_file(event.data.from, event.data.to) end,
  })

  -- Path operations
  local yank_path = function()
    local path = (MiniFiles.get_fs_entry() or {}).path
    if path == nil then return vim.notify("Cursor is not on valid entry") end
    vim.fn.setreg(vim.v.register, path)
    vim.notify("Copied: " .. path, vim.log.levels.INFO)
  end

  local ui_open = function()
    local entry = MiniFiles.get_fs_entry()
    if entry then vim.ui.open(entry.path) end
  end

  -- Yank path variants
  local yank_filename = function()
    local entry = MiniFiles.get_fs_entry()
    if entry then
      local name = vim.fn.fnamemodify(entry.path, ":t")
      vim.fn.setreg("+", name)
      vim.notify("Copied filename: " .. name, vim.log.levels.INFO)
    end
  end

  local yank_relative_path = function()
    local entry = MiniFiles.get_fs_entry()
    if entry then
      local relative_path = vim.fn.fnamemodify(entry.path, ":~:.")
      vim.fn.setreg("+", relative_path)
      vim.notify("Copied relative path: " .. relative_path, vim.log.levels.INFO)
    end
  end

  local yank_path_from_home = function()
    local entry = MiniFiles.get_fs_entry()
    if entry then
      local path_from_home = vim.fn.fnamemodify(entry.path, ":~")
      vim.fn.setreg("+", path_from_home)
      vim.notify("Copied path from home: " .. path_from_home, vim.log.levels.INFO)
    end
  end

  local yank_absolute_path = function()
    local entry = MiniFiles.get_fs_entry()
    if entry then
      vim.fn.setreg("+", entry.path)
      vim.notify("Copied absolute path: " .. entry.path, vim.log.levels.INFO)
    end
  end

  -- Buffer-local keymaps for MiniFiles
  vim.api.nvim_create_autocmd("User", {
    pattern = "MiniFilesBufferCreate",
    callback = function(args)
      local bufid = args.data.buf_id
      local map = vim.keymap.set

      local function setBranch(path) MiniFiles.set_branch({ vim.fn.expand(path) }) end

            -- stylua: ignore start
            -- Path operations
            map("n", "gx", ui_open, { buffer = bufid, desc = "OS open" })
            map("n", "gy", yank_path, { buffer = bufid, desc = "Yank path" })

            -- Yank path variants
            map("n", "<leader>yn", yank_filename, { buffer = bufid, desc = "Yank filename" })
            map("n", "<leader>yr", yank_relative_path, { buffer = bufid, desc = "Yank relative path" })
            map("n", "<leader>yh", yank_path_from_home, { buffer = bufid, desc = "Yank path from home" })
            map("n", "<leader>ya", yank_absolute_path, { buffer = bufid, desc = "Yank absolute path" })

            -- Bookmark navigation (g prefix)
            map("n", "g.", function() setBranch(vim.fn.getcwd()) end, { buffer = bufid, desc = "Current working directory" })
            map("n", "gh", function() setBranch("$HOME/") end, { buffer = bufid, desc = "Home", nowait = true })
            map("n", "gc", function() setBranch("$HOME/.config") end, { buffer = bufid, desc = "Config", nowait = true })
            map("n", "gr", function() setBranch("$HOME/repos") end, { buffer = bufid, desc = "Repos", nowait = true })
            map("n", "gl", function() setBranch("$HOME/.local/share/nvim/lazy") end, { buffer = bufid, desc = "Lazy Packages", nowait = true })

            -- Project bookmarks (g + number)
            map("n", "g0", function() setBranch("$HOME/repos/nikbrunner/dots") end, { buffer = bufid, desc = "nbr - dots" })
            map("n", "g1", function() setBranch("$HOME/repos/nikbrunner/notes") end, { buffer = bufid, desc = "nbr - notes" })
            map("n", "g2", function() setBranch("$HOME/repos/nikbrunner/dcd-notes") end, { buffer = bufid, desc = "DCD - Notes" })
            map("n", "g4", function() setBranch("$HOME/repos/black-atom-industries/core") end, { buffer = bufid, desc = "Black Atom - core" })
            map("n", "g5", function() setBranch("$HOME/repos/black-atom-industries/nvim") end, { buffer = bufid, desc = "Black Atom - nvim" })
            map("n", "g6", function() setBranch("$HOME/repos/black-atom-industries/radar.nvim") end, { buffer = bufid, desc = "Black Atom - radar.nvim" })
            map("n", "g7", function() setBranch("$HOME/repos/nikbrunner/nbr.haus") end, { buffer = bufid, desc = "nikbrunner - nbr.haus" })
            map("n", "g8", function() setBranch("$HOME/repos/nikbrunner/koyo") end, { buffer = bufid, desc = "nikbrunner - koyo" })
            map("n", "g9", function() setBranch("$HOME/repos/dealercenter-digital/bc-desktop-client") end, { buffer = bufid, desc = "DCD - BC Desktop Client" })

            -- Picker in MiniFiles directory
            map("n", "<leader><leader>", function()
                local current_dir = vim.fn.fnamemodify(MiniFiles.get_fs_entry().path, ":h")
                MiniFiles.close()
                require("mini.pick").builtin.files(nil, { source = { cwd = current_dir }})
            end, { buffer = bufid, desc = "Find files in current directory" })
      -- stylua: ignore end
    end,
  })

  -- Global keymaps
  local map = vim.keymap.set
    -- stylua: ignore start
    -- map("n", "-", function() MiniFiles.open(vim.api.nvim_buf_get_name(0)) end, { desc = "[E]xplorer" })
    -- map("n", "_", function() MiniFiles.open(vim.fn.getcwd()) end, { desc = "[E]xplorer (cwd)" })
    map("n", "<leader>ee", function() MiniFiles.open(vim.api.nvim_buf_get_name(0)) end, { desc = "[E]xplorer" })
  -- stylua: ignore end
end

return {
  { "nvim-mini/mini.icons", version = false, opts = {} },
  -- { "nvim-mini/mini.cmdline", version = false, opts = {} },
  {
    "nvim-mini/mini.indentscope",
    config = function()
      require("mini.indentscope").setup({
        symbol = vim.g.indent_scope_char,
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

      if Augroup ~= nil then
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
      end
    end,
  },
  { "nvim-mini/mini.extra", version = false, opts = {} },
  { "nvim-mini/mini.fuzzy", version = false, opts = {} },
  { "nvim-mini/mini.visits", version = false, opts = {} },
  { "nvim-mini/mini.align", version = false, opts = {} },
  -- {
  --   "nvim-mini/mini.pick",
  --   version = false,
  --   lazy = false,
  --   init = function()
  --     P("mini.pick config?")
  --     -- ============================================================================
  --     -- MiniPick Configuration
  --     -- ============================================================================
  --
  --     -- Window configuration for picker
  --     M.win_config = {
  --       -- Small picker in bottom-left corner of editor
  --       left_corner = function()
  --         return {
  --           relative = "editor",
  --           anchor = "SW",
  --           height = math.floor(0.25 * vim.o.lines),
  --           width = math.floor(0.4 * vim.o.columns),
  --           border = "single",
  --           row = vim.o.lines - 1,
  --           col = 0,
  --         }
  --       end,
  --
  --       -- Picker at bottom of current buffer window
  --       buf_bottom = function()
  --         local window_height = vim.api.nvim_win_get_height(0)
  --         local height = math.floor(0.25 * window_height)
  --
  --         local window_width = vim.api.nvim_win_get_width(0)
  --         local border_width = 2
  --
  --         local width
  --         if window_width >= 165 then
  --           width = math.floor(0.5 * vim.o.columns)
  --         else
  --           width = window_width - border_width
  --         end
  --
  --         return {
  --           relative = "win",
  --           height = height,
  --           border = "solid",
  --           width = width,
  --           row = math.floor(window_height - 1),
  --           col = 0,
  --         }
  --       end,
  --     }
  --
  --     --- Smart file picker with intelligent prioritization
  --     ---
  --     --- Combines multiple sources (alternative file, recent files, visited paths, all files)
  --     --- into a single picker with weighted scoring for better file navigation.
  --     ---
  --     --- Priority order (lower score = higher priority):
  --     --- 1. Alternative file (#) - heavily prioritized for quick switching
  --     --- 2. Recent files (oldfiles) - files recently opened in cwd
  --     --- 3. Visited paths (mini.visits) - frequently accessed files
  --     --- 4. All other files - general fallback
  --     ---
  --     --- Current file is always ranked last to avoid accidental re-selection.
  --     function M.smart_picker()
  --       local MiniPick = require("mini.pick")
  --       local MiniFuzzy = require("mini.fuzzy")
  --       local MiniVisits = require("mini.visits")
  --
  --       local visit_paths = MiniVisits.list_paths()
  --       local current_file = vim.fn.expand("%")
  --       local cwd = vim.fn.getcwd()
  --
  --       -- Get alternative file for priority boost
  --       local alt_file = vim.fn.expand("#")
  --
  --       -- Get oldfiles scoped to current working directory
  --       local oldfiles = {}
  --       for _, file in ipairs(vim.v.oldfiles) do
  --         local abs_path = vim.fn.fnamemodify(file, ":p")
  --         if vim.startswith(abs_path, cwd) then table.insert(oldfiles, vim.fn.fnamemodify(file, ":.")) end
  --       end
  --
  --       MiniPick.builtin.files(nil, {
  --         source = {
  --           match = function(stritems, indices, query)
  --             -- Concatenate prompt to a single string
  --             local prompt = vim.pesc(table.concat(query))
  --
  --             -- If ignorecase is on and there are no uppercase letters in prompt,
  --             -- convert paths to lowercase for matching purposes
  --             local convert_path = function(str) return str end
  --             if vim.o.ignorecase and string.find(prompt, "%u") == nil then
  --               convert_path = function(str) return string.lower(str) end
  --             end
  --
  --             local current_file_cased = convert_path(current_file)
  --             local alt_file_rel = alt_file ~= "" and vim.fn.fnamemodify(alt_file, ":.") or nil
  --             local alt_file_cased = alt_file_rel and convert_path(alt_file_rel) or nil
  --
  --             -- Create lookup tables for priority files
  --             local oldfiles_lookup = {}
  --             for index, file_path in ipairs(oldfiles) do
  --               oldfiles_lookup[convert_path(file_path)] = index
  --             end
  --
  --             local visits_lookup = {}
  --             for index, path in ipairs(visit_paths) do
  --               local key = vim.fn.fnamemodify(path, ":.")
  --               visits_lookup[convert_path(key)] = index
  --             end
  --
  --             local result = {}
  --             for _, index in ipairs(indices) do
  --               local path = stritems[index]
  --               local path_cased = convert_path(path)
  --               local match_score = prompt == "" and 0 or MiniFuzzy.match(prompt, path).score
  --
  --               if match_score >= 0 then
  --                 local score
  --
  --                 -- Current file gets ranked last
  --                 if path_cased == current_file_cased then
  --                   score = 999999
  --                   -- Alt file gets highest priority
  --                 elseif alt_file_cased and path_cased == alt_file_cased then
  --                   score = match_score - 10000
  --                   -- Oldfiles get second priority
  --                 elseif oldfiles_lookup[path_cased] then
  --                   score = match_score - 1000 + oldfiles_lookup[path_cased]
  --                   -- Visit paths get third priority
  --                 elseif visits_lookup[path_cased] then
  --                   score = match_score + visits_lookup[path_cased]
  --                   -- Everything else
  --                 else
  --                   score = match_score + 100000
  --                 end
  --
  --                 table.insert(result, {
  --                   index = index,
  --                   score = score,
  --                 })
  --               end
  --             end
  --
  --             table.sort(result, function(a, b) return a.score < b.score end)
  --
  --             return vim.tbl_map(function(val) return val.index end, result)
  --           end,
  --         },
  --       })
  --     end
  --
  --     local MiniPick = require("mini.pick")
  --     local MiniExtra = require("mini.extra")
  --
  --     MiniPick.setup({
  --       mappings = {
  --         scroll_down = "<C-d>",
  --         scroll_left = "<C-h>",
  --         scroll_right = "<C-l>",
  --         scroll_up = "<C-u>",
  --       },
  --       window = {
  --         config = M.win_config.buf_bottom,
  --         prompt_caret = "█",
  --         prompt_prefix = "  ",
  --       },
  --     })
  --
  --     MiniPick.registry.frecency = M.smart_picker
  --
  --     -- Custom picker: modified + untracked files (all changed files) with diff preview
  --     MiniPick.registry.git_changed = function()
  --       local git_root = vim.fn.systemlist("git rev-parse --show-toplevel")[1]
  --       if vim.v.shell_error ~= 0 then
  --         vim.notify("Not in a git repository", vim.log.levels.ERROR)
  --         return
  --       end
  --
  --       local modified = vim.fn.systemlist("git ls-files --modified")
  --       local untracked = vim.fn.systemlist("git ls-files --others --exclude-standard")
  --
  --       local items = {}
  --       local status_lookup = {}
  --       local seen = {}
  --
  --       for _, file in ipairs(modified) do
  --         if not seen[file] then
  --           seen[file] = true
  --           table.insert(items, file)
  --           status_lookup[file] = "modified"
  --         end
  --       end
  --
  --       for _, file in ipairs(untracked) do
  --         if not seen[file] then
  --           seen[file] = true
  --           table.insert(items, file)
  --           status_lookup[file] = "untracked"
  --         end
  --       end
  --
  --       MiniPick.start({
  --         source = {
  --           items = items,
  --           name = "Git Changed",
  --           cwd = git_root,
  --           preview = function(buf_id, item)
  --             local lines
  --             if status_lookup[item] == "modified" then
  --               lines = vim.fn.systemlist({ "git", "-C", git_root, "diff", "--", item })
  --             else
  --               -- Untracked: show as new file diff
  --               lines = vim.fn.systemlist({ "git", "-C", git_root, "diff", "--no-index", "/dev/null", item })
  --             end
  --
  --             if #lines == 0 then lines = { "No diff available" } end
  --
  --             vim.api.nvim_buf_set_lines(buf_id, 0, -1, false, lines)
  --             vim.bo[buf_id].filetype = "diff"
  --           end,
  --         },
  --       })
  --     end
  --
  --     -- Use MiniPick for vim.ui.select
  --     vim.ui.select = MiniPick.ui_select
  --
  --     local map = vim.keymap.set
  --
  --     -- General
  --     map("n", "<leader>ff", MiniPick.registry.frecency, { desc = "Pick file" })
  --     map("n", "<leader>.", function() MiniPick.builtin.resume() end, { desc = "Resume Picker" })
  --     map("n", "<leader>;", function() MiniExtra.pickers.commands() end, { desc = "Commands" })
  --     map("n", "<leader>:", function() MiniExtra.pickers.history({ scope = ":" }) end, { desc = "Command History" })
  --     map("n", "<leader>'", function() MiniExtra.pickers.registers() end, { desc = "Registers" })
  --
  --     -- App
  --     map("n", "<leader>aa", function() MiniExtra.pickers.commands() end, { desc = "[A]ctions" })
  --     map("n", "<leader>ar", function() MiniExtra.pickers.oldfiles() end, { desc = "[R]ecent Documents (Anywhere)" })
  --     map("n", "<leader>at", function() MiniExtra.pickers.colorschemes() end, { desc = "[T]hemes" })
  --     map("n", "<leader>ahh", function() MiniExtra.pickers.hl_groups() end, { desc = "[H]ightlights" })
  --     map("n", "<leader>ahk", function() MiniExtra.pickers.keymaps() end, { desc = "[K]eymaps" })
  --     map("n", "<leader>aht", function() MiniPick.builtin.help() end, { desc = "[T]ags" })
  --     map(
  --       "n",
  --       "<leader>as",
  --       function()
  --         MiniPick.builtin.files(nil, { source = { cwd = vim.fn.expand("$HOME") .. "/repos/nikbrunner/dots" } })
  --       end,
  --       { desc = "[S]ettings (Dots)" }
  --     )
  --
  --     -- Workspace
  --     map("n", "<leader>wd", MiniPick.registry.frecency, { desc = "[D]ocument" })
  --     map(
  --       "n",
  --       "<leader>wr",
  --       function() MiniExtra.pickers.oldfiles({ current_dir = true }) end,
  --       { desc = "[R]ecent Documents" }
  --     )
  --     map("n", "<leader>wt", function() MiniPick.builtin.grep_live() end, { desc = "[T]ext" })
  --     map(
  --       "n",
  --       "<leader>ww",
  --       function() MiniPick.builtin.grep({ pattern = vim.fn.expand("<cword>") }) end,
  --       { desc = "[W]ord" }
  --     )
  --     map("n", "<leader>wm", MiniPick.registry.git_changed, { desc = "[M]odified Documents" })
  --     map("n", "<leader>wc", function() MiniExtra.pickers.git_hunks() end, { desc = "[C]hanges" })
  --     map(
  --       "n",
  --       "<leader>ws",
  --       function() MiniExtra.pickers.lsp({ scope = "workspace_symbol" }) end,
  --       { desc = "[S]ymbols" }
  --     )
  --     map("n", "<leader>wvb", function() MiniExtra.pickers.git_branches() end, { desc = "[B]ranches" })
  --     map("n", "<leader>wvh", function() MiniExtra.pickers.git_commits() end, { desc = "[H]istory" })
  --     map("n", "<leader>wj", function() MiniExtra.pickers.list({ scope = "jump" }) end, { desc = "[J]umps" })
  --     map("n", "<leader>wp", function() MiniExtra.pickers.diagnostic() end, { desc = "[P]roblems" })
  --
  --     -- Document
  --     map("n", "<leader>dt", function() MiniExtra.pickers.buf_lines({ scope = "current" }) end, { desc = "[T]ext" })
  --     map(
  --       "n",
  --       "<leader>ds",
  --       function() MiniExtra.pickers.lsp({ scope = "document_symbol" }) end,
  --       { desc = "[S]ymbols" }
  --     )
  --     map(
  --       "n",
  --       "<leader>dp",
  --       function() MiniExtra.pickers.diagnostic({ scope = "current" }) end,
  --       { desc = "[P]roblems" }
  --     )
  --
  --     -- Symbol
  --     map("n", "sr", function() MiniExtra.pickers.lsp({ scope = "references" }) end, { desc = "[R]eferences" })
  --     map("n", "si", function() MiniExtra.pickers.lsp({ scope = "implementation" }) end, { desc = "[I]mplementations" })
  --   end,
  -- },
  -- {
  --   "nvim-mini/mini.files",
  --   version = false,
  --   config = function()
  --     -- ============================================================================
  --     -- MiniFiles Configuration
  --     -- ============================================================================
  --
  --     local MiniFiles = require("mini.files")
  --
  --     MiniFiles.setup({
  --       mappings = {
  --         show_help = "g?",
  --         close = "q",
  --         go_in = "<CR>",
  --         go_in_plus = "<CR>",
  --         go_out = "-",
  --         go_out_plus = "_",
  --         mark_goto = "'",
  --         mark_set = "m",
  --         reset = "<BS>",
  --         reveal_cwd = "@",
  --         synchronize = "=",
  --         trim_left = "<",
  --         trim_right = ">",
  --       },
  --       options = {
  --         use_as_default_explorer = false,
  --       },
  --       windows = {
  --         max_number = 3,
  --         preview = true,
  --         width_focus = 50,
  --         width_nofocus = 25,
  --         width_preview = 65,
  --       },
  --     })
  --
  --     -- Override global winborder for MiniFiles
  --     vim.api.nvim_create_autocmd("User", {
  --       pattern = "MiniFilesWindowOpen",
  --       callback = function(args)
  --         local config = vim.api.nvim_win_get_config(args.data.win_id)
  --         config.border = "single"
  --         vim.api.nvim_win_set_config(args.data.win_id, config)
  --       end,
  --     })
  --
  --     -- Split keymaps
  --     local map_split = function(buf_id, lhs, direction)
  --       local rhs = function()
  --         local cur_target = MiniFiles.get_explorer_state().target_window
  --         local new_target = vim.api.nvim_win_call(cur_target, function()
  --           vim.cmd(direction .. " split")
  --           return vim.api.nvim_get_current_win()
  --         end)
  --         MiniFiles.set_target_window(new_target)
  --         MiniFiles.go_in({ close_on_file = true })
  --       end
  --       local desc = "Split " .. direction
  --       vim.keymap.set("n", lhs, rhs, { buffer = buf_id, desc = desc })
  --     end
  --
  --     vim.api.nvim_create_autocmd("User", {
  --       pattern = "MiniFilesBufferCreate",
  --       callback = function(args)
  --         local buf_id = args.data.buf_id
  --         map_split(buf_id, "<C-v>", "belowright vertical")
  --         map_split(buf_id, "<C-s>", "belowright horizontal")
  --         map_split(buf_id, "<C-t>", "tab")
  --       end,
  --     })
  --
  --     -- LSP rename integration with Snacks
  --     vim.api.nvim_create_autocmd("User", {
  --       pattern = "MiniFilesActionRename",
  --       callback = function(event) Snacks.rename.on_rename_file(event.data.from, event.data.to) end,
  --     })
  --
  --     -- Path operations
  --     local yank_path = function()
  --       local path = (MiniFiles.get_fs_entry() or {}).path
  --       if path == nil then return vim.notify("Cursor is not on valid entry") end
  --       vim.fn.setreg(vim.v.register, path)
  --       vim.notify("Copied: " .. path, vim.log.levels.INFO)
  --     end
  --
  --     local ui_open = function()
  --       local entry = MiniFiles.get_fs_entry()
  --       if entry then vim.ui.open(entry.path) end
  --     end
  --
  --     -- Yank path variants
  --     local yank_filename = function()
  --       local entry = MiniFiles.get_fs_entry()
  --       if entry then
  --         local name = vim.fn.fnamemodify(entry.path, ":t")
  --         vim.fn.setreg("+", name)
  --         vim.notify("Copied filename: " .. name, vim.log.levels.INFO)
  --       end
  --     end
  --
  --     local yank_relative_path = function()
  --       local entry = MiniFiles.get_fs_entry()
  --       if entry then
  --         local relative_path = vim.fn.fnamemodify(entry.path, ":~:.")
  --         vim.fn.setreg("+", relative_path)
  --         vim.notify("Copied relative path: " .. relative_path, vim.log.levels.INFO)
  --       end
  --     end
  --
  --     local yank_path_from_home = function()
  --       local entry = MiniFiles.get_fs_entry()
  --       if entry then
  --         local path_from_home = vim.fn.fnamemodify(entry.path, ":~")
  --         vim.fn.setreg("+", path_from_home)
  --         vim.notify("Copied path from home: " .. path_from_home, vim.log.levels.INFO)
  --       end
  --     end
  --
  --     local yank_absolute_path = function()
  --       local entry = MiniFiles.get_fs_entry()
  --       if entry then
  --         vim.fn.setreg("+", entry.path)
  --         vim.notify("Copied absolute path: " .. entry.path, vim.log.levels.INFO)
  --       end
  --     end
  --
  --     -- Buffer-local keymaps for MiniFiles
  --     vim.api.nvim_create_autocmd("User", {
  --       pattern = "MiniFilesBufferCreate",
  --       callback = function(args)
  --         local bufid = args.data.buf_id
  --         local map = vim.keymap.set
  --
  --         local function setBranch(path) MiniFiles.set_branch({ vim.fn.expand(path) }) end
  --
  --           -- stylua: ignore start
  --           -- Path operations
  --           map("n", "gx", ui_open, { buffer = bufid, desc = "OS open" })
  --           map("n", "gy", yank_path, { buffer = bufid, desc = "Yank path" })
  --
  --           -- Yank path variants
  --           map("n", "<leader>yn", yank_filename, { buffer = bufid, desc = "Yank filename" })
  --           map("n", "<leader>yr", yank_relative_path, { buffer = bufid, desc = "Yank relative path" })
  --           map("n", "<leader>yh", yank_path_from_home, { buffer = bufid, desc = "Yank path from home" })
  --           map("n", "<leader>ya", yank_absolute_path, { buffer = bufid, desc = "Yank absolute path" })
  --
  --           -- Bookmark navigation (g prefix)
  --           map("n", "g.", function() setBranch(vim.fn.getcwd()) end, { buffer = bufid, desc = "Current working directory" })
  --           map("n", "gh", function() setBranch("$HOME/") end, { buffer = bufid, desc = "Home", nowait = true })
  --           map("n", "gc", function() setBranch("$HOME/.config") end, { buffer = bufid, desc = "Config", nowait = true })
  --           map("n", "gr", function() setBranch("$HOME/repos") end, { buffer = bufid, desc = "Repos", nowait = true })
  --           map("n", "gl", function() setBranch("$HOME/.local/share/nvim/lazy") end, { buffer = bufid, desc = "Lazy Packages", nowait = true })
  --
  --           -- Project bookmarks (g + number)
  --           map("n", "g0", function() setBranch("$HOME/repos/nikbrunner/dots") end, { buffer = bufid, desc = "nbr - dots" })
  --           map("n", "g1", function() setBranch("$HOME/repos/nikbrunner/notes") end, { buffer = bufid, desc = "nbr - notes" })
  --           map("n", "g2", function() setBranch("$HOME/repos/nikbrunner/dcd-notes") end, { buffer = bufid, desc = "DCD - Notes" })
  --           map("n", "g4", function() setBranch("$HOME/repos/black-atom-industries/core") end, { buffer = bufid, desc = "Black Atom - core" })
  --           map("n", "g5", function() setBranch("$HOME/repos/black-atom-industries/nvim") end, { buffer = bufid, desc = "Black Atom - nvim" })
  --           map("n", "g6", function() setBranch("$HOME/repos/black-atom-industries/radar.nvim") end, { buffer = bufid, desc = "Black Atom - radar.nvim" })
  --           map("n", "g7", function() setBranch("$HOME/repos/nikbrunner/nbr.haus") end, { buffer = bufid, desc = "nikbrunner - nbr.haus" })
  --           map("n", "g8", function() setBranch("$HOME/repos/nikbrunner/koyo") end, { buffer = bufid, desc = "nikbrunner - koyo" })
  --           map("n", "g9", function() setBranch("$HOME/repos/dealercenter-digital/bc-desktop-client") end, { buffer = bufid, desc = "DCD - BC Desktop Client" })
  --
  --           -- Picker in MiniFiles directory
  --           map("n", "<leader><leader>", function()
  --               local current_dir = vim.fn.fnamemodify(MiniFiles.get_fs_entry().path, ":h")
  --               MiniFiles.close()
  --               require("mini.pick").builtin.files(nil, { source = { cwd = current_dir }})
  --           end, { buffer = bufid, desc = "Find files in current directory" })
  --         -- stylua: ignore end
  --       end,
  --     })
  --
  --     -- Global keymaps
  --     local map = vim.keymap.set
  --     -- map("n", "-", function() MiniFiles.open(vim.api.nvim_buf_get_name(0)) end, { desc = "[E]xplorer" })
  --     -- map("n", "_", function() MiniFiles.open(vim.fn.getcwd()) end, { desc = "[E]xplorer (cwd)" })
  --     map("n", "<leader>ee", function() MiniFiles.open(vim.api.nvim_buf_get_name(0)) end, { desc = "[E]xplorer" })
  --   end,
  -- },
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
          update_n_lines = 500,
        },
        custom_surroundings = {
          tag_name_only = {
            input = { "<(%w-)%f[^<%w][^<>]->.-</%1>", "^<()%w+().*</()%w+()>$" },
            output = function()
              local tag_name = require("mini.surround").user_input("Tag name (excluding attributes)")
              if tag_name == nil then return nil end
              return { left = tag_name, right = tag_name }
            end,
          },
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
          -- ["?"] = false,
          -- 				["/"] = ai.gen_spec.user_prompt(),
          -- 				["%"] = function() -- Entire file
          -- 					local from = { line = 1, col = 1 }
          -- 					local to = {
          -- 						line = vim.fn.line("$"),
          -- 						col = math.max(vim.fn.getline("$"):len(), 1),
          -- 					}
          -- 					return { from = from, to = to }
          -- 				end,
          -- 				a = ai.gen_spec.treesitter({ a = "@parameter.outer", i = "@parameter.inner" }),
          -- 				c = ai.gen_spec.treesitter({ a = "@comment.outer", i = "@comment.inner" }),
          -- 				f = ai.gen_spec.treesitter({ a = "@function.outer", i = "@function.inner" }),
          -- 				s = { -- Single words in different cases (camelCase, snake_case, etc.)
          -- 					{
          -- 						"%u[%l%d]+%f[^%l%d]",
          -- 						"%f[^%s%p][%l%d]+%f[^%l%d]",
          -- 						"^[%l%d]+%f[^%l%d]",
          -- 						"%f[^%s%p][%a%d]+%f[^%a%d]",
          -- 						"^[%a%d]+%f[^%a%d]",
          -- 					},
          -- 					"^().*()$",
          -- 				},
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
      mappings = {
        ["`"] = { neigh_pattern = "[^\\`]." }, -- Prevent 4th backtick (https://github.com/echasnovski/mini.nvim/issues/31#issuecomment-2151599842)
      },
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

            if desc then
              return {
                mode = "n",
                keys = string.format("`%s", key),
                desc = desc,
              }
            end
          end)
          :totable()
      end

      -- Clues for recorded macros.
      local function macro_clues()
        local res = {}
        for _, register in ipairs(vim.split("abcdefghijklmnopqrstuvwxyz", "")) do
          local keys = string.format('"%s', register)
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
          { mode = "n", keys = '"' },
          { mode = "x", keys = '"' },
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
          { mode = "n", keys = "<leader>s", desc = "+search" },
          { mode = "n", keys = "<leader>t", desc = "+terminal" },
          { mode = "n", keys = "<leader>r", desc = "+repl" },
          { mode = "n", keys = "<leader>l", desc = "+lsp" },
          { mode = "n", keys = "<leader>n", desc = "+notes" },
          { mode = "n", keys = "<leader>g", desc = "+git" },
          { mode = "n", keys = "<leader>p", desc = "+plugins" },
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
  -- {
  --   "nvim-mini/mini.nvim",
  --   version = false,
  --   lazy = false,
  --   config = function()
  --     M.visits()
  --     M.extra()
  --     M.pick()
  --     M.files()
  --     -- M.clue()
  --     -- M.git()
  --     -- M.diff()
  --     -- M.ai()
  --     -- M.statusline()
  --     M.icons()
  --     -- M.surround()
  --     -- M.test()
  --     -- M.sessions()
  --     -- M.snippets()
  --
  --     -- Start LSP server to show snippets in completion
  --     -- require("mini.snippets").start_lsp_server()
  --
  --     -- M.hues()
  --   end,
  -- },
}

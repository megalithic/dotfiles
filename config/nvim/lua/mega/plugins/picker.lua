if vim.g.picker ~= "fzf" then return {} end
--- Require when an exported method is called.
---
--- Creates a new function. Cannot be used to compare functions,
--- set new values, etc. Only useful for waiting to do the require until you actually
--- call the code.
---
--- ```lua
--- -- This is not loaded yet
--- local lazy_mod = lazy.require_on_exported_call('my_module')
--- local lazy_func = lazy_mod.exported_func
---
--- -- ... some time later
--- lazy_func(42)  -- <- Only loads the module now
---
--- ```
---@param require_path string
---@return table<string, fun(...): any>
local function reqcall(require_path)
  return setmetatable({}, {
    __index = function(_, k)
      return function(...) return require(require_path)[k](...) end
    end,
  })
end

local fn, env = vim.fn, vim.env
local icons = mega.icons
local prompt = icons.misc.telescope .. "  "

local fzf_lua = reqcall("fzf-lua") ---@module 'fzf-lua'
------------------------------------------------------------------------------------------------------------------------
-- FZF-LUA HELPERS
------------------------------------------------------------------------------------------------------------------------
local function title(str, icon, icon_hl)
  return { { " " }, { (icon or ""), icon_hl or "DevIconDefault" }, { " " }, { str, "Bold" }, { " " } }
end

local file_picker = function(cwd) fzf_lua.files({ cwd = cwd }) end

local function git_files_cwd_aware(opts)
  opts = opts or {}
  local fzf = require("fzf-lua")
  -- git_root() will warn us if we're not inside a git repo
  -- so we don't have to add another warning here, if
  -- you want to avoid the error message change it to:
  -- local git_root = fzf_lua.path.git_root(opts, true)
  local git_root = fzf.path.git_root(opts)
  if not git_root then return fzf.files(opts) end
  local relative = fzf.path.relative(vim.loop.cwd(), git_root)
  opts.fzf_opts = { ["--query"] = git_root ~= relative and relative or nil }
  return fzf.git_files(opts)
end

-- local function list_sessions()
--   local fzf = require("fzf-lua")
--   local ok, persisted = mega.pcall(require, "persisted")
--   if not ok then return end
--   local sessions = persisted.list()
--   fzf.fzf_exec(
--     vim.tbl_map(function(s) return s.name end, sessions),
--     dropdown({
--       winopts = { title = format_title("Sessions", ""), height = 0.33, row = 0.5 },
--       previewer = false,
--       actions = {
--         ["default"] = function(selected)
--           local session = vim.tbl_filter(function(s) return s.name == selected[1] end, sessions)[1]
--           if not session then return end
--           persisted.load({ session = session.file_path })
--         end,
--         ["ctrl-d"] = {
--           function(selected)
--             local session = vim.iter(sessions):find(function(s) return s.name == selected[1] end)
--             if not session then return end
--             fn.delete(vim.fn.expand(session.file_path))
--           end,
--           fzf.actions.resume,
--         },
--       },
--     })
--   )
-- end

local function ivy(opts, ...)
  opts = opts or { winopts = {} }
  return vim.tbl_deep_extend("force", {
    prompt = prompt,
    fzf_opts = { ["--layout"] = "reverse" },
    winopts = {
      title_pos = opts.winopts.title and "center" or nil,
      height = 0.35,
      width = 1.00,
      row = 0.94,
      col = 1,
      border = { " ", " ", " ", " ", " ", " ", " ", " " },
      preview = {
        layout = "flex",
        flip_columns = 130,
        scrollbar = "float",
        scrolloff = "-1",
        scrollchars = { "█", "░" },
      },
    },
  }, opts, ...)
end

local function dropdown(opts, ...)
  opts = opts or { winopts = {} }

  return vim.tbl_deep_extend("force", {
    prompt = prompt,
    fzf_opts = { ["--layout"] = "reverse" },
    winopts = {
      title_pos = (opts.winopts and opts.winopts.title) and "center" or nil,
      height = 0.70,
      width = 0.45,
      row = 0.1,
      col = 0.5,
      preview = { hidden = "hidden", layout = "vertical", vertical = "up:50%" },
    },
  }, opts, ...)
end

local function cursor_dropdown(opts)
  return dropdown({
    winopts = {
      row = 1,
      relative = "cursor",
      height = 0.33,
      width = 0.25,
    },
  }, opts)
end

-- if vim.g.picker == "fzf" then
--   mega.augroup("FzfStartup", {
--     {
--       event = { "VimEnter" },
--       pattern = { "*" },
--       once = true,
--       command = function(args)
--         if not vim.g.started_by_firenvim then
--           -- Open file browser if argument is a folder
--           -- REF: https://github.com/protiumx/.dotfiles/blob/main/stow/nvim/.config/nvim/lua/config/telescope.lua#L50
--           local fzf = require("fzf-lua")
--           local arg = vim.api.nvim_eval("argv(0)")
--           if arg and (vim.fn.isdirectory(arg) ~= 0 or arg == "") then
--             file_picker(dropdown({
--               -- actions = {
--               --   files = {
--               --     ["default"] = fzf.actions.file_edit,
--               --   },
--               -- },
--             }))
--           end
--         end
--       end,
--     },
--   })
-- end

return {
  {
    "ibhagwan/fzf-lua",
    cmd = "FzfLua",
    enabled = vim.g.picker == "fzf",
    dependencies = { "nvim-tree/nvim-web-devicons" },
    keys = {
      { "<c-p>", git_files_cwd_aware, desc = "find files" },
      { "<leader>fa", "<Cmd>FzfLua<CR>", desc = "builtins" },
      { "<leader>ff", file_picker, desc = "find files" },
      { "<leader>fo", fzf_lua.oldfiles, desc = "oldfiles" },
      { "<leader>fr", fzf_lua.resume, desc = "resume picker" },
      { "<leader>fvh", fzf_lua.highlights, desc = "highlights" },
      { "<leader>fvk", fzf_lua.keymaps, desc = "keymaps" },
      { "<leader>fle", fzf_lua.diagnostics_workspace, desc = "workspace diagnostics" },
      { "<leader>fld", fzf_lua.lsp_document_symbols, desc = "document symbols" },
      { "<leader>fls", fzf_lua.lsp_live_workspace_symbols, desc = "workspace symbols" },
      { "<leader>f?", fzf_lua.help_tags, desc = "help" },
      { "<leader>fh", fzf_lua.oldfiles, desc = "Most (f)recently used files" },
      { "<leader>fgb", fzf_lua.git_branches, desc = "branches" },
      { "<leader>fgc", fzf_lua.git_commits, desc = "commits" },
      { "<leader>fgB", fzf_lua.git_bcommits, desc = "buffer commits" },
      { "<leader>fb", fzf_lua.buffers, desc = "buffers" },
      -- { "<leader>a", function(cwd) fzf_lua.live_grep_glob({ search = "hi" }) end, desc = "live grep" },
      { "<leader>a", fzf_lua.live_grep_glob, desc = "live grep" },
      { "<leader>A", fzf_lua.grep_cword, desc = "grep (under cursor)" },
      { "<leader>A", fzf_lua.grep_visual, desc = "grep (visual selection)", mode = "v" },
      { "<leader>fva", fzf_lua.autocmds, desc = "autocommands" },
      { "<localleader>p", fzf_lua.registers, desc = "Registers" },
      { "<leader>fd", function() file_picker(vim.env.DOTFILES) end, desc = "dotfiles" },
      { "<leader>fc", function() file_picker(vim.g.vim_dir) end, desc = "nvim config" },
      { "<leader>fO", function() file_picker(env.SYNC_DIR .. "/notes/org") end, desc = "org files" },
      { "<leader>fN", function() file_picker(env.SYNC_DIR .. "/notes/neorg") end, desc = "norg files" },
    },
    config = function()
      local lsp_kind = require("lspkind")
      local fzf = require("fzf-lua")

      local function hl_match(t)
        for _, h in ipairs(t) do
          local ok, hl = pcall(vim.api.nvim_get_hl_by_name, h, true)
          -- must have at least bg or fg, otherwise this returns
          -- succesffully for cleared highlights (on colorscheme switch)
          if ok and (hl.foreground or hl.background) then return h end
        end
      end

      fzf.setup({
        fzf_opts = {
          ["--info"] = "default", -- hidden OR inline:⏐
          ["--reverse"] = false,
          ["--layout"] = "reverse", -- "default" or "reverse"
          ["--scrollbar"] = "▓",
          ["--ellipsis"] = icons.misc.ellipsis,
        },
        fzf_colors = {
          ["fg"] = { "fg", "TelescopeNormal" },
          ["fg+"] = { "fg", "TelescopeNormal" },
          ["bg"] = { "bg", "TelescopeNormal" },
          ["bg+"] = { "bg", hl_match({ "CursorLine" }) },
          ["hl"] = { "fg", hl_match({ "Directory" }) },
          ["hl+"] = { "fg", "CmpItemKindVariable", "italic" },
          ["info"] = { "fg", hl_match({ "WarningMsg" }) },
          ["prompt"] = { "fg", "Orange", "italic" },
          ["pointer"] = { "fg", "DiagnosticError" },
          ["marker"] = { "fg", "DiagnosticError" },
          ["spinner"] = { "fg", "Label" },
          ["header"] = { "fg", "TelescopePrompt" },
          ["border"] = { "fg", "TelescopeBorder" },
          ["gutter"] = { "bg", "TelescopeSelectionCaret" },
          ["separator"] = { "fg", "Comment" },
        },
        border = mega.get_border(),
        previewers = {
          builtin = {
            toggle_behavior = "extend",
            syntax_limit_l = 0, -- syntax limit (lines), 0=nolimit
            syntax_limit_b = 1024 * 1024, -- syntax limit (bytes), 0=nolimit
            limit_b = 1024 * 1024 * 10, -- preview limit (bytes), 0=nolimit
          },
        },
        winopts = {
          title_pos = nil,
          height = 0.35,
          width = 1.00,
          row = 0.94,
          col = 1,
          border = { " ", " ", " ", " ", " ", " ", " ", " " },
          hl = { border = "PickerBorder" },
          preview = {
            layout = "flex",
            flip_columns = 130,
            scrollbar = "float",
            scrolloff = "-1",
            scrollchars = { "█", "░" },
          },
        },
        keymap = {
          builtin = {
            ["<c-/>"] = "toggle-help",
            ["<c-e>"] = "toggle-preview",
            ["<c-=>"] = "toggle-fullscreen",
            ["<c-f>"] = "preview-page-down",
            ["<c-b>"] = "preview-page-up",
          },
          fzf = {
            ["esc"] = "abort",
          },
        },
        actions = {
          files = {
            ["ctrl-o"] = fzf.actions.file_edit_or_qf,
            ["ctrl-x"] = fzf.actions.arg_add,
            ["ctrl-g"] = fzf.actions.arg_add,
            ["ctrl-s"] = fzf.actions.file_split,
            ["default"] = fzf.actions.file_vsplit,
            ["ctrl-t"] = fzf.actions.file_tabedit,
            ["ctrl-q"] = fzf.actions.file_sel_to_qf,
            ["alt-q"] = fzf.actions.file_sel_to_ll,
          },
          grep = {
            ["ctrl-o"] = fzf.actions.file_edit_or_qf,
            ["ctrl-l"] = fzf.actions.arg_add,
            ["ctrl-s"] = fzf.actions.file_split,
            ["default"] = fzf.actions.file_vsplit,
            ["ctrl-t"] = fzf.actions.file_tabedit,
            ["ctrl-q"] = fzf.actions.file_sel_to_qf,
            ["alt-q"] = fzf.actions.file_sel_to_ll,
            ["ctrl-g"] = "",
            ["ctrl-r"] = fzf.actions.grep_lgrep,
          },
        },
        highlights = {
          prompt = prompt,
          winopts = { title = title("Highlights") },
        },
        helptags = {
          prompt = prompt,
          winopts = { title = title("Help", "󰋖") },
        },
        oldfiles = dropdown({
          cwd_only = true,
          winopts = { title = title("History", "") },
        }),
        files = {
          multiprocess = true,
          prompt = prompt,
          winopts = { title = title("Files", "") },
          -- previewer = "builtin",
          -- action = { ["ctrl-r"] = fzf.actions.arg_add },
        },
        buffers = dropdown({
          fzf_opts = { ["--delimiter"] = "' '", ["--with-nth"] = "-1.." },
          winopts = { title = title("Buffers", "󰈙") },
        }),
        keymaps = dropdown({
          winopts = { title = title("Keymaps", ""), width = 0.7 },
        }),
        registers = cursor_dropdown({
          winopts = { title = title("Registers", ""), width = 0.6 },
        }),
        grep = {
          prompt = " ",
          winopts = { title = title("Grep", "󰈭") },
          rg_opts = "--hidden --column --line-number --no-ignore-vcs --no-heading --color=always --smart-case -g '!.git'",
          rg_glob = true, -- enable glob parsing by default to all
          glob_flag = "--iglob", -- for case sensitive globs use '--glob'
          glob_separator = "%s%-%-", -- query separator pattern (lua): ' --'
          -- previewer = "builtin",
          -- fzf_opts = {
          --   ["--keep-right"] = "",
          -- },
        },
        lsp = {
          cwd_only = true,
          symbols = {
            symbol_style = 1,
            symbol_icons = lsp_kind.symbols,
            symbol_hl = function(s) return mega.colors.lsp[s] end,
          },
          code_actions = cursor_dropdown({
            winopts = { title = title("Code Actions", "", "@type") },
          }),
        },
        jumps = dropdown({
          winopts = { title = title("Jumps", ""), preview = { hidden = "nohidden" } },
        }),
        changes = dropdown({
          prompt = "",
          winopts = { title = title("Changes", "⟳"), preview = { hidden = "nohidden" } },
        }),
        diagnostics = dropdown({
          winopts = { title = title("Diagnostics", "", "DiagnosticError") },
        }),
        git = {
          files = dropdown({
            path_shorten = false, -- this doesn't use any clever strategy unlike telescope so is somewhat useless
            cmd = "git ls-files --others --cached --exclude-standard",
            winopts = { title = title("Git Files", "") },
          }),
          branches = dropdown({
            winopts = { title = title("Branches", ""), height = 0.3, row = 0.4 },
          }),
          status = {
            prompt = "",
            preview_pager = "delta --width=$FZF_PREVIEW_COLUMNS",
            winopts = { title = title("Git Status", "") },
          },
          bcommits = {
            prompt = "",
            preview_pager = "delta --width=$FZF_PREVIEW_COLUMNS",
            winopts = { title = title("", "Buffer Commits") },
          },
          commits = {
            prompt = "",
            preview_pager = "delta --width=$FZF_PREVIEW_COLUMNS",
            winopts = { title = title("", "Commits") },
          },
          icons = {
            ["M"] = { icon = icons.git.mod, color = "yellow" },
            ["D"] = { icon = icons.git.remove, color = "red" },
            ["A"] = { icon = icons.git.add, color = "green" },
            ["R"] = { icon = icons.git.rename, color = "yellow" },
            ["C"] = { icon = icons.git.mod, color = "yellow" },
            ["T"] = { icon = icons.git.mod, color = "magenta" },
            ["?"] = { icon = "?", color = "magenta" },
          },
        },
      })

      fzf.register_ui_select(dropdown({
        winopts = { title = title("Select one of:"), height = 0.33, row = 0.5 },
      }))
    end,
  },
}

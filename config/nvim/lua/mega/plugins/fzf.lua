-- REFs:
--
-- https://github.com/akinsho/dotfiles/blob/main/.config/nvim/lua/as/plugins/picker.lua
local M = {
  "ibhagwan/fzf-lua",
  cmd = { "FzfLua" },
  enabled = vim.g.picker == "fzf",
  dependencies = {
    "vijaymarupudi/nvim-fzf",
    "nvim-tree/nvim-web-devicons",
    {
      "junegunn/fzf",
      init = function()
        vim.g.fzf_commands_expect = "enter"
        vim.g.fzf_layout = {
          window = {
            width = 1.0,
            height = 0.4,
            yoffset = 1,
            highlight = "Normal",
          },
        }
        vim.g.fzf_colors = {
          fg = { "fg", "TelescopeNormal" },
          bg = { "bg", "TelescopeNormal" },
          hl = { "fg", "Green" },
          ["fg+"] = { "fg", "CursorLine", "CursorColumn", "Normal" },
          ["bg+"] = { "bg", "CursorLine", "CursorColumn" },
          ["hl+"] = { "fg", "Cyan" },
          info = { "fg", "Aqua" },
          prompt = { "fg", "Orange" },
          pointer = { "fg", "Blue" },
          marker = { "fg", "Yellow" },
          spinner = { "fg", "Yellow" },
          header = { "fg", "Grey" },
          border = { "fg", "TelescopeBorder" },
        }
      end,
    },
  },
  keys = {
    { "<leader>ff", "<cmd>FzfLua files<cr>", desc = "fzf: files" },
    { "<leader>a", "<cmd>FzfLua live_grep_glob exec_empty_query=true<cr>", desc = "fzf: live grep" },
    { "<leader>A", "<cmd>FzfLua grep_cword<cr>", desc = "fzf: grep cursor" },
    { "<leader>A", "<cmd>FzfLua grep_visual<cr>", desc = "fzf: grep selection", mode = "v" },
    { "<leader>fb", "<cmd>FzfLua buffers<cr>", desc = "fzf: buffers" },
    { "<leader>fo", "<cmd>FzfLua oldfiles<cr>", desc = "fzf: oldfiles/history/mru" },
    -- { "<C-u>", function() require("fzf-lua.win").preview_scroll(-1) end, desc = "fzf: scroll preview up" },
    -- { "<C-d>", function() require("fzf-lua.win").preview_scroll(1) end, desc = "fzf: scroll preview down" },
  },
}

function M.config()
  local res, fzf_lua = pcall(require, "fzf-lua")
  if not res then return end

  -- local img_prev_bin = vim.fn.executable("ueberzug") == 1 and { "ueberzug" }
  local img_prev_bin = vim.fn.executable("preview") == 1 and { "preview" }
    or vim.fn.executable("term-image") == 1 and { "term-image" }
    or vim.fn.executable("chafa") == 1 and { "chafa" }
    or vim.fn.executable("viu") == 1 and { "viu", "-b" }
    or { "catimg" }
    or { "kitty", "+kitten", "icat" }

  -- return first matching highlight or nil
  local function hl_match(t)
    for _, h in ipairs(t) do
      local ok, hl = pcall(vim.api.nvim_get_hl_by_name, h, true)
      -- must have at least bg or fg, otherwise this returns
      -- succesffully for cleared highlights (on colorscheme switch)
      if ok and (hl.foreground or hl.background) then return h end
    end
  end

  local fzf_colors = function(opts)
    local colors = {
      ["fg"] = { "fg", "TelescopeNormal" },
      ["bg"] = { "bg", "TelescopeNormal" },
      ["hl"] = { "fg", hl_match({ "Directory" }) },
      ["fg+"] = { "fg", "TelescopeNormal" },
      ["bg+"] = { "bg", hl_match({ "CursorLine" }) },
      ["hl+"] = { "fg", "CmpItemKindVariable" },
      ["info"] = { "fg", hl_match({ "WarningMsg" }) },
      ["prompt"] = { "fg", "Orange" },
      ["pointer"] = { "fg", "DiagnosticError" },
      ["marker"] = { "fg", "DiagnosticError" },
      ["spinner"] = { "fg", "Label" },
      ["header"] = { "fg", "TelescopePrompt" },
      ["border"] = { "fg", "TelescopeBorder" },
      ["gutter"] = { "bg", "TelescopeSelectionCaret" },
    }

    return colors
  end

  -- custom devicons setup file to be loaded when `multiprocess = true`
  -- fzf_lua.config._devicons_setup = "~/.config/nvim/lua/plugins/devicons.lua"

  fzf_lua.setup({
    -- fzf_bin = { opts = { ["--no-separator"] = "" } },
    fzf_opts = {
      ["--border"] = "none",
    },
    fzf_colors = fzf_colors,
    winopts = {
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
      -- on_create        = function()
      --   print("on_create")
      -- end,
    },
    color_icons = false,
    -- winopts_fn = function()
    --   local hl = {
    --     border = hl_match({ "FloatBorder" }),
    --     cursorline = hl_match({ "CursorLine" }),
    --     cursorlinenr = hl_match({ "CursorLineNr" }),
    --   }
    --   return { hl = hl }
    -- end,
    previewers = {
      bat = { theme = "Forest%20Night%20Italic" },
      builtin = {
        ueberzug_scaler = "cover",
        extensions = {
          ["gif"] = img_prev_bin,
          ["png"] = img_prev_bin,
          ["jpg"] = img_prev_bin,
          ["jpeg"] = img_prev_bin,
          ["svg"] = { "chafa" },
        },
        treesitter = { enable = true },
        -- syntax = true, -- preview syntax highlight?
        -- syntax_limit_l = 0, -- syntax limit (lines), 0=nolimit
        -- syntax_limit_b = 1024 * 1024 * 10, -- syntax limit (bytes), 0=nolimit
        -- limit_b = 1024 * 1024 * 50, -- preview limit (bytes), 0=nolimit
      },
    },
    actions = {
      files = {
        ["ctrl-o"] = fzf_lua.actions.file_edit_or_qf,
        ["ctrl-x"] = fzf_lua.actions.arg_add,
        ["ctrl-g"] = fzf_lua.actions.arg_add,
        ["ctrl-s"] = fzf_lua.actions.file_split,
        ["default"] = fzf_lua.actions.file_vsplit,
        ["ctrl-t"] = fzf_lua.actions.file_tabedit,
        ["ctrl-q"] = fzf_lua.actions.file_sel_to_qf,
        ["alt-q"] = fzf_lua.actions.file_sel_to_ll,
      },
      grep = {
        ["ctrl-o"] = fzf_lua.actions.file_edit_or_qf,
        ["ctrl-l"] = fzf_lua.actions.arg_add,
        ["ctrl-s"] = fzf_lua.actions.file_split,
        ["default"] = fzf_lua.actions.file_vsplit,
        ["ctrl-t"] = fzf_lua.actions.file_tabedit,
        ["ctrl-q"] = fzf_lua.actions.file_sel_to_qf,
        ["alt-q"] = fzf_lua.actions.file_sel_to_ll,
        ["ctrl-g"] = fzf_lua.actions.grep_lgrep,
      },
    },
    files = {
      fd_opts = "--color=never --type f --hidden --follow --no-ignore-vcs --strip-cwd-prefix --exclude .git",
      action = { ["ctrl-g"] = fzf_lua.actions.arg_add },
      previewer = "builtin",
    },
    grep = {
      rg_opts = "--hidden --column --line-number --no-ignore-vcs --no-heading --color=always --smart-case -g '!.git'",
      rg_glob = true, -- enable glob parsing by default to all
      glob_flag = "--iglob", -- for case sensitive globs use '--glob'
      glob_separator = "%s%-%-", -- query separator pattern (lua): ' --'
      previewer = "builtin",
    },
    git = {
      status = {
        cmd = "git status -su",
        winopts = {
          preview = { vertical = "down:70%", horizontal = "right:70%" },
        },
        actions = {
          ["ctrl-x"] = { fzf_lua.actions.git_reset, fzf_lua.actions.resume },
        },
        preview_pager = vim.fn.executable("delta") == 1 and "delta --width=$COLUMNS",
      },
      commits = {
        winopts = { preview = { vertical = "down:60%" } },
        preview_pager = vim.fn.executable("delta") == 1 and "delta --width=$COLUMNS",
      },
      bcommits = {
        winopts = { preview = { vertical = "down:60%" } },
        preview_pager = vim.fn.executable("delta") == 1 and "delta --width=$COLUMNS",
      },
      branches = { winopts = {
        preview = { vertical = "down:75%", horizontal = "right:75%" },
      } },
    },
    lsp = { symbols = { path_shorten = 1 } },
    diagnostics = { file_icons = false, icon_padding = " ", path_shorten = 1 },
  })

  -- register fzf-lua as vim.ui.select interface
  if vim.ui then
    fzf_lua.register_ui_select({
      winopts = {
        win_height = 0.30,
        win_width = 0.70,
        win_row = 0.40,
      },
    })
  end

  -- nmap("<c-p>", "<cmd>FzfLua files<cr>", "fzf: find files")
end

return {}

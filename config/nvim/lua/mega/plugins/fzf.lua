local M = {
  "ibhagwan/fzf-lua",
  cmd = { "FzfLua" },
  keys = {
    { "<leader>ff", "<cmd>FzfLua files<cr>", desc = "fzf: files" },
    { "<leader>a", "<cmd>FzfLua live_grep exec_empty_query=true<cr>", desc = "fzf: live grep" },
    { "<leader>A", "<cmd>FzfLua grep_cword<cr>", desc = "fzf: grep cursor" },
    { "<leader>A", "<cmd>FzfLua grep_visual<cr>", desc = "fzf: grep selection", mode = "v" },
    { "<leader>fb", "<cmd>FzfLua buffers<cr>", desc = "fzf: buffers" },
  },
}

function M.config()
  local res, fzf_lua = pcall(require, "fzf-lua")
  if not res then return end

  -- local img_prev_bin = vim.fn.executable("ueberzug") == 1 and { "ueberzug" }
  local img_prev_bin = vim.fn.executable("term-image") == 1 and { "term-image" }
    or vim.fn.executable("chafa") == 1 and { "chafa" }
    or vim.fn.executable("viu") == 1 and { "viu", "-b" }
    or nil
  -- local img_prev_bin = vim.fn.executable("viu") == 1 and { "viu", "-bt" } or { "catimg" }
  -- local img_prev_bin = vim.fn.executable("ueberzug") == 1 and { "ueberzug" }
  --   or { "kitty", "+kitten", "icat" }
  --   or { "viu", "-b", "-t" }
  -- local img_prev_bin = { "kitty", "+kitten", "icat" } or { "viu", "-b", "-t" }
  -- local img_prev_bin = vim.fn.executable("ueberzug") == 1 and { "ueberzug" } or { "viu", "-b" }

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
    local binary = opts and opts.fzf_bin
    local colors = {
      ["fg"] = { "fg", "Normal" },
      ["bg"] = { "bg", "Normal" },
      ["hl"] = { "fg", hl_match({ "NightflyViolet", "Directory" }) },
      ["fg+"] = { "fg", "Normal" },
      ["bg+"] = { "bg", hl_match({ "NightflyVisual", "CursorLine" }) },
      ["hl+"] = { "fg", "CmpItemKindVariable" },
      ["info"] = { "fg", hl_match({ "NightflyPeach", "WarningMsg" }) },
      -- ["prompt"] = { "fg", "SpecialKey" },
      ["pointer"] = { "fg", "DiagnosticError" },
      ["marker"] = { "fg", "DiagnosticError" },
      ["spinner"] = { "fg", "Label" },
      ["header"] = { "fg", "Comment" },
      ["gutter"] = { "bg", "Normal" },
    }
    if binary == "sk" and vim.fn.executable(binary) == 1 then
      colors["matched_bg"] = { "bg", "Normal" }
      colors["current_match_bg"] = { "bg", hl_match({ "NightflyVisual", "CursorLine" }) }
    end
    return colors
  end

  -- custom devicons setup file to be loaded when `multiprocess = true`
  -- fzf_lua.config._devicons_setup = "~/.config/nvim/lua/plugins/devicons.lua"

  fzf_lua.setup({
    -- fzf_bin = { opts = { ["--no-separator"] = "" } },
    fzf_colors = fzf_colors,
    winopts = {
      height = 0.35,
      width = 1.00,
      row = 1,
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
    winopts_fn = function()
      local hl = {
        border = hl_match({ "FloatBorder" }),
        cursorline = hl_match({ "CursorLine" }),
        cursorlinenr = hl_match({ "CursorLineNr" }),
      }
      return { hl = hl }
    end,
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
      },
    },
    actions = {
      files = {
        ["ctrl-o"] = fzf_lua.actions.file_edit_or_qf,
        ["ctrl-l"] = fzf_lua.actions.arg_add,
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
      },
    },
    files = {
      fd_opts = "--color=never --type f --hidden --follow --no-ignore-vcs --strip-cwd-prefix --exclude .git",
      action = { ["ctrl-l"] = fzf_lua.actions.arg_add },
      previewer = "builtin",
    },
    grep = {
      rg_glob = true,
      rg_opts = "--hidden --column --line-number --no-ignore-vcs --no-heading --color=always --smart-case -g '!.git'",
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
  -- if vim.ui then
  --   fzf_lua.register_ui_select({
  --     winopts = {
  --       win_height = 0.30,
  --       win_width = 0.70,
  --       win_row = 0.40,
  --     },
  --   })
  -- end

  -- nmap("<c-p>", "<cmd>FzfLua files<cr>", "fzf: find files")
end

return M

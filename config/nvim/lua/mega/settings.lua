local BORDER_STYLE = "none"
local fmt = string.format

vim.lsp.set_log_level("ERROR")

local border_chars = {
  none = { " ", " ", " ", " ", " ", " ", " ", " " },
  single = { "🭽", "▔", "🭾", "▕", "🭿", "▁", "🭼", "▏" },
  rounded = { "╭", "─", "╮", "│", "╯", "─", "╰", "│" },
}

local telescope_border_chars = {
  none = { "", "", "", "", "", "", "", "" },
  single = { "─", "│", "─", "│", "┌", "┐", "┘", "└" },
  double = { "═", "║", "═", "║", "╔", "╗", "╝", "╚" },
  rounded = { "─", "│", "─", "│", "╭", "╮", "╯", "╰" },
  solid = { " ", " ", " ", " ", " ", " ", " ", " " },
  shadow = { "", "", "", "", "", "", "", "" },
}

local connected_telescope_border_chars = {
  none = { "", "", "", "", "", "", "", "" },
  single = { "─", "│", "─", "│", "┌", "┐", "┤", "├" },
  double = { "═", "║", "═", "║", "╔", "╗", "╣", "╠" },
  rounded = { "─", "│", "─", "│", "╭", "╮", "┤", "├" },
  solid = { " ", " ", " ", " ", " ", " ", " ", " " },
  shadow = { "", "", "", "", "", "", "", "" },
}

local current_border = function(opts)
  opts = opts or { hl = "FloatBorder", style = BORDER_STYLE }
  local hl = opts.hl or "FloatBorder"
  local style = opts.style or BORDER_STYLE
  local border = {}
  for _, char in ipairs(border_chars[style]) do
    table.insert(border, { char, hl })
  end

  return border
end

local uname = vim.uv.os_uname().sysname
local is_macos = uname == "Darwin"
local is_linux = uname == "Linux"
local is_windows = uname == "Windows"
local home_path = os.getenv("HOME")
local icloud_path = vim.env.ICLOUD_DIR
local icloud_documents_path = vim.env.ICLOUD_DOCUMENTS_DIR
local obsidian_vault_path = vim.env.OBSIDIAN_VAULT_DIR
local dotfiles_path = vim.env.DOTS or vim.fn.expand("~/.dotfiles")
local hammerspoon_path = fmt("%s/config/hammerspoon", dotfiles_path)

-- is_remote_dev = vim.trim(vim.fn.system("hostname")) == "seth-dev",
-- is_local_dev = vim.trim(vim.fn.system("hostname")) ~= "seth-dev",

--- @class Settings
--- @field enabled_elixir_ls {"elixirls"|"nextls"|"lexical"}
local M = {
  -- NOTE: char options (https://unicodeplus.com/): ┊│┆ ┊  ▎││ ▏▏│¦┆┊
  indent_scope_char = "│",
  indent_char = "┊",
  virt_column_char = "│",
  border_style = BORDER_STYLE,
  border = current_border(),
  border_chars = border_chars[BORDER_STYLE],
  telescope_border_chars = telescope_border_chars[BORDER_STYLE],
  colorscheme = "megaforest", -- alt: `vim` for default
  default_colorcolumn = "81",
  notifier_enabled = true,
  debug_enabled = false,
  picker = "telescope", -- alt: telescope, fzf_lua
  formatter = "conform", -- alt: null-ls/none-ls, conform
  tree = "neo-tree",
  explorer = "oil", -- alt: dirbuf, oil
  tester = "vim-test", -- alt: neotest, vim-test, quicktest
  gitter = "neogit", -- alt: neogit, fugitive
  snipper = "snippets", -- alt: vsnip, luasnip, snippets (nvim-builtin)
  note_taker = "marksman", -- alt: zk, marksman, markdown_oxide, obsidian
  ai = "", -- alt: minuet, neocodeium, codecompanion
  completer = "cmp", -- alt: cmp, epo
  ts_ignored_langs = {}, -- alt: { "svg", "json", "heex", "jsonc" }
  is_screen_sharing = false,
  enabled_plugins = {
    "abbreviations",
    "megaline",
    "megacolumn",
    "term",
    "lsp",
    "repls",
    "cursorline",
    "colorcolumn",
    "windows",
    "numbers",
    "folds",
    "env",
  },
  disabled_semantic_tokens = { "lua" },
  disabled_lsp_formatters = { "tailwindcss", "html", "ts_ls", "ls_emmet", "zk", "sumneko_lua" },
  ---@format disable
  enabled_elixir_ls = { "", "nextls", "" },
  completion_exclusions = { "elixirls", "", "lexical" },
  formatter_exclusions = { "elixirls", "", "lexical" },
  definition_exclusions = { "elixirls", "", "lexical" },
  references_exclusions = { "elixirls", "", "lexical" },
  diagnostic_exclusions = { "elixirls", "", "lexical", "ts_ls" },
  max_diagnostic_exclusions = { "elixirls", "", "lexical" },
  ---@format enable
  disable_autolint = false,
  disable_autoformat = false,
  disable_autoresize = false,
  enable_signsplaced = false,
  markdown_fenced_languages = {
    "shell=sh",
    "bash=sh",
    "zsh=sh",
    "console=sh",
    "vim",
    "lua",
    "elixir",
    "heex",
    "cpp",
    "sql",
    "python",
    "javascript",
    "typescript",
    "js=javascript",
    "ts=typescript",
    "yaml",
    "json",
  },
  colorizer = {
    filetypes = { "*", "!lazy", "!gitcommit", "!NeogitCommitMessage", "!oil" },
    buftypes = { "*", "!prompt", "!nofile", "!oil" },
    user_default_options = {
      RGB = false, -- #RGB hex codes
      RRGGBB = true, -- #RRGGBB hex codes
      names = false, -- "Name" codes like Blue or blue
      RRGGBBAA = true, -- #RRGGBBAA hex codes
      AARRGGBB = true, -- 0xAARRGGBB hex codes
      rgb_fn = true, -- CSS rgb() and rgba() functions
      hsl_fn = true, -- CSS hsl() and hsla() functions
      -- css = true, -- Enable all CSS features: rgb_fn, hsl_fn, names, RGB, RRGGBB
      css_fn = true, -- Enable all CSS *functions*: rgb_fn, hsl_fn
      sass = { enable = false, parsers = { "css" } }, -- Enable sass colors
      mode = "background", -- Set the display mode.
    },
    -- all the sub-options of filetypes apply to buftypes
  },
  icons = {
    lsp = {
      error = "", -- alts: 󰬌      
      warn = "󰔷", -- alts: 󰬞 󰔷   ▲ 󰔷
      info = "󰖧", -- alts: 󰖧 󱂈 󰋼  󰙎   󰬐 󰰃     ● 󰬐 
      hint = "▫", -- alts:  󰬏 󰰀  󰌶 󰰂 󰰂 󰰁 󰫵 󰋢   
      ok = "✓", -- alts: ✓✓
      clients = "", -- alts:     󱉓 󱡠 󰾂 
    },
    test = {
      passed = "", --alts: 
      failed = "", --alts: 
      running = "",
      skipped = "○",
      unknown = "", -- alts: 
    },
    kind = {
      Array = "",
      Boolean = "",
      Class = "󰠱",
      -- Class = "", -- Class
      Codeium = "",
      Color = "󰏘",
      -- Color = "", -- Color
      Constant = "󰏿",
      -- Constant = "", -- Constant
      Constructor = "",
      -- Constructor = "", -- Constructor
      Enum = "", -- alts: 
      -- Enum = "", -- Enum -- alts: 了
      EnumMember = "", -- alts: 
      -- EnumMember = "", -- EnumMember
      Event = "",
      Field = "󰜢",
      File = "󰈙",
      -- File = "", -- File
      Folder = "󰉋",
      -- Folder = "", -- Folder
      Function = "󰊕",
      Interface = "",
      Key = "",
      Keyword = "󰌋",
      -- Keyword = "", -- Keyword
      Method = "",
      Module = "",
      Namespace = "",
      Null = "󰟢", -- alts: 󰱥󰟢
      Number = "󰎠", -- alts: 
      Object = "",
      -- Operator = "\u{03a8}", -- Operator
      Operator = "󰆕",
      Package = "",
      Property = "󰜢",
      -- Property = "", -- Property
      Reference = "󰈇",
      Snippet = "", -- alts: 
      String = "", -- alts:  󱀍 󰀬 󱌯
      Struct = "󰙅",
      Text = "󰉿",
      TypeParameter = "",
      Unit = "󰑭",
      -- Unit = "", -- Unit
      Value = "󰎠",
      Variable = "󰀫",
      -- Variable = "", -- Variable, alts: 

      -- Text = "",
      -- Method = "",
      -- Function = "",
      -- Constructor = "",
      -- Field = "",
      -- Variable = "",
      -- Class = "",
      -- Interface = "",
      -- Module = "",
      -- Property = "",
      -- Unit = "",
      -- Value = "",
      -- Enum = "",
      -- Keyword = "",
      -- Snippet = "",
      -- Color = "",
      -- File = "",
      -- Reference = "",
      -- Folder = "",
      -- EnumMember = "",
      -- Constant = "",
      -- Struct = "",
      -- Event = "",
      -- Operator = "",
      -- TypeParameter = "",
    },
    separators = {
      thin_block = "│",
      left_thin_block = "▏",
      vert_bottom_half_block = "▄",
      vert_top_half_block = "▀",
      right_block = "🮉",
      right_med_block = "▐",
      light_shade_block = "░",
    },
    misc = {
      formatter = "", -- alts: 󰉼
      clock = "",
      ellipsis = "…",
      lblock = "▌",
      rblock = "▐",
      bug = "", -- alts: 
      question = "",
      lock = "󰌾", -- alts:   
      shaded_lock = "",
      circle = "",
      project = "",
      dashboard = "",
      history = "󰄉",
      comment = "󰅺",
      robot = "󰚩",
      lightbulb = "󰌵",
      file_tree = "󰙅",
      help = "󰋖", -- alts: 󰘥 󰮥 󰮦 󰋗 󰞋 󰋖
      search = "", -- alts: 󰍉
      code = "",
      telescope = "",
      terminal = "", -- alts: 
      gear = "",
      package = "",
      list = "",
      sign_in = "",
      check = "✓", -- alts: ✓
      fire = "",
      note = "󰎛",
      bookmark = "",
      pencil = "󰏫",
      arrow_right = "",
      caret_right = "",
      chevron_right = "",
      double_chevron_right = "»",
      table = "",
      calendar = "",
      fold_open = "",
      fold_close = "",
      hydra = "🐙",
      flames = "󰈸", -- alts: 󱠇󰈸
      vsplit = "◫",
      v_border = "▐ ",
      virtual_text = "◆",
      mode_term = "",
      ln_sep = "ℓ", -- alts: ℓ 
      sep = "⋮",
      perc_sep = "",
      modified = "", -- alts: ∘✿✸✎ ○∘●●∘■ □ ▪ ▫● ◯ ◔ ◕ ◌ ◎ ◦ ◆ ◇ ▪▫◦∘∙⭘
      mode = "",
      vcs = "",
      readonly = "",
      prompt = "",
      markdown = {
        h1 = "◉", -- alts: 󰉫¹◉
        h2 = "◆", -- alts: 󰉬²◆
        h3 = "󱄅", -- alts: 󰉭³✿
        h4 = "⭘", -- alts: 󰉮⁴○⭘
        h5 = "◌", -- alts: 󰉯⁵◇◌
        h6 = "", -- alts: 󰉰⁶
        dash = "",
      },
    },
    git = {
      add = "▕", -- alts:  ▕,▕, ▎, ┃, │, ▌, ▎ 🮉
      change = "▕", -- alts:  ▕ ▎║▎
      mod = "",
      remove = "", -- alts: 
      delete = "🮉", -- alts: ┊▎▎
      topdelete = "🮉",
      changedelete = "🮉",
      untracked = "▕",
      ignore = "",
      rename = "",
      diff = "",
      repo = "",
      symbol = "", -- alts:  
      unstaged = "󰛄",
    },
  },
}

M.apply_abbreviations = function()
  -- vim.cmd.cnoreabbrev("ntl NeotestLast")
  -- vim.cmd.cnoreabbrev("nts NeotestSummary")
  -- vim.cmd.cnoreabbrev("nto NeotestOutput")
end

M.apply = function()
  -- function modified_icon() return vim.bo.modified and M.icons.misc.circle or "" end
  local settings = {
    g = {
      mapleader = ",",
      maplocalleader = " ",
      -- ruby_host_prog = "~/.local/share/mise/installs/ruby/latest",
      bullets_checkbox_markers = " x",
      bullets_outline_levels = { "ROM", "ABC", "rom", "abc", "std-" },
      mkdp_echo_preview_url = 1,
      mkdp_preview_options = {
        maid = {
          theme = "dark",
        },
      },
      mkdp_theme = "dark",
      colorscheme = M.colorscheme,
      default_colorcolumn = M.default_colorcolumn,
      notifier_enabled = M.notifier_enabled,
      debug_enabled = M.debug_enabled,
      picker = M.picker,
      formatter = M.formatter,
      tree = M.tree,
      explorer = M.explorer,
      tester = M.tester,
      gitter = M.gitter,
      ai = M.ai,
      snipper = M.snipper,
      completer = M.completer,
      note_taker = M.note_taker,
      ts_ignored_langs = M.ts_ignored_langs,
      is_screen_sharing = M.is_screen_sharing,
      disable_autolint = M.disable_autolint,
      disable_autoformat = M.disable_autoformat,
      disable_autoresize = M.disable_autoresize,
      markdown_fenced_languages = M.markdown_fenced_languages,
      have_nerd_font = true,

      open_command = is_macos and "open" or "xdg-open",
      is_tmux_popup = vim.env.TMUX_POPUP ~= nil,
      code_path = fmt("%s/code", home_path),
      projects_path = fmt("%s/code", home_path),
      vim_path = fmt("%s/.config/nvim", home_path),
      dotfiles_path = fmt("%s/.dotfiles", home_path),
      nvim_path = fmt("%s/.config/nvim", home_path),
      cache_path = fmt("%s/.cache/nvim", home_path),
      local_state_path = fmt("%s/.local/state/nvim", home_path),
      local_share_path = fmt("%s/.local/share/nvim", home_path),
      db_ui_path = fmt("%s/_sql", icloud_documents_path),
      notes_path = fmt("%s/_notes", icloud_documents_path),
      obsidian_path = fmt("%s/_obsidian", icloud_documents_path),
      zk_path = fmt("%s/_zk", icloud_documents_path),
      org_path = fmt("%s/_org", icloud_documents_path),
      neorg_path = fmt("%s/_org", icloud_documents_path),
      hs_emmy_path = fmt("%s/Spoons/EmmyLua.spoon", hammerspoon_path),
    },
    o = {
      cmdwinheight = 7,
      cmdheight = 1,
      diffopt = "internal,filler,closeoff,linematch:60",
      linebreak = true, -- lines wrap at words rather than random characters
      splitbelow = true,
      splitkeep = "screen",
      splitright = true,
      startofline = true,
      swapfile = false,
      undodir = vim.env.HOME .. "/.vim/undodir",
      undofile = true,
      virtualedit = "block",
      wrapscan = true,
    },
    opt = {
      -- [[ Setting options ]]
      -- See `:help vim.opt`
      -- NOTE: You can change these options as you wish!
      --  For more options, you can see `:help option-list`

      -- Make line numbers default
      number = false,
      -- You can also add relative line numbers, to help with jumping.
      --  Experiment for yourself to see if you like it!
      relativenumber = false,

      -- Enable mouse mode, can be useful for resizing splits for example!
      mouse = "a",

      showbreak = string.format("%s ", string.rep("↪", 1)), -- Make it so that long lines wrap smartly; alts: -> '…', '↳ ', '→','↪ '
      -- Don't show the mode, since it's already in the status line
      showmode = false,
      showcmd = false,

      -- Sync clipboard between OS and Neovim.
      --  Remove this option if you want your OS clipboard to remain independent.
      --  See `:help 'clipboard'`
      clipboard = "unnamedplus",

      -- Enable break indent
      breakindent = true,

      -- Case-insensitive searching UNLESS \C or one or more capital letters in the search term
      ignorecase = true,
      smartcase = true,

      -- Keep signcolumn on by default
      signcolumn = "yes",

      -- Decrease update time
      updatetime = 250,

      -- Decrease mapped sequence wait time
      -- Displays which-key popup sooner
      timeoutlen = 300, -- Configure how new splits should be opened

      -- Sets how neovim will display certain whitespace characters in the editor.
      --  See `:help 'list'`
      --  and `:help 'listchars'`
      list = true,
      listchars = {
        eol = nil,
        tab = "» ", -- alts: »│ │
        nbsp = "␣",
        extends = "›", -- alts: … »
        precedes = "‹", -- alts: … «
        trail = "·", -- alts: • BULLET (U+2022, UTF-8: E2 80 A2)
      },
      formatoptions = vim.opt.formatoptions
        - "a" -- Auto formatting is BAD.
        - "t" -- Don't auto format my code. I got linters for that.
        + "c" -- In general, I like it when comments respect textwidth
        + "q" -- Allow formatting comments w/ gq
        - "o" -- O and o, don't continue comments
        + "r" -- But do continue when pressing enter.
        + "n" -- Indent past the formatlistpat, not underneath it.
        + "j" -- Auto-remove comments if possible.
        - "2", -- I'm not in gradeschool anymore

      fillchars = {
        horiz = "━",
        vert = "▕", -- alternatives │┃
        -- horizdown = '┳',
        -- horizup   = '┻',
        -- vertleft  = '┫',
        -- vertright = '┣',
        -- verthoriz = '╋',
        fold = " ",
        eob = " ", -- suppress ~ at EndOfBuffer
        diff = "╱", -- alts: = ⣿ ░ ─
        msgsep = " ", -- alts: ‾ ─
        foldopen = M.icons.misc.fold_open, -- alts: ▾
        -- foldsep = "│",
        foldsep = " ",
        foldclose = M.icons.misc.fold_close, -- alts: ▸
        stl = " ", -- alts: ─ ⣿ ░ ▐ ▒▓
        stlnc = " ", -- alts: ─
      },

      diffopt = {
        "vertical",
        "iwhite",
        "hiddenoff",
        "foldcolumn:0",
        "context:4",
        "algorithm:histogram",
        "indent-heuristic",
        "linematch:60",
      },

      -- Preview substitutions live, as you type!
      inccommand = "split",

      -- Show which line your cursor is on
      cursorline = true,

      -- Minimal number of screen lines to keep above and below the cursor.
      scrolloff = 10,

      -- Set highlight on search, but clear on pressing <Esc> in normal mode
      hlsearch = true,

      -- Tabline
      tabline = "",
      showtabline = 0,
      guicursor = vim.opt.guicursor + "a:blinkon500-blinkoff100",
    },
  }

  -- apply the above settings
  for scope, ops in pairs(settings) do
    local op_group = vim[scope]
    for op_key, op_value in pairs(ops) do
      op_group[op_key] = op_value
    end
  end

  vim.filetype.add({
    filename = {
      ["~/.dotfiles/config"] = "gitconfig",
      [".env"] = "bash",
      [".eslintrc"] = "jsonc",
      [".gitignore"] = "conf",
      [".prettierrc"] = "jsonc",
      [".tool-versions"] = "conf",
      -- ["Brewfile"] = "ruby",
      -- ["Brewfile.cask"] = "ruby",
      -- ["Brewfile.mas"] = "ruby",
      ["Deskfile"] = "bash",
      ["NEOGIT_COMMIT_EDITMSG"] = "NeogitCommitMessage",
      ["default-gems"] = "conf",
      ["default-node-packages"] = "conf",
      ["default-python-packages"] = "conf",
      ["kitty.conf"] = "kitty",
      ["tool-versions"] = "conf",
      ["tsconfig.json"] = "jsonc",
      id_ed25519 = "pem",
    },
    extension = {
      conf = "conf",
      cts = "typescript",
      eex = "eelixir",
      eslintrc = "jsonc",
      exs = "elixir",
      json = "jsonc",
      keymap = "keymap",
      lexs = "elixir",
      luau = "luau",
      md = "markdown",
      mdx = "markdown",
      mts = "typescript",
      prettierrc = "jsonc",
      typ = "typst",
    },
    pattern = {
      [".*%.conf"] = "conf",
      -- [".*%.env%..*"] = "env",
      [".*%.eslintrc%..*"] = "jsonc",
      [".*%.gradle"] = "groovy",
      [".*%.html.en"] = "html",
      [".*%.jst.eco"] = "jst",
      [".*%.prettierrc%..*"] = "jsonc",
      [".*%.theme"] = "conf",
      [".*env%..*"] = "bash",
      [".*ignore"] = "conf",
      [".nvimrc"] = "lua",
      ["default-*%-packages"] = "conf",
    },
    -- ['.*tmux.*conf$'] = 'tmux',
  })

  M.apply_abbreviations()

  -- NOTE: to use in one of our plugins:
  -- `if not plugin_loaded("plugin_name") then return end`
  function _G.plugin_loaded(plugin)
    if not mega then return false end
    local enabled_plugins = M.enabled_plugins

    if not enabled_plugins then return false end
    if not vim.tbl_contains(enabled_plugins, plugin) then return false end

    return true
  end
end

return M

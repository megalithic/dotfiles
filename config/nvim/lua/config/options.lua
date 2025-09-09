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

local borders = {
  round = { "╭", "─", "╮", "│", "╯", "─", "╰", "│" },
  none = { "", "", "", "", "", "", "", "" },
  empty = { " ", " ", " ", " ", " ", " ", " ", " " },
  blink_empty = { " ", " ", " ", " ", " ", " ", " ", " " },
  inner_thick = { " ", "▄", " ", "▌", " ", "▀", " ", "▐" },
  outer_thick = { "▛", "▀", "▜", "▐", "▟", "▄", "▙", "▌" },
  cmp_items = { "▛", "▀", "▀", " ", "▄", "▄", "▙", "▌" },
  cmp_doc = { "▀", "▀", "▀", " ", "▄", "▄", "▄", "▏" },
  outer_thin = { "🭽", "▔", "🭾", "▕", "🭿", "▁", "🭼", "▏" },
  inner_thin = { " ", "▁", " ", "▏", " ", "▔", " ", "▕" },
  outer_thin_telescope = { "▔", "▕", "▁", "▏", "🭽", "🭾", "🭿", "🭼" },
  outer_thick_telescope = { "▀", "▐", "▄", "▌", "▛", "▜", "▟", "▙" },
  rounded_telescope = { "─", "│", "─", "│", "╭", "╮", "╯", "╰" },
  square = { "┌", "─", "┐", "│", "┘", "─", "└", "│" },
  square_telescope = { "─", "│", "─", "│", "┌", "┐", "┘", "└" },
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

local function get_enabled_elixir_ls()
  local ls = "elixirls"
  if vim.env.ELIXIR_LS ~= nil then ls = vim.env.ELIXIR_LS end
  return { ls }
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
local proton_path = vim.env.PROTON_DIR

--- @class Settings
local M = {
  -- NOTE: char options (https://unicodeplus.com/): ┊│┆ ┊  ▎││ ▏▏│¦┆┊
  indent_scope_char = "│",
  indent_char = "┊",
  virt_column_char = "│",
  border_style = BORDER_STYLE,
  border = current_border(),
  border_chars = border_chars[BORDER_STYLE],
  telescope_border_chars = telescope_border_chars[BORDER_STYLE],
  borders = borders,
  colorscheme = "megaforest", -- alt: megaforest, onedark, bamboo, `vim` for default, forestbones, everforest
  default_colorcolumn = "81",
  notifier_enabled = true,
  debug_enabled = false,
  picker = "telescope", -- alt: telescope, fzf_lua, snacks.pick
  formatter = "conform", -- alt: null-ls/none-ls, conform
  tree = "neo-tree",
  explorer = "oil", -- alt: dirbuf, oil
  tester = "vim-test", -- alt: neotest, vim-test, quicktest
  gitter = "neogit", -- alt: neogit, fugitive
  snipper = "snippets", -- alt: vsnip, luasnip, snippets (nvim-builtin)
  note_taker = "", -- alt: zk, marksman, markdown_oxide, obsidian
  ai = "", -- alt: minuet, neocodeium, codecompanion, supermaven, avante, copilot
  completer = "blink", -- alt: cmp, blink, epo
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
  disabled_semantic_tokens = {
    -- "typescript",
    -- "javascript",
    "lua",
  },
  enabled_inlay_hints = {},
  disabled_lsp_formatters = { "tailwindcss", "html", "ts_ls", "ls_emmet", "zk", "sumneko_lua" },
  enabled_elixir_ls = get_enabled_elixir_ls(), --- opts: {"elixirls", "nextls", "lexical"}
  completion_exclusions = {},
  formatter_exclusions = { "emmylua_ls" },
  definition_exclusions = {},
  references_exclusions = {},
  diagnostic_exclusions = {},
  max_diagnostic_exclusions = {},
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
  treesitter_ignored_langs = {}, -- alt: { "svg", "json", "heex", "jsonc" }
  treesitter_ensure_installed = {
    "bash",
    "c",
    "cpp",
    "css",
    "csv",
    -- "comment", -- too slow still.
    -- "dap_repl",
    "commonlisp",
    "devicetree",
    "dockerfile",
    "diff",
    "elixir",
    "elm",
    "eex",
    "embedded_template",
    "erlang",
    "fish",
    "git_config",
    "git_rebase",
    "gitattributes",
    "gitcommit",
    "gitignore",
    "gleam",
    "go",
    "graphql",
    "heex",
    "html",
    "javascript",
    "jq",
    "jsdoc",
    "json",
    "jsonc",
    "json5",
    "lua",
    "luadoc",
    "luap",
    "kotlin",
    "make",
    "markdown",
    "markdown_inline",
    "nix",
    -- "org",
    "perl",
    "printf",
    "psv",
    "python",
    "query",
    "regex",
    "ruby",
    "rust",
    "scss",
    "scheme",
    "sql",
    "surface",
    -- "teal",
    "terraform",
    "tmux",
    "toml",
    "tsv",
    "tsx",
    "typescript",
    "vim",
    "vimdoc",
    "yaml",
  },
  -- FIXME: still need to get indentions working correctly
  treesitter_branch = "master",
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
  chat = {
    provider = "anthropic.claude",
    api_key = os.getenv("ANTHROPIC_API_KEY"),
    model = "claude-3-5-sonnet-latest",
    system = "Be concise and direct in your responses. Respond without unnecessary explanation.",
    signs = {
      context = "∙",
      highlight = "DiagnosticInfo",
    },
    keymaps = {
      ask = "<leader>c",
      mark = "<leader>m",
    },
  },
  lsp_lookup = {
    elixirls = "ex",
    nextls = "next",
    lua_ls = "lua",
    tailwindcss = "twcss",
    emmet_ls = "em",
    emmet_language_server = "em",
    lexical = "lex",
    postgres_lsp = "pglsp",
  },

  icons = {
    lsp = {

      error = "", -- alts:  󰬌      
      warn = "󰔷", -- alts: 󰬞 󰔷   ▲ 󰔷  󰲉
      info = "", -- alts: 󰖧 󱂈 󰋼  󰙎   󰬐 󰰃     ● 󰬐  ∙  󰌶
      hint = "▫", -- alts:  󰬏 󰰀  󰰂 󰰂 󰰁 󰫵 󰋢    ∴
      ok = "✓", -- alts: ✓✓
      clients = "", -- alts:     󱉓 󱡠 󰾂 
    },
    test = {
      passed = "", --alts: 
      failed = "", --alts: 
      running = "",
      skipped = "○",
      unknown = "", -- alts: 
    },
    vscode = {
      Text = "󰉿 ",
      Method = "󰆧 ",
      Function = "󰊕 ",
      Constructor = " ",
      Field = "󰜢 ",
      Variable = "󰀫 ",
      Class = "󰠱 ",
      Interface = " ",
      Module = " ",
      Property = "󰜢 ",
      Unit = "󰑭 ",
      Value = "󰎠 ",
      Enum = " ",
      Keyword = "󰌋 ",
      Snippet = " ",
      Color = "󰏘 ",
      File = "󰈙 ",
      Reference = "󰈇 ",
      Folder = "󰉋 ",
      EnumMember = " ",
      Constant = "󰏿 ",
      Struct = "󰙅 ",
      Event = " ",
      Operator = "󰆕 ",
      TypeParameter = " ",
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
      buffers = "",
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
      robot = "󰚩", -- alts: 󰭆
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
      ln_sep = "≡", -- alts: ≡ ℓ 
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
      change = "🮉", -- alts:  ▕ ▎║▎ ▀, ▁, ▂, ▃, ▄, ▅, ▆, ▇, █, ▉, ▊, ▋, ▌, ▍, ▎, ▏, ▐
      delete = "█", -- alts: ┊▎▎
      topdelete = "▀",
      changedelete = "▄",
      untracked = "▕",
      mod = "",
      remove = "", -- alts: 
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
      is_screen_sharing = M.is_screen_sharing,
      disable_autolint = M.disable_autolint,
      disable_autoformat = M.disable_autoformat,
      disable_autoresize = M.disable_autoresize,
      -- This is breaking elixir/heex.vim syntax files; not sure why
      -- markdown_fenced_languages = M.markdown_fenced_languages,
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
      python3_host_prog = vim.env.XDG_DATA_HOME .. "/mise/installs/python/latest/bin/python3",
      ruby_host_prog = vim.env.XDG_DATA_HOME .. "/mise/installs/ruby/latest/bin/ruby",
      node_host_prog = vim.env.XDG_DATA_HOME .. "/mise/installs/node/latest/bin/node",
      loaded_node_provider = 0,
      loaded_perl_provider = 0,
      loaded_ruby_provider = 0,
    },
    opt = {
      cmdwinheight = 7,
      cmdheight = 1,
      winborder = BORDER_STYLE,
      linebreak = true, -- lines wrap at words rather than random characters
      splitbelow = true,
      splitkeep = "screen",
      splitright = true,
      whichwrap = vim.opt.whichwrap + "h,l,<,>,[,]",
      startofline = true,
      swapfile = false,
      undodir = vim.env.HOME .. "/.vim/undodir",
      undofile = true,
      virtualedit = "block",
      wrapscan = true,
      redrawtime = 4000,
      -- winbar = "%{%v:lua.require('dropbar').get_dropbar_str()%}",
      -- foldcolumn = "1",
      -- foldlevel = 99,
      -- vim.opt.foldlevelstart = 99
      -- foldmethod = "indent",
      -- foldtext = "v:lua.vim.treesitter.foldtext()",

      -- cia = "kind,abbr,menu",
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

      fillchars = {
        horiz = "━",
        vert = "▕", -- alternatives │┃
        -- horizdown = '┳',
        -- horizup   = '┻',
        -- vertleft  = '┫',
        -- vertright = '┣',
        -- verthoriz = '╋',
        eob = " ", -- suppress ~ at EndOfBuffer
        diff = "╱", -- alts: = ⣿ ░ ─
        msgsep = " ", -- alts: ‾ ─
        fold = " ",
        foldopen = M.icons.misc.fold_open, -- alts: ▾
        -- foldsep = "│",
        foldsep = " ",
        foldclose = M.icons.misc.fold_close, -- alts: ▸
        stl = " ", -- alts: ─ ⣿ ░ ▐ ▒▓
        stlnc = " ", -- alts: ─
      },

      formatoptions = vim.opt.formatoptions
        - "a" -- Auto formatting is BAD.
        - "t" -- Don't auto format my code. I got linters for that.
        + "c" -- In general, I like it when comments respect textwidth
        + "q" -- Allow formatting comments w/ `gq`
        + "w" -- Trailing whitespace indicates a paragraph
        - "o" -- Insert comment leader after hitting `o` or `O`
        + "r" -- Insert comment leader after hitting Enter
        + "n" -- Indent past the formatlistpat, not underneath it.
        + "j" -- Remove comment leader when makes sense (joining lines)
        -- + "2" -- Use the second line's indent vale when indenting (allows indented first line)
        - "2", -- I'm not in gradeschool anymore

      shortmess = vim.opt.shortmess:append({
        I = true, -- No splash screen
        W = true, -- Don't print "written" when editing
        a = true, -- Use abbreviations in messages ([RO] intead of [readonly])
        c = true, -- Do not show ins-completion-menu messages (match 1 of 2)
        F = true, -- Do not print file name when opening a file
        s = true, -- Do not show "Search hit BOTTOM" message
      }),

      suffixesadd = { ".md", ".js", ".ts", ".tsx" }, -- File extensions not required when opening with `gf`
      diffopt = {
        "vertical",
        "iwhite",
        "hiddenoff",
        "foldcolumn:0",
        "context:4",
        "algorithm:histogram",
        "indent-heuristic",
        "linematch:60",
        "internal",
        "filler",
        "closeoff",
      },

      sessionoptions = vim.opt.sessionoptions:remove({ "buffers", "folds" }),

      shada = { "!", "'1000", "<50", "s10", "h" }, -- Increase the shadafile size so that history is longer

      -- Preview substitutions live, as you type!
      inccommand = "split",

      -- Show which line your cursor is on
      cursorline = true,

      -- Minimal number of screen lines to keep above and below the cursor.
      scrolloff = 10,

      -- Set highlight on search, but clear on pressing <Esc> in normal mode
      hlsearch = true,

      -- Tabline
      showtabline = 0,
      guicursor = vim.opt.guicursor + "a:blinkon500-blinkoff100",
      pumheight = 25, -- also controls nvim-cmp completion window height
      path = "**",
      grepprg = "rg --ignore-case --vimgrep",
      grepformat = "%f:%l:%c:%m,%f:%l:%m",
      wildignore = {
        "**/node_modules/**",
        "**/coverage/**",
        "**/.idea/**",
        "**/.git/**",
        "**/.nuxt/**",
      },
    },
  }

  -- apply the above settings
  for scope, opts in pairs(settings) do
    local opt_group = vim[scope]

    for opt_key, opt_value in pairs(opts) do
      opt_group[opt_key] = opt_value
    end
  end

  vim.filetype.add({
    filename = {
      ["~/.dotfiles/config"] = "gitconfig",
      [".env"] = "bash",
      [".eslintrc"] = "jsonc",
      [".eslintrc.json"] = "jsonc",
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
      ["tsconfig*.json"] = "jsonc",
      [".*/%.vscode/.*%.json"] = "jsonc",
      [".*%.gradle"] = "groovy",
      [".*%.html.en"] = "html",
      [".*%.jst.eco"] = "jst",
      [".*%.prettierrc%..*"] = "jsonc",
      [".*%.theme"] = "conf",
      -- [".*env%..*"] = "bash",
      [".*ignore"] = "conf",
      [".nvimrc"] = "lua",
      ["default-*%-packages"] = "conf",
    },
    -- ['.*tmux.*conf$'] = 'tmux',
  })

  ---@diagnostic disable-next-line: param-type-mismatch
  local base = vim.fs.joinpath(vim.fn.stdpath("state"), "dbee", "notes")
  local pattern = string.format("%s/.*", base)
  vim.filetype.add({
    extension = {
      sql = function(path, _)
        if path:match(pattern) then return "sql.dbee" end

        return "sql"
      end,
    },

    pattern = {
      [pattern] = "sql.dbee",
    },
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

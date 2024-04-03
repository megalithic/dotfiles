local in_dotfiles = vim.fn.system("git --git-dir=$HOME/.dotfiles/ --work-tree=$HOME ls-tree --name-only HEAD") ~= ""

local BORDER_STYLE = "none"

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

local M = {
  border = BORDER_STYLE,
  telescope_border_chars = telescope_border_chars[BORDER_STYLE],
  colorscheme = "megaforest", -- alt: `vim` for default
  default_colorcolumn = "81",
  notifier_enabled = true,
  debug_enabled = false,
  picker = "telescope", -- alt: telescope, fzf_lua
  formatter = "conform", -- alt: null-ls/none-ls, conform
  tree = "neo-tree",
  explorer = "oil", -- alt: dirbuf, oil
  tester = "vim-test", -- alt: neotest, nvim-test, vim-test
  gitter = "neogit", -- alt: neogit, fugitive
  snipper = "snippets", -- alt: vsnip, luasnip, snippets (nvim-builtin)
  completer = "cmp", -- alt: cmp, epo
  ts_ignored_langs = {}, -- alt: { "svg", "json", "heex", "jsonc" }
  is_screen_sharing = false,
  enabled_plugin = {
    abbreviations = true,
    megaline = true,
    megacolumn = true,
    term = true,
    lsp = true,
    repls = true,
    cursorline = true,
    colorcolumn = true,
    windows = true,
    numbers = true,
    folds = true,
    env = true,
    -- old_term = false,
    -- tmux = false,
    -- breadcrumb = false,
    -- megaterm = false,
    -- vscode = false,
    -- winbar = false,
  },
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
  -- REF: elixir LSPs: elixir-tools(tools-elixirls, tools-nextls, credo), elixirls, nextls, lexical
  enabled_elixir_ls = { "", "", "elixirls", "", "lexical" },
  formatter_exclusions = { "tools-elixirls", "tools-nextls", "", "nextls", "lexical" },
  diagnostic_exclusions = { "tools-elixirls", "tools-nextls", "elixirls", "nextls", "", "tsserver" },
  max_diagnostic_exclusions = { "tools-elixirls", "tools-nextls", "elixirls", "nextls", "lexical" },
  completion_exclusions = { "tools-elixirls", "tools-nextls", "elixirls", "nextls", "" },
  disable_autolint = false,
  disable_autoformat = false,
  markdown_fenced_languages = {
    "shell=sh",
    "bash=sh",
    "zsh=sh",
    "console=sh",
    "vim",
    "lua",
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
}

M.apply = function()
  -- NOTE: to use in one of our plugins:
  -- `if not plugin_loaded("plugin_name") then return end`
  function _G.plugin_loaded(plugin)
    if not mega then return false end

    if not M.enabled_plugins then return false end
    if not vim.tbl_contains(M.enabled_plugins, plugin) then return false end

    return true
  end

  function modified_icon() return vim.bo.modified and mega.icons.misc.circle or "" end

  local settings = {
    g = {
      mapleader = ",",
      maplocalleader = " ",
      ruby_host_prog = "~/.local/share/mise/installs/ruby/latest",
      bullets_checkbox_markers = " x",
      bullets_outline_levels = { "ROM", "ABC", "rom", "abc", "std-" },
      mkdp_echo_preview_url = 1,
      mkdp_preview_options = {
        maid = {
          theme = "dark",
        },
      },
      mkdp_theme = "dark",
      colorscheme = M.colorscheme, -- alt: `vim` for default
      default_colorcolumn = M.default_colorcolumn,
      notifier_enabled = M.notifier_enabled,
      debug_enabled = M.debug_enabled,
      picker = M.picker, -- alt: telescope, fzf_lua
      formatter = M.formatter, -- alt: null-ls/none-ls, conform
      tree = M.tree,
      explorer = M.explorer, -- alt: dirbuf, oil
      tester = M.tester, -- alt: neotest, nvim-test, vim-test
      gitter = M.gitter, -- alt: neogit, fugitive
      snipper = M.snipper, -- alt: vsnip, luasnip, snippets (nvim-builtin)
      completer = M.completer, -- alt: cmp, epo
      ts_ignored_langs = M.ts_ignored_langs, -- alt: { "svg", "json", "heex", "jsonc" }
      is_screen_sharing = M.is_screen_sharing,
      -- REF: elixir LSPs: elixir-tools(tools-elixirls, tools-nextls, credo), elixirls, nextls, lexical
      enabled_elixir_ls = M.enabled_elixir_ls,
      formatter_exclusions = M.formatter_exclusions,
      diagnostic_exclusions = M.diagnostic_exclusions,
      max_diagnostic_exclusions = M.max_diagnostic_exclusions,
      completion_exclusions = M.completion_exclusions,
      disable_autolint = M.disable_autolint,
      disable_autoformat = M.disable_autoformat,
      markdown_fenced_languages = M.markdown_fenced_languages,
    },
    o = {
      autoindent = true,
      autowriteall = true,
      backup = false,
      breakindentopt = "sbr",
      cedit = "<C-y>", -- Enter Command-line Mode from command-mode
      cmdheight = 1, -- Set command line height to two lines
      colorcolumn = "80",
      compatible = false,
      conceallevel = 2,
      confirm = true,
      cpoptions = "aABceFs", -- make `cw` compatible with other `w` operations
      cursorline = true,
      cursorlineopt = "both",
      eadirection = "hor",
      encoding = "utf-8",
      expandtab = true,
      exrc = true, -- Allow project local vimrc files example .nvimrc see :h exrc
      foldcolumn = "1",
      foldenable = true,
      foldexpr = "v:lua.vim.treesitter.foldexpr()",
      foldlevel = 99,
      foldlevelstart = 99,
      foldmethod = "expr",
      foldnestmax = 10, -- 10 nested fold max
      formatoptions = "jcroqlnt", -- tcqj
      gdefault = true,
      guifont = "JetBrainsMono Nerd Font:h15",
      hlsearch = true,
      ignorecase = true,
      lazyredraw = false, -- should make scrolling faster; disabled for noice.nvim
      linebreak = true, -- lines wrap at words rather than random characters
      list = true,
      mouse = "",

      mousefocus = true,
      mousemoveevent = true,
      number = true,
      pumheight = 20,
      pumblend = 0, -- Make popup window translucent
      relativenumber = true,
      ruler = false,
      scrolloff = 9,
      secure = true, -- Disable autocmd etc for project local vimrc files.
      shiftwidth = 2,
      shiftround = true,
      shortmess = "filnxtToOFWIcC", -- alts: "filnxtToOFWIcC", "tAoOTfFsCsFWcCW"
      showbreak = string.rep("↪", 3), -- Make it so that long lines wrap smartly; alts: -> '…', '↳ ', '→','↪ '
      showcmd = true, -- show current mode (insert, etc) under the cmdline
      showmode = false, -- show current mode (insert, etc) under the cmdline
      sidescroll = 1,
      sidescrolloff = 5,
      -- FIXME: use 'auto:2-4' when the ability to set only a single lsp sign is restored
      --@see: https://github.com/neovim/neovim/issues?q=set_signs
      -- vim.o.signcolumn = "auto:2-5",
      -- vim.osigncolumn = "auto:3-9",
      signcolumn = "yes:1",
      shada = [[!,'100,<0,s100,h]],
      smartcase = true,
      smoothscroll = true,
      softtabstop = 2,
      splitbelow = true,
      splitright = true,
      splitkeep = "screen",
      startofline = true,
      swapfile = false,
      switchbuf = "useopen,uselast",
      synmaxcol = 1024, -- don't syntax highlight long lines
      tabstop = 2,
      termguicolors = true,
      textwidth = 79, -- alts: 0 disables
      timeout = true,
      timeoutlen = 500,
      titlestring = "%{substitute($VIM, '.*[/\\]', '', '')} %{fnamemodify(getcwd(), \":t\")}%( %{v:lua.modified_icon()}%)",
      titleold = vim.fn.fnamemodify(vim.uv.os_getenv("SHELL"), ":t"),
      titlelen = 70,
      -- FIXME: this breaks tmux (vim.o.title); so disabling for now ¯\_(ツ)_/¯
      title = not vim.g.is_tmux_popup,
      ttimeoutlen = 10,
      ttyfast = true, -- more faster scrolling (thanks @morganick!)
      undodir = vim.env.HOME .. "/.vim/undodir",
      undofile = true,
      updatetime = 300,
      virtualedit = "block,onemore",
      wildcharm = vim.fn.char2nr(vim.keycode([[<Tab>]])),
      wildignorecase = true, -- Case insensitive file/directory completion
      wildmode = "longest:full,full", -- Shows a menu bar as opposed to an enormous list
      winblend = 0,
      wrap = false,
      wrapscan = true,
      -- wrapmargin = 2,
    },
    opt = {
      clipboard = { "unnamedplus" },
      completeopt = { "menu", "menuone", "preview", "noselect", "noinsert" },
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
        foldopen = mega.icons.misc.fold_open, -- alts: ▾
        -- foldsep = "│",
        foldsep = " ",
        foldclose = mega.icons.misc.fold_close, -- alts: ▸
      },
      guicursor = {
        [[n-v-c:block,i-ci-ve:ver25,r-cr:hor20,o:hor50]],
        [[a:blinkwait700-blinkoff400-blinkon250-Cursor/lCursor]],
        [[sm:block-blinkwait175-blinkoff150-blinkon175]],
        -- 'n-v-c-sm:block-Cursor',
        -- 'i-ci-ve:ver25-iCursor',
        -- 'r-cr-o:hor20-Cursor',
        -- 'a:blinkon0',
      },
      iskeyword = vim.opt.iskeyword:append("-"),
      jumpoptions = { "stack", "view" },
      listchars = {
        eol = nil,
        tab = nil, -- alts: »│
        nbsp = "␣",
        extends = "›", -- alts: … »
        precedes = "‹", -- alts: … «
        trail = "·", -- alts: • BULLET (U+2022, UTF-8: E2 80 A2)
      },
      mousescroll = { "ver:1", "hor:6" },
      sessionoptions = {
        "blank",
        "buffers",
        "curdir",
        "folds",
        "globals",
        -- "help",
        -- "tabpages",
        "terminal",
        "winpos",
        "winsize",
      },
      viewoptions = { "cursor", "folds" },
      wildignore = {
        "*.aux",
        "*.out",
        "*.toc",
        "*.o",
        "*.obj",
        "*.dll",
        "*.jar",
        "*.pyc",
        "*.rbc",
        "*.class",
        "*.gif",
        "*.ico",
        "*.jpg",
        "*.jpeg",
        "*.png",
        "*.avi",
        "*.wav",
        -- Temp/System
        "*.*~",
        "*~ ",
        "*.swp",
        ".lock",
        ".DS_Store",
        "tags.lock",
      },
      wildoptions = { "pum", "fuzzy" },

      -- vim.opt.path:append("**") -- Lets `find` search recursively into subfolders
    },
    env = {
      GIT_WORK_TREE = in_dotfiles and vim.env.HOME or vim.env.GIT_WORK_TREE,
      GIT_DIR = in_dotfiles and vim.env.HOME .. "/.dotfiles" or vim.env.GIT_DIR,
      -- for constant paging in Telescope delta commands
      GIT_PAGER = "delta --paging=always",
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
      ["Brewfile"] = "ruby",
      ["Brewfile.cask"] = "ruby",
      ["Brewfile.mas"] = "ruby",
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

  -- FIXME: deprecate:
  -- require("mega.options")
end

return M

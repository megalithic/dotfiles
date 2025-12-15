local M = {}

-- add binaries installed by mason.nvim to path
vim.env.PATH = vim.env.PATH .. (vim.g.is_windows and ";" or ":") .. vim.fn.stdpath("data") .. "/mason/bin"

local enabled_plugins = {
  "lsp",
  "statusline",
  "statuscolumn",
  "gotroot",
  "undo",
  "windows",
  "term",
  "filetypes",
  "cursorline",
  "notes",
  -- "fakecolumn",
  -- "term",
  -- "abbreviations",
  -- -- "winbar",
  -- -- "tabline",
  -- -- "megaterm",
  -- "repls",
  -- "colorcolumn",
  -- "numbers",
  -- "clipboard",
  -- "folds",
  -- "dotenv",
  -- "notes",
  -- "chat",
}

local uname = vim.uv.os_uname().sysname
local is_macos = uname == "Darwin"
local dotfiles_path = vim.env.DOTS
local hammerspoon_path = string.format("%s/config/hammerspoon", dotfiles_path)
local BORDER_STYLE = "none"
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

M.g = {
  mapleader = ",",
  maplocalleader = " ",
  lsp_semantic_enabled = 1,
  netrw_liststyle = 1,
  netrw_sort_by = "size",
  open_command = is_macos and "open" or "xdg-open",
  is_tmux_popup = vim.env.TMUX_POPUP ~= nil,
  code_path = vim.env.CODE,
  projects_path = vim.env.CODE,
  vim_path = vim.fn.stdpath("config"),
  nvim_path = vim.fn.stdpath("config"),
  dotfiles_path = vim.env.DOTS,
  cache_path = vim.fn.stdpath("cache"),
  local_state_path = vim.fn.stdpath("state"),
  local_share_path = vim.fn.stdpath("data"),
  db_ui_path = vim.env.NVIM_DB_HOME,
  notes_path = vim.env.NOTES_HOME,
  obsidian_path = vim.env.OBSIDIAN_HOME,
  -- zk_path = string.format("%s/_zk", icloud_documents_path),
  -- org_path = string.format("%s/_org", icloud_documents_path),
  -- neorg_path = string.format("%s/_org", icloud_documents_path),
  hs_emmy_path = string.format("%s/Spoons/EmmyLua.spoon", hammerspoon_path),

  -- python3_host_prog = vim.env.XDG_DATA_HOME .. "/mise/installs/python/latest/bin/python3",
  -- ruby_host_prog = vim.env.XDG_DATA_HOME .. "/mise/installs/ruby/latest/bin/ruby",
  -- node_host_prog = vim.env.XDG_DATA_HOME .. "/mise/installs/node/latest/bin/node",
  --
  enabled_plugins = enabled_plugins,
  treesitter_branch = "master",
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

  lsp_lookup = {
    expert = "exp",
    elixirls = "ex",
    nextls = "next",
    lua_ls = "lua",
    tailwindcss = "twcss",
    emmet_ls = "em",
    emmet_language_server = "em",
    lexical = "lex",
    postgres_lsp = "pglsp",
  },

  disabled_semantic_tokens = {
    -- "typescript",
    -- "javascript",
    "lua",
  },
  enabled_inlay_hints = {},
  disabled_lsp_formatters = { "tailwindcss", "html", "ts_ls", "ls_emmet", "zk", "sumneko_lua" },
  enabled_elixir_ls = (function()
    local ls = "elixirls"
    if vim.env.ELIXIR_LS ~= nil then ls = vim.env.ELIXIR_LS end
    return { ls, "expert", "", "" } --- opts: {"expert", "elixirls", "nextls", "lexical"}
  end)(),
  completion_exclusions = {},
  formatter_exclusions = { "emmylua_ls" },
  definition_exclusions = {},
  references_exclusions = {},
  diagnostic_exclusions = {},
  max_diagnostic_exclusions = {},
  disable_autolint = false,
  disable_autoformat = false,
  disable_autoresize = false,
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
}

M.opt = {
  cmdwinheight = 4,
  cmdheight = 1,
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
    msgsep = " ", -- alts: ‾ ─ fold = " ", foldopen = Icons.misc.fold_open, -- alts: ▾ foldsep = "│", foldsep = " ",
    foldclose = Icons.misc.fold_close, -- alts: ▸
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
  -- Preview substitutions live, as you type!
  inccommand = "split",
  splitkeep = "cursor",
  list = true,
  listchars = {
    eol = nil,
    tab = "» ", -- alts: »│ │
    nbsp = "␣",
    extends = "›", -- alts: … »
    precedes = "‹", -- alts: … «
    trail = "·", -- alts: • BULLET (U+2022, UTF-8: E2 80 A2)
  },
  -- Enable mouse mode, can be useful for resizing splits for example!
  mouse = "a",
  sessionoptions = vim.opt.sessionoptions:remove({ "buffers", "folds" }),
  shada = { "!", "'1000", "<50", "s10", "h" }, -- Increase the shadafile size so that history is longer
  shortmess = vim.opt.shortmess:append({
    I = true, -- No splash screen
    W = true, -- Don't print "written" when editing
    a = true, -- Use abbreviations in messages ([RO] intead of [readonly])
    c = true, -- Do not show ins-completion-menu messages (match 1 of 2)
    F = true, -- Do not print file name when opening a file
    s = true, -- Do not show "Search hit BOTTOM" message
  }),

  showbreak = string.format("%s ", string.rep("↪", 1)), -- Make it so that long lines wrap smartly; alts: -> '…', '↳ ', '→','↪ '
  -- Don't show the mode, since it's already in the status line
  showmode = false,
  showcmd = false,

  suffixesadd = { ".md", ".js", ".ts", ".tsx" }, -- File extensions not required when opening with `gf`

  -- Basic settings
  number = true, -- Line numbers
  relativenumber = true, -- Relative line numbers
  cursorline = true, -- Highlight current line
  wrap = false, -- Don't wrap lines
  scrolloff = 10, -- Keep 10 lines above/below cursor
  sidescrolloff = 8, -- Keep 8 columns left/right of cursor

  -- Indentation vim.opt.tabstop = 2        -- Tab width vim.opt.shiftwidth = 2     -- Indent width vim.opt.softtabstop = 2    -- Soft tab stop
  expandtab = true, -- Use spaces instead of tabs
  smartindent = true, -- Smart auto-indenting
  autoindent = true, -- Copy indent from current line

  -- Search settings
  ignorecase = true, -- Case insensitive search
  smartcase = true, -- Case sensitive if uppercase in search
  hlsearch = false, -- Don't highlight search results
  incsearch = true, -- Show matches as you type

  -- Visual settings
  termguicolors = true, -- Enable 24-bit colors
  signcolumn = "yes", -- Always show sign column
  colorcolumn = "100", -- Show column at 100 characters
  showmatch = true, -- Highlight matching brackets
  matchtime = 2, -- How long to show matching bracket
  completeopt = "menuone,noinsert,noselect", -- Completion options
  pumheight = 10, -- Popup menu height
  pumblend = 10, -- Popup menu transparency
  winblend = 0, -- Floating window transparency
  winborder = BORDER_STYLE,
  conceallevel = 0, -- Don't hide markup
  concealcursor = "", -- Don't hide cursor line markup
  -- lazyredraw = true, -- Don't redraw during macros
  synmaxcol = 300, -- Syntax highlighting limit

  -- File handling
  backup = false, -- Don't create backup files
  writebackup = false, -- Don't create backup before writing
  swapfile = false, -- Don't create swap files
  undofile = true, -- Persistent undo
  undodir = vim.fn.expand("~/.vim/undodir"), -- Undo directory
  updatetime = 300, -- Faster completion
  timeoutlen = 500, -- Key timeout duration
  ttimeoutlen = 0, -- Key code timeout
  autoread = true, -- Auto reload files changed outside vim
  autowrite = false, -- Don't auto save

  -- Behavior settings
  hidden = true, -- Allow hidden buffers
  errorbells = false, -- No error bells
  backspace = "indent,eol,start", -- Better backspace behavior
  autochdir = false, -- Don't auto change directory
  iskeyword = vim.opt.iskeyword:append("-"), -- Treat dash as part of word
  path = vim.opt.path:append("**"), -- include subdirectories in search
  selection = "exclusive", -- Selection behavior
  clipboard = vim.opt.clipboard:append("unnamedplus"), -- Use system clipboard
  modifiable = true, -- Allow buffer modifications
  encoding = "UTF-8", -- Set encoding

  -- Cursor settings
  -- guicursor =
  -- "n-v-c:block,i-ci-ve:block,r-cr:hor20,o:hor50,a:blinkwait700-blinkoff400-blinkon250-Cursor/lCursor,sm:block-blinkwait175-blinkoff150-blinkon175",
  guicursor = vim.opt.guicursor:append("a:blinkon500-blinkoff100"),

  -- Folding settings
  foldmethod = "expr", -- Use expression for folding
  foldexpr = "nvim_treesitter#foldexpr()", -- Use treesitter for folding
  foldlevel = 99, -- Start with all folds open

  -- Split behavior
  splitbelow = true, -- Horizontal splits go below
  splitright = true, -- Vertical splits go right
}

-- vim.print(vim.o.packpath)
-- vim.print(vim.fs.joinpath(vim.fn.stdpath("data"), "site", "pack", "core", "opt"))
-- o = {
--   packpath = vim.o.packpath .. ";" .. string.format("%s/site/pack/core/opt", vim.fn.stdpath("data")), --vim.fs.joinpath(vim.fn.stdpath("data"), "site", "pack", "core", "opt"),
--   -- string.format("%s/site/pack/core", vim.fn.stdpath("data"))
-- }

for _, provider in ipairs({ "node", "perl", "python3", "ruby" }) do
  vim.g["loaded_" .. provider .. "_provider"] = 0
  -- vim.g[provider .. "_host_prog"] = vim.env.XDG_DATA_HOME .. "/mise/installs/" .. provider .. "/latest/bin/" .. provider
end

-- apply the above settings
for scope, opts in pairs(M) do
  local opt_group = vim[scope]

  for opt_key, opt_value in pairs(opts) do
    opt_group[opt_key] = opt_value
  end
end

-- vim.print(vim.o.packpath)

vim.filetype.add({
  filename = {
    [".env"] = "bash",
    [".envrc"] = "bash",
    [".eslintrc"] = "jsonc",
    [".eslintrc.json"] = "jsonc",
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
    [".*ignore$"] = "gitignore",
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

-- HT: https://github.com/tjdevries/config.nvim/blob/master/plugin/clipboard.lua
if vim.env.SSH_CONNECTION then
  local function vim_paste()
    local content = vim.fn.getreg('"')
    return vim.split(content, "\n")
  end

  vim.g.clipboard = {
    name = "OSC 52",
    copy = {
      ["+"] = require("vim.ui.clipboard.osc52").copy("+"),
      ["*"] = require("vim.ui.clipboard.osc52").copy("*"),
    },
    paste = {
      ["+"] = vim_paste,
      ["*"] = vim_paste,
    },
  }
end

return M

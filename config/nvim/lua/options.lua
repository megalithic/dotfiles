-- lua/options.lua
-- Core Neovim options

local opt = vim.opt

-- ═══════════════════════════════════════════════════════════════════════════════
-- UI
-- ═══════════════════════════════════════════════════════════════════════════════
opt.termguicolors = true
opt.number = true
opt.relativenumber = true
opt.signcolumn = "yes"
opt.cursorline = true
opt.showmode = false -- Mode shown in statusline
opt.showcmd = false
opt.cmdheight = 0
opt.laststatus = 2 -- Individual statusline per split
opt.pumheight = 10 -- Popup menu height
opt.pumblend = 10 -- Popup menu transparency
opt.winblend = 0
opt.splitbelow = true
opt.splitright = true
opt.splitkeep = "screen"
opt.scrolloff = 8
opt.sidescrolloff = 8

-- ═══════════════════════════════════════════════════════════════════════════════
-- Editing
-- ═══════════════════════════════════════════════════════════════════════════════
opt.expandtab = true
opt.shiftwidth = 2
opt.tabstop = 2
opt.softtabstop = 2
opt.smartindent = true
opt.wrap = false
opt.linebreak = true
opt.breakindent = true
opt.virtualedit = "block" -- Allow cursor beyond end of line in visual block mode

-- ═══════════════════════════════════════════════════════════════════════════════
-- Search
-- ═══════════════════════════════════════════════════════════════════════════════
opt.ignorecase = true
opt.smartcase = true
opt.hlsearch = true
opt.incsearch = true

-- ═══════════════════════════════════════════════════════════════════════════════
-- Files
-- ═══════════════════════════════════════════════════════════════════════════════
opt.backup = false
opt.writebackup = false
opt.swapfile = false
opt.undofile = true
opt.undolevels = 10000
opt.autoread = true
opt.autowrite = false -- Don't auto-save on mode change; use explicit :w or format_on_save

-- ═══════════════════════════════════════════════════════════════════════════════
-- Completion
-- ═══════════════════════════════════════════════════════════════════════════════
opt.completeopt = "menu,menuone,noselect"
opt.wildmode = "longest:full,full"
opt.wildignorecase = true

-- ═══════════════════════════════════════════════════════════════════════════════
-- Performance
-- ═══════════════════════════════════════════════════════════════════════════════
opt.updatetime = 200
opt.timeoutlen = 300
opt.redrawtime = 1500
opt.lazyredraw = false -- Disabled for noice.nvim compatibility

-- ═══════════════════════════════════════════════════════════════════════════════
-- Misc
-- ═══════════════════════════════════════════════════════════════════════════════
opt.clipboard = "unnamedplus"
opt.mouse = "a"
opt.confirm = true -- Confirm before closing unsaved buffer
opt.inccommand = "nosplit" -- Preview substitutions live
opt.jumpoptions = "view"
opt.shortmess:append({ W = true, I = true, c = true, C = true })
opt.formatoptions = "jcroqlnt" -- tcqj default

-- Fillchars and listchars
opt.fillchars = {
  foldopen = "-",
  foldclose = "+",
  fold = " ",
  foldsep = " ",
  diff = "/",
  eob = " ",
}

opt.list = true
opt.listchars = {
  tab = "» ",
  trail = "·",
  nbsp = "␣",
  extends = "›",
  precedes = "‹",
}

opt.diffopt = {
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
}
opt.fillchars = {
  horiz = "━",
  vert = "▕", -- alternatives │┃
  -- horizdown = '┳',
  -- horizup   = '┻',
  -- vertleft  = '┫',
  -- vertright = '┣',
  -- verthoriz = '╋',
  eob = " ", -- suppress ~ at EndOfBuffer
  diff = "╱", -- alts: = ⣿ ░ ─
  msgsep = " ", -- alts: ‾ ─ fold = " ", foldopen = mega.ui.icons.misc.fold_open, -- alts: ▾ foldsep = "│", foldsep = " ",
  foldclose = mega.ui.icons.misc.fold_close, -- alts: ▸
  stl = " ", -- alts: ─ ⣿ ░ ▐ ▒▓
  stlnc = " ", -- alts: ─
}
opt.formatoptions = vim.opt.formatoptions
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
  - "2" -- I'm not in gradeschool anymore
-- Preview substitutions live, as you type!
opt.inccommand = "split"
opt.splitkeep = "cursor"
opt.list = true
opt.listchars = {
  eol = nil,
  tab = "» ", -- alts: »│ │
  nbsp = "␣",
  extends = "›", -- alts: … »
  precedes = "‹", -- alts: … «
  trail = "·", -- alts: • BULLET (U+2022, UTF-8: E2 80 A2)
}
-- Enable mouse mode, can be useful for resizing splits for example!
opt.mouse = "a"
opt.sessionoptions = vim.opt.sessionoptions:remove({ "buffers", "folds" })
opt.shada = { "!", "'1000", "<50", "s10", "h" } -- Increase the shadafile size so that history is longer
opt.shortmess = vim.opt.shortmess:append({
  I = true, -- No splash screen
  W = true, -- Don't print "written" when editing
  a = true, -- Use abbreviations in messages ([RO] intead of [readonly])
  c = true, -- Do not show ins-completion-menu messages (match 1 of 2)
  F = true, -- Do not print file name when opening a file
  s = true, -- Do not show "Search hit BOTTOM" message
})

opt.showbreak = string.format("%s ", string.rep("↪", 1)) -- Make it so that long lines wrap smartly; alts: -> '…', '↳ ', '→','↪ '
-- Don't show the mode, since it's already in the status line
opt.showmode = false
opt.showcmd = false

opt.suffixesadd = { ".md", ".js", ".ts", ".tsx" } -- File extensions not required when opening with `gf`

-- detect utf-16 files
opt.fileencodings = {
  "ucs-bom",
  "utf-8",
  "utf-16",
  "default",
  "latin1",
}

opt.exrc = true

-- ═══════════════════════════════════════════════════════════════════════════════
-- Grep (use ripgrep if available)
-- ═══════════════════════════════════════════════════════════════════════════════
if vim.fn.executable("rg") == 1 then
  opt.grepprg = "rg --vimgrep --smart-case --hidden"
  opt.grepformat = "%f:%l:%c:%m"
end

-- setup clipboard with support for OSC52 if in an SSH session
-- see: https://github.com/neovim/neovim/discussions/28010#discussioncomment-9877494
vim.opt.clipboard = "unnamedplus"
if vim.env.SSH_TTY ~= nil and vim.env.SSH_TTY ~= "" then
  local function paste()
    return {
      vim.fn.split(vim.fn.getreg(""), "\n"),
      vim.fn.getregtype(""),
    }
  end
  vim.g.clipboard = {
    name = "OSC 52",
    copy = {
      ["+"] = require("vim.ui.clipboard.osc52").copy("+"),
      ["*"] = require("vim.ui.clipboard.osc52").copy("*"),
    },
    paste = {
      ["+"] = paste,
      ["*"] = paste,
    },
  }
end

vim.filetype.add({
  pattern = {
    ["*.jsonc"] = "jsonc",
    ["tsconfig.json"] = "jsonc",
    ["tsconfig*.json"] = "jsonc",
    -- pass edit uses secure temp files in pass.<random>/<tmp>-<entry>.txt
    [".*/pass%.[^/]+/[^/]+%-.+%.txt"] = "pass",
    -- yaml.github-action & yaml.docker-compose needed for proper treesitter and lsp setups
    [".*/%.github/actions/.*"] = "yaml.github-action",
    [".*/%.github/workflows/.*"] = "yaml.github-action",
    ["docker%-compose%..*"] = "yaml.docker-compose",
    -- Needed for proper treesitter setup
    ["todo.txt"] = "todotxt",
    -- Bigfile detection
    [".*"] = {
      function(path, buf)
        if not path or not buf or vim.bo[buf].filetype == "bigfile" then return end
        if path ~= vim.fs.normalize(vim.api.nvim_buf_get_name(buf)) then return end
        local size = vim.fn.getfsize(path)
        if size <= 0 then return end
        -- Detect files larger than 1.5MB
        if size > 1.5 * 1024 * 1024 then return "bigfile" end
        -- Detect minified files with long lines
        local lines = vim.api.nvim_buf_line_count(buf)
        return (size - lines) / lines > 1000 and "bigfile" or nil
      end,
    },
  },
})

--[[
  ╭────────────────────────────────────────────────────────────────────────────╮
  │  Str  │  Help page   │  Affected modes                           │  VimL   │
  │────────────────────────────────────────────────────────────────────────────│
  │  ''   │  mapmode-nvo │  Normal, Visual, Select, Operator-pending │  :map   │
  │  'n'  │  mapmode-n   │  Normal                                   │  :nmap  │
  │  'v'  │  mapmode-v   │  Visual and Select                        │  :vmap  │
  │  's'  │  mapmode-s   │  Select                                   │  :smap  │
  │  'x'  │  mapmode-x   │  Visual                                   │  :xmap  │
  │  'o'  │  mapmode-o   │  Operator-pending                         │  :omap  │
  │  '!'  │  mapmode-ic  │  Insert and Command-line                  │  :map!  │
  │  'i'  │  mapmode-i   │  Insert                                   │  :imap  │
  │  'l'  │  mapmode-l   │  Insert, Command-line, Lang-Arg           │  :lmap  │
  │  'c'  │  mapmode-c   │  Command-line                             │  :cmap  │
  │  't'  │  mapmode-t   │  Terminal                                 │  :tmap  │
  ╰────────────────────────────────────────────────────────────────────────────╯
--]]

-- REFS:
-- https://github.com/BlakeJC94/.dots/blob/master/.config/nvim/lua/mappings.lua
-- https://github.com/rafamadriz/NeoCode/blob/main/lua/core/mappings.lua
-- https://github.com/rafamadriz/NeoCode/blob/main/lua/modules/plugins/which-key.lua
-- https://github.com/mbriggs/nvim/blob/main/lua/mb/which-key.lua
-- https://github.com/akinsho/dotfiles/blob/main/.config/nvim/lua/as/plugins/whichkey.lua

local fn = vim.fn
local exec = mega.exec
-- NOTE: all convenience mode mappers are on the _G global; so no local assigns needed

-- FIXME: i'm not so sure these are doing the right things...
-- at all.
-- mega.augroup("AddTerminalMappings", {
--   {
--     event = { "TermOpen" },
--     pattern = { "term://*" },
--     command = function()
--       local opts = { silent = false, buffer = 0 }
--       tnoremap("<esc>", [[<C-\><C-n>]], opts)
--       tnoremap("jk", [[<C-\><C-n>]], opts)
--       tnoremap("<C-h>", [[<C-\><C-n><C-W>h]], opts)
--       tnoremap("<C-j>", [[<C-\><C-n><C-W>j]], opts)
--       tnoremap("<C-k>", [[<C-\><C-n><C-W>k]], opts)
--       tnoremap("<C-l>", [[<C-\><C-n><C-W>l]], opts)
--       tnoremap("]t", [[<C-\><C-n>:tablast<CR>]])
--       tnoremap("[t", [[<C-\><C-n>:tabnext<CR>]])
--       tnoremap("<S-Tab>", [[<C-\><C-n>:bprev<CR>]])
--       tnoremap("<leader><Tab>", [[<C-\><C-n>:close \| :bnext<cr>]])
--     end,
--   },
-- })

local has_wk, wk = mega.safe_require("which-key")
if has_wk then
  -- REF: predefine groups: https://github.com/lucax88x/configs/blob/master/dotfiles/.config/nvim/lua/lt/plugins/which-key/init.lua#L76-L90
  wk.setup({
    plugins = {
      marks = true, -- shows a list of your marks on ' and `
      registers = true, -- shows your registers on " in NORMAL or <C-r> in INSERT mode
      -- the presets plugin, adds help for a bunch of default keybindings in Neovim
      -- No actual key bindings are created
      spelling = {
        enabled = true, -- enabling this will show WhichKey when pressing z= to select spelling suggestions
        suggestions = 20, -- how many suggestions should be shown in the list?
      },
      presets = {
        operators = false, -- adds help for operators like d, y, ... and registers them for motion / text object completion
        motions = true, -- adds help for motions
        text_objects = true, -- help for text objects triggered after entering an operator
        windows = false, -- default bindings on <c-w>
        nav = true, -- misc bindings to work with windows
        z = true, -- bindings for folds, spelling and others prefixed with z
        g = true, -- bindings for prefixed with g
      },
    },
    -- add operators that will trigger motion and text object completion
    -- to enable all native operators, set the preset / operators plugin above
    operators = { gc = "Comments" },
    key_labels = {
      -- override the label used to display some keys. It doesn't effect WK in any other way.
      -- For example:
      ["<space>"] = "SPC",
      ["<cr>"] = "RET",
      ["<tab>"] = "TAB",
    },
    icons = {
      breadcrumb = "»", -- symbol used in the command line area that shows your active key combo
      separator = "➜", -- symbol used between a key and it's label
      group = "+", -- symbol prepended to a group
    },
    window = {
      border = "none", -- none, single, double, shadow
      position = "bottom", -- bottom, top
      margin = { 1, 0, 1, 0 }, -- extra window margin [top, right, bottom, left]
      padding = { 1, 1, 1, 1 }, -- extra window padding [top, right, bottom, left]
    },
    layout = {
      height = { min = 3, max = 25 }, -- min and max height of the columns
      width = { min = 10, max = 40 }, -- min and max width of the columns
      spacing = 3, -- spacing between columns
    },
    hidden = { "<silent>", "<cmd>", "<Cmd>", "<CR>", "call", "lua", "^:", "^ " }, -- hide mapping boilerplate
    show_help = true, -- show help message on the command line when the popup is visible
    triggers = "auto", -- automatically setup triggers
    -- triggers = {"<leader>"} -- or specifiy a list manually
    --triggers_blacklist = {
    -- list of mode / prefixes that should never be hooked by WhichKey
    -- this is mostly relevant for key maps that start with a native binding
    -- most people should not need to change this
    -- 	i = { "j", "k" },
    -- 	v = { "j", "k" },
    -- },
  })

  local gs = require("gitsigns")

  -- Normal Mode {{{1
  local n_mappings = {
    ["[h"] = "go to prev git hunk",
    ["]h"] = "go to next git hunk",
    ["[d"] = "lsp: go to prev diagnostic",
    ["]d"] = "lsp: go to next diagnostic",
    -- f = {}, -- see plugins.lua > telescope-mappings
    ["<leader>c"] = {
      name = "+actions",
      d = { "telescope: diagnostics" },
      s = { "telescope: document symbols" },
      w = { "telescope: search workspace symbols" },
    },
    ["<leader>e"] = {
      name = "edit files",
      r = { [[<cmd>RenameFile<cr>]], "rename file to <input>" },
      s = { [[<cmd>SaveAsFile<cr>]], "save file as <input>" },
      d = { [[:DuplicateFile<cr>]], "duplicate current file" },
      D = { [[<cmd>Delete!<cr>]], "delete file" },
      yp = { [[:let @+ = expand("%")<CR>]], "yank path to clipboard" },
      t = { [[:Neotree toggle reveal<cr>]], "toggle neo-tree" },
    },
    ["<leader>f"] = {
      name = "telescope",
      a = { "builtins" },
      b = { "current buffer fuzzy find" },
      d = { "dotfiles" },
      p = { "privates" },
      f = { "find/git files" },
      g = {
        name = "+git",
      },
      M = { "man pages" },
      m = { "oldfiles (mru)" },
      k = { "keymaps" },
      P = { "plugins" },
      o = { "buffers" },
      O = { "org files" },
      R = { "module reloader" },
      r = { "resume last picker" },
      s = { "grep string" },
      v = {
        name = "+vim",
        h = { "highlights" },
        a = { "autocommands" },
        o = { "options" },
      },
      t = {
        name = "+tmux",
        s = { "sessions" },
        w = { "windows" },
      },
      ["?"] = { "help" },
      h = { "help" },
    },
    ["<leader>g"] = {
      name = "git",
      g = { "<cmd>Git<CR>", "Fugitive" },
      H = "browse at line",
      O = "browse repo",
      B = "browse blame at line",
      r = {
        name = "+reset",
        e = "gitsigns: reset entire buffer",
      },
      b = {
        function()
          gs.blame_line({ full = true })
        end,
        "gitsigns: blame current line",
      },
      h = {
        name = "+gitsigns hunk",
        s = { gs.stage_hunk, "stage" },
        u = { gs.undo_stage_hunk, "undo stage" },
        r = { gs.reset_hunk, "reset hunk" },
        p = { gs.preview_hunk, "preview current hunk" },
        d = { gs.diffthis, "diff this line" },
        D = {
          function()
            gs.diffthis("~")
          end,
          "diff this with ~",
        },
        b = {
          name = "+blame",
          l = "gitsigns: blame current line",
          d = "gitsigns: toggle word diff",
          b = {
            function()
              gs.blame_line({ full = true })
            end,
            "blame current line",
          },
        },
      },
      w = "gitsigns: stage entire buffer",
      m = "gitsigns: list modified in quickfix",
    },
    ["<leader>l"] = {
      name = "+lsp",
      d = { "telescope: definitions" },
      D = { "telescope: diagnostics" },
      t = { "telescope: type definitions" },
      r = { "telescope: references" },
      i = { "telescope: implementations" },
      s = { "telescope: document symbols" },
      S = { "telescope: workspace symbols" },
      w = { "telescope: dynamic workspace symbols" },
      n = { "lsp: rename" },
    },
    ["<leader>m"] = {
      name = "markdown",
      p = { [[<cmd>MarkdownPreviewToggle<CR>]], "open preview" },
      g = { [[<cmd>Glow<CR>]], "open glow" },
    },
    ["<leader>p"] = {
      name = "project",
      p = { "<cmd>:AV<cr>", "Toggle Alternate (vsplit)" },
      P = { "<cmd>:A<cr>", "Open Alternate (edit)" },
      l = { "<cmd>:Vheex<cr>", "Open Heex for LiveView (vsplit)" },
      L = { "<cmd>:Vlive<cr>", "Open Live for LiveView (vsplit)" },
    },
    ["<leader>r"] = {
      name = "runner",
      f = { "<cmd>Format<cr>", "Run _formatter" },
      r = { "", "Run  _repl" },
      n = { "<cmd>TestNearest<cr>", "Run _test under cursor" },
      a = { "<cmd>TestFile<cr>", "Run _all tests in file" },
      l = { "<cmd>TestLast<cr>", "Run _last test" },
      v = { "<cmd>TestVisit<cr>", "Run test file _visit" },
    },
    ["<leader>z"] = {
      name = "zk",
    },
    ["<localleader>t"] = {
      name = "test",
    },
    ["<localleader>d"] = {
      name = "debugger",
    },
    ["<localleader>g"] = {
      name = "gitsigns",
    },
    g = {
      name = "go-to",
      c = "comment text",
      ["cc"] = "comment line",
    },
    K = { "lsp: hover" },
    z = {
      name = "highlight/folds/paging",
      -- t = { [[<cmd>TSHighlightCapturesUnderCursor<CR>]], "show TS highlights under cursor" },
      -- TODO: ensure that we can get to these
      S = { "show syntax highlights under cursor" },
      s = { "show syntax highlights under cursor" },
      -- j = { mega.showCursorHighlights, "show syntax highlights under cursor" },
      -- S = {
      --   [[<cmd>lua require'nvim-treesitter-refactor.highlight_definitions'.highlight_usages(vim.fn.bufnr())<cr>]],
      --   "all usages under cursor",
      -- },
    },
  }
  -- }}}

  -- Visual Mode {{{1
  local v_mappings = {
    ["<leader>b"] = { name = "buffers", s = "save buffer" },
    ["<leader>f"] = { "format selection" },
    ["<leader>g"] = { name = "git link", y = "copy permalink selection" },
  }
  -- }}}

  wk.register(n_mappings, { mode = "n" })
  wk.register(v_mappings, { mode = "v" })
end

-- [convenience mappings] ------------------------------------------------------

nmap("gb", string.format("<cmd>ls<CR>:b<space>%s", mega.replace_termcodes("<tab>")), "current buffers")
nmap("gs", "i<CR><ESC>^mwgk:silent! s/\v +$//<CR>:noh<CR>`w", "split line")
nmap("gj", "mzJ`z", "join lines")
nmap("gx", mega.open_uri, "open uri under cursor")

nmap("zs", mega.showCursorHighlights, "show syntax highlights under cursor")
nmap("zS", mega.showCursorHighlights, "show syntax highlights under cursor")

nmap("<localleader>tn", "<cmd>TestNearest<cr>", "run _test under cursor")
nmap("<localleader>ta", "<cmd>TestFile<cr>", "run _all tests in file")
nmap("<localleader>tf", "<cmd>TestFile<cr>", "run _all tests in file")
nmap("<localleader>tl", "<cmd>TestLast<cr>", "run _last test")
nmap("<localleader>tt", "<cmd>TestLast<cr>", "run _last test")
nmap("<localleader>tv", "<cmd>TestVisit<cr>", "run test file _visit")
nmap("<localleader>tp", "<cmd>:A<cr>", "open alt (edit)")
nmap("<localleader>tP", "<cmd>:AV<cr>", "open alt (vsplit)")

-- make the tab key match bracket pairs
exec("silent! unmap [%", true)
exec("silent! unmap ]%", true)

nmap("<Tab>", "%")
smap("<Tab>", "%")
vmap("<Tab>", "%")
xmap("<Tab>", "%")
omap("<Tab>", "%")

-- https://github.com/tpope/vim-rsi/blob/master/plugin/rsi.vim
-- c-a / c-e everywhere - RSI.vim provides these
cnoremap("<C-n>", "<Down>")
cnoremap("<C-p>", "<Up>")
-- <C-A> allows you to insert all matches on the command line e.g. bd *.js <c-a>
-- will insert all matching files e.g. :bd a.js b.js c.js
cnoremap("<c-x><c-a>", "<c-a>")
cnoremap("<C-a>", "<Home>")
cnoremap("<C-e>", "<End>")
cnoremap("<C-b>", "<Left>")
cnoremap("<C-d>", "<Del>")
cnoremap("<C-k>", [[<C-\>e getcmdpos() == 1 ? '' : getcmdline()[:getcmdpos() - 2]<CR>]])
-- move cursor one character backwards unless at the end of the command line
cnoremap("<C-f>", [[getcmdpos() > strlen(getcmdline())? &cedit: "\<Lt>Right>"]], { expr = true })
-- see :h cmdline-editing
cnoremap("<Esc>b", [[<S-Left>]])
cnoremap("<Esc>f", [[<S-Right>]])
-- Insert escaped '/' while inputting a search pattern
cnoremap("/", [[getcmdtype() == "/" ? "\/" : "/"]], { expr = true })

-- [overrides/remaps mappings] ---------------------------------------------------------

exec([[
" -- ( overrides ) --
" Help
noremap <C-]> K

" Copy to system clipboard
noremap Y y$

" Start search on current word under the cursor
nnoremap <leader>/ /<CR>

" Start reverse search on current word under the cursor
nnoremap <leader>? ?<CR>

" Faster sort
vnoremap <leader>S :!sort<CR>

" Command mode conveniences
noremap <leader>: :!
noremap <leader>; :<Up>

" Remap VIM 0 to first non-blank character
map 0 ^

" gi already moves to 'last place you exited insert mode', so we'll map gI to
" something similar: move to last change
" nnoremap gI `.

" reselect visually selected content:
xnoremap > >gv

" ## Indentions
" Indent/dedent/autoindent what you just pasted.
nnoremap <lt>> V`]<
nnoremap ><lt> V`]>
nnoremap =- V`]=

" Better save and quit
silent! unmap <leader>w
nnoremap <silent><leader>w :write<CR>
nnoremap <silent><leader>W :write !sudo -S tee > /dev/null %<CR>
cmap w!! w !sudo tee > /dev/null %
nnoremap <leader>q :q<CR>

vnoremap <C-r> "hy:%Subvert/<C-r>h//gc<left><left><left>
]])

-- Clear UI state via escape:
-- - Clear search highlight
-- - Clear command-line
-- - Close floating windows
nmap([[<Esc>]], [[<Nop>]])
nnoremap([[<Esc>]], function()
  -- vcmd([[nnoremap <silent><ESC> :syntax sync fromstart<CR>:nohlsearch<CR>:redrawstatus!<CR><ESC> ]])
  vim.cmd("nohlsearch")
  mega.close_float_wins()
  vim.cmd("echo ''")
  mega.blink_cursorline()

  do
    local ok, minijump = pcall(require, "mini.jump")
    if ok then
      minijump.stop_jumping()
    end
  end

  -- local n_ok, n = require("notify")
  -- if n_ok then
  --   vim.notify = n
  --   vim.notify.dismiss()
  -- end
end, { silent = true, desc = "Clear UI" })

-- Use operator pending mode to visually select the whole buffer
-- e.g. dA = delete buffer ALL, yA = copy whole buffer ALL
omap("A", ":<C-U>normal! mzggVG<CR>`z")
xmap("A", ":<C-U>normal! ggVG<CR>")

-- useful remaps from theprimeagen:
-- - ref: https://www.youtube.com/watch?v=hSHATqh8svM
-- useful remaps/maps from lukas-reineke:
-- - ref: https://github.com/lukas-reineke/dotfiles/blob/master/vim/lua/mappings.lua

-- Convenient Line operations
nmap("H", "^")
nmap("L", "$")
vmap("L", "g_")

-- TODO: no longer needed; nightly adds these things?
-- map("n", "Y", '"+y$')
-- map("n", "Y", "yg_") -- copy to last non-blank char of the line

-- Remap VIM 0 to first non-blank character
nmap("0", "^")

nmap("q", "<Nop>")
nmap("Q", "@q")
vnoremap("Q", ":norm @q<CR>")

-- selections
nnoremap("gv", "`[v`]", "reselect pasted content")
nnoremap("<leader>V", "V`]", "reselect pasted content")
nnoremap("gV", "ggVG", "select whole buffer")
nnoremap("<leader>v", "ggVG", "select whole buffer")

-- Map <leader>o & <leader>O to newline without insert mode
nnoremap("<leader>o", ":<C-u>call append(line(\".\"), repeat([\"\"], v:count1))<CR>")
nnoremap("<leader>O", ":<C-u>call append(line(\".\")-1, repeat([\"\"], v:count1))<CR>")

-- Jumplist mutations and dealing with word wrapped lines
nnoremap("k", "v:count == 0 ? 'gk' : (v:count > 5 ? \"m'\" . v:count : '') . 'k'", { expr = true })
nnoremap("j", "v:count == 0 ? 'gj' : (v:count > 5 ? \"m'\" . v:count : '') . 'j'", { expr = true })

-- Fast previous buffer switching
nnoremap("<leader><leader>", "<C-^>")

-- Use the text that has already been typed as the prefix for searching through commands
cnoremap("<C-p>", "<Up>", { desc = "Line Up (command-mode)" })
cnoremap("<C-n>", "<Down>", { desc = "Line Down (command-mode)" })

nnoremap("<C-f>", "<C-f>zz")
nnoremap("<C-b>", "<C-b>zz")

vnoremap([[J]], [[5j]], "Jump down")
vnoremap([[K]], [[5k]], "Jump up")

-- quickly enter command mode with substitution commands prefilled
-- TODO: need to force redraw
-- nnoremap ([[<leader>/]], [[:%s/]], "Substitute")
-- nnoremap ([[<leader>?]], [[:%S/]], "Substitute (rev)")
-- vnoremap ([[<leader>/]], [[:s/]],  "Substitute")
-- vnoremap ([[<leader>?]], [[:S/]],  "Substitute (rev)")

-- Readline bindings (command)
local rl_bindings = {
  { lhs = "<c-a>", rhs = "<home>" },
  { lhs = "<c-e>", rhs = "<end>" },
}
for _, binding in ipairs(rl_bindings) do
  cnoremap(binding.lhs, binding.rhs, binding.opts or {})
end

-- don't yank the currently pasted text
vim.cmd([[xnoremap <expr> p 'pgv"' . v:register . 'y']])

-- yank to empty register for D, c, etc.
nnoremap("x", "\"_x")
nnoremap("X", "\"_X")
nnoremap("D", "\"_D")
nnoremap("c", "\"_c")
nnoremap("C", "\"_C")
nnoremap("cc", "\"_S")

xnoremap("x", "\"_x")
xnoremap("X", "\"_X")
xnoremap("D", "\"_D")
xnoremap("c", "\"_c")
xnoremap("C", "\"_C")

-- Undo breakpoints
imap(",", ",<C-g>u")
imap(".", ".<C-g>u")
imap("!", "!<C-g>u")
imap("?", "?<C-g>u")

-- REF: https://github.com/mhinz/vim-galore/blob/master/README.md#saner-behavior-of-n-and-n
nnoremap("n", "'Nn'[v:searchforward].'zzzv'.'<Esc><Cmd>lua mega.blink_cursorline(150)<CR>'", { expr = true })
xnoremap("n", "'Nn'[v:searchforward].'zzzv'.'<Esc><Cmd>lua mega.blink_cursorline(150)<CR>'", { expr = true })
onoremap("n", "'Nn'[v:searchforward].'zzzv'.'<Esc><Cmd>lua mega.blink_cursorline(150)<CR>'", { expr = true })
nnoremap("N", "'nN'[v:searchforward].'zzzv'.'<Esc><Cmd>lua mega.blink_cursorline(150)<CR>'", { expr = true })
xnoremap("N", "'nN'[v:searchforward].'zzzv'.'<Esc><Cmd>lua mega.blink_cursorline(150)<CR>'", { expr = true })
onoremap("N", "'nN'[v:searchforward].'zzzv'.'<Esc><Cmd>lua mega.blink_cursorline(150)<CR>'", { expr = true })

-- REF: https://github.com/mhinz/vim-galore/blob/master/README.md#saner-command-line-history
cnoremap("<C-n>", [[wildmenumode() ? "\<c-n>" : "\<down>"]], { expr = true })
cnoremap("<C-p>", [[wildmenumode() ? "\<c-p>" : "\<up>"]], { expr = true })

nnoremap("<leader>yf", [[:let @*=expand("%:p")<CR>]], "yank file path into the clipboard")
nnoremap("yf", [[:let @*=expand("%:p")<CR>]], "yank file path into the clipboard")

-- [custom mappings] -----------------------------------------------------------

-- Things 3
-- nnoremap("<leader>T", "<cmd>!open \"things:///add?show-quick-entry=true&title=%:t&notes=%\"<cr>", { expr = true })

-- Spelling
-- map("n", "<leader>s", "z=e") -- Correct current word
nmap("<leader>s", "b1z=e") -- Correct previous word
nmap("<leader>S", "zg") -- Add word under cursor to dictionary

-- # find and replace in multiple files
nnoremap("<leader>R", "<cmd>cfdo %s/<C-r>s//g<bar>update<cr>")

-- # save and execute vim/lua file
nmap("<leader>x", mega.save_and_exec)

-- [plugin mappings] -----------------------------------------------------------

-- # treesitter
-- ( ts treehopper )
omap("m", ":<C-U>lua require('tsht').nodes()<CR>")
vnoremap("m", ":'<'>lua require('tsht').nodes()<CR>")

-- ( ts units )
xnoremap("iu", ":lua require\"treesitter-unit\".select()<CR>")
xnoremap("au", ":lua require\"treesitter-unit\".select(true)<CR>")
onoremap("iu", ":<c-u>lua require\"treesitter-unit\".select()<CR>")
onoremap("au", ":<c-u>lua require\"treesitter-unit\".select(true)<CR>")

-- # paq
-- map("n", "<F5>", mega.sync_plugins())
nmap("<F5>", "<cmd>lua mega.sync_plugins()<cr>", "paq: sync plugins")

-- -- # dirbuf.nvim
-- nmap("<C-t>", function()
--   local buf = vim.api.nvim_buf_get_name(0)
--   vim.cmd([[vertical topleft split|vertical resize 60]])
--   require("dirbuf").open(buf)
-- end)
-- nmap("-", "<Nop>") -- disable this mapping globally, only map in dirbuf ftplugin

-- # telescope
nmap("<leader>a", "<cmd>lua require('telescope.builtin').live_grep()<cr>", "telescope: live grep for a word")
nmap("<leader>A", [[<cmd>lua require('telescope.builtin').grep_string()<cr>]], "telescope: grep for word under cursor")
vmap(
  "<leader>A",
  [[y:lua require("telescope.builtin").grep_string({ search = '<c-r>"' })<cr>]],
  "telescope: grep for visual selection"
)

-- # formatter.nvim
nmap("<leader>F", [[<cmd>FormatWrite<cr>]], "format file")

-- Map Q to replay q register
nnoremap("Q", "@q")

-----------------------------------------------------------------------------//
-- Multiple Cursor Replacement
-- http://www.kevinli.co/posts/2017-01-19-multiple-cursors-in-500-bytes-of-vimscript/
-- REF:
-- https://github.com/akinsho/dotfiles/issues/10#issuecomment-1098265323
-- https://github.com/akinsho/dotfiles/issues/9
-- https://github.com/olimorris/dotfiles/blob/main/.config/nvim/lua/Oli/core/mappings.lua#L70-L130

-- - Go on top of a word you want to change
-- - Press cn or cN
-- - Type the new word you want to replace it with
-- - Smash that dot '.' multiple times to change all the other occurrences of the word
-- It's quicker than searching or replacing. It's pure magic.
-----------------------------------------------------------------------------//
nnoremap("cn", "*``cgn", "multi-cursors forward")
nnoremap("cN", "*``cgN", "multi-cursors backward")

-- 1. Position the cursor over a word; alternatively, make a selection.
-- 2. Hit cq to start recording the macro.
-- 3. Once you are done with the macro, go back to normal mode.
-- 4. Hit Enter to repeat the macro over search matches.
function mega.mappings.setup_CR()
  nmap("<Enter>", [[:nnoremap <lt>Enter> n@z<CR>q:<C-u>let @z=strpart(@z,0,strlen(@z)-1)<CR>n@z]])
end

vim.g.mc = mega.replace_termcodes([[y/\V<C-r>=escape(@", '/')<CR><CR>]])
xnoremap("cn", [[g:mc . "``cgn"]], { expr = true, silent = true, desc = "multi-cursor forward" })
xnoremap("cN", [[g:mc . "``cgN"]], { expr = true, silent = true, desc = "multi-cursor backward" })
nnoremap("cq", [[:\<C-u>call v:lua.mega.mappings.setup_CR()<CR>*``qz]], "multi-cursor macro forward")
nnoremap("cQ", [[:\<C-u>call v:lua.mega.mappings.setup_CR()<CR>#``qz]], "multi-cursor macro backward")
xnoremap(
  "cq",
  [[":\<C-u>call v:lua.mega.mappings.setup_CR()<CR>gv" . g:mc . "``qz"]],
  { expr = true, desc = "multi cursor macro forward" }
)
xnoremap(
  "cQ",
  [[":\<C-u>call v:lua.mega.mappings.setup_CR()<CR>gv" . substitute(g:mc, '/', '?', 'g') . "``qz"]],
  { expr = true, desc = "multi cursor macro forward" }
)

---------------------------------------------------------------------------------
-- Toggle list
---------------------------------------------------------------------------------
--- Utility function to toggle the location or the quickfix list
---@param list_type '"quickfix"' | '"location"'
---@return nil
function mega.toggle_list(list_type)
  local is_location_target = list_type == "location"
  local prefix = is_location_target and "l" or "c"
  local L = vim.log.levels
  local is_open = mega.is_vim_list_open()
  if is_open then
    return fn.execute(prefix .. "close")
  end
  local list = is_location_target and fn.getloclist(0) or fn.getqflist()
  if vim.tbl_isempty(list) then
    local msg_prefix = (is_location_target and "Location" or "QuickFix")
    return vim.notify(msg_prefix .. " List is Empty.", L.WARN)
  end

  local winnr = fn.winnr()
  fn.execute(prefix .. "open")
  if fn.winnr() ~= winnr then
    vim.cmd("wincmd p")
  end
end

nnoremap("<leader>lq", function()
  mega.toggle_list("quickfix")
end, "lists: toggle quickfix")
nnoremap("<leader>lc", function()
  mega.toggle_list("location")
end, "lists: toggle location")

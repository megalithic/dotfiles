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

local vcmd = vim.cmd
local exec = mega.exec
-- NOTE: all convenience mode mappers are on the _G global; so no local assigns needed

mega.augroup("AddTerminalMappings", {
  {
    events = { "TermOpen" },
    targets = { "term://*" },
    command = function()
      if vim.bo.filetype == "" or vim.bo.filetype == "toggleterm" then
        local opts = { silent = false, buffer = 0 }
        tnoremap("<esc>", [[<C-\><C-n>]], opts)
        tnoremap("jk", [[<C-\><C-n>]], opts)
        tnoremap("<C-h>", [[<C-\><C-n><C-W>h]], opts)
        tnoremap("<C-j>", [[<C-\><C-n><C-W>j]], opts)
        tnoremap("<C-k>", [[<C-\><C-n><C-W>k]], opts)
        tnoremap("<C-l>", [[<C-\><C-n><C-W>l]], opts)
        tnoremap("]t", [[<C-\><C-n>:tablast<CR>]])
        tnoremap("[t", [[<C-\><C-n>:tabnext<CR>]])
        tnoremap("<S-Tab>", [[<C-\><C-n>:bprev<CR>]])
        tnoremap("<leader><Tab>", [[<C-\><C-n>:close \| :bnext<cr>]])
      end
    end,
  },
})

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
        windows = true, -- default bindings on <c-w>
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
    ["<leader>"] = {
      -- f = {}, -- see plugins.lua > telescope-mappings
      ["[h"] = "go to next git hunk",
      ["]h"] = "go to previous git hunk",
      e = {
        name = "edit files",
        c = { [[:Copy<cr>]], "save as <input>" },
        cp = { [[:let @+ = expand("%")<CR>]], "copy path to clipboard" },
        d = { [[:Duplicate<cr>]], "duplicate current file" },
      },
      g = {
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
      p = {
        name = "project",
        p = { "<cmd>:A<cr>", "Toggle Alternate (vsplit)" },
        P = { "<cmd>:AV<cr>", "Open Alternate (vsplit)" },
        l = { "<cmd>:Vheex<cr>", "Open Heex for LiveView (vsplit)" },
        L = { "<cmd>:Vlive<cr>", "Open Live for LiveView (vsplit)" },
      },
      m = {
        name = "markdown",
        p = { [[<cmd>MarkdownPreviewToggle<CR>]], "open preview" },
        g = { [[<cmd>Glow<CR>]], "open glow" },
      },
      r = {
        name = "runner",
        f = { "<cmd>Format<cr>", "Run _formatter" },
        r = { "", "Run  _repl" },
        n = { "<cmd>TestNearest<cr>", "Run _test under cursor" },
        a = { "<cmd>TestFile<cr>", "Run _all tests in file" },
        l = { "<cmd>TestLast<cr>", "Run _last test" },
        v = { "<cmd>TestVisit<cr>", "Run test file _visitation" },
      },
      z = {
        name = "zk",
      },
    },
    ["<localleader>"] = {
      t = {
        name = "test",
        n = { "<cmd>TestNearest<cr>", "Run _test under cursor" },
        a = { "<cmd>TestFile<cr>", "Run _all tests in file" },
        f = { "<cmd>TestFile<cr>", "Run _all tests in file" },
        l = { "<cmd>TestLast<cr>", "Run _last test" },
        t = { "<cmd>TestLast<cr>", "Run _last test" },
        v = { "<cmd>TestVisit<cr>", "Run test file _visitation" },
      },
      g = {
        name = "gitsigns",
      },
    },
    z = {
      name = "highlight/folds/paging",
      -- t = { [[<cmd>TSHighlightCapturesUnderCursor<CR>]], "show TS highlights under cursor" },
      -- TODO: ensure that we can get to these
      S = { mega.showCursorHighlights, "show syntax highlights under cursor" },
      s = { mega.showCursorHighlights, "show syntax highlights under cursor" },
      -- j = { mega.showCursorHighlights, "show syntax highlights under cursor" },
      -- S = {
      --   [[<cmd>lua require'nvim-treesitter-refactor.highlight_definitions'.highlight_usages(vim.fn.bufnr())<cr>]],
      --   "all usages under cursor",
      -- },
    },
    g = {
      name = "go-to",
      -- TODO: https://github.com/dkarter/dotfiles/blob/59e7e27b41761ece3bf2213de2977b9d5c53c3cd/vimrc#L1580-L1636
      x = { mega.open_uri, "open uri under cursor" },
      R = { "show reg-explainer" },
      j = { "mzJ`z", "join lines" },
      s = { "i<CR><ESC>^mwgk:silent! s/\v +$//<CR>:noh<CR>`w", "split line" },
    },
  }
  -- local n_mappings = {
  --   ["<leader>"] = {
  --     ["<space>"] = "file in project",
  --     ["/"] = "search in project",
  --     ["e"] = "explorer",
  --     h = {
  --       name = "help",
  --       h = "help tags",
  --       m = "man pages",
  --       o = "options nvim",
  --       t = "theme",
  --       p = {
  --         name = "plugins",
  --         C = "clean",
  --         S = "sync",
  --         c = "compile",
  --         h = "help packer",
  --         i = "install",
  --         s = "status",
  --         u = "update",
  --       },
  --     },
  --     b = {
  --       name = "buffers",
  --       n = "next buffer",
  --       p = "previous buffer",
  --       ["%"] = "source file",
  --       ["<C-t>"] = "focus in new tab",
  --       Q = "quit all other buffers",
  --       S = "save all buffers",
  --       b = "all buffers",
  --       f = "new file",
  --       h = "no highlight",
  --       q = "quit buffer",
  --       s = "save buffer",
  --       v = "new file in split",
  --       d = { "<Cmd>BufDel<CR>", "bufferline: delete current buffer" },
  --       D = { "<Cmd>BufDel!<CR>", "bufferline: force delete current buffer" },
  --     },
  --     n = {
  --       name = "notes",
  --       L = "new link",
  --       b = "zk backlinks",
  --       f = "find notes",
  --       l = "zk links",
  --       n = "new note",
  --       o = "zk orphans",
  --       t = "find tags",
  --     },
  --     w = {
  --       name = "windows",
  --       ["+"] = "increase height",
  --       ["-"] = "decrease height",
  --       [">"] = "increase width",
  --       ["<"] = "decrease width",
  --       ["="] = "normalize split layout",
  --       T = "break out into new tab",
  --       h = "jump to left window",
  --       j = "jump to the down window",
  --       k = "jump to the up window",
  --       l = "jump to the right window",
  --       m = "max out window",
  --       q = "quit window",
  --       r = "replace current with next",
  --       s = "split window",
  --       v = "vertical split",
  --       w = "cycle through windows",
  --     },
  --     -- f = {}, -- see plugins.lua > telescope-mappings
  --     ["[h"] = "go to next git hunk",
  --     ["]h"] = "go to previous git hunk",
  --     g = {
  --       name = "git",
  --       g = { "<cmd>Git<CR>", "Fugitive" },
  --       H = "browse at line",
  --       O = "browse repo",
  --       B = "browse blame at line",
  --       r = {
  --         name = "+reset",
  --         e = "gitsigns: reset entire buffer",
  --       },
  --       b = {
  --         name = "+blame",
  --         l = "gitsigns: blame current line",
  --         d = "gitsigns: toggle word diff",
  --       },
  --       h = {
  --         name = "+gitsigns hunk",
  --         s = { gs.stage_hunk, "stage" },
  --         u = { gs.undo_stage_hunk, "undo stage" },
  --         r = { gs.reset_hunk, "reset hunk" },
  --         p = { gs.preview_hunk, "preview current hunk" },
  --         d = { gs.diffthis, "diff this line" },
  --         D = {
  --           function()
  --             gs.diffthis("~")
  --           end,
  --           "diff this with ~",
  --         },
  --         b = {
  --           function()
  --             gs.blame_line({ full = true })
  --           end,
  --           "blame current line",
  --         },
  --       },
  --       w = "gitsigns: stage entire buffer",
  --       m = "gitsigns: list modified in quickfix",
  --     },
  --     q = {
  --       name = "quit/session",
  --       Q = "quit all",
  --       q = "home",
  --       l = "restore last session",
  --       c = "restore session in current directory",
  --     },
  --     p = {
  --       name = "project",
  --       p = { "<cmd>:A<cr>", "Toggle Alternate (vsplit)" },
  --       P = { "<cmd>:AV<cr>", "Open Alternate (vsplit)" },
  --       l = { "<cmd>:Vheex<cr>", "Open Heex for LiveView (vsplit)" },
  --       L = { "<cmd>:Vlive<cr>", "Open Live for LiveView (vsplit)" },
  --     },
  --     r = {
  --       name = "runner",
  --       f = { "<cmd>Format<cr>", "Run _formatter" },
  --       r = { "", "Run  _repl" },
  --       n = { "<cmd>TestNearest<cr>", "Run _test under cursor" },
  --       a = { "<cmd>TestFile<cr>", "Run _all tests in file" },
  --       l = { "<cmd>TestLast<cr>", "Run _last test" },
  --       v = { "<cmd>TestVisit<cr>", "Run test file _visitation" },
  --       --   ["."] = "find current file",
  --       --   J = "append line down",
  --       --   K = "append line up",
  --       --   b = "open file browser",
  --       --   e = "open explorer",
  --       --   f = "format",
  --       --   g = "gitsigns refresh",
  --       --   l = "open loclist window",
  --       --   n = "open neovim config",
  --       --   q = "open quickfix window",
  --       --   r = "repeat last command",
  --       --   s = "save without formatting",
  --       --   t = "open terminal",
  --       --   u = "open undotree",
  --       --   c = {
  --       --     name = "colorizer",
  --       --     a = "attach to buffer",
  --       --     t = "toggle",
  --       --   },
  --       -- },
  --       -- -- z = {
  --       -- --   name = "zen mode",
  --       -- --   a = "ataraxis",
  --       -- --   c = "centered",
  --       -- --   f = "focus",
  --       -- --   m = "minimalist",
  --       -- --   q = "quit zen mode",
  --       -- -- },
  --     },
  --     ["c"] = {
  --       ["."] = "search & replace word under cursor",
  --       ["d"] = "cd into current file",
  --     },
  --     ["["] = {
  --       L = "location first",
  --       Q = "quickfix first",
  --       l = "location prev",
  --       q = "quickfix prev",
  --     },
  --     ["]"] = {
  --       L = "location last",
  --       Q = "quickfix last",
  --       l = "location next",
  --       q = "quickfix next",
  --     },
  --   },
  -- }
  -- }}}

  -- Visual Mode {{{1
  local v_mappings = {
    ["<leader>"] = {
      ["b"] = { name = "buffers", s = "save buffer" },
      ["f"] = { "format selection" },
      ["g"] = { name = "git link", y = "copy permalink selection" },
    },
  }
  -- }}}

  -- Misc {{{1
  wk.register({
    ["g"] = {
      -- ["p"] = "select last pasted text",
      ["c"] = "comment text",
      ["cc"] = "comment line",
    },
  })
  wk.register(n_mappings, { mode = "n" })
  wk.register(v_mappings, { mode = "v" })
end

-- [convenience mappings] ------------------------------------------------------

-- make the tab key match bracket pairs
exec("silent! unmap [%", true)
exec("silent! unmap ]%", true)

nmap("<Tab>", "%")
smap("<Tab>", "%")
vmap("<Tab>", "%")
xmap("<Tab>", "%")
omap("<Tab>", "%")

-- [overrides/remaps mappings] ---------------------------------------------------------
--
exec([[
" -- ( overrides ) --
" Help
noremap <C-]> K

" Copy to system clipboard
noremap Y y$

" Better buffer navigation
"noremap J }
"noremap K {
noremap H ^
noremap L $
vnoremap L g_

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

" ## Selections
" reselect pasted content:
nnoremap gV `[v`]
" select all text in the file
nnoremap <leader>v ggVG
" Easier linewise reselection of what you just pasted.
nnoremap <leader>V V`]
" gi already moves to 'last place you exited insert mode', so we'll map gI to
" something similar: move to last change
nnoremap gI `.
" reselect visually selected content:
xnoremap > >gv

" ## Indentions
" Indent/dedent/autoindent what you just pasted.
nnoremap <lt>> V`]<
nnoremap ><lt> V`]>
nnoremap =- V`]=

" Don't overwrite blackhole register with selection
" https://www.reddit.com/r/vim/comments/clccy4/pasting_when_selection_touches_eol/
xnoremap p "_c<c-r>"<esc>
xmap P p

" Better window navigation
nnoremap <C-h> <C-w>h
nnoremap <C-j> <C-w>j
nnoremap <C-k> <C-w>k
nnoremap <C-l> <C-w>l

" Better save and quit
silent! unmap <leader>w
nnoremap <silent><leader>w :write<CR>
nnoremap <silent><leader>W :write !sudo -S tee > /dev/null %<CR>
cmap w!! w !sudo tee > /dev/null %
nnoremap <leader>q :q<CR>

" open a (new)file in a new vsplit
" nnoremap <silent><leader>o :vnew<CR>:e<space><C-d>
" nnoremap <leader>o :vnew<CR>:e<space>

" Background (n)vim
vnoremap <C-z> <ESC>zv`<ztgv

" always paste from 0 register to avoid pasting deleted text (from r/vim)
xnoremap <silent> p p:let @"=@0<CR>


function! Show_position()
  return ":\<c-u>echo 'start=" . string(getpos("v")) . " end=" . string(getpos(".")) . "'\<cr>gv"
endfunction
vmap <expr> <leader>P Show_position()

" flip between two last edited files/alternate/buffer
" nnoremap <Leader><Leader> <C-^>

" Don't overwrite blackhole register with selection
" https://www.reddit.com/r/vim/comments/clccy4/pasting_when_selection_touches_eol/
" xnoremap p "_c<c-r>"<esc>
" xmap P p

vnoremap <C-r> "hy:%Subvert/<C-r>h//gc<left><left><left>

" clear incsearch term
nnoremap <silent><ESC> :syntax sync fromstart<CR>:nohlsearch<CR>:redrawstatus!<CR><ESC>

" REF: https://github.com/savq/dotfiles/blob/master/nvim/init.lua#L90-L101
"      https://github.com/neovim/neovim/issues/4495#issuecomment-207825278
" nnoremap z= :setlocal spell<CR>z=
]])

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

-- Open file with wildmenu pum;
nmap("<leader>e", ":vnew<space>**/")

-- Map <leader>o & <leader>O to newline without insert mode
nnoremap("<leader>o", ":<C-u>call append(line(\".\"), repeat([\"\"], v:count1))<CR>")
nnoremap("<leader>O", ":<C-u>call append(line(\".\")-1, repeat([\"\"], v:count1))<CR>")

-- REF/HT:
-- https://github.com/ibhagwan/nvim-lua/blob/main/lua/keymaps.lua#L121-L139
--
-- <leader>v|<leader>s act as <cmd-v>|<cmd-s>
-- <leader>p|P paste from yank register (0)
-- map("n", "<leader>v", '"+p', { noremap = true })
-- map("n", "<leader>V", '"+P', { noremap = true })
-- map("v", "<leader>v", '"_d"+p', { noremap = true })
-- map("v", "<leader>v", '"_d"+P', { noremap = true })
-- map("n", "<leader>s", '"*p', { noremap = true })
-- map("n", "<leader>S", '"*P', { noremap = true })
-- map("v", "<leader>s", '"*p', { noremap = true })
-- map("v", "<leader>S", '"*p', { noremap = true })

-- -- Overloads for 'd|c' that don't pollute the unnamed registers
-- -- In visual-select mode 'd=delete, x=cut (unchanged)'
-- map("n", "<leader>d", '"_d', { noremap = true })
-- map("n", "<leader>D", '"_D', { noremap = true })
-- map("n", "<leader>c", '"_c', { noremap = true })
-- map("n", "<leader>C", '"_C', { noremap = true })
-- map("v", "<leader>c", '"_c', { noremap = true })
-- map("v", "d", '"_d', { noremap = true })

-- Jumplist mutations and dealing with word wrapped lines
nnoremap("k", "v:count == 0 ? 'gk' : (v:count > 5 ? \"m'\" . v:count : '') . 'k'", { expr = true })
nnoremap("j", "v:count == 0 ? 'gj' : (v:count > 5 ? \"m'\" . v:count : '') . 'j'", { expr = true })

-- Clear highlights
vcmd([[nnoremap <silent><ESC> :syntax sync fromstart<CR>:nohlsearch<CR>:redrawstatus!<CR><ESC> ]])

-- Fast previous buffer switching
nnoremap("<leader><leader>", "<C-^>")

-- Keep line in middle of buffer when searching
nnoremap("n", "(v:searchforward ? 'n' : 'N') . 'zzzv'", { expr = true, force = true })
nnoremap("N", "(v:searchforward ? 'N' : 'n') . 'zzzv'", { expr = true, force = true })

-- Readline bindings (command)
local rl_bindings = {
  { lhs = "<c-a>", rhs = "<home>" },
  { lhs = "<c-e>", rhs = "<end>" },
}
for _, binding in ipairs(rl_bindings) do
  cnoremap(binding.lhs, binding.rhs, binding.opts or {})
end

-- Undo breakpoints
imap(",", ",<C-g>u")
imap(".", ".<C-g>u")
imap("!", "!<C-g>u")
imap("?", "?<C-g>u")

-- nnoremap cn *``cgn
-- nnoremap cN *``cgN
-- - Go on top of a word you want to change
-- - Press cn or cN
-- - Type the new word you want to replace it with
-- - Smash that dot '.' multiple times to change all the other occurrences of the word
-- It's quicker than searching or replacing. It's pure magic.

-- REF: https://github.com/mhinz/vim-galore/blob/master/README.md#saner-behavior-of-n-and-n
nnoremap("n", "'Nn'[v:searchforward]", { expr = true, force = true })
xnoremap("n", "'Nn'[v:searchforward]", { expr = true, force = true })
onoremap("n", "'Nn'[v:searchforward]", { expr = true, force = true })
nnoremap("N", "'nN'[v:searchforward]", { expr = true, force = true })
xnoremap("N", "'nN'[v:searchforward]", { expr = true, force = true })
onoremap("N", "'nN'[v:searchforward]", { expr = true, force = true })

-- REF: https://github.com/mhinz/vim-galore/blob/master/README.md#saner-command-line-history
cnoremap("<C-n>", [[wildmenumode() ? "\<c-n>" : "\<down>"]], { expr = true })
cnoremap("<C-p>", [[wildmenumode() ? "\<c-p>" : "\<up>"]], { expr = true })

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

-- # gist
-- vim.g.gist_open_url = true
-- vim.g.gist_default_private = true
-- map("v", "<Leader>gG", ":Gist -po<CR>")

-- # markdown-related

-- # slash
exec(
  [[
  noremap <plug>(slash-after) zz
  if has('timers')
    " blink 2 times with 50ms interval
    noremap <expr> <plug>(slash-after) 'zz'.slash#blink(2, 50)
  endif
  ]],
  true
)

-- # lightspeed
-- do -- this continues to break my f/t movements :(
-- 	function repeat_ft(reverse)
-- 		local ls = require("lightspeed")
-- 		ls.ft["instant-repeat?"] = true
-- 		ls.ft:to(reverse, ls.ft["prev-t-like?"])
-- 	end

-- 	-- map({ "n", "x" }, ";", repeat_ft(false))
-- 	-- map({ "n", "x" }, ",", repeat_ft(true))
-- 	map({ "n", "x" }, ";", "<cmd>lua repeat_ft(false)<cr>")
-- 	map({ "n", "x" }, ",", "<cmd>lua repeat_ft(true)<cr>")
-- end

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

-- # nvim-tree
-- nmap("<C-t>", "<cmd>NvimTreeToggle<CR>", "nvim-tree: toggle")

-- # dirbuf.nvim
nmap("<C-t>", "<cmd>vertical topleft split|vertical resize 60|Dirbuf<CR>", "filetree: open dirbuf")
nmap("-", "<Nop>") -- disable this mapping globally, only map in dirbuf ftplugin

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
-- REF: http://www.kevinli.co/posts/2017-01-19-multiple-cursors-in-500-bytes-of-vimscript/
-----------------------------------------------------------------------------//
nnoremap("cn", "*``cgn")
nnoremap("cN", "*``cgN")

-- 1. Position the cursor over a word; alternatively, make a selection.
-- 2. Hit cq to start recording the macro.
-- 3. Once you are done with the macro, go back to normal mode.
-- 4. Hit Enter to repeat the macro over search matches.
function mega.mappings.setup_CR()
  nmap("<Enter>", [[:nnoremap <lt>Enter> n@z<CR>q:<C-u>let @z=strpart(@z,0,strlen(@z)-1)<CR>n@z]])
end

vim.g.mc = mega.replace_termcodes([[y/\V<C-r>=escape(@", '/')<CR><CR>]])
xnoremap("cn", [[g:mc . "``cgn"]], { expr = true, silent = true })
xnoremap("cN", [[g:mc . "``cgN"]], { expr = true, silent = true })
nnoremap("cq", [[:\<C-u>call v:lua.mega.mappings.setup_CR()<CR>*``qz]])
nnoremap("cQ", [[:\<C-u>call v:lua.mega.mappings.setup_CR()<CR>#``qz]])
xnoremap("cq", [[":\<C-u>call v:lua.mega.mappings.setup_CR()<CR>gv" . g:mc . "``qz"]], { expr = true })
xnoremap(
  "cQ",
  [[":\<C-u>call v:lua.mega.mappings.setup_CR()<CR>gv" . substitute(g:mc, '/', '?', 'g') . "``qz"]],
  { expr = true }
)

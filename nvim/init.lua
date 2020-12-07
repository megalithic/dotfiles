-- ┌───────────────────────────────────────────────────────────────────────────┐
-- │                                                                           │
-- │ Setup for Lua-based plugins                                               │
-- │ --> REF: https://github.com/nanotee/nvim-lua-guide                        │
-- │                                                                           │
-- └───────────────────────────────────────────────────────────────────────────┘

_G["mega"] = require("mega.global")

local cache_dir = vim.fn.stdpath('cache')
local data_dir = vim.fn.stdpath('data')

local function initial_mappings()
    -- Disable ex mode. I'm not that smart.
    mega.map('n', 'Q', '', {})

    -- Remap the leader key.
    -- mega.map('n', '<Space>', '', {})
    mega.map('n', ',', '', {})
    vim.g.mapleader = ","
    vim.g.maplocalleader = ","

    -- <leader>w for writing (with update instead of 'write')
    mega.map('n', '<leader>w', '<cmd>update<cr>', {})
end

-- local function bootstrap_env()
--     local stdlib = require('posix.stdlib')
--     stdlib.setenv('NVIM_CACHE_DIR', cache_dir)

--     local vim_venv_bin = cache_dir .. '/venv/bin'
--     local hererocks_bin = cache_dir .. '/hr/bin'
--     local langservers_bin = cache_dir .. '/langservers/bin'

--     stdlib.setenv('PATH', string.format('%s:%s:%s:%s', langservers_bin, hererocks_bin, vim_venv_bin,
--         stdlib.getenv('PATH')))
-- end

-- local function hererocks()
--   local lua_version = string.gsub(_VERSION, 'Lua ', '')
--   local hererocks_path = cache_dir .. '/hr'
--   local share_path = hererocks_path .. '/share/lua/' .. lua_version
--   local lib_path = hererocks_path .. '/lib/lua/' .. lua_version
--   package.path = package.path .. ';' .. share_path .. '/?.lua' .. ';' .. share_path ..
--                    '/?/init.lua'
--   package.cpath = package.cpath .. ';' .. lib_path .. '/?.so'
-- end

local function global_vars()
    vim.g.netrw_home = data_dir
    vim.g.netrw_banner = 0
    vim.g.netrw_liststyle = 3
    vim.g.fzf_command_prefix = 'Fzf'
    vim.g.fzf_layout = { window = { width=0.6, height=0.5 } }
    vim.g.fzf_action = { enter='vsplit' }
    vim.g.fzf_preview_window = {'right:50%:hidden', 'alt-p'}
    vim.g.polyglot_disabled = {'markdown'; 'sensible'; 'autoindent'}
    -- vim.g.user_emmet_mode = 'i' vim.g.user_emmet_leader_key = [[<C-x>]] 
end

local function ui_options()
    vim.o.termguicolors = true
    vim.o.showcmd = false
    vim.o.laststatus = 2
    vim.o.ruler = true
    vim.o.rulerformat = [[%-14.(%l,%c   %o%)]]
    vim.o.statusline  = "%t %h%w%m%r %=%(%l,%c%V %= %P%)"
    -- vim.o.statusline="%<%f\ %h%m%r%=%-14.(%l,%c\ \ \ %o%)"
    -- vim.o.rulerformat="%-14.(%l,%c\ \ \ %o%)"
    vim.o.guicursor = ''
    vim.o.mouse = ''
    vim.o.shortmess = 'filnxtToOFIc'
    -- require('mega.nova').enable()
end

local function global_options()
    vim.o.completeopt = 'menuone,noinsert,noselect'
    vim.o.hidden = true
    vim.o.backspace = 'indent,eol,start'
    vim.o.hlsearch = false
    vim.o.incsearch = true
    vim.o.smartcase = true
    vim.o.wildmenu = true
    vim.o.wildmode = 'list:longest'
    vim.o.autoindent = true
    vim.o.smartindent = true
    vim.o.smarttab = true
    vim.o.errorbells = false
    vim.o.backup = false
    vim.o.swapfile = false
    vim.o.inccommand = 'split'
    vim.o.jumpoptions = 'stack'
end

local function misc_options()
    local opt = require('mega.tj_opts').opt

    -- Ignore compiled files
    opt.wildignore = '__pycache__'
    opt.wildignore = opt.wildignore + {'*.o' ,'*~','*.pyc','*pycache*'}
    opt.wildignore = opt.wildignore + {'*.obj','*.bin','*.dll','*.exe','*.DS_Store'}
    opt.wildignore = opt.wildignore + {'*/.git/*','*/.svn/*','*/__pycache__/*','*/build/**','*/undo/*'}
    opt.wildignore = opt.wildignore + {'*.aux','*.bbl','*.blg','*.brf','*.fls','*.fdb_latexmk','*.synctex.gz'}

    -- Cool floating window popup menu for completion on command line
    opt.pumblend = 17

    opt.wildmode = {'longest', 'list', 'full'}
    opt.wildmode = opt.wildmode - 'list'
    opt.wildmode = opt.wildmode + { 'longest', 'full' }

    opt.wildoptions = 'pum'

    opt.showmode       = false
    opt.showcmd        = true
    opt.cmdheight      = 1     -- Height of the command bar
    opt.incsearch      = true  -- Makes search act like search in modern browsers
    opt.showmatch      = true  -- show matching brackets when text indicator is over them
    opt.relativenumber = true  -- Show line numbers
    opt.number         = true  -- But show the actual number for the line we're on
    opt.ignorecase     = true  -- Ignore case when searching...
    opt.smartcase      = true  -- ... unless there is a capital letter in the query
    opt.hidden         = true  -- I like having buffers stay around
    opt.cursorline     = false  -- Highlight the current line
    opt.equalalways    = false -- I don't like my windows changing all the time
    opt.splitright     = true  -- Prefer windows splitting to the right
    opt.splitbelow     = true  -- Prefer windows splitting to the bottom
    opt.updatetime     = 1000  -- Make updates happen faster
    opt.hlsearch       = true  -- I wouldn't use this without my DoNoHL function
    opt.scrolloff      = 10    -- Make it so there are always ten lines below my cursor

    -- Tabs
    opt.autoindent     = true
    opt.cindent        = true
    opt.wrap           = true

    opt.tabstop        = 4
    opt.shiftwidth     = 4
    opt.softtabstop    = 4
    opt.expandtab      = true

    opt.breakindent    = true
    opt.showbreak      = string.rep(' ', 3) -- Make it so that long lines wrap smartly
    opt.linebreak      = true

    opt.foldmethod     = 'marker'
    opt.foldlevel      = 0
    opt.modelines      = 1

    opt.belloff        = 'all' -- Just turn the dang bell off

    opt.clipboard      = 'unnamedplus'

    opt.inccommand     = 'split'
    opt.swapfile       = false -- Living on the edge
    opt.shada          = { "!", "'1000", "<50", "s10", "h" }

    opt.mouse          = 'n'
-- Helpful related items:
    --   1. :center, :left, :right
    --   2. gw{motion} - Put cursor back after formatting motion.
    --
    -- TODO: w, {v, b, l}
    opt.formatoptions = opt.formatoptions
                        - 'a'     -- Auto formatting is BAD.
                        - 't'     -- Don't auto format my code. I got linters for that.
                        + 'c'     -- In general, I like it when comments respect textwidth
                        + 'q'     -- Allow formatting comments w/ gq
                        - 'o'     -- O and o, don't continue comments
                        + 'r'     -- But do continue when pressing enter.
                        + 'n'     -- Indent past the formatlistpat, not underneath it.
                        + 'j'     -- Auto-remove comments if possible.
                        - '2'     -- I'm not in gradeschool anymore

    -- set joinspaces
    opt.joinspaces = false         -- Two spaces and grade school, we're done

    -- set fillchars=eob:~
    opt.fillchars = { eob = "~" }
end

local function rnu()
    vim.cmd('set relativenumber')
end

-- local function folding()
--     local fold_method = 'indent'
--     vim.o.foldlevelstart = 99
--     vim.wo.foldmethod = fold_method
--     vim.schedule(function()
--         mega.augroup('folding_config', {
--                 {events = {'BufEnter'}; targets = {'*'}; command = [[setlocal foldmethod=]] .. fold_method};
--             })
--         end)
--     end

local function global_mappings()
    local rl_bindings = {
        {lhs = '<c-a>'; rhs = '<home>'; opts = {noremap = true}};
        {lhs = '<c-e>'; rhs = '<end>'; opts = {noremap = true}};
        {lhs = '<c-f>'; rhs = '<right>'; opts = {noremap = true}};
        {lhs = '<c-b>'; rhs = '<left>'; opts = {noremap = true}};
        {lhs = '<c-p>'; rhs = '<up>'; opts = {noremap = true}};
        {lhs = '<c-n>'; rhs = '<down>'; opts = {noremap = true}};
        {lhs = '<c-d>'; rhs = '<del>'; opts = {noremap = true}};
    }
    local maps = {
        n = {
            {lhs = '<leader>o'; rhs = mega.cmd_map('only')};
            {lhs = '<leader>O'; rhs = mega.cmd_map('only') .. mega.cmd_map('tabonly')};
            {
                lhs = 'j';
                rhs = [[(v:count > 8 ? "m'" . v:count : '') . 'j']];
                opts = {expr = true; noremap = true};
            };
            {
                lhs = 'k';
                rhs = [[(v:count > 8 ? "m'" . v:count : '') . 'k']];
                opts = {expr = true; noremap = true};
            };
        };
        i = {{lhs = '<c-d>'; rhs = '<del>'; opts = {noremap = true}}};
        c = rl_bindings;
        o = rl_bindings;
    }

    local win_mov_keys = {'h'; 'j'; 'k'; 'l'}
    for _, key in ipairs(win_mov_keys) do
        table.insert(maps.n, {lhs = '<leader>' .. key; rhs = mega.cmd_map('wincmd ' .. key)})
    end

    mega.create_mappings(maps)
end

local function convenience_mappings()
    -- Start search on current word under the cursor
    mega.map("n", "<Leader>/", "/<CR>")
    -- Start reverse search on current word under the cursor
    mega.map("n", "<Leader>?", "?<CR>")

    -- Convenient command mode operations
    mega.map("n", "<Leader>:", ":!")
    mega.map("n", "<Leader>;", ":<Up>")

    -- Window movements
    mega.map("n", "<C-h>", "<C-w>h")
    mega.map("n", "<C-j>", "<C-w>j")
    mega.map("n", "<C-k>", "<C-w>k")
    mega.map("n", "<C-l>", "<C-w>l")

    -- Better save and quit
    vim.cmd('silent! unmap <leader>w')
    mega.map("n", "<leader>w", ":w<CR>")
    mega.map("n", "<leader>W", ":w !sudo tee > /dev/null %<CR>")
    mega.map("n", "<leader>q", ":q<CR>")

    vim.cmd('cmap w!! w !sudo tee > /dev/null %')


    -- ( overrides / remaps ) ---------------------------------------------
    
    -- Convenient Line operations
    mega.map("n", "H", "^")
    mega.map("n", "L", "$")
    mega.map("v", "L", "g_")
    mega.map("n", "Y", '"+y')
    -- Remap VIM 0 to first non-blank character
    mega.map("n", "0", "^")
end

local function iabbrevs()
    vim.cmd([[iabbrev cabbb Co-authored-by: Bijan Boustani <bijanbwb@gmail.com>]])
    vim.cmd([[iabbrev cabpi Co-authored-by: Patrick Isaac <pisaac@enbala.com>]])
    vim.cmd([[iabbrev cabtw Co-authored-by: Tony Winn <hi@tonywinn.me>]])
end

do
    initial_mappings()
    -- hererocks()
    -- bootstrap_env()

    vim.schedule(function()
        global_options()
        global_mappings()
        convenience_mappings()
    end)

    ui_options()
    rnu()
    --folding()
    global_vars()
    misc_options()
    iabbrevs()

    require('mega.plugins')
    require('mega.statusline')
    require("mega.lc")
end


-- vim.g.mapleader = ","
-- vim.g.maplocalleader = ","

-- require("settings")
-- require("plugins")
-- require("autocmds")
-- require("keymaps")


-- [ plugins.. ] ---------------------------------------------------------------

-- require("p.fzf")
-- require("p.telescope")
-- require("p.colorizer")
-- require("p.golden_ratio")
-- require("p.treesitter")

-- [ lsp.. ] -------------------------------------------------------------------

--require("lc.config")

local remap = vim.api.nvim_set_keymap

-- Remap escape keys to something usable on home row
remap('i', 'jk',    '<Esc>', { noremap = true })
remap('c', 'jk',    '<C-C>', { noremap = true })
remap('i', '<Esc>', '<Nop>', { noremap = true })
remap('c', '<Esc>', '<Nop>', { noremap = true })
-- Use Q to execute default register.
remap('n', 'Q', '<Nop>', { noremap = true })
-- Save
remap('n', '<Leader>w', '<Esc>:w<CR>', { noremap = true })
-- Search and Replace
remap('n', 'c.', ':%s//g<Left><Left><CR>', { noremap = true })
remap('n', '<Leader>c.', ':%s/\\<<C-r><C-w>\\>//g<Left><Left>', { noremap = true })
-- Quit
remap('n', '<Leader>x', '<Esc>:x<CR>',  { noremap = true })
remap('n', '<Leader>q', '<Esc>:q<CR>',  { noremap = true })
remap('n', '<Leader>Q', '<Esc>:qa<CR>', { noremap = true })
-- Navigate buffers
remap('n', '[b', ':bprevious<CR>', { noremap = true })
remap('n', ']b', ':bnext<CR>',     { noremap = true })
remap('n', '[B', ':bfirst<CR>',    { noremap = true })
remap('n', ']B', ':blast<CR>',     { noremap = true })
-- Reload buffer
remap('n', '<Leader>e', ':e<CR>',     { noremap = true })
remap('n', '<Leader>E', ':bufdo<CR>', { noremap = true })
-- Tab navigation
remap('n', '<Leader>tp', ':tabprevious<CR>', { noremap = true })
remap('n', '<Leader>tn', ':tabnext<CR>',     { noremap = true })
remap('n', '<Leader>tf', ':tabfirst<CR>',    { noremap = true })
remap('n', '<Leader>tl', ':tablast<CR>',     { noremap = true })
remap('n', '<Leader>tN', ':tabnew<CR>',      { noremap = true })
remap('n', '<Leader>tc', ':tabclose<CR>',    { noremap = true })
-- For tags
remap('n', '[t', ':tprevious<CR>', { noremap = true })
remap('n', ']t', ':tNext<CR>',     { noremap = true })
remap('n', '[T', ':tfirst<CR>',    { noremap = true })
remap('n', ']T', ':tlast<CR>',     { noremap = true })
remap('n', '<Leader>ts', ':<C-u>tselect <C-r><C-w><CR>', { noremap = true })
-- Quickfix list mappings
remap('n', 'qo', ':copen<CR>',     { noremap = true })
remap('n', 'qc', ':cclose<CR>',    { noremap = true })
remap('n', '[q', ':cprevious<CR>', { noremap = true })
remap('n', ']q', ':cnext<CR>',     { noremap = true })
remap('n', '[Q', ':cfirst<CR>',    { noremap = true })
remap('n', ']Q', ':clast<CR>',     { noremap = true })
-- Location list mappings
remap('n', 'Lo', ':lopen<CR>',     { noremap = true })
remap('n', 'Lc', ':lclose<CR>',    { noremap = true })
remap('n', '[l', ':lprevious<CR>', { noremap = true })
remap('n', ']l', ':lnext<CR>',     { noremap = true })
remap('n', '[L', ':lfirst<CR>',    { noremap = true })
remap('n', ']L', ':lfirst<CR>',    { noremap = true })
-- Preview tags
remap('n', 'pt', ':ptag <C-R><C-W><CR>',    { noremap = true })
remap('n', '[p', ':ptprevious<CR>',         { noremap = true })
remap('n', ']p', ':ptnext<CR>',             { noremap = true })
remap('n', 'po', ':ppop<CR>',               { noremap = true })
remap('n', 'pc', ':pc<CR>',                 { noremap = true })
remap('n', 'pi', ':psearch <C-R><C-W><CR>', { noremap = true })
-- Short cuts for setting fold methods
remap('n', 'zmi', ':set foldmethod=indent<CR>', { noremap = true })
remap('n', 'zmm', ':set foldmethod=manual<CR>', { noremap = true })
remap('n', 'zme', ':set foldmethod=expr<CR>',   { noremap = true })
remap('n', 'zmk', ':set foldmethod=marker<CR>', { noremap = true })
remap('n', 'zms', ':set foldmethod=syntax<CR>', { noremap = true })

-- Key Bindings to help with terminal mode
remap('t', 'jk', '<C-\\><C-n>', { noremap = true })

-- Key bindings to move between window splits
remap('n', '<Space>0', '0<C-w>w', { noremap = true })
remap('n', '<Space>1', '1<C-w>w', { noremap = true })
remap('n', '<Space>2', '2<C-w>w', { noremap = true })
remap('n', '<Space>3', '3<C-w>w', { noremap = true })
remap('n', '<Space>4', '4<C-w>w', { noremap = true })
remap('n', '<Space>5', '5<C-w>w', { noremap = true })
remap('n', '<Space>6', '6<C-w>w', { noremap = true })
remap('n', '<Space>7', '7<C-w>w', { noremap = true })
remap('n', '<Space>8', '8<C-w>w', { noremap = true })
remap('n', '<Space>9', '9<C-w>w', { noremap = true })

-- Disable Arrow Keys
remap('i', '<Up>',    '<NOP>', { noremap = true })
remap('i', '<Down>',  '<NOP>', { noremap = true })
remap('i', '<Left>',  '<NOP>', { noremap = true })
remap('i', '<Right>', '<NOP>', { noremap = true })
remap('n', '<Up>',    '<NOP>', { noremap = true })
remap('n', '<Down>',  '<NOP>', { noremap = true })
remap('n', '<Left>',  '<NOP>', { noremap = true })
remap('n', '<Right>', '<NOP>', { noremap = true })

-- Tag helpers
remap('n', '<C-\\>', ':vsp <CR>:<C-u>tag <C-r><C-w><CR>', { noremap = true })
remap('n', '<A-]>',  ':sp <CR>:<C-u>tag <C-r><C-w><CR>',  { noremap = true })

remap('n', '<Leader>n', ':nohlsearch<CR>', { noremap = true, silent = true })

-- Move across wrapped lines like regular lines
-- Go to the first non-blank character of a line
remap('n', '0', '^', { noremap = true })
-- Just in case you need to go to the very beginning of a line
remap('n', '^', '0', { noremap = true })
-- Centre the window on each search movement
remap('n', 'n', 'nzz', { noremap = true })
remap('n', 'N', 'Nzz', { noremap = true })
remap('v', 'n', 'nzz', { noremap = true })
remap('v', 'N', 'Nzz', { noremap = true })

-- Make dot work on visually selected lines
remap('v', '.', ':norm.<CR>', { noremap = true })
-- Go to the last file we changed
remap('n', '<BS>', '<C-^>', { noremap = true })

-- Use Tab & S-Tab instead of C-g and C-t for incsearch
remap('c', '<Tab>',   'getcmdtype() =~ \'[?/]\' ? \'<C-g>\' : feedkeys(\'<Tab>\', \'int\')[1]',   { noremap = true, expr = true })
remap('c', '<S-Tab>', 'getcmdtype() =~ \'[?/]\' ? \'<C-t>\' : feedkeys(\'<S-Tab>\', \'int\')[1]', { noremap = true, expr = true })

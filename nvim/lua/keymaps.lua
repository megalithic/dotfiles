-- [ keymaps.. ] ---------------------------------------------------------------

local utils = require "utils"


-- ( telescope.nvim ) ..........................................................

utils.gmap('n', '<Leader>m', '<cmd>lua require("telescope.builtin").fd()<CR>')
utils.gmap('n', '<Leader>f', '<cmd>lua require("telescope.builtin").git_files()<CR>')
utils.gmap('n', "<Leader>a", '<cmd>lua require("telescope.builtin").live_grep()<CR>')
utils.gmap('c', '<c-r><c-r>', '<Plug>(TelescopeFuzzyCommandSearch)', {noremap = false, nowait = true})


-- ( vim-commentary ) ..........................................................

utils.gmap('n', '<Leader>c', '<cmd>Commentary<CR>')
utils.gmap('v', '<Leader>c', '<cmd>Commentary<CR>')
--utils.gmap('x', '<Leader>c', '<cmd>Commentary<CR>')


-- ( general ) .................................................................

-- Join / Split Lines
-- Keep the cursor in place while joining lines
utils.gmap("n", "J", 'mzJ`z')
-- Split line (sister to [J]oin lines above)
-- The normal use of S is covered by cc, so don't worry about shadowing it.
utils.gmap("n", "S", 'i<CR><ESC>^mwgk:silent! s/\v +$//<CR>:noh<CR>`w')

-- Spelling
-- map("x", "b1z=e") -- Correct previous word
-- utils.lmap("c", "1z=1") -- Correct current word
-- utils.lmap("s", ":lua cycle_lang()<cr>") -- Change spelling language
--
--do
--  local i = 1
--  local langs = {"", "en", "es", "de"}
--  function cycle_lang()
--    i = (i % #langs) + 1 -- update index
--    b.spelllang = langs[i] -- change spelllang
--    w.spell = langs[i] ~= "" -- if empty then nospell
--  end
--end
--
---- Poor man's Zen mode
---- utils.lmap("z", ":lua toggle_zen()<cr>")
--function toggle_zen()
--  w.list = not w.list --(hidden chars)
--  w.number = not w.number
--  w.relativenumber = not w.relativenumber
--  w.cursorline = not w.cursorline
--  w.cursorcolumn = not w.cursorcolumn
--  w.colorcolumn = w.colorcolumn == "0" and "80" or "0"
--  o.laststatus = o.laststatus == 2 and 0 or 2
--  o.ruler = not o.ruler
--end

-- Other mappings
-- utils.lmap("l", "<cmd>luafile %<cr>") -- source lua file
-- utils.lmap("t", "<cmd> sp<cr>|<cmd>te   <cr>i") -- open terminal
-- utils.lmap("rc", "<cmd> e ~/.config/nvim <cr>") -- open config directory

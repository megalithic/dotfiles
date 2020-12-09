-- ( general ) .................................................................

-- local function global_mappings()
--   local rl_bindings = {
--     {lhs = "<c-a>", rhs = "<home>", opts = {noremap = true}},
--     {lhs = "<c-e>", rhs = "<end>", opts = {noremap = true}},
--     {lhs = "<c-f>", rhs = "<right>", opts = {noremap = true}},
--     {lhs = "<c-b>", rhs = "<left>", opts = {noremap = true}},
--     {lhs = "<c-p>", rhs = "<up>", opts = {noremap = true}},
--     {lhs = "<c-n>", rhs = "<down>", opts = {noremap = true}},
--     {lhs = "<c-d>", rhs = "<del>", opts = {noremap = true}}
--   }

--   local maps = {
--     n = {
--       {lhs = "<leader>o", rhs = mega.cmd_map("only")},
--       {lhs = "<leader>O", rhs = mega.cmd_map("only") .. mega.cmd_map("tabonly")},

--         lhs = "j",
--         rhs = [[(v:count > 8 ? "m'" . v:count : '') . 'j']],
--         opts = {expr = true, noremap = true}
--       },
--       {
--         lhs = "k",
--         rhs = [[(v:count > 8 ? "m'" . v:count : '') . 'k']],
--         opts = {expr = true, noremap = true}
--       }
--     },
--     i = {{lhs = "<c-d>", rhs = "<del>", opts = {noremap = true}}},
--     c = rl_bindings,
--     o = rl_bindings
--   }

--   local win_mov_keys = {"h", "j", "k", "l"}
--   for _, key in ipairs(win_mov_keys) do
--     table.insert(maps.n, {lhs = "<leader>" .. key, rhs = mega.cmd_map("wincmd " .. key)})
--   end

--   mega.create_mappings(maps)
-- end

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
  vim.cmd("silent! unmap <leader>w")
  mega.map("n", "<leader>w", ":w<CR>")
  mega.map("n", "<leader>W", ":w !sudo tee > /dev/null %<CR>")
  mega.map("n", "<leader>q", ":q<CR>")

  vim.cmd("cmap w!! w !sudo tee > /dev/null %")
  --
  -- flip between two last edited files
  mega.map("n", "<Leader><Leader>", "<C-^>")

  -- Command mode conveniences
  mega.map("n", "<Leader>:", ":!")
  mega.map("n", "<Leader>;", ":<Up>")

  -- Selections
  mega.map("n", "gV", "`[v`]`") -- reselect pasted content
  mega.map("n", "<leader>v", "ggVG") -- select all text in the file
  mega.map("n", "<leader>V", "V`]") -- Easier linewise reselection of what you just pasted.
  -- gi already moves to 'last place you exited insert mode', so we'll map gI to
  --  something similar: move to last change
  mega.map("n", "gI", "`.")
  mega.map("x", ">", ">gv") -- reselect visually selected content:

  -- Indentions
  --  Indent/dedent/autoindent what you just pasted.
  mega.map("n", "<lt>>", "V`]<")
  mega.map("n", "><lt>", "V`]>")
  mega.map("n", "=-", "V`]=")

  -- make the tab key match bracket pairs
  vim.api.nvim_exec("silent! unmap [%", true)
  vim.api.nvim_exec("silent! unmap ]%", true)

  mega.map("n", "<Tab>", "%", {noremap = false})
  mega.map("s", "<Tab>", "%", {noremap = false})
  mega.map("n", "<Tab>", "%", {noremap = true})
  mega.map("v", "<Tab>", "%", {noremap = true})
  mega.map("x", "<Tab>", "%", {noremap = true})

  -- Background (n)vim
  mega.map("v", "<C-z>", "<ESC>zv`<ztgv")
end

local function override_mappings()
  -- Convenient Line operations
  mega.map("n", "H", "^")
  mega.map("n", "L", "$")
  mega.map("v", "L", "g_")
  mega.map("n", "Y", '"+y')
  -- Remap VIM 0 to first non-blank character
  mega.map("n", "0", "^")

  mega.map("n", "q", "<Nop>")
  mega.map("n", "Q", "@q")
  mega.map("v", "Q", ":norm @q<CR>")

  -- Join / Split Lines
  mega.map("n", "J", "mzJ`z") -- Join lines
  mega.map("n", "S", "i<CR><ESC>^mwgk:silent! s/\v +$//<CR>:noh<CR>`w") -- Split line

  -- clear highlights
  -- mega.map("n", "<silent><ESC>", ":syntax sync fromstart<CR>:nohlsearch<CR>:redrawstatus!<CR><ESC>")
  vim.api.nvim_exec([[nnoremap <silent><ESC> :syntax sync fromstart<CR>:nohlsearch<CR>:redrawstatus!<CR><ESC>
]], true)

  -- keep line in middle of buffer when searching
  mega.map("n", "n", "(v:searchforward ? 'n' : 'N') . 'zzzv'", {noremap = true, expr = true})
  mega.map("n", "N", "(v:searchforward ? 'N' : 'n') . 'zzzv'", {noremap = true, expr = true})

  -- Default to case insensitive search
  -- mega.map("n", "/", "/\v")
  --mega.map("v", "/", "/\v")
end

local function custom_mappings()
  -- Things 3
  vim.api.nvim_exec(
    [[command! -nargs=* Things :silent !open "things:///add?show-quick-entry=true&title=%:t&notes=%<cr>"]],
    true
  )
  mega.map("n", "<Leader>T", "<cmd>Things<CR>")

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

  -- Zoom the current split into it's own tab (toggleable)
  -- local function toggle_zen()
  --   vim.wo.list = not vim.wo.list --(hidden chars)
  --   vim.wo.number = not vim.wo.number
  --   vim.wo.relativenumber = not vim.wo.relativenumber
  --   vim.wo.cursorline = not vim.wo.cursorline
  --   vim.wo.cursorcolumn = not vim.wo.cursorcolumn
  --   vim.wo.colorcolumn = vim.wo.colorcolumn == "0" and "80" or "0"
  --   vim.wo.laststatus = vim.o.laststatus == 2 and 0 or 2
  --   vim.o.ruler = not vim.o.ruler
  -- end
  -- mega.map("n", "<leader>z", ":lua toggle_zen()<cr>")
end

-- Other mappings
-- utils.lmap("l", "<cmd>luafile %<cr>") -- source lua file
-- utils.lmap("t", "<cmd> sp<cr>|<cmd>te   <cr>i") -- open terminal
-- utils.lmap("rc", "<cmd> e ~/.config/nvim <cr>") -- open config directory
--
return {
  activate = function()
    -- global_mappings()
    override_mappings()
    convenience_mappings()
    custom_mappings()
  end
}

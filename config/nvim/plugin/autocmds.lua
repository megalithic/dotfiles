-- [ autocmds.. ] --------------------------------------------------------------

local vcmd, fn = vim.cmd, vim.fn
local au, augroup = mega.au, mega.augroup

-- vim.api.nvim_exec(
--   [[
--    augroup vimrc -- Ensure all autocommands are cleared
--    autocmd!
--    augroup END
--   ]],
--   ''
-- )

au([[FocusGained,BufEnter,CursorHold,CursorHoldI,BufWinEnter * if mode() != 'c' | checktime | endif]])
au([[StdinReadPost * set buftype=nofile]])
au([[FileType help wincmd L]])
au([[CmdwinEnter * nnoremap <buffer> <CR> <CR>]])
au([[VimResized * lua require('golden_size').on_win_enter()]])
au([[InsertLeave,CompleteDone * if pumvisible() == 0 | pclose | endif]])
au([[Syntax * call matchadd('TSNote', '\W\zs\(TODO\|CHANGED\)')]])
au([[Syntax * call matchadd('TSDanger', '\W\zs\(FIXME\|BUG\|HACK\)')]])
au([[Syntax * call matchadd('TSDanger', '^\(<\|=\|>\)\{7\}\([^=].\+\)\?$')]])
au([[Syntax * call matchadd('TSNote', '\W\zs\(NOTE\|INFO\|IDEA\|REF\)')]])
au([[Syntax * syn match extTodo "\<\(NOTE\|HACK\|BAD\|TODO\):\?" containedin=.*Comment.* | hi! link extTodo Todo]])
au([[VimEnter * ++once lua require('mega.start').start()]])
au([[WinEnter * if &previewwindow | setlocal wrap | endif]])
au([[FileType fzf :tnoremap <buffer> <esc> <C-c>]])
au([[FileType help,startuptime,qf,lspinfo nnoremap,man <buffer><silent> q :quit<CR>]])
au([[BufWritePre * %s/\n\+\%$//e]])

-- NOTE: presently handled by null-ls
-- Trim Whitespace
-- exec(
--   [[
--     fun! TrimWhitespace()
--         let l:save = winsaveview()
--         keeppatterns %s/\s\+$//e
--         call winrestview(l:save)
--     endfun
--     autocmd BufWritePre * :call TrimWhitespace()
-- ]],
--   false
-- )

-- augroup("auto-cursor", {
--   -- When editing a file, always jump to the last known cursor position.
--   -- Don't do it for commit messages, when the position is invalid, or when
--   -- inside an event handler (happens when dropping a file on gvim).
--   events = { "BufReadPost" },
--   targets = { "*" },
--   command = function()
--     local pos = fn.line([['"]])
--     if vim.bo.ft ~= "gitcommit" and pos > 0 and pos <= fn.line("$") then
--       vcmd("keepjumps normal g`\"")
--     end
--   end,
-- })

-- EXAMPLE of new nvim lua autocmd API:
-- vim.api.nvim_create_autocmd("FileType", {
--   pattern = { "yaml", "toml" },
--   callback = function()
--     map("n", "<C-a>", require("dial.map").inc_normal("dep_files"), { remap = true })
--   end,
-- })

if vim.env.TMUX ~= nil then
  augroup("External", {
    {
      events = { "BufEnter" },
      targets = { "*" },
      command = function()
        vim.o.titlestring = require("mega.utils").ext.title_string()
      end,
    },
    {
      events = { "VimLeavePre" },
      targets = { "*" },
      command = function()
        require("mega.utils").ext.tmux.set_statusline(true)
      end,
    },
    {
      events = { "ColorScheme", "FocusGained" },
      targets = { "*" },
      command = function()
        -- NOTE: there is a race condition here as the colors
        -- for kitty to re-use need to be set AFTER the rest of the colorscheme
        -- overrides
        vim.defer_fn(function()
          require("mega.utils").ext.tmux.set_statusline()
        end, 1)
      end,
    },
  })
end

augroup("Utilities", {
  {
    events = { "BufNewFile", "BufWritePre" },
    targets = { "*" },
    command = mega.auto_mkdir,
    -- BUG: this causes the cursor to jump to the top on VimEnter
    -- {
    --   -- When editing a file, always jump to the last known cursor position.
    --   -- Don't do it for commit messages, when the position is invalid, or when
    --   -- inside an event handler (happens when dropping a file on gvim).
    --   events = { "BufWinEnter" },
    --   targets = { "*" },
    --   command = function()
    --     local pos = fn.line([['"]])
    --     if vim.bo.ft ~= "gitcommit" and vim.fn.win_gettype() ~= "popup" and pos > 0 and pos <= fn.line("$") then
    --       vcmd("keepjumps normal g`\"")
    --     end
    --   end,
    -- },
  },
  -- BUG: this causes the cursor to jump to the top on VimEnter
  {
    -- When editing a file, always jump to the last known cursor position.
    -- Don't do it for commit messages, when the position is invalid, or when
    -- inside an event handler (happens when dropping a file on gvim).
    events = { "BufWinEnter" },
    targets = { "*" },
    command = function()
      local pos = fn.line([['"]])
      if vim.bo.ft ~= "gitcommit" and vim.fn.win_gettype() ~= "popup" and pos > 0 and pos <= fn.line("$") then
        vcmd("keepjumps normal g`\"")
      end
    end,
  },
})

augroup("Kitty", {
  {
    events = { "BufWritePost" },
    targets = { "kitty.conf" },
    command = function()
      -- auto-reload kitty upon kitty.conf write
      vim.notify(string.format(" sourced %s", vim.fn.expand("%")))
      vcmd(":silent !kill -SIGUSR1 $(pgrep kitty)")
    end,
  },
})

augroup("Plugins/Paq", {
  {
    events = { "BufWritePost" },
    targets = { "*/mega/plugins/*.lua" },
    command = function()
      -- auto-source paq-nvim upon plugins/*.lua buffer writes
      vcmd("luafile %")
      vim.notify(string.format(" sourced %s", vim.fn.expand("%")))
    end,
  },
  {
    events = { "BufEnter" },
    targets = { "<buffer>" },
    command = function()
      --- Open a repository from an "authorname/repository" string
      nnoremap("gf", function()
        local repo = vim.fn.expand("<cfile>")
        if not repo or #vim.split(repo, "/") ~= 2 then
          return vcmd("norm! gf")
        end
        local url = string.format("https://www.github.com/%s", repo)
        vim.fn.jobstart("open " .. url)
        vim.notify(string.format("Opening %s at %s", repo, url))
      end)
    end,
  },
})

augroup("YankHighlightedRegion", {
  {
    events = { "TextYankPost" },
    targets = { "*" },
    command = function()
      vim.highlight.on_yank({
        timeout = 500,
        on_visual = false,
        higroup = "Visual",
      })
    end,
  },
})

augroup("Terminal", {
  {
    events = { "TermClose" },
    targets = { "term://*" },
    command = "noremap <buffer><silent><ESC> :bd!<CR>",
  },
  {
    events = { "TermClose" },
    targets = { "term://*" },
    command = function()
      --- automatically close a terminal if the job was successful
      if not vim.v.event.status == 0 then
        vcmd("bdelete! " .. fn.expand("<abuf>"))
      end
    end,
  },
})

augroup("UpdateVim", {
  --   {
  --     -- TODO: not clear what effect this has in the post vimscript world
  --     -- it correctly sources $MYVIMRC but all the other files that it
  --     -- requires will need to be resourced or reloaded themselves
  --     events = "BufWritePost",
  --     targets = { "$DOTFILES/**/nvim/plugin/*.{lua,vim}", "$MYVIMRC" },
  --     modifiers = { "++nested" },
  --     command = function()
  --       local ok, msg = pcall(vcmd, "source $MYVIMRC | redraw | silent doautocmd ColorScheme")
  --       msg = ok and "sourced " .. vim.fn.fnamemodify(vim.env.MYVIMRC, ":t") or msg
  --       vim.notify(msg)
  --     end,
  --   },
  {
    events = { "FocusLost" },
    targets = { "*" },
    command = "silent! wall",
  },
  --   -- Make windows equal size when vim resizes
  --   {
  --     events = { "VimResized" },
  --     targets = { "*" },
  --     command = "wincmd =",
  --   },
})

augroup("LazyLoads", {
  {
    -- nvim-bqf
    events = { "FileType" },
    targets = { "qf" },
    command = [[packadd nvim-bqf]],
  },
  {
    -- nvim-bqf
    events = { "FileType" },
    targets = { "markdown" },
    command = [[packadd markdown-preview]],
  },
  {
    -- dash.nvim
    events = { "BufReadPre" },
    targets = { "*" },
    command = function()
      if mega.is_macos then
        vcmd([[packadd dash.nvim]])

        require("which-key").register({
          ["<leader>f"] = {
            name = "telescope",
            D = { require("dash").search, "dash" },
          },
          ["<leader>"] = {
            name = "dash",
            d = { [[<cmd>Dash<CR>]], "dash" },
            D = { [[<cmd>DashWord<CR>]], "dash" },
          },
        })
      end
    end,
  },
  {
    -- tmux-navigate
    -- vim-kitty-navigator
    events = { "FocusGained", "BufEnter", "VimEnter", "BufWinEnter" },
    targets = { "*" },
    command = function()
      if vim.env.TMUX ~= nil then
        vcmd([[packadd tmux-navigate]])
      else
        vcmd([[packadd vim-kitty-navigator]])
      end
    end,
  },
})

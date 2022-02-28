--
-- https://github.com/ful1e5/dotfiles/blob/main/nvim/.config/nvim/lua/au.lua
--

-- [ setup ] --------------------------------------------------------------

local cmd = vim.api.nvim_command

local function autocmd(this, event, spec)
  local is_table = type(spec) == "table"
  local pattern = is_table and spec[1] or "*"
  -- REF: https://gist.github.com/numToStr/1ab83dd2e919de9235f9f774ef8076da?permalink_comment_id=3929923#gistcomment-3929923
  -- pattern = type(pattern) == "table" and table.concat(pattern, ",") or pattern
  local action = is_table and spec[2] or spec
  if type(action) == "function" then
    action = this.set(action)
  end
  local e = type(event) == "table" and table.concat(event, ",") or event
  cmd("autocmd " .. e .. " " .. pattern .. " " .. action)
end

local S = { __au = {} }

local X = setmetatable({}, { __index = S, __newindex = autocmd, __call = autocmd })

function S.exec(id)
  S.__au[id]()
end

function S.set(fn)
  local id = string.format("%p", fn)
  S.__au[id] = fn
  return string.format("lua require(\"au\").exec(\"%s\")", id)
end

function S.group(grp, cmds)
  cmd("augroup " .. grp)
  cmd("autocmd!")
  if type(cmds) == "function" then
    cmds(X)
  else
    for _, au in ipairs(cmds) do
      autocmd(S, au[1], { au[2], au[3] })
    end
  end
  cmd("augroup END")
end

local au = X

-- [ autocmds ] --------------------------------------------------------------

au({ "FocusGained", "BufEnter", "CursorHold", "CursorHoldI", "BufWinEnter" }, {
  "*",
  function()
    vim.cmd([[ if mode() != 'c' | checktime | endif]])
  end,
})
au({ "StdinReadPost" }, {
  "*",
  function()
    vim.cmd([[set buftype=nofile]])
  end,
})
au({ "FileType" }, {
  "help",
  function()
    vim.cmd([[wincmd L]])
  end,
})
au({ "CmdwinEnter" }, {
  "*",
  function()
    vim.cmd([[nnoremap <buffer> <CR> <CR>]])
  end,
})
au({ "VimResized" }, {
  "*",
  function()
    vim.cmd([[lua require('golden_size').on_win_enter()]])
  end,
})
au({ "InsertLeave", "CompleteDone" }, {
  "*",
  function()
    vim.cmd([[if pumvisible() == 0 | pclose | endif]])
  end,
})
au({ "Syntax" }, {
  "*",
  function()
    vim.cmd([[call matchadd('TSNote', '\W\zs\(TODO\|CHANGED\)')]])
    vim.cmd([[call matchadd('TSDanger', '\W\zs\(FIXME\|BUG\|HACK\)')]])
    vim.cmd([[call matchadd('TSDanger', '^\(<\|=\|>\)\{7\}\([^=].\+\)\?$')]])
    vim.cmd([[call matchadd('TSNote', '\W\zs\(NOTE\|INFO\|IDEA\|REF\)')]])
  end,
})
au({ "FileType" }, {
  "help,startuptime,qf,lspinfo,man",
  function()
    vim.cmd([[nnoremap <buffer><silent> q :quit<CR>]])
  end,
})
au({ "BufWritePre" }, {
  "*",
  function()
    vim.cmd([[%s/\n\+\%$//e]])
  end,
})
-- au({ "BufNewFile", "BufWritePre" }, {
--   "*",
--   function()
--     mega.auto_mkdir()
--   end,
-- })
au({ "BufWritePost" }, {
  "kitty.conf",
  function()
    -- auto-reload kitty upon `kitty.conf` edit
    vim.cmd(":silent !kill -SIGUSR1 $(pgrep kitty)")
  end,
})
au({ "BufWritePost" }, {
  "*/mega/plugins.lua",
  -- "*/mega/plugins/*.lua",
  function()
    -- auto-source paq-nvim upon `plugins.lua` edit
    vim.cmd("luafile %")
  end,
})
au({ "TextYankPost" }, {
  "*",
  function()
    -- auto-source paq-nvim upon `plugins.lua` edit
    vim.highlight.on_yank({ higroup = "Substitute", timeout = 150, on_macro = true })
  end,
})

-- augroup("auto-cursor", {
--   -- When editing a file, always jump to the last known cursor position.
--   -- Don't do it for commit messages, when the position is invalid, or when
--   -- inside an event handler (happens when dropping a file on gvim).
--   events = { "BufReadPost" },
--   targets = { "*" },
--   command = function()
--     local pos = fn.line([['"]])
--     if vim.bo.ft ~= "gitcommit" and pos > 0 and pos <= fn.line("$") then
--       vim.cmd("keepjumps normal g`\"")
--     end
--   end,
-- })

au.group("Terminal", function(grp)
  grp.TermClose = {
    "*",
    function()
      vim.cmd([[noremap <buffer><silent><ESC> :bd!<CR>]])
    end,
  }
  grp.TermOpen = {
    "*",
    function()
      vim.cmd([[setlocal nonumber norelativenumber conceallevel=0 | startinsert]])
    end,
  }
end)

return X

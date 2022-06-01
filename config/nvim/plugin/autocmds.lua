-- [ autocmds.. ] --------------------------------------------------------------
--
-- REFS:
-- https://github.com/oncomouse/dotfiles/blob/master/conf/vim/init.lua#L279
-- https://github.com/akinsho/dotfiles/blob/main/.config/nvim/plugin/autocommands.lua
--

local vcmd = vim.cmd
local fn = vim.fn
local api = vim.api
local augroup = mega.augroup
local fmt = string.format
local contains = vim.tbl_contains

augroup("Startup", {
  {
    event = { "VimEnter" },
    pattern = "*",
    once = true,
    command = function()
      -- our basic dashboard/startify/alpha:
      require("mega.start").start()
    end,
  },
})

augroup("CheckOutsideTime", {
  {
    -- automatically check for changed files outside vim
    event = { "WinEnter", "FocusGained" },
    pattern = "*",
    command = "checktime",
  },
})

do
  local smart_close_filetypes = {
    "help",
    "git-status",
    "git-log",
    "gitcommit",
    "dirbuf",
    "dbui",
    "fugitive",
    "fugitiveblame",
    "LuaTree",
    "log",
    "tsplayground",
    "qf",
    "man",
    "terminal",
    "megaterm",
    "dirbuf",
    "lspinfo",
  }
  local smart_close_buftypes = {} -- Don't include no file buffers as diff buffers are nofile

  local function smart_close()
    if fn.winnr("$") ~= 1 then
      api.nvim_win_close(0, true)
    end
  end

  augroup("SmartClose", {
    {
      -- Auto open grep quickfix window
      event = { "QuickFixCmdPost" },
      pattern = { "*grep*" },
      command = "cwindow",
    },
    {
      -- Close certain filetypes by pressing q.
      event = { "FileType" },
      pattern = { "*" },
      command = function()
        local is_unmapped = fn.hasmapto("q", "n") == 0
        local is_eligible = is_unmapped
          or vim.wo.previewwindow
          or contains(smart_close_buftypes, vim.bo.buftype)
          or contains(smart_close_filetypes, vim.bo.filetype)
        if is_eligible then
          nnoremap("q", smart_close, { buffer = 0, nowait = true })
        end
      end,
    },
    {
      -- Close quick fix window if the file containing it was closed
      event = { "BufEnter" },
      command = function()
        if fn.winnr("$") == 1 and vim.bo.buftype == "quickfix" then
          api.nvim_buf_delete(0, { force = true })
        end
      end,
    },
    {
      -- automatically close corresponding loclist when quitting a window
      event = { "QuitPre" },
      nested = true,
      command = function()
        if vim.bo.filetype ~= "qf" then
          vim.cmd("silent! lclose")
        end
      end,
    },
  })
end

do
  local save_excluded = { "lua.luapad", "gitcommit", "NeogitCommitMessage", "dirbuf" }
  local function can_save()
    return mega.empty(fn.win_gettype())
      and mega.empty(vim.bo.buftype)
      and not mega.empty(vim.bo.filetype)
      and vim.bo.modifiable
      and not vim.tbl_contains(save_excluded, vim.bo.filetype)
  end

  augroup("Utilities", {
    {
      event = { "BufWritePost" },
      command = function()
        if vim.fn.getline(1) == "^#!" then
          if vim.fn.getline(1) == "/bin/" then
            vim.cmd([[chmod a+x <afile>]])
          end
        end
      end,
    },

    -- {
    --   event = { "WinNew", "WinLeave" },
    --   command = [[setlocal winhl=CursorLine:CursorLineNC,CursorLineNr:CursorLineNrNC,Normal:PanelBackground syntax=disable | TSBufDisable &filetype]],
    -- },
    -- {
    --   event = { "WinEnter" },
    --   command = [[setlocal winhl= syntax=enable | TSBufEnable &filetype]],
    -- },
    {
      event = { "BufNewFile", "BufWritePre" },
      command = function()
        -- @see https://github.com/yutkat/dotfiles/blob/main/.config/nvim/lua/rc/autocmd.lua#L113-L140
        mega.auto_mkdir()
      end,
    },
    {
      -- Last place of cursor position.
      -- When editing a file, always jump to the last known cursor position.
      -- Don't do it for commit messages, when the position is invalid.
      event = { "BufWinEnter" },
      command = function()
        -- REF:
        -- https://github.com/novasenco/nvim.config/blob/main/autoload/autocmd.vim#L34
        -- https://github.com/akinsho/dotfiles/blob/main/.config/nvim/plugin/autocommands.lua#L401-L419
        if vim.bo.ft ~= "gitcommit" and vim.fn.win_gettype() ~= "popup" then
          local last_place_mark = vim.api.nvim_buf_get_mark(0, "\"")
          local line_nr = last_place_mark[1]
          local last_line = vim.api.nvim_buf_line_count(0)

          if line_nr > 0 and line_nr <= last_line then
            vim.api.nvim_win_set_cursor(0, last_place_mark)
          end
          -- local row, col = unpack(api.nvim_buf_get_mark(0, "\""))
          -- if { row, col } ~= { 0, 0 } then
          --   -- TODO: exact column instead?
          --   local ok, msg = pcall(api.nvim_win_set_cursor, 0, { row, 0 })
          --   if not ok then
          --     vim.notify(msg, "error", { title = "Last cursor position" })
          --   else
          --     vim.cmd("normal! zz")
          --   end
          -- end
        end
      end,
    },
    {
      event = { "BufLeave" },
      command = function()
        if can_save() then
          vim.cmd("silent! update")
        end
      end,
    },
  })
end

augroup("Kitty", {
  {
    event = { "BufWritePost" },
    pattern = { "*/kitty/*.conf" },
    command = function()
      -- auto-reload kitty upon kitty.conf write
      vim.notify(fmt(" sourced %s", vim.fn.expand("%")))
      vcmd(":silent !kill -SIGUSR1 $(pgrep kitty)")
    end,
  },
})

augroup("Plugins/Paq", {
  {
    event = { "BufWritePost" },
    pattern = { "nvim/lua/mega/plugins/*.lua", "nvim/lua/plugin/*" },
    command = function()
      -- auto-source paq-nvim upon plugins/*.lua buffer writes
      vim.cmd("luafile %")
      vim.notify(fmt(" sourced %s", vim.fn.expand("%")))
    end,
    desc = "Paq reload",
  },
  {
    event = { "BufEnter" },
    buffer = 0,
    command = mega.open_plugin_url,
  },
  {
    event = { "User" },
    pattern = "PaqDoneSync",
    command = function()
      vim.cmd("Messages")
    end,
  },
})

augroup("YankHighlightedRegion", {
  {
    event = { "TextYankPost" },
    command = function()
      vim.highlight.on_yank({
        timeout = 500,
        on_visual = false,
        higroup = "Visual",
      })
    end,
  },
})

-- augroup("Terminal", {
--   {
--     event = { "TermClose" },
--     pattern = { "term://*" },
--     command = "noremap <buffer><silent><ESC> :bd!<CR>",
--   },
--   {
--     event = { "TermClose" },
--     pattern = { "term://*" },
--     command = function()
--       --- automatically close a terminal if the job was successful
--       if not vim.v.event.status == 0 then
--         vcmd("bdelete! " .. fn.expand("<abuf>"))
--       end
--     end,
--   },
-- })

augroup("UpdateVim", {
  --   {
  --     -- TODO: not clear what effect this has in the post vimscript world
  --     -- it correctly sources $MYVIMRC but all the other files that it
  --     -- requires will need to be resourced or reloaded themselves
  --     event = "BufWritePost",
  --     pattern = { "$DOTFILES/**/nvim/plugin/*.{lua,vim}", "$MYVIMRC" },
  --     nested = true,
  --     command = function()
  --       local ok, msg = pcall(vcmd, "source $MYVIMRC | redraw | silent doautocmd ColorScheme")
  --       msg = ok and "sourced " .. vim.fn.fnamemodify(vim.env.MYVIMRC, ":t") or msg
  --       vim.notify(msg)
  --     end,
  --   },
  {
    event = { "FocusLost" },
    command = "silent! wall",
  },
  {
    event = { "VimResized" },
    command = function()
      vim.cmd([[wincmd =]])
      require("golden_size").on_win_enter()
      require("virt-column").refresh()
    end,
  },
})

do
  local sidebar_fts = {
    "NvimTree",
    "dap-repl",
    "dapui_*",
    "dirbuf",
    "packer",
    "qf",
    "undotree",
    "megaterm",
    "terminal",
  }

  local function on_sidebar_enter()
    vim.wo.winhighlight = table.concat({
      "Normal:PanelBackground",
      "EndOfBuffer:PanelBackground",
      "StatusLine:PanelSt",
      "StatusLineNC:PanelStNC",
      "SignColumn:PanelBackground",
      "VertSplit:PanelVertSplit",
      "WinSeparator:PanelWinSeparator",
    }, ",")
  end

  mega.augroup("UserHighlights", {
    {
      event = { "FileType" },
      pattern = sidebar_fts,
      command = function()
        on_sidebar_enter()
      end,
    },
  })
end

augroup("LazyLoads", {
  {
    event = { "FileType" },
    pattern = { "help" },
    command = function()
      vim.cmd([[wincmd J | :resize 40]])
    end,
  },
})

do
  -- hlsearch things
  --[[
    NOTE: all of this graciously thieved from akinsho; big up to him.

    In order to get hlsearch working the way I like i.e. on when using /,?,N,n,*,#, etc. and off when
    When I'm not using them, I need to set the following:
    The mappings below are essentially faked user input this is because in order to automatically turn off
    the search highlight just changing the value of 'hlsearch' inside a function does not work
    read `:h nohlsearch`. So to have this work I check that the current mouse position is not a search
    result, if it is we leave highlighting on, otherwise I turn it off on cursor moved by faking my input
    using the expr mappings below.

    This is based on the implementation discussed here:
    https://github.com/neovim/neovim/issues/5581
  --]]

  vim.keymap.set({ "n", "v", "o", "i", "c" }, "<Plug>(StopHL)", "execute(\"nohlsearch\")[-1]", { expr = true })

  local function stop_hl_search()
    if vim.v.hlsearch == 0 or api.nvim_get_mode().mode ~= "n" then
      return
    end
    api.nvim_feedkeys(mega.replace_termcodes("<Plug>(StopHL)"), "m", false)
  end

  local function start_hl_search()
    local col = api.nvim_win_get_cursor(0)[2]
    local curr_line = api.nvim_get_current_line()
    local ok, match = pcall(fn.matchstrpos, curr_line, fn.getreg("/"), 0)
    if not ok then
      return vim.notify(match, "error", { title = "HL SEARCH" })
    end
    local _, p_start, p_end = unpack(match)
    -- if the cursor is in a search result, leave highlighting on
    if col < p_start or col > p_end then
      stop_hl_search()
    end
  end

  augroup("IncSearchHighlight", {
    {
      event = { "CursorMoved" },
      command = function()
        start_hl_search()
      end,
    },
    {
      event = { "InsertEnter" },
      command = function()
        stop_hl_search()
      end,
    },
    {
      event = { "OptionSet" },
      pattern = { "hlsearch" },
      command = function()
        vim.schedule(function()
          vim.cmd("redrawstatus")
        end)
      end,
    },
  })
end

do
  --- automatically clear commandline messages after a few seconds delay
  --- source: http://unix.stackexchange.com/a/613645
  ---@return function
  local function clear_commandline()
    --- Track the timer object and stop any previous timers before setting
    --- a new one so that each change waits for 10secs and that 10secs is
    --- deferred each time
    local timer
    return function()
      if timer then
        timer:stop()
      end
      timer = vim.defer_fn(function()
        if fn.mode() == "n" then
          vim.cmd([[echon '']])
        end
      end, 5000)
    end
  end

  augroup("ClearCommandMessages", {
    {
      event = { "CmdlineLeave", "CmdlineChanged" },
      pattern = { ":" },
      command = clear_commandline(),
    },
  })
end

augroup("GitConflicts", {
  {
    event = { "User" },
    pattern = "GitConflictDetected",
    command = function()
      vim.notify("Conflict detected in " .. vim.fn.expand("<afile>"))
      require("which-key").register({
        c = {
          name = "git-conflict",
          t = "Resolve with _Theirs",
          o = "Resolve with _Ours",
          b = "Resolve with _Both",
          q = { "<cmd>GitConflictListQf<CR>", "Send conflicts to _Quickfix" },
          ["0"] = "Resolve with None",
        },
        ["[c"] = { "<cmd>GitConflictPrevConflict<CR>", "go to prev conflict" },
        ["]c"] = { "<cmd>GitConflictNextConflict<CR>", "go to next conflict" },
      })
    end,
  },
  {
    event = { "User" },
    pattern = "GitConflictResolved",
    command = function()
      vim.notify("Conflict resolved in " .. vim.fn.expand("<afile>"))
      -- vim.keymap.set("n", "cww", function()
      --   engage.conflict_buster()
      -- end)
    end,
  },
})

augroup("Windows", {
  {
    event = { "WinEnter" },
    command = function(args)
      if vim.wo.diff then
        vim.diagnostic.disable(args.buf)
      end
    end,
  },
  {
    event = { "WinLeave" },
    command = function(args)
      if vim.wo.diff then
        vim.diagnostic.enable(args.buf)
      end
    end,
  },
})

augroup("Mini", {
  {
    event = { "FileType" },
    command = function()
      vim.cmd(
        "if index(['help', 'startify', 'dashboard', 'packer', 'neogitstatus', 'NvimTree', 'neo-tree', 'Trouble', 'DirBuf', 'markdown', 'megaterm'], &ft) != -1 || index(['nofile', 'terminal', 'megaterm', 'lsp-installer', 'lspinfo', 'markdown'], &bt) != -1 | let b:miniindentscope_disable=v:true | endif"
      )
    end,
  },
})

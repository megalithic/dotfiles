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

-- augroup("Startup", {
--   {
--     event = { "VimEnter" },
--     pattern = { "*" },
--     once = true,
--     command = function()
--       -- our basic dashboard/startify/alpha:
--       require("mega.start").start()
--     end,
--   },
-- })

augroup("CheckOutsideTime", {
  {
    -- automatically check for changed files outside vim
    event = { "WinEnter", "FocusGained" },
    pattern = { "*" },
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
    "startuptime",
    "qf",
    "man",
    "terminal",
    "megaterm",
    "dirbuf",
    "lspinfo",
  }
  local smart_close_buftypes = {} -- Don't include no file buffers as diff buffers are nofile

  local function smart_close()
    if fn.winnr("$") ~= 1 then api.nvim_win_close(0, true) end
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
        if is_eligible then nnoremap("q", smart_close, { buffer = 0, nowait = true }) end
      end,
    },
    {
      -- Close quick fix window if the file containing it was closed
      event = { "BufEnter" },
      command = function()
        if fn.winnr("$") == 1 and vim.bo.buftype == "quickfix" then api.nvim_buf_delete(0, { force = true }) end
      end,
    },
    {
      -- automatically close corresponding loclist when quitting a window
      event = { "QuitPre" },
      nested = true,
      command = function()
        if vim.bo.filetype ~= "qf" then vim.cmd("silent! lclose") end
      end,
    },
  })
end

do
  local save_excluded = {
    "lua.luapad",
    "gitcommit",
    "NeogitCommitMessage",
    "dirbuf",
    "neo-tree",
    "neo-tree-popup",
    "megaterm",
    "kittybuf",
  }
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
        if string.match(vim.fn.getline(1), "^#!") ~= nil then
          if string.match(vim.fn.getline(1), "/bin/") ~= nil then vim.cmd([[silent !chmod a+x <afile>]]) end
        end
      end,
    },
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

          if line_nr > 0 and line_nr <= last_line then vim.api.nvim_win_set_cursor(0, last_place_mark) end
        end
      end,
    },
    {
      event = { "BufLeave" },
      pattern = { "*" },
      command = function()
        if can_save() then vim.cmd.update({ mods = { silent = true } }) end
      end,
    },
  })
end

-- @trial this (or move it to `term.lua`?)
augroup("Terminal", {
  {
    event = { "TermClose" },
    pattern = { "*" },
    command = function()
      --- automatically close a terminal if the job was successful
      if not vim.v.event.status == 0 then vim.cmd.bdelete({ fn.expand("<abuf>"), bang = true }) end
    end,
  },
})

augroup("Kitty", {
  {
    event = { "BufWritePost" },
    pattern = { "*/kitty/*.conf" },
    command = function()
      -- auto-reload kitty upon kitty.conf write
      -- vim.notify(fmt(" sourced %s", vim.fn.expand("%")))
      vcmd(":silent !kill -SIGUSR1 $(grep kitty =(ps auxwww))")
    end,
  },
})

augroup("Plugins/Paq", {
  -- {
  --   event = { "BufWritePost" },
  --   pattern = { "*/nvim/lua/mega/plugins/*.lua", "*/nvim/lua/plugin/*" },
  --   command = function()
  --     -- auto-source paq-nvim upon plugins/*.lua buffer writes
  --     vim.cmd("luafile %")
  --     vim.notify(fmt(" sourced %s", vim.fn.expand("%")))
  --   end,
  --   desc = "Paq reload",
  -- },
  {
    event = { "BufEnter" },
    buffer = 0,
    command = mega.open_plugin_url,
  },
  {
    event = { "User" },
    pattern = { "PaqDoneSync" },
    command = function() vim.cmd("Messages | Cfilter Paq") end,
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
  -- {
  --   event = { "FocusLost" },
  --   command = "silent! wall",
  -- },
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
    "neo-tree",
    "packer",
    "qf",
    "undotree",
    "megaterm",
    "terminal",
    "neotest-summary",
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
      command = function() on_sidebar_enter() end,
    },
  })
end

augroup("General", {
  {
    event = { "FileType" },
    pattern = { "help" },
    command = function() vim.cmd([[wincmd J | :resize 40]]) end,
  },
  -- {
  --   event = { "BufWritePost" },
  --   pattern = { "*/spell/*.add" },
  --   command = "silent! :mkspell! %",
  -- },
  -- {
  --   event = { "InsertLeave" },
  --   pattern = { "*" },
  --   command = [[execute 'normal! mI']],
  --   desc = "global mark I for last edit",
  -- },
  -- {
  --   event = { "BufEnter", "WinEnter" },
  --   pattern = { "*/node_modules/*" },
  --   command = ":LspStop",
  -- },
  -- { event = { "BufLeave" }, pattern = { "*/node_modules/*" }, command = ":LspStart" },
  -- {
  --   event = { "FileType" },
  --   pattern = { "lua", "vim", "dart", "python", "javascript", "typescript", "rust", "md", "gitcommit" },
  --   -- FIXME: spellsitter is slow in large files
  --   command = function(args) vim.opt_local.spell = vim.api.nvim_buf_line_count(args.buf) < 8000 end,
  -- },
})

do
  augroup("ClearCommandMessages", {
    {
      event = { "CmdlineLeave", "CmdlineChanged" },
      pattern = { ":" },
      command = mega.clear_commandline(),
    },
  })
end

augroup("GitConflicts", {
  {
    event = { "User" },
    pattern = { "GitConflictDetected" },
    command = function()
      vim.notify("Conflicts detected.")
      vim.diagnostic.disable(0)
      vim.cmd("LspStop")
      vim.cmd([[GitConflictListQf]]) -- | Telescope quickfix theme=get_ivy]])

      require("which-key").register({
        c = {
          name = "git-conflict",
          ["0"] = "Resolve with _None",
          t = "Resolve with _Theirs",
          o = "Resolve with _Ours",
          b = "Resolve with _Both",
          q = { "<cmd>GitConflictListQf<CR>", "Send conflicts to _Quickfix" },
        },
        ["[c"] = { "<cmd>GitConflictPrevConflict<CR>", "go to prev conflict" },
        ["]c"] = { "<cmd>GitConflictNextConflict<CR>", "go to next conflict" },
      })
    end,
  },
  {
    event = { "User" },
    pattern = { "GitConflictResolved" },
    command = function()
      vim.notify("Conflicts resolved.")
      vim.diagnostic.enable(0)
      vim.cmd("LspStart")
      vim.cmd("cclose")

      -- vim.keymap.set("n", "cww", function()
      --   engage.conflict_buster()
      -- end)
    end,
  },
})

augroup("Windows", {
  {
    event = { "BufWinEnter" },
    command = function(args)
      if vim.wo.diff then vim.diagnostic.disable(args.buf) end
    end,
  },
  {
    event = { "BufWinLeave" },
    command = function(args)
      if vim.wo.diff then vim.diagnostic.enable(args.buf) end
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

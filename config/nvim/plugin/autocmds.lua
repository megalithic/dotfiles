-- [ autocmds.. ] --------------------------------------------------------------
--
-- REFS:
-- https://github.com/oncomouse/dotfiles/blob/master/conf/vim/init.lua#L279
-- https://github.com/akinsho/dotfiles/blob/main/.config/nvim/plugin/autocommands.lua
--

if not mega then return end
if not vim.g.enabled_plugin["autocmds"] then return end

_G.fmt = fmt or string.format
local vcmd = vim.cmd
local fn = vim.fn
local api = vim.api
local augroup = mega.augroup
local contains = vim.tbl_contains

-- do
--   local function get_workspace_if_exists()
--     local ws = nil
--     local workspaces = require("workspaces").get()
--     local cwd = vim.fn.getcwd() .. "/"
--     for _, workspace in pairs(workspaces) do
--       if cwd == workspace.path then ws = workspace end
--     end

--     return ws
--   end

--   augroup("Startup", {
--     {
--       event = { "VimEnter" },
--       pattern = { "*" },
--       once = true,
--       command = function()
--         if not vim.g.started_by_firenvim then
--           vim.cmd([[if argc() == 0 | vert help news | exec '79wincmd|' | endif]])
--           -- require("mega.start").start()
--         end
--       end,
--     },
--     -- {
--     --   event = { "VimEnter" },
--     --   pattern = { "*" },
--     --   command = function(args)
--     --     vim.schedule_wrap(function()
--     --       local ws = get_workspace_if_exists()
--     --       if ws and type(ws) == "table" and args.file == "" then
--     --         P(ws.name)
--     --         require("workspaces").open(ws.name)
--     --       else
--     --         require("mega.start").start()
--     --       end
--     --     end, 0)
--     --   end,
--     -- },
--   })
-- end

-- Skeletons (Templates)
-- REF:
-- - https://github.com/disrupted/dotfiles/blob/master/.config/nvim/plugin/skeletons.lua
-- - https://vimtricks.com/p/vim-file-templates/
-- - https://github.com/chrisgrieser/dotfiles/blob/main/.config/nvim/lua/options-and-autocmds.lua#L155-L177
mega.augroup("Skeletons", {
  {
    event = { "BufNewFile" },
    desc = "Load skeleton when creating new file",
    command = function(args)
      local skeletons = { "lua", "sh", "applescript", "js", "elixir", "ruby" }
      local ft = vim.api.nvim_buf_get_option(args.buf, "filetype")
      local ext = vim.fn.expand("%:e")

      if vim.tbl_contains(skeletons, ft) then
        if
          pcall(vim.fn, { "filereadable", fmt("~/.config/nvim/templates/skeleton.%s", ext) })
          -- and pcall(vim.cmd, (fmt("0r ~/.config/nvim/templates/skeleton.%s | normal! G", ext)))
        then
          vim.cmd(fmt("0r ~/.config/nvim/templates/skeleton.%s | normal! G", ext))
          vim.notify(fmt("loaded skeleton for %s (%s)", ft, ext), vim.log.levels.INFO, { title = "mega" })
        end
      end
    end,
  },
})

augroup("CheckOutsideTime", {
  {
    -- automatically check for changed files outside vim
    event = { "BufEnter", "FocusGained" },
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
    "preview",
    "qf",
    "man",
    "terminal",
    "megaterm",
    "dirbuf",
    "lspinfo",
    "query",
  }
  local smart_close_buftypes = {} -- Don't include no file buffers as diff buffers are nofile

  local function smart_close()
    if fn.winnr("$") ~= 1 then
      api.nvim_win_close(0, true)
      vim.cmd("wincmd p")
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
    -- {
    --   -- Last place of cursor position.
    --   -- When editing a file, always jump to the last known cursor position.
    --   -- Don't do it for commit messages, when the position is invalid.
    --   event = { "BufEnter", "BufWinEnter", "WinEnter" },
    --   command = function()
    --     -- REF:
    --     -- https://github.com/novasenco/nvim.config/blob/main/autoload/autocmd.vim#L34
    --     -- https://github.com/akinsho/dotfiles/blob/main/.config/nvim/plugin/autocommands.lua#L401-L419
    --     if vim.bo.ft ~= "gitcommit" and vim.fn.win_gettype() ~= "popup" then
    --       local last_place_mark = vim.api.nvim_buf_get_mark(0, "\"")
    --       local line_nr = last_place_mark[1]
    --       local last_line = vim.api.nvim_buf_line_count(0)

    --       if line_nr > 0 and line_nr <= last_line then vim.api.nvim_win_set_cursor(0, last_place_mark) end
    --     end
    --   end,
    -- },
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
  -- {
  --   event = { "User" },
  --   pattern = { "PaqDoneSync" },
  --   command = function() vim.cmd("Messages | Cfilter Paq") end,
  -- },
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
    "query",
  }

  local function on_sidebar_enter()
    vim.opt_local.winhighlight = table.concat({
      "Normal:PanelBackground",
      "EndOfBuffer:PanelBackground",
      "StatusLine:PanelSt",
      "StatusLineNC:PanelStNC",
      "SignColumn:PanelBackground",
      "VertSplit:PanelVertSplit",
      "WinSeparator:PanelWinSeparator",
    }, ",")

    -- vim.opt_local.winhighlight:append({
    --   Normal = "PanelBackground",
    --   EndOfBuffer = "PanelBackground",
    --   StatusLine = "PanelSt",
    --   StatusLineNC = "PanelStNC",
    --   SignColumn = "PanelBackground",
    --   VertSplit = "PanelVertSplit",
    --   WinSeparator = "PanelWinSeparator",
    -- })
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
    command = function(args)
      mega.notify("Conflicts detected.")
      vim.diagnostic.disable(args.buf)
      vim.cmd("LspStop")
      -- vim.cmd("GitConflictListQf") -- | Telescope quickfix theme=get_ivy]])

      mega.nnoremap("cq", "<cmd>GitConflictListQf<CR>", "send conflicts to qf")
      mega.nnoremap("[c", "<cmd>GitConflictPrevConflict<CR>", "go to prev conflict")
      mega.nnoremap("]c", "<cmd>GitConflictNextConflict<CR>", "go to next conflict")
    end,
  },
  {
    event = { "User" },
    pattern = { "GitConflictResolved" },
    command = function(args)
      mega.notify("Conflicts resolved.")
      vim.diagnostic.enable(args.buf)
      vim.cmd("LspStart")
      vim.cmd("cclose")
    end,
  },
})

augroup("ExternalCommands", {
  {
    -- Open images in an image viewer (probably Preview)
    event = { "BufEnter" },
    pattern = { "*.png", "*.jpg", "*.gif" },
    command = function() vim.cmd(fmt("silent! \"%s | :bw\"", vim.g.open_command .. " " .. fn.expand("%"))) end,
  },
})

augroup("LspDiagnosticExclusions", {
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

do
  vim.keymap.set({ "n", "v", "o", "i", "c", "t" }, "<Plug>(StopHL)", "execute(\"nohlsearch\")[-1]", { expr = true })
  local function stop_hl()
    if vim.v.hlsearch == 0 or api.nvim_get_mode().mode ~= "n" then return end
    api.nvim_feedkeys(mega.replace_termcodes("<Plug>(StopHL)"), "m", false)
  end
  local function hl_search()
    local col = api.nvim_win_get_cursor(0)[2]
    local curr_line = api.nvim_get_current_line()
    local ok, match = pcall(fn.matchstrpos, curr_line, fn.getreg("/"), 0)
    if not ok then return end
    local _, p_start, p_end = unpack(match)
    -- if the cursor is in a search result, leave highlighting on
    if col < p_start or col > p_end then stop_hl() end
  end

  mega.augroup("IncSearchHighlight", {
    {
      event = { "CursorMoved" },
      command = function() hl_search() end,
    },
    {
      event = { "InsertEnter" },
      command = function(evt)
        if vim.bo[evt.buf].filetype == "megaterm" then return end
        stop_hl()
      end,
    },
    {
      event = { "OptionSet" },
      pattern = { "hlsearch" },
      command = function()
        vim.schedule(function() vim.cmd.redrawstatus() end)
      end,
    },
    {
      event = { "RecordingEnter" },
      command = function() vim.o.hlsearch = false end,
    },
    {
      event = { "RecordingLeave" },
      command = function() vim.o.hlsearch = true end,
    },
  })
end

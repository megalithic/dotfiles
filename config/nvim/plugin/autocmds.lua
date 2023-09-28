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

augroup("Startup", {
  {
    event = { "VimEnter" },
    pattern = { "*" },
    once = true,
    command = function(args)
      if not vim.g.started_by_firenvim then
        if vim.fn.argc() > 1 then
          vim.schedule(function()
            mega.resize_windows(args.buf)
            require("virt-column").update()
          end, 0)
        end
      end
    end,
  },
})

augroup("CheckOutsideTime", {
  -- automatically check for changed files outside vim
  event = { "WinEnter", "BufWinEnter", "BufWinLeave", "BufRead", "BufEnter", "FocusGained" },
  command = "silent! checktime",
})

do
  local smart_close_filetypes = {
    "help",
    "git-status",
    "git-log",
    "gitcommit",
    "oil",
    "dbui",
    "fugitive",
    "fugitiveblame",
    "LuaTree",
    "log",
    "tsplayground",
    "startuptime",
    "outputpanel",
    "preview",
    "qf",
    "man",
    "terminal",
    "lspinfo",
    "neotest-output",
    "neotest-output-panel",
    "query",
    "elixirls",
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
    -- {
    --   -- automatically close corresponding loclist when quitting a window
    --   event = { "QuitPre" },
    --   nested = true,
    --   command = function()
    --     if vim.bo.filetype ~= "qf" then vim.cmd("silent! lclose") end
    --   end,
    -- },
  })
end

do
  -- local save_excluded = {
  --   "lua.luapad",
  --   "gitcommit",
  --   "NeogitCommitMessage",
  --   "dirbuf",
  --   "neo-tree",
  --   "neo-tree-popup",
  --   "megaterm",
  --   "kittybuf",
  -- }
  -- local function can_save()
  --   return mega.empty(fn.win_gettype())
  --     and mega.empty(vim.bo.buftype)
  --     and not mega.empty(vim.bo.filetype)
  --     and vim.bo.modifiable
  --     and not vim.tbl_contains(save_excluded, vim.bo.filetype)
  -- end

  augroup("Utilities", {
    {
      event = { "BufWritePost" },
      command = function(args)
        if string.match(vim.fn.getline(1), "^#!") ~= nil then
          if string.match(vim.fn.getline(1), "/bin/") ~= nil then
            vim.notify(fmt("making %s executable", args.file), L.INFO)
            vim.cmd([[!chmod a+x <afile> | update]])
            vim.schedule(function() vim.cmd("edit") end)
            -- assert(vim.uv.fs_chmod(args.match, 755), fmt("failed to make %s executable", args.file))

            -- local filename = vim.fs.basename(api.nvim_buf_get_name(0))
          end
        end
      end,
    },
    -- {
    --   event = { "BufReadPost" },
    --   command = function()
    --     if vim.fn.line("'\"") > 0 and vim.fn.line("'\"") <= vim.fn.line("$") then
    --       vim.fn.setpos(".", vim.fn.getpos("'\""))
    --       if vim.fn.prevnonblank(".") == vim.fn.line(".") then
    --         vim.api.nvim_feedkeys("zz", "n", true)
    --         vim.cmd("silent! foldopen")
    --       end
    --       mega.flash_cursorline()
    --     end
    --   end,
    -- },
    {
      event = { "BufNewFile", "BufWritePre" },
      pattern = { "*" },
      command = [[if @% !~# '\(://\)' | call mkdir(expand('<afile>:p:h'), 'p') | endif]],
      -- command = function()
      --   -- @see https://github.com/yutkat/dotfiles/blob/main/.config/nvim/lua/rc/autocmd.lua#L113-L140
      --   mega.auto_mkdir()
      -- end,
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
    -- {
    --   event = { "BufLeave" },
    --   pattern = { "*" },
    --   command = function()
    --     if can_save() then vim.cmd.update({ mods = { silent = true } }) end
    --   end,
    -- },
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
      event = { "BufEnter" },
      buffer = 0,
      command = function()
        mega.nnoremap("gf", function()
          local target = fn.expand("<cfile>")
          if require("mega.utils").is_image(target) then
            local root_dir = require("mega.utils.lsp").root_dir({ ".git" })
            dd(root_dir)
            -- naive for now:
            target = target:gsub("./samples", fmt("%s/samples", root_dir))
            dd(target)
            return require("mega.utils").preview_file(target)
          end
          if target:match("https://") then return vim.cmd("norm gx") end
          if not target or #vim.split(target, "/") ~= 2 then return vim.cmd("norm! gf") end
          local url = fmt("https://www.github.com/%s", target)
          fn.jobstart(fmt("%s %s", vim.g.open_command, url))
          vim.notify(fmt("Opening %s at %s", target, url))
        end)
      end,
    },
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
    {
      event = { "VimResized" },
      command = function(_args)
        mega.resize_windows()
        require("virt-column").update()
      end,
    },

    {
      event = { "BufEnter", "BufWritePost", "TextChanged", "InsertLeave", "FileType" },
      pattern = { "*.html", "*.heex", "*.tsx", "*.jsx", "*.ex", "elixir", "heex", "html" },
      command = function(args)
        -- dd(args)
        -- local bufnr = vim.api.nvim_get_current_buf()
        require("mega.utils").conceal_class(args.buf)
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
      -- if not vim.v.event.status == 0 then vim.cmd.bdelete({ fn.expand("<abuf>"), bang = true }) end
      if vim.v.event.status == 0 then vim.cmd.bdelete({ fn.expand("<abuf>"), bang = true }) end
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
    "SidebarNvim",
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

  augroup("UserHighlights", {
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
--
-- augroup("LspDiagnosticExclusions", {
--   {
--     event = { "BufWinEnter" },
--     command = function(args)
--       if vim.wo.diff then vim.diagnostic.disable(args.buf) end
--     end,
--   },
--   {
--     event = { "BufWinLeave" },
--     command = function(args)
--       if vim.wo.diff then vim.diagnostic.enable(args.buf) end
--     end,
--   },
-- })

do
  vim.keymap.set({ "n", "v", "o", "i", "c", "t" }, "<Plug>(StopHL)", "execute(\"nohlsearch\")[-1]", { expr = true })
  local function stop_hl()
    if vim.v.hlsearch == 0 or api.nvim_get_mode().mode ~= "n" then return end
    api.nvim_feedkeys(vim.keycode("<Plug>(StopHL)"), "m", false)
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

  augroup("IncSearchHighlight", {
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

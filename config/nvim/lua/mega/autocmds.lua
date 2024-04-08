-- [ autocmds.. ] --------------------------------------------------------------
--
-- REFS:
-- https://github.com/oncomouse/dotfiles/blob/master/conf/vim/init.lua#L279
-- https://github.com/akinsho/dotfiles/blob/main/.config/nvim/plugin/autocommands.lua
--

if not mega then return end

_G.fmt = fmt or string.format
local vcmd = vim.cmd
local fn = vim.fn
local api = vim.api
local augroup = mega.augroup
local contains = vim.tbl_contains
local U = require("mega.utils")
local SETTINGS = require("mega.settings")

augroup("Startup", {
  {
    event = { "VimEnter" },
    pattern = { "*" },
    once = true,
    desc = "Crazy behaviours for opening vim with arguments (or not)",
    command = function(args)
      -- TODO: handle situations where 2 file names given and the second is of the shape of a line number, e.g. `:200`;
      -- maybe use this? https://github.com/stevearc/dotfiles/commit/db4849d91328bb6f39481cf2e009866911c31757
      local arg = vim.api.nvim_eval("argv(0)")
      if
        not vim.g.started_by_firenvim
        and (not vim.env.TMUX_POPUP and vim.env.TMUX_POPUP ~= 1)
        and not vim.tbl_contains({ "NeogitStatus" }, vim.bo[args.buf].filetype)
      then
        if vim.fn.argc() > 1 then
          local linenr = string.match(vim.fn.argv(1), "^:(%d+)$")
          if string.find(vim.fn.argv(1), "^:%d*") ~= nil then
            vim.cmd.edit({ args = { vim.fn.argv(0) } })
            pcall(vim.api.nvim_win_set_cursor, 0, { tonumber(linenr), 0 })
            vim.api.nvim_buf_delete(args.buf + 1, { force = true })
          else
            vim.schedule(function()
              mega.resize_windows(args.buf)
              require("virt-column").update()
            end)
          end
        elseif vim.fn.argc() == 1 then
          if vim.fn.isdirectory(arg) == 1 then
            require("oil").open(arg)
          else
            -- handle editing an argument with `:300`(line number) at the end
            local bufname = vim.api.nvim_buf_get_name(args.buf)
            local root, line = bufname:match("^(.*):(%d+)$")
            if vim.fn.filereadable(bufname) == 0 and root and line and vim.fn.filereadable(root) == 1 then
              vim.schedule(function()
                vim.cmd.edit({ args = { root } })
                pcall(vim.api.nvim_win_set_cursor, 0, { tonumber(line), 0 })
                vim.api.nvim_buf_delete(args.buf, { force = true })
              end)
            end
          end
        elseif vim.fn.isdirectory(arg) == 1 then
          require("oil").open(arg)
        elseif _G.picker ~= nil and _G.picker[vim.g.picker] ~= nil and _G.picker[vim.g.picker]["startup"] then
          _G.picker[vim.g.picker]["startup"](args)
        end
      end
    end,
  },
  -- {
  --   event = { "BufNew" },
  --   desc = "Edit files with :line at the end",
  --   pattern = "*",
  --   command = function(args)
  --     local bufname = vim.api.nvim_buf_get_name(args.buf)
  --     local root, line = bufname:match("^(.*):(%d+)$")
  --     if vim.fn.filereadable(bufname) == 0 and root and line and vim.fn.filereadable(root) == 1 then
  --       vim.schedule(function()
  --         vim.cmd.edit({ args = { root } })
  --         pcall(vim.api.nvim_win_set_cursor, 0, { tonumber(line), 0 })
  --         vim.api.nvim_buf_delete(args.buf, { force = true })
  --       end)
  --     end
  --   end,
  -- },
})

augroup("CheckOutsideTime", {
  desc = "Automatically check for changed files outside vim",
  event = { "WinEnter", "BufWinEnter", "BufWinLeave", "BufRead", "BufEnter", "FocusGained" },
  command = "silent! checktime",
})

local miniindentscope_disable_ft = {
  "help",
  "alpha",
  "dashboard",
  "neo-tree",
  "Trouble",
  "lazy",
  "mason",
  "fzf",
  "dirbuf",
  "terminal",
  "fzf-lua",
  "fzflua",
  "megaterm",
  "nofile",
  "terminal",
  "megaterm",
  "lsp-installer",
  "SidebarNvim",
  "lspinfo",
  "markdown",
  "help",
  "startify",
  "packer",
  "NeogitStatus",
  "oil",
  "oil_preview",
  "DirBuf",
  "markdown",
}

local smart_close_filetypes = {
  "help",
  "git-status",
  "git-log",
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

local function do_smart_close()
  if fn.winnr("$") ~= 1 then
    api.nvim_win_close(0, true)
    vim.cmd("wincmd p")
  end
end

augroup("FileTypes", {
  {
    event = { "FileType" },
    desc = "Smart close certain filetypes with `q`",
    pattern = { "*" },
    command = function()
      local is_unmapped = fn.hasmapto("q", "n") == 0
      local is_eligible = is_unmapped
        or vim.wo.previewwindow
        or contains(smart_close_buftypes, vim.bo.buftype)
        or contains(smart_close_filetypes, vim.bo.filetype)
      if is_eligible then nnoremap("q", do_smart_close, { buffer = 0, nowait = true }) end
    end,
  },
  {
    desc = "Disable miniindentscope as needed",
    event = { "FileType" },
    pattern = miniindentscope_disable_ft,
    command = function() vim.b.miniindentscope_disable = true end,
  },
})

augroup("EnterLeaveBehaviours", {
  {
    desc = "Enable things on *Enter",
    event = { "BufEnter" },
    command = function(evt)
      vim.defer_fn(function()
        -- enable ibl for active buffer
        local ibl_ok, ibl = pcall(require, "ibl")
        if ibl_ok then ibl.setup_buffer(evt.buf, { indent = { char = SETTINGS.indent_char } }) end
      end, 1)
    end,
  },
  {
    desc = "Disable things on *Leave",
    event = { "BufLeave" },
    command = function(evt)
      vim.defer_fn(function()
        -- disable ibl for inactive buffer
        local ibl_ok, ibl = pcall(require, "ibl")
        if ibl_ok then ibl.setup_buffer(evt.buf, { indent = { char = "" } }) end
      end, 1)
    end,
  },
})

augroup("Utilities", {
  {
    desc = "Auto open grep quickfix window",
    event = { "QuickFixCmdPost" },
    pattern = { "*grep*" },
    command = "cwindow",
  },
  {
    desc = "Close quick fix window if the file containing it was closed",
    event = { "BufEnter" },
    command = function()
      if fn.winnr("$") == 1 and vim.bo.buftype == "quickfix" then api.nvim_buf_delete(0, { force = true }) end
    end,
  },
  {
    event = { "QuitPre" },
    nested = true,
    desc = "Auto-close corresponding loclist when quitting a window",
    command = function()
      if vim.bo.filetype ~= "qf" then vim.cmd.lclose({ mods = { silent = true } }) end
    end,
  },
  {
    event = { "BufWritePost" },
    desc = "Auto chmod +x shell scripts, as needed",
    command = function(args)
      local not_executable = vim.fn.getfperm(vim.fn.expand("%")):sub(3, 3) ~= "x"
      local has_shebang = string.match(vim.fn.getline(1), "^#!")
      local has_bin = string.match(vim.fn.getline(1), "/bin/")
      if not_executable and has_shebang and has_bin then
        vim.notify(fmt("made %s executable", args.file), L.INFO)
        vim.cmd([[!chmod +x <afile>]])
        -- vim.cmd([[!chmod a+x <afile>]])
        -- vim.schedule(function() vim.cmd("edit") end)
      end
    end,
  },
  -- REF: https://github.com/ribru17/nvim/blob/master/lua/autocmds.lua#L68
  -->> "RUN ONCE" ON FILE OPEN COMMANDS <<--
  -- prevent comment from being inserted when entering new line in existing comment
  {
    event = { "BufRead", "BufNewFile" },
    command = function()
      -- allow <CR> to continue block comments only
      -- https://stackoverflow.com/questions/10726373/auto-comment-new-line-in-vim-only-for-block-comments
      vim.schedule(function()
        -- TODO: find a way for this to work without changing comment format, to
        -- allow for automatic comment wrapping when hitting textwidth
        vim.opt_local.comments:remove("://")
        vim.opt_local.comments:remove(":--")
        vim.opt_local.comments:remove(":#")
        vim.opt_local.comments:remove(":%")
      end)
      vim.opt_local.bufhidden = "delete"
    end,
  },

  {
    event = { "BufNewFile", "BufWritePre" },
    desc = "Auto-mkdir recursive on-demand",
    pattern = { "*" },
    command = [[if @% !~# '\(://\)' | call mkdir(expand('<afile>:p:h'), 'p') | endif]],
    -- command = function()
    --   -- @see https://github.com/yutkat/dotfiles/blob/main/.config/nvim/lua/rc/autocmd.lua#L113-L140
    --   mega.auto_mkdir()
    -- end,
  },
  {
    event = { "BufEnter" },
    buffer = 0,
    desc = "Crazy `gf` open behaviour",
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
    desc = "Blink selection post-yank",
    command = function()
      vim.highlight.on_yank({
        timeout = 150,
        on_visual = false,
        higroup = "VisualYank",
      })
    end,
  },
  {
    event = { "VimResized", "WinResized" },
    desc = "Attempt to window resize to my liking - windows.lua (golden ratio)",
    command = function()
      vim.schedule(function()
        mega.resize_windows()
        if pcall(require, "virt-column") then require("virt-column").update() end
      end)
    end,
  },
  {
    event = { "BufEnter", "TextChanged", "InsertLeave", "FileType" },
    desc = "Conceal strings for various attributes that look like `class`",
    pattern = { "*.html", "*.heex", "*.tsx", "*.jsx", "*.ex", "elixir", "heex", "html" },
    command = function(args)
      -- require("mega.utils").conceal_class(args.buf)
    end,
  },
  -- clear marks a-z on buffer enter
  -- See: https://github.com/chentoast/marks.nvim/issues/13
  --      https://github.com/neovim/neovim/issues/4295
  -- {
  --   event = { "BufEnter" },
  --   pattern = { "*.html", "*.heex", "*.tsx", "*.jsx", "*.ex", "elixir", "heex", "html" },
  --   command = "delm a-z",
  -- },
})

-- @trial this (or move it to `term.lua`?)
augroup("Terminal", {
  {
    event = { "TermClose" },
    pattern = { "*" },
    desc = "Auto-kill terminal if the job was successful",
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
    desc = "Restart Kitty after config change",
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
  end

  augroup("UserHighlights", {
    {
      event = { "FileType" },
      pattern = sidebar_fts,
      desc = "Set sidebar/panel colors",
      command = function() on_sidebar_enter() end,
    },
  })
end

augroup("General", {
  {
    event = { "FileType" },
    pattern = { "help" },
    desc = "Resize help",
    command = function() vim.cmd([[wincmd J | :resize 40]]) end,
  },
  {
    event = { "BufHidden" },
    desc = "Delete [No Name] buffers",
    command = function(data)
      if data.file == "" and vim.bo[data.buf].buftype == "" and not vim.bo[data.buf].modified then
        vim.schedule(function() pcall(vim.api.nvim_buf_delete, data.buf, {}) end)
      end
    end,
  },
  -- {
  --   event = { "CmdlineChanged" },
  --   command = function()
  --     -- dd("CmdlineChanged")
  --     pcall(vim.cmd.redraw)
  --     pcall(vim.cmd.redrawstatus)
  --   end,
  -- },
  -- {
  --   event = { "CmdwinEnter" },
  --   desc = "Disable incremental selection when entering the cmdline window",
  --   command = "TSBufDisable incremental_selection",
  -- },
  -- {
  --   event = { "CmdwinLeave" },
  --   desc = "Enable incremental selection when leaving the cmdline window",
  --   command = "TSBufEnable incremental_selection",
  -- },
  {
    event = { "BufEnter", "WinEnter", "WinNew", "VimResized" },
    -- NOTE: keeps cursorline centered (`zz`'d);
    -- TODO: add function to toggle this
    desc = "Keeps cursorline in center of screen when screen sharing",
    command = function()
      if vim.g.is_screen_sharing then vim.wo[0].scrolloff = 1 + math.floor(vim.api.nvim_win_get_height(0) / 2) end
    end,
  },
  {
    event = { "BufWritePost" },
    pattern = { "*/spell/*.add" },
    desc = "Run mkspell after writing to a dictionary",
    command = "silent! :mkspell! %",
  },
  {
    event = { "BufEnter" },
    desc = "Disable autoformat when not in my preferred code repos/folders",
    command = function(args)
      vim.b[args.buf].disable_autoformat = vim.g.started_by_firenvim
      local paths = vim.split(vim.o.runtimepath, ",")
      if paths ~= nil then
        local match = mega.find(function(dir)
          if dir == nil then return false end
          local path = api.nvim_buf_get_name(args.buf)
          if path == nil then return false end
          if vim.startswith(path, vim.g.code) then return false end
          if vim.startswith(path, vim.env.VIMRUNTIME) then return true end
          return vim.startswith(path, dir)
        end, paths)
        -- vim.b[args.buf].formatting_disabled = match ~= nil
        vim.b[args.buf].disable_autoformat = match ~= nil
      end
    end,
  },
  {
    event = { "BufWritePost" },
    pattern = { "*" },
    nested = true,
    desc = "Correctly set filetype",
    command = function()
      if mega.falsy(vim.bo.filetype) or vim.fn.exists("b:ftdetect") == 1 then
        vim.cmd([[
        unlet! b:ftdetect
        filetype detect
        call v:lua.vim.notify('Filetype set to ' . &ft, "info", {})
      ]])
      end
    end,
  },
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

-- do
augroup("ClearCommandMessages", {
  {
    event = { "CmdlineLeave", "CmdlineChanged" },
    pattern = { ":" },
    command = U.clear_commandline(),
  },
})
-- end
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

-- -----------------------------------------------------------------------------
-- # IncSearch behaviours
-- HT: akinsho
-- -----------------------------------------------------------------------------
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

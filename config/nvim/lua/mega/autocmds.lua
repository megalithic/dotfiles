local fmt = string.format
local map = vim.keymap.set

local SETTINGS = require("mega.settings")
local U = require("mega.utils")

local M = {}

---@class Autocommand
---@field desc string
---@field event  string[] list of autocommand events
---@field pattern string[] list of autocommand patterns
---@field command string | function
---@field nested  boolean
---@field once    boolean
---@field buffer  number
---@field enabled boolean

---Create an autocommand
---returns the group ID so that it can be cleared or manipulated.
---@param name string
---@param ... Autocommand A list of autocommands to create (variadic parameter)
---@return number
function M.augroup(name, commands)
  --- Validate the keys passed to mega.augroup are valid
  ---@param name string
  ---@param cmd Autocommand
  local function validate_autocmd(name, cmd)
    local keys = { "event", "buffer", "pattern", "desc", "callback", "command", "group", "once", "nested", "enabled" }
    local incorrect = U.fold(function(accum, _, key)
      if not vim.tbl_contains(keys, key) then table.insert(accum, key) end
      return accum
    end, cmd, {})
    if #incorrect == 0 then return end
    vim.schedule(
      function()
        vim.notify("Incorrect keys: " .. table.concat(incorrect, ", "), vim.log.levels.ERROR, {
          title = fmt("Autocmd: %s", name),
        })
      end
    )
  end

  assert(name ~= "User", "The name of an augroup CANNOT be User")

  local auname = fmt("mega-%s", name)
  local id = vim.api.nvim_create_augroup(auname, { clear = true })

  for _, autocmd in ipairs(commands) do
    if autocmd.enabled == nil or autocmd.enabled == true then
      validate_autocmd(name, autocmd)
      local is_callback = type(autocmd.command) == "function"
      vim.api.nvim_create_autocmd(autocmd.event, {
        group = id,
        pattern = autocmd.pattern,
        desc = autocmd.desc,
        callback = is_callback and autocmd.command or nil,
        command = not is_callback and autocmd.command or nil,
        once = autocmd.once,
        nested = autocmd.nested,
        buffer = autocmd.buffer,
      })
    end
  end

  return id
end

function M.apply()
  M.augroup("Startup", {
    {
      event = { "VimEnter" },
      pattern = { "*" },
      enabled = true,
      once = true,
      desc = "Crazy behaviours for opening vim with arguments (or not)",
      command = function(evt)
        local args = vim.api.nvim_eval("argv()")
        local arg_count = #args

        if
          not vim.g.started_by_firenvim
          and (not vim.env.TMUX_POPUP and vim.env.TMUX_POPUP ~= 1)
          and not vim.tbl_contains({ "NeogitStatus" }, vim.bo[evt.buf].filetype)
        then
          if arg_count == 0 then
            if mega.picker ~= nil and mega.picker["startup"] ~= nil then mega.picker.startup(evt.buf) end
          elseif arg_count == 1 then
            local arg = args[1]
            if vim.fn.isdirectory(arg) == 1 then
              require("oil").open(arg)
            else
              -- handle single argment like `filename.lua:300`
              local bufname = vim.api.nvim_buf_get_name(evt.buf)
              local root, line = bufname:match("^(.*):(%d+)$")
              if vim.fn.filereadable(bufname) == 0 and root and line and vim.fn.filereadable(root) == 1 then
                vim.schedule(function()
                  vim.cmd.edit({ args = { root } })
                  pcall(vim.api.nvim_win_set_cursor, 0, { tonumber(line), 0 })
                  vim.api.nvim_buf_delete(evt.buf, { force = true })
                end)
              end
            end
          elseif arg_count == 2 then
            local line = string.match(args[2], "^:(%d+)$")
            local root = vim.api.nvim_buf_get_name(evt.buf)
            -- handle argments like `filename.lua :300`
            if string.find(args[2], "^:%d*") ~= nil then
              if root and vim.fn.filereadable(root) == 1 and line then
                vim.cmd.edit({ args = { root } })
                pcall(vim.api.nvim_win_set_cursor, 0, { tonumber(line), 0 })
                vim.api.nvim_buf_delete(evt.buf + 1, { force = true })
              end
            else
              vim.schedule(function()
                mega.resize_windows(evt.buf)
                require("virt-column").update()
              end)
            end
          else
            vim.schedule(function()
              mega.resize_windows(evt.buf)
              require("virt-column").update()
            end)
          end
        end
      end,
    },
  })

  M.augroup("AutoSave", {
    {
      event = { "BufWinLeave", "BufLeave", "FocusLost" },
      desc = "Automatically update and write modified buffer on certain events",
      command = function(ctx)
        local saveInstantly = ctx.event == "FocusLost" or ctx.event == "BufLeave"
        local bufnr = ctx.buf
        local bo = vim.bo[bufnr]
        local b = vim.b[bufnr]
        if bo.buftype ~= "" or bo.ft == "gitcommit" or bo.readonly then return end
        if b.saveQueued and not saveInstantly then return end

        b.saveQueued = true
        vim.defer_fn(function()
          if not vim.api.nvim_buf_is_valid(bufnr) then return end
          -- `noautocmd` prevents weird cursor movement
          vim.api.nvim_buf_call(bufnr, function() vim.cmd("silent! noautocmd lockmarks update!") end)
          b.saveQueued = false
        end, saveInstantly and 0 or 2000)
        -- local bufnr = ctx.buf
        -- local bo = vim.bo[bufnr]
        -- local b = vim.b[bufnr]
        -- if bo.buftype ~= "" or bo.ft == "gitcommit" or bo.readonly then return end
        -- if b.saveQueued and ctx.event ~= "FocusLost" then return end

        -- if vim.bo.modified and not vim.bo.readonly and vim.fn.expand("%") ~= "" and vim.bo.buftype == "" then
        --   local debounce = ctx.event == "FocusLost" and 0 or 1000 -- save at once on focus loss
        --   b.saveQueued = true
        --   vim.defer_fn(function()
        --     if not vim.api.nvim_buf_is_valid(bufnr) then return end
        --     -- `noautocmd` prevents weird cursor movement
        --     vim.api.nvim_buf_call(bufnr, function()
        --       vim.cmd("silent! noautocmd lockmarks update!")
        --       vim.cmd("silent! write")
        --       vim.g.is_saving = true
        --     end)
        --     b.saveQueued = false

        --     vim.defer_fn(function()
        --       vim.g.is_saving = false
        --       pcall(vim.cmd.redrawstatus)
        --     end, 500)
        --   end, debounce)
        -- end
      end,
    },
  })

  M.augroup("HighlightYank", {
    {
      desc = "Highlight when yanking (copying) text",
      event = { "TextYankPost" },
      command = function() vim.highlight.on_yank({ timeout = 500, on_visual = false, higroup = "VisualYank" }) end,
    },
  })

  M.augroup("CheckOutsideTime", {
    desc = "Automatically check for changed files outside vim",
    event = { "WinEnter", "BufWinEnter", "BufWinLeave", "BufRead", "BufEnter", "FocusGained" },
    command = function() vim.cmd.checktime() end,
  })

  M.augroup("SmartCloseBuffers", {
    {
      event = { "FileType" },
      desc = "Smart close certain filetypes with `q`",
      pattern = { "*" },
      command = function()
        -- local is_unmapped = vim.fn.hasmapto("q", "n") == 0
        local is_eligible =
          -- is_unmapped
          vim.wo.previewwindow or vim.tbl_contains({}, vim.bo.buftype) or vim.tbl_contains({
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
          }, vim.bo.filetype)
        if is_eligible then
          map("n", "q", function()
            if vim.fn.winnr("$") ~= 1 then
              -- dbg("smart close quit mappings")
              vim.api.nvim_win_close(0, true)
              vim.cmd("wincmd p")
            end
          end, { buffer = 0, nowait = true, desc = "smart buffer quit" })
        end
      end,
    },
  })

  local function clear_commandline()
    --- Track the timer object and stop any previous timers before setting
    --- a new one so that each change waits for 10secs and that 10secs is
    --- deferred each time
    local timer

    return function()
      if timer then timer:stop() end

      timer = vim.defer_fn(function()
        if vim.fn.mode() == "n" then vim.cmd.echon("''") end
      end, 10000)
    end
  end

  M.augroup("CmdlineBehaviours", {
    {
      event = "CmdlineEnter",
      command = function(ctx)
        if not ctx.match == ":" then return end
        local cmdline = vim.fn.getcmdline()
        local isSubstitution = cmdline:find("s ?/.+/.-/%a*$")
        if isSubstitution then vim.cmd(cmdline .. "ne") end
      end,
    },
    {
      event = "CmdlineLeave",
      command = function(ctx)
        if not ctx.match == ":" then return end
        vim.defer_fn(function()
          local lineJump = vim.fn.histget(":", -1):match("^%d+$")
          if lineJump then vim.fn.histdel(":", -1) end
        end, 100)
      end,
    },
    {
      event = { "CmdlineLeave", "CmdlineChanged" },
      desc = "Clear command line messages",
      pattern = { ":" },
      command = clear_commandline(),
    },
  })

  M.augroup("EnterLeaveBehaviours", {
    {
      desc = "Enable things on *Enter",
      event = { "BufEnter", "WinEnter" },
      command = function(evt)
        vim.defer_fn(function()
          local ibl_ok, ibl = pcall(require, "ibl")
          if ibl_ok then ibl.setup_buffer(evt.buf, { indent = { char = SETTINGS.indent_char } }) end
        end, 1)
        vim.wo.cursorline = true
        if not vim.g.started_by_firenvim then require("colorizer").attach_to_buffer(evt.buf) end
      end,
    },
    {
      desc = "Disable things on *Leave",
      event = { "BufLeave", "WinLeave" },
      command = function(evt)
        vim.defer_fn(function()
          local ibl_ok, ibl = pcall(require, "ibl")
          if ibl_ok then ibl.setup_buffer(evt.buf, { indent = { char = "" } }) end
        end, 1)
        vim.wo.cursorline = false
        if not vim.g.started_by_firenvim then require("colorizer").detach_from_buffer(evt.buf) end
      end,
    },
  })

  M.augroup("InsertBehaviours", {
    {
      enabled = not vim.g.started_by_firenvim,
      desc = "OnInsertEnter",
      event = { "InsertEnter" },
      command = function(_evt) vim.diagnostic.enable(not vim.diagnostic.is_enabled()) end,
    },
    {
      enabled = not vim.g.started_by_firenvim,
      desc = "OnInsertLeave",
      event = { "InsertLeave" },
      command = function(_evt) vim.diagnostic.enable() end,
    },
  })

  -- -----------------------------------------------------------------------------
  -- # IncSearch behaviours
  -- HT: akinsho
  -- -----------------------------------------------------------------------------
  -- vim.keymap.set({ "n", "v", "o", "i", "c", "t" }, "<Plug>(StopHL)", "execute(\"nohlsearch\")[-1]", { expr = true })
  -- local function stop_hl()
  --   if vim.v.hlsearch == 0 or vim.api.nvim_get_mode().mode ~= "n" then return end
  --   vim.api.nvim_feedkeys(vim.keycode("<Plug>(StopHL)"), "m", false)
  -- end
  -- local function hl_search()
  --   local col = vim.api.nvim_win_get_cursor(0)[2]
  --   local curr_line = vim.api.nvim_get_current_line()
  --   local ok, match = pcall(vim.fn.matchstrpos, curr_line, vim.fn.getreg("/"), 0)
  --   if not ok then return end
  --   local _, p_start, p_end = unpack(match)
  --   -- if the cursor is in a search result, leave highlighting on
  --   if col < p_start or col > p_end then stop_hl() end
  -- end
  -- M.augroup("IncSearchHighlight", {
  --   {
  --     event = { "CursorMoved" },
  --     command = function() hl_search() end,
  --   },
  --   {
  --     event = { "InsertEnter" },
  --     command = function(evt)
  --       if vim.bo[evt.buf].filetype == "megaterm" then return end
  --       stop_hl()
  --     end,
  --   },
  --   {
  --     event = { "OptionSet" },
  --     pattern = { "hlsearch" },
  --     command = function()
  --       vim.schedule(function() vim.cmd.redrawstatus() end)
  --     end,
  --   },
  --   {
  --     event = { "RecordingEnter" },
  --     command = function() vim.o.hlsearch = false end,
  --   },
  --   {
  --     event = { "RecordingLeave" },
  --     command = function() vim.o.hlsearch = true end,
  --   },
  -- })

  --- @trial: determining if this implementation of the above IncSearchHighlight autocmd is more reliable
  -- REF: https://github.com/ibhagwan/nvim-lua/blob/main/lua/autocmd.lua#L111-L144

  function mega.searchCountIndicator(mode)
    local signColumnPlusScrollbarWidth = 2 + 3 -- CONFIG

    local countNs = vim.api.nvim_create_namespace("searchCounter")
    vim.api.nvim_buf_clear_namespace(0, countNs, 0, -1)
    if mode == "clear" then return end

    local row = vim.api.nvim_win_get_cursor(0)[1]
    local last_search = vim.fn.getreg("/")
    local count = vim.fn.searchcount()
    if count.total == 0 then return end
    local text = (" %d/%d (%s) "):format(count.current, count.total, last_search)
    local line = vim.api.nvim_get_current_line():gsub("\t", (" "):rep(vim.bo.shiftwidth))
    local lineFull = #line + signColumnPlusScrollbarWidth >= vim.api.nvim_win_get_width(0)
    local margin = { (" "):rep(lineFull and signColumnPlusScrollbarWidth or 0) }

    vim.api.nvim_buf_set_extmark(0, countNs, row - 1, 0, {
      virt_text = { { text, "IncSearch" }, margin },
      virt_text_pos = lineFull and "right_align" or "eol",
      priority = 200, -- so it comes in front of lsp-endhints
    })
  end

  -- without the `searchCountIndicator`, this `on_key` simply does `auto-nohl`
  vim.on_key(function(char)
    local key = vim.fn.keytrans(char)
    local isCmdlineSearch = vim.fn.getcmdtype():find("[/?]") ~= nil
    local isNormalMode = vim.api.nvim_get_mode().mode == "n"
    local searchStarted = (key == "/" or key == "?") and isNormalMode
    local searchConfirmed = (key == "<CR>" and isCmdlineSearch)
    local searchCancelled = (key == "<Esc>" and isCmdlineSearch)
    if not (searchStarted or searchConfirmed or searchCancelled or isNormalMode) then return end

    -- works for RHS, therefore no need to consider remaps
    local searchMovement = vim.tbl_contains({ "n", "N", "*", "#" }, key)

    if searchCancelled or (not searchMovement and not searchConfirmed) then
      vim.opt.hlsearch = false
      mega.searchCountIndicator("clear")
    elseif searchMovement or searchConfirmed or searchStarted then
      vim.opt.hlsearch = true
      vim.defer_fn(mega.searchCountIndicator, 1)
    end
  end, vim.api.nvim_create_namespace("autoNohlAndSearchCount"))

  -- M.augroup("ToggleSearchHL", {
  --   {
  --     event = { "CursorMoved" },
  --     command = function()
  --       if vim.snippet.active() then
  --         vim.cmd.nohlsearch()
  --         return
  --       end

  --       vim.defer_fn(function()
  --         -- No bloat lua adpatation of: https://github.com/romainl/vim-cool
  --         local view, rpos = vim.fn.winsaveview(), vim.fn.getpos(".")
  --         -- Move the cursor to a position where (whereas in active search) pressing `n`
  --         -- brings us to the original cursor position, in a forward search / that means
  --         -- one column before the match, in a backward search ? we move one col forward
  --         vim.cmd(string.format("silent! keepjumps go%s", (vim.fn.line2byte(view.lnum) + view.col + 1 - (vim.v.searchforward == 1 and 2 or 0))))
  --         -- Attempt to goto next match, if we're in an active search cursor position
  --         -- should be equal to original cursor position
  --         local ok, _ = pcall(vim.cmd, "silent! keepjumps norm! n")
  --         local in_search = ok
  --           and (function()
  --             local npos = vim.fn.getpos(".")
  --             return npos[2] == rpos[2] and npos[3] == rpos[3]
  --           end)()
  --         -- restore original view and position
  --         vim.fn.winrestview(view)
  --         if not in_search then
  --           vim.schedule(function()
  --             vim.cmd.nohlsearch()
  --             mega.searchCountIndicator("clear")
  --           end)
  --         else
  --           vim.schedule(function() mega.searchCountIndicator() end)
  --         end
  --       end, 250)
  --     end,
  --   },
  --   {
  --     event = { "InsertEnter" },
  --     command = function(evt)
  --       if vim.snippet.active() then
  --         vim.cmd.nohlsearch()
  --         return
  --       end
  --       vim.schedule(function()
  --         vim.cmd.nohlsearch()
  --         vim.schedule(function() mega.searchCountIndicator("clear") end)
  --       end)
  --     end,
  --   },
  -- })

  M.augroup("Utilities", {
    {
      event = { "VimResized" },
      --     desc = "Automatically resize windows in all tabpages when resizing Vim",
      command = function(args)
        vim.schedule(function()
          vim.cmd("tabdo wincmd =")
          mega.resize_windows(args.buf)
        end)
      end,
    },
    {
      event = { "QuickFixCmdPost" },
      desc = "Goes to first item in quickfix list automatically in Trouble",
      command = function(_args)
        vim.cmd([[Trouble qflist open]])
        pcall(vim.cmd.cfirst)
      end,
    },
    {
      event = { "UIEnter", "ColorScheme" },
      desc = "Remove terminal padding around neovim instance",
      command = function(_args)
        local normal = vim.api.nvim_get_hl(0, { name = "Normal" })
        if not normal.bg then return end
        io.write(string.format("\027]11;#%06x\027\\", normal.bg))
      end,
    },
    {
      event = { "UILeave" },
      desc = "remove terminal padding around neovim instance",
      command = function(_args) io.write("\027]111\027\\") end,
    },
    {
      event = { "TermClose" },
      command = function(args)
        --- automatically close a terminal if the job was successful
        if U.falsy(vim.v.event.status) and U.falsy(vim.bo[args.buf].ft) then vim.cmd.bdelete({ args.buf, bang = true }) end
      end,
    },

    --     {
    -- local no_lastplace = {
    --     buftypes = {
    --         "quickfix",
    --         "nofile",
    --         "help",
    --         "terminal",
    --     },
    --     filetypes = {
    --         "gitcommit",
    --         "gitrebase",
    --     },
    -- }
    --
    -- aucmd({ "BufReadPost" }, {
    --     pattern = "*",
    --     desc = "Jump to last place in files",
    --     group = augroup("JumpToLastPosition", { clear = true }),
    --     callback = function()
    --         if
    --             vim.fn.line [['"]] >= 1
    --             and vim.fn.line [['"]] <= vim.fn.line "$"
    --             and not vim.tbl_contains(no_lastplace.buftypes, vim.o.buftype)
    --             and not vim.tbl_contains(no_lastplace.filetypes, vim.o.filetype)
    --         then
    --             vim.cmd [[normal! g`" | zv]]
    --         end
    --     end,
    -- })
    --     },

    {
      event = { "BufWritePost" },
      desc = "chmod +x shell scripts on-demand",
      command = function(args)
        local not_executable = vim.fn.getfperm(vim.fn.expand("%")):sub(3, 3) ~= "x"
        local has_shebang = string.match(vim.fn.getline(1), "^#!")
        local has_bin = string.match(vim.fn.getline(1), "/bin/")
        if not_executable and has_shebang and has_bin then
          vim.notify(fmt("made %s executable", args.file), L.INFO)
          -- vim.cmd([[!chmod +x "%"]]) -- or a+x ?
          vim.cmd([[silent !chmod +x <afile>]]) -- or a+x ?
          vim.defer_fn(function() vim.cmd("edit") end, 100)
        end
      end,
    },
    -- REF: https://github.com/ribru17/nvim/blob/master/lua/autocmds.lua#L68
    -->> "RUN ONCE" ON FILE OPEN COMMANDS <<--
    --
    {
      event = { "BufRead", "BufNewFile" },
      enabled = false,
      desc = "Prevents comment from being inserted when entering new line in existing comment",
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
      desc = "Recursive mkdir on-demand",
      pattern = { "*" },
      command = [[if @% !~# '\(://\)' | call mkdir(expand('<afile>:p:h'), 'p') | endif]],
      -- command = function()
      --   -- @see https://github.com/yutkat/dotfiles/blob/main/.config/nvim/lua/rc/autocmd.lua#L113-L140
      --   mega.auto_mkdir()
      -- end,
    },
    {
      event = "BufWritePost",
      pattern = ".envrc",
      command = function()
        if vim.fn.executable("direnv") then vim.cmd([[silent !direnv allow %]]) end
      end,
    },
    {
      event = "BufWritePost",
      pattern = "*/spell/*.add",
      command = "silent! :mkspell! %",
    },
    {
      event = { "BufEnter", "BufRead", "BufNewFile" },
      buffer = 0,
      desc = "Extreeeeme `gf` open behaviour",
      command = function(args)
        map("n", "gf", function()
          local target = vim.fn.expand("<cfile>")

          -- FIXME: get working with ghostty
          -- if U.is_image(target) then
          --   local root_dir = require("mega.utils.lsp").root_dir({ ".git" })
          --   target = target:gsub("./samples", fmt("%s/samples", root_dir))
          --   return require("mega.utils").preview_file(target)
          -- end

          -- go to linear ticket
          if target:match("TRN-") then
            local url = fmt("https://linear.app/ternit/issue/%s", target)
            vim.notify(fmt("Opening linear ticket %s at %s", target, url))
            vim.fn.jobstart(fmt("%s %s", vim.g.open_command, url))

            return false
          end

          -- go to PR for specific repos
          if target:match("^PR%-([DIR|BELL|RET|MOB]*)#(%d*)") then
            local repo_abbr, pr_num = target:match("^PR%-([DIR|BELL|RET|MOB]*)#(%d*)")
            local repos = {
              DIR = "director",
              BELL = "bellhop",
              RET = "retriever",
              MOB = "ternreturns",
            }

            local url = fmt("https://github.com/TernSystems/%s/pull/%s", repos[repo_abbr], pr_num)
            vim.notify(fmt("Opening PR %d on %s", pr_num, repos[repo_abbr]))
            vim.fn.jobstart(fmt("%s %s", vim.g.open_command, url))

            return false
          end

          -- go to hex packages
          if args.file:match("mix.exs") then
            local line = vim.fn.getline(".")
            local _, _, pkg, _ = string.find(line, [[^%s*{:(.*), %s*"(.*)"}]])

            local url = fmt("https://hexdocs.pm/%s/", pkg)
            vim.notify(fmt("Opening %s at %s", pkg, url))
            vim.fn.jobstart(fmt("%s %s", vim.g.open_command, url))

            return false
          end

          -- go to node packages
          if args.file:match("package.json") then
            local line = vim.fn.getline(".")
            local _, _, pkg, _ = string.find(line, [[^%s*"(.*)":%s*"(.*)"]])

            local url = fmt("https://www.npmjs.com/package/%s", pkg)
            vim.notify(fmt("Opening %s at %s", pkg, url))
            vim.fn.jobstart(fmt("%s %s", vim.g.open_command, url))

            return false
          end

          -- go to web address
          if target:match("https://") then return vim.cmd("norm gx") end

          -- a normal file, so do the normal go-to-file thing
          if not target or #vim.split(target, "/") ~= 2 then return vim.cmd("norm! gf") end

          -- maybe it's a github repo? try it and see..
          local url = fmt("https://github.com/%s", target)
          vim.fn.jobstart(fmt("%s %s", vim.g.open_command, url))
          vim.notify(fmt("Opening %s at %s", target, url))
        end, { desc = "[g]oto [f]ile (on steroids)" })
      end,
    },
    {
      event = { "BufRead", "BufNewFile" },
      pattern = "*/doc/*.txt",
      command = function(args) vim.bo.filetype = "help" end,
    },
    {
      event = { "BufRead", "BufNewFile" },
      pattern = "package.json",
      command = function(args)
        vim.keymap.set({ "n" }, "gx", function()
          local line = vim.fn.getline(".")
          local _, _, pkg, _ = string.find(line, [[^%s*"(.*)":%s*"(.*)"]])

          if pkg then
            local url = "https://www.npmjs.com/package/" .. pkg
            vim.ui.open(url)
          end
        end, { buffer = true, silent = true, desc = "[g]o to node [p]ackage" })
      end,
    },
    {
      event = { "BufRead", "BufNewFile" },
      pattern = "mix.exs",
      command = function(args)
        vim.keymap.set({ "n" }, "gx", function()
          local line = vim.fn.getline(".")
          local _, _, pkg, _ = string.find(line, [[^%s*{:(.*), %s*"(.*)"}]])

          if pkg then
            local url = fmt("https://hexdocs.pm/%s/", pkg)
            vim.ui.open(url)
          end
        end, { buffer = true, silent = true, desc = "[g]o to hex [p]ackage" })
      end,
    },
  })
end

return M

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

  local id = vim.api.nvim_create_augroup(fmt("mega-%s", name), { clear = true })

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
          elseif mega.picker ~= nil and mega.picker["startup"] ~= nil then
            mega.picker.startup(args.buf)
          end
        end
      end,
    },
    {
      enabled = false,
      event = { "VimEnter" },
      pattern = { "*" },
      once = true,
      desc = "Advanced startup behaviours based upon the arguments given..",
      command = function(args)
        local startup_allowed = function()
          return not vim.g.started_by_firenvim
            and (not vim.env.TMUX_POPUP and vim.env.TMUX_POPUP ~= 1)
            and not vim.tbl_contains({ "NeogitStatus" }, vim.bo[args.buf].filetype)
        end

        -- TODO: handle situations where 2 file names given and the second is of the shape of a line number, e.g. `:200`;
        -- maybe use this? https://github.com/stevearc/dotfiles/commit/db4849d91328bb6f39481cf2e009866911c31757
        local startup_args = vim.api.nvim_eval("argv()")

        if startup_allowed() then
          -- cli_args > 1; usually a few files to open in splits, or a file and a `:ln_no`
          if #startup_args > 1 then
            -- we opened a file, and a line_no (e.g. path/to/file.txt :20)
            local linenr = string.match(startup_args[1], "^:(%d+)$")
            if string.find(startup_args[1], "^:%d*") ~= nil then
              -- open the file
              vim.cmd.edit({ args = { startup_args[0] } })
              -- jump to the line number
              pcall(vim.api.nvim_win_set_cursor, 0, { tonumber(linenr), 0 })
              -- delete the empty buffer that got opened, too
              vim.api.nvim_buf_delete(args.buf + 1, { force = true })
            else
              -- we've simply opened a few files that need to be opened in splits and resized accordingly
              vim.schedule(function()
                -- mega.resize_windows(args.buf)
                -- require("virt-column").update()
                pcall(mega.resize_windows, args.buf)
                pcall(require("virt-column").update)
              end)
            end
          -- we've passed in one (1) startup argument
          elseif #startup_args == 1 then
            -- our startup arg is a directory, according to vim..
            if vim.fn.isdirectory(startup_args[0]) == 1 then
              -- so, let's use oil to open the list of files/folders
              local ok, oil = pcall(require, "oil")
              if ok then oil.open(arg) end
            else
              -- handle editing an argument with `:300`(line number) at the end (e.g. this is when we have path/to/file.txt:20)
              local bufname = vim.api.nvim_buf_get_name(args.buf)
              local root, linenr = bufname:match("^(.*):(%d+)$")
              if vim.fn.filereadable(bufname) == 0 and root and linenr and vim.fn.filereadable(root) == 1 then
                vim.schedule(function()
                  -- open the file
                  vim.cmd.edit({ args = { root } })
                  -- jump to the line number
                  pcall(vim.api.nvim_win_set_cursor, 0, { tonumber(linenr), 0 })
                  -- delete the empty buffer that got opened, too
                  vim.api.nvim_buf_delete(args.buf, { force = true })
                end)
              end
            end
          else
            -- just opening vim without any arguments, just executes our preferred startup method
            mega.picker.startup(args.buf)
          end
        end
      end,
    },
  })

  M.augroup("HighlightYank", {
    {
      desc = "Highlight when yanking (copying) text",
      event = { "TextYankPost" },
      command = function() vim.highlight.on_yank() end,
    },
  })

  M.augroup("CheckOutsideTime", {
    desc = "Automatically check for changed files outside vim",
    event = { "WinEnter", "BufWinEnter", "BufWinLeave", "BufRead", "BufEnter", "FocusGained" },
    command = "silent! checktime",
  })

  M.augroup("SmartCloseBuffers", {
    {
      event = { "FileType" },
      desc = "Smart close certain filetypes with `q`",
      pattern = { "*" },
      command = function()
        local is_unmapped = vim.fn.hasmapto("q", "n") == 0
        local is_eligible = is_unmapped
          or vim.wo.previewwindow
          or vim.tbl_contains({}, vim.bo.buftype)
          or vim.tbl_contains({
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
              vim.api.nvim_win_close(0, true)
              vim.cmd("wincmd p")
            end
          end, { buffer = 0, nowait = true, desc = "smart buffer quit" })
        end
      end,
    },
  })

  M.augroup("CmdlineBehaviours", {
    {
      -- make `:substitute` also notify how many changes were made
      -- works, as `CmdlineLeave` is triggered before the execution of the command
      event = "CmdlineLeave",
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
      command = function(_evt)
        vim.diagnostic.enable(not vim.diagnostic.is_enabled())
        -- vim.wo.number = true
        -- vim.wo.relativenumber = false
      end,
    },
    {
      enabled = not vim.g.started_by_firenvim,
      desc = "OnInsertLeave",
      event = { "InsertLeave" },
      command = function(_evt)
        vim.diagnostic.enable()
        -- vim.wo.number = true
        -- vim.wo.relativenumber = true
      end,
    },
  })

  -- M.augroup("CursorMovementBehaviours", {
  --   {
  --     desc = "Disable things on CursorMoved",
  --     event = { "CursorMoved" },
  --     command = function(evt)
  --       vim.defer_fn(function()
  --         local ibl_ok, ibl = pcall(require, "ibl")
  --         if ibl_ok then ibl.setup_buffer(evt.buf, { indent = { char = "" } }) end
  --         -- vim.b.miniindentscope_disable = true
  --       end, 1)
  --     end,
  --   },
  --   {
  --     desc = "Enable things on CursorHold",
  --     event = { "CursorHold" },
  --     command = function(evt)
  --       vim.defer_fn(function()
  --         local ibl_ok, ibl = pcall(require, "ibl")
  --         if ibl_ok then ibl.setup_buffer(evt.buf, { indent = { char = SETTINGS.indent_char } }) end
  --         -- vim.b.miniindentscope_disable = false
  --       end, 2)
  --     end,
  --   },
  -- })

  -- -----------------------------------------------------------------------------
  -- # IncSearch behaviours
  -- HT: akinsho
  -- -----------------------------------------------------------------------------
  vim.keymap.set({ "n", "v", "o", "i", "c", "t" }, "<Plug>(StopHL)", "execute(\"nohlsearch\")[-1]", { expr = true })
  local function stop_hl()
    if vim.v.hlsearch == 0 or vim.api.nvim_get_mode().mode ~= "n" then return end
    vim.api.nvim_feedkeys(vim.keycode("<Plug>(StopHL)"), "m", false)
  end
  local function hl_search()
    local col = vim.api.nvim_win_get_cursor(0)[2]
    local curr_line = vim.api.nvim_get_current_line()
    local ok, match = pcall(vim.fn.matchstrpos, curr_line, vim.fn.getreg("/"), 0)
    if not ok then return end
    local _, p_start, p_end = unpack(match)
    -- if the cursor is in a search result, leave highlighting on
    if col < p_start or col > p_end then stop_hl() end
  end

  M.augroup("IncSearchHighlight", {
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

  M.augroup("Utilities", {
    {
      event = { "BufWritePost" },
      desc = "chmod +x shell scripts on-demand",
      command = function(args)
        local not_executable = vim.fn.getfperm(vim.fn.expand("%")):sub(3, 3) ~= "x"
        local has_shebang = string.match(vim.fn.getline(1), "^#!")
        local has_bin = string.match(vim.fn.getline(1), "/bin/")
        if not_executable and has_shebang and has_bin then
          vim.notify(fmt("made %s executable", args.file), L.INFO)
          vim.cmd([[!chmod +x <afile>]]) -- or a+x ?
          -- vim.schedule(function() vim.cmd("edit") end)
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
      event = { "BufEnter" },
      buffer = 0,
      desc = "Crazy `gf` open behaviour",
      command = function()
        map("n", "gf", function()
          local target = vim.fn.expand("<cfile>")
          if U.is_image(target) then
            local root_dir = require("mega.utils.lsp").root_dir({ ".git" })
            -- dd(root_dir)
            -- naive for now:
            target = target:gsub("./samples", fmt("%s/samples", root_dir))
            -- dd(target)
            return require("mega.utils").preview_file(target)
          end
          if target:match("https://") then return vim.cmd("norm gx") end
          if not target or #vim.split(target, "/") ~= 2 then return vim.cmd("norm! gf") end
          local url = fmt("https://www.github.com/%s", target)
          vim.fn.jobstart(fmt("%s %s", vim.g.open_command, url))
          vim.notify(fmt("Opening %s at %s", target, url))
        end, { desc = "[g]oto [f]ile (preview, github repo, url)" })
      end,
    },
  })
end

return M

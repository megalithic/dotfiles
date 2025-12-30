local U = require("config.utils")

local M = {}
local map = vim.keymap.set

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
    -- local debug_info = debug.getinfo(2)
    -- local mod_name = vim.fn.fnamemodify(debug_info.short_src, ":t:r")
    -- local mod_line = debug_info.currentline

    vim.schedule(
      function()
        vim.notify("Incorrect keys: " .. table.concat(incorrect, ", "), vim.log.levels.ERROR, {
          title = string.format("Autocmd: %s", name),
        })
      end
    )
  end

  assert(name ~= "User", "The name of an augroup CANNOT be User")

  local auname = string.format("mega_mvim-%s", name)
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

M.augroup("Filetypes", {
  {
    event = { "FileType" },
    pattern = { "gitcommit", "markdown", "text", "log", "typst" },
    desc = "Enable wrap and spell in these filetypes",
    command = function(args)
      vim.opt_local.wrap = true
      vim.opt_local.spell = true
    end,
  },
  {
    event = { "FileType" },
    pattern = "*",
    desc = "close certain file types with `q`",
    command = function(args)
      -- local is_unmapped = vim.fn.hasmapto("q", "n") == 0
      local is_eligible =
        -- is_unmapped
        vim.wo.previewwindow or vim.tbl_contains({}, vim.bo[args.buf].buftype) or vim.tbl_contains({
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
        }, vim.bo[args.buf].filetype)
      if is_eligible then
        map("n", "q", function()
          if vim.fn.winnr("$") ~= 1 then
            vim.api.nvim_win_close(0, true)
            vim.cmd("wincmd p")
          end
        end, { buffer = args.buf, nowait = true, desc = "buffer quiter" })
      end
    end,
  },
})

M.augroup("Reading", {
  {
    event = { "BufReadPre" },
    desc = "Clear the last used search pattern when opening a new buffer",
    pattern = "*",
    command = function()
      vim.fn.setreg("/", "") -- Clears the search register
      vim.cmd('let @/ = ""') -- Clear the search register using Vim command
    end,
  },
  {
    event = { "BufReadPost" },
    desc = "Restore last cursor location",
    command = function(args)
      if not vim.api.nvim_buf_is_valid(args.buf) then return end

      local mark = vim.api.nvim_buf_get_mark(args.buf, '"')
      local line_count = vim.api.nvim_buf_line_count(args.buf)
      if mark[1] > 0 and mark[1] <= line_count then
        if pcall(vim.api.nvim_win_set_cursor, 0, mark) then
          vim.api.nvim_win_set_cursor(0, mark)
        else
          vim.cmd('normal! g`"zz')
        end
      else
        local line = vim.fn.line("'`")
        if
          line > 1
          and line <= vim.fn.line("$")
          and vim.bo.filetype ~= "commit"
          and vim.fn.index({ "xxd", "gitrebase" }, vim.bo.filetype) == -1
        then
          vim.cmd('normal! g`"')
        end
      end
    end,
  },
})

M.augroup("Writing", {
  {
    event = { "BufWritePre" },
    desc = "chmod +x shell scripts on-demand",
    command = function(args)
      -- string.match(vim.api.nvim_buf_get_lines(0, 0, 1, false)[1], "^#!")
      -- string.match(vim.api.nvim_buf_get_lines(0, 0, 1, false)[1], ".+/bin/.+")
      local not_executable = vim.fn.getfperm(vim.fn.expand("%")):sub(3, 3) ~= "x"
      local has_shebang = string.match(vim.fn.getline(1), "^#!")
      local has_bin = string.match(vim.fn.getline(1), "/bin/")
      -- TODO: check certain filetypes, { "*.sh", "*.bash", "*.zsh" }
      if not_executable and has_shebang and has_bin then
        vim.notify(string.format("made %s executable", args.file), L.INFO)
        vim.fn.system("chmod a+x " .. vim.fn.expand("%"))
        vim.defer_fn(vim.cmd.edit, 100)
      end
    end,
  },

  {
    event = { "BufWritePre" },
    once = false,
    command = function()
      local function auto_mkdir(dir, force)
        if not dir or string.len(dir) == 0 then return end
        local stats = vim.uv.fs_stat(dir)
        local is_directory = (stats and stats.type == "directory") or false
        if string.match(dir, "^%w%+://") or is_directory or string.match(dir, "^suda:") then return end
        if not force then
          vim.fn.inputsave()
          local result = vim.fn.input(string.format('"%s" does not exist. Create? [y/N]', dir), "")
          if string.len(result) == 0 then
            print("Canceled")
            return
          end
          vim.fn.inputrestore()
        end
        vim.fn.mkdir(dir, "p")
      end

      -- Skip for Oil buffers or unnamed buffers
      if vim.bo.filetype == "oil" or vim.api.nvim_buf_get_name(0) == "" then return end

      auto_mkdir(vim.fn.expand("<afile>:p:h"), vim.v.cmdbang)
    end,
  },
})

M.augroup("Editing", {
  {
    event = { "FocusGained", "BufEnter", "CursorHold", "CursorHoldI", "TermClose" },
    pattern = "*",
    command = function()
      -- Don’t interfere while editing a command line or in terminal‑insert mode
      if
        vim.fn.mode():match("[ciR!t]") == nil
        and vim.fn.getcmdwintype() == ""
        and vim.fn.bufname("%") ~= ""
        and vim.fn.filereadable(vim.fn.bufname("%"))
      then
        vim.cmd.checktime()
      end
    end,
    desc = "Reload buffer if the underlying file was changed",
  },
  {
    desc = "Highlight when yanking (copying) text",
    event = { "TextYankPost" },
    command = function()
      vim.highlight.on_yank({ timeout = 250, on_visual = false, higroup = "VisualYank" }) -- or "Visual"
    end,
  },
  {
    event = { "FocusLost" },
    -- event = { "BufWinLeave", "BufLeave", "FocusLost" },
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
    end,
  },
})

M.augroup("Entering", {
  {
    enabled = false,
    event = { "BufWinEnter" },
    desc = "Restore view settings",
    command = "silent! loadview",
  },
  {
    event = { "BufWinEnter", "FileType" },
    command = function(args)
      local ignore_buftype = { "quickfix", "nofile", "help", "prompt" }
      local ignore_filetype = { "gitcommit", "gitrebase", "svn", "hgcommit" }
      if vim.tbl_contains(ignore_buftype, vim.bo.buftype) then return end

      if vim.tbl_contains(ignore_filetype, vim.bo.filetype) then
        -- reset cursor to first line
        vim.cmd.normal({ "gg", bang = true })
        return
      end

      -- If a line has already been specified on the command line, we are done
      --   nvim file +num
      if vim.api.nvim_win_get_cursor(0)[1] > 1 then return end

      local last_line = vim.fn.line([['"]])
      local buff_last_line = vim.api.nvim_buf_line_count(0)

      -- If the last line is set and the less than the last line in the buffer
      if last_line > 0 and last_line <= buff_last_line then
        local win_last_line = vim.fn.line("w$")
        local win_first_line = vim.fn.line("w0")
        -- Check if the last line of the buffer is the same as the win
        if win_last_line == buff_last_line then
          -- Set line to last line edited
          vim.cmd.normal({ "g`", bang = true })
        -- Try to center
        elseif buff_last_line - last_line > ((win_last_line - win_first_line) / 2) - 1 then
          vim.cmd.normal({ 'g`"zz', bang = true })
        else
          vim.cmd.normal({ [[G'"<c-e>]], bang = true })
        end
      end
    end,
  },
})

M.augroup("Leaving", {
  {
    enabled = false,
    event = { "VimResized", "WinResized" },
    desc = "Create view settings",
    command = "silent! mkview",
  },
})

-- Socket registration for Hammerspoon interop
-- See config/interop.lua for implementation details
local interop = require("config.interop")

M.augroup("HammerspoonInterop", {
  {
    event = { "VimEnter" },
    desc = "Register nvim server socket for Hammerspoon discovery",
    command = function()
      interop.register_socket()
    end,
  },
  {
    event = { "VimLeavePre" },
    desc = "Cleanup nvim server socket file",
    command = function()
      interop.cleanup_socket()
    end,
  },
})

M.augroup("Resizing", {
  {
    event = { "VimResized", "WinResized" },
    desc = "Automatically resize windows in all tabpages when resizing Vim (and use our golden ratio resizer)",
    command = function(args)
      vim.cmd.tabdo("wincmd =")

      vim.schedule(function() pcall(mega.resize_windows, args.buf) end)
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
        if ibl_ok then ibl.setup_buffer(evt.buf, { indent = { char = vim.g.indent_char } }) end
      end, 1)
      vim.wo.cursorline = true
      -- if not vim.g.started_by_firenvim then require("colorizer").attach_to_buffer(evt.buf) end
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
      -- if not vim.g.started_by_firenvim then require("colorizer").detach_from_buffer(evt.buf) end
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
    command = function(_evt) vim.diagnostic.enable(true) end,
  },
  {
    event = "InsertLeave",
    command = [[execute 'normal! mI']],
    desc = "global mark I for last edit",
  },
})

M.augroup("Utilities", {
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
    desc = "Extreme `gf` open behaviour",
    command = function(args)
      map("n", "gf", function()
        local target = vim.fn.expand("<cfile>")

        -- FIXME: get working with ghostty
        -- if U.is_image(target) then
        --   local root_dir = require("config.utils.lsp").root_dir({ ".git" })
        --   target = target:gsub("./samples", string.format("%s/samples", root_dir))
        --   return require("config.utils").preview_file(target)
        -- end

        -- FIXME: update tern related things to new things

        -- go to aha ticket
        if target:match("LD-") then
          local url = string.format("https://c-spire1.aha.io/features/%s", target)
          vim.notify(string.format("Opening aha ticket %s at %s", target, url))
          vim.fn.jobstart(string.format("%s %s", vim.g.open_command, url))

          return false
        end

        -- go to PR for specific repos
        -- if target:match("^PR%-([DIR|BELL|RET|MOB]*)#(%d*)") then
        --   local repo_abbr, pr_num = target:match("^PR%-([DIR|BELL|RET|MOB]*)#(%d*)")
        --   local repos = {
        --     DIR = "director",
        --     BELL = "bellhop",
        --     RET = "retriever",
        --     MOB = "ternreturns",
        --   }
        --
        --   local url = string.format("https://github.com/TernSystems/%s/pull/%s", repos[repo_abbr], pr_num)
        --   vim.notify(string.format("Opening PR %d on %s", pr_num, repos[repo_abbr]))
        --   vim.fn.jobstart(string.format("%s %s", vim.g.open_command, url))
        --
        --   return false
        -- end

        -- go to hex packages
        if args.file:match("mix.exs") then
          local line = vim.fn.getline(".")
          local _, _, pkg, _ = string.find(line, [[^%s*{:(.*), %s*"(.*)"}]])

          local url = string.format("https://hexdocs.pm/%s/", pkg)
          vim.notify(string.format("Opening %s at %s", pkg, url))
          vim.fn.jobstart(string.format("%s %s", vim.g.open_command, url))

          return false
        end

        -- go to node packages
        if args.file:match("package.json") then
          local line = vim.fn.getline(".")
          local _, _, pkg, _ = string.find(line, [[^%s*"(.*)":%s*"(.*)"]])

          local url = string.format("https://www.npmjs.com/package/%s", pkg)
          vim.notify(string.format("Opening %s at %s", pkg, url))
          vim.fn.jobstart(string.format("%s %s", vim.g.open_command, url))

          return false
        end

        -- go to web address
        if target:match("https://") then return vim.cmd("norm gx") end

        -- a normal file, so do the normal go-to-file thing
        if not target or #vim.split(target, "/") ~= 2 then return vim.cmd("norm! gf") end

        -- maybe it's a github repo? try it and see..
        local url = string.format("https://github.com/%s", target)
        vim.fn.jobstart(string.format("%s %s", vim.g.open_command, url))
        vim.notify(string.format("Opening %s at %s", target, url))
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
      map({ "n" }, "gx", function()
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
      map({ "n" }, "gx", function()
        local line = vim.fn.getline(".")
        local _, _, pkg, _ = string.find(line, [[^%s*{:(.*), %s*"(.*)"}]])

        if pkg then
          local url = string.format("https://hexdocs.pm/%s/", pkg)
          vim.ui.open(url)
        end
      end, { buffer = true, silent = true, desc = "[g]o to hex [p]ackage" })
    end,
  },
  -- {
  --   event = { "BufEnter", "CursorMoved", "CursorHoldI" },
  --   desc = "When at eob, bring the current line towards center screen",
  --   command = function(args)
  --     local win_h = vim.api.nvim_win_get_height(0)
  --     local off = math.min(vim.o.scrolloff, math.floor(win_h / 2))
  --     local dist = vim.fn.line("$") - vim.fn.line(".")
  --     local rem = vim.fn.line("w$") - vim.fn.line("w0") + 1

  --     if dist < off and win_h - rem + dist < off then
  --       local view = vim.fn.winsaveview()
  --       view.topline = view.topline + off - (win_h - rem + dist)
  --       vim.fn.winrestview(view)
  --     end
  --   end,
  -- },
})

--------------------------------------------------------------------------------
-- AUTO-NOHL & INLINE SEARCH COUNT
-- REF: https://github.com/chrisgrieser/.config/blob/main/nvim/lua/config/autocmds.lua#L197C1-L243C62

---@param mode? "clear"
local function searchCountIndicator(mode)
  local signColumnPlusScrollbarWidth = 2 + 3 -- CONFIG

  local countNs = vim.api.nvim_create_namespace("searchCounter")
  vim.api.nvim_buf_clear_namespace(0, countNs, 0, -1)
  if mode == "clear" then return end

  local row = vim.api.nvim_win_get_cursor(0)[1]
  local count = vim.fn.searchcount()
  if vim.tbl_isempty(count) or count.total == 0 then return end
  local text = (" %d/%d "):format(count.current, count.total)
  local line = vim.api.nvim_get_current_line():gsub("\t", (" "):rep(vim.bo.shiftwidth))
  local lineFull = #line + signColumnPlusScrollbarWidth >= vim.api.nvim_win_get_width(0)
  local margin = { (" "):rep(lineFull and signColumnPlusScrollbarWidth or 0) }

  vim.api.nvim_buf_set_extmark(0, countNs, row - 1, 0, {
    virt_text = { { text, "IncSearch" }, margin },
    virt_text_pos = lineFull and "right_align" or "eol",
    priority = 200, -- so it comes in front of `nvim-lsp-endhints`
  })
end

-- without the `searchCountIndicator`, this `on_key` simply does `auto-nohl`
vim.on_key(function(key, _typed)
  key = vim.fn.keytrans(key)
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
    searchCountIndicator("clear")
  elseif searchMovement or searchConfirmed or searchStarted then
    vim.opt.hlsearch = true
    vim.defer_fn(searchCountIndicator, 1)
  end
end, vim.api.nvim_create_namespace("autoNohlAndSearchCount"))

--------------------------------------------------------------------------------
-- NOTES CAPTURE LINKING
-- Auto-link captures to daily note on save
--
-- Entry types (mutually exclusive per capture):
-- - Image capture (clipper.lua): [[filename]]
--   → Added immediately when image is captured
-- - Text capture (this autocmd): [[filename|description]]
--   → Added on first save, shows descriptive text from notes or source
--
-- If an entry already exists (from image capture), we skip adding the
-- text-style entry to avoid duplicates.
--------------------------------------------------------------------------------

--- Detect code fence language using treesitter
--- Treesitter parses markdown and identifies fenced_code_block with info_string
---@param buf number Buffer handle
---@return string|nil Language from first code fence, or nil
local function detect_code_fence_language(buf)
  local ok, parser = pcall(vim.treesitter.get_parser, buf, "markdown")
  if not ok or not parser then return nil end

  local tree = parser:parse()[1]
  if not tree then return nil end

  local root = tree:root()

  -- Walk tree looking for info_string (the language hint after ```)
  local function find_info_string(node)
    if node:type() == "info_string" then
      local text = vim.treesitter.get_node_text(node, buf)
      if text and text ~= "" then
        return text:match("^%s*(%S+)") -- First word only (ignore attributes)
      end
    end
    for child in node:iter_children() do
      local result = find_info_string(child)
      if result then return result end
    end
    return nil
  end

  return find_info_string(root)
end

--- Parse frontmatter from buffer lines
---@param lines string[]
---@return table frontmatter Key-value pairs from YAML frontmatter
---@return number end_line Line number where frontmatter ends (0-indexed)
local function parse_frontmatter(lines)
  local frontmatter = {}
  local end_line = 0

  if #lines == 0 or lines[1] ~= "---" then
    return frontmatter, 0
  end

  for i = 2, #lines do
    if lines[i] == "---" then
      end_line = i
      break
    end
    local key, value = lines[i]:match("^(%w+):%s*(.+)$")
    if key and value then
      frontmatter[key] = value:gsub("^[\"']", ""):gsub("[\"']$", "")
    end
  end

  return frontmatter, end_line
end

--- Extract first meaningful content line (after frontmatter and code blocks)
---@param lines string[]
---@param start_line number Line to start searching from (0-indexed)
---@return string|nil First content line or nil
local function extract_first_content(lines, start_line)
  local in_code_block = false

  for i = start_line + 1, #lines do
    local line = lines[i]

    -- Track code block state
    if line:match("^```") then
      in_code_block = not in_code_block
    elseif not in_code_block then
      -- Skip empty lines and headings
      local trimmed = line:match("^%s*(.-)%s*$")
      if trimmed and trimmed ~= "" and not trimmed:match("^#") then
        -- Found real content - truncate if too long
        if #trimmed > 60 then
          trimmed = trimmed:sub(1, 57) .. "..."
        end
        return trimmed
      end
    end
  end

  return nil
end

--- Build descriptive text for wikilink
---@param frontmatter table Parsed frontmatter
---@param first_content string|nil First content line
---@param detected_lang string|nil Language detected via treesitter
---@return string description
local function build_description(frontmatter, first_content, detected_lang)
  -- Priority 1: User's actual notes
  if first_content then
    return first_content
  end

  -- Priority 2: Source context
  local parts = {}

  -- Extract domain from URL
  if frontmatter.source_url then
    local domain = frontmatter.source_url:match("https?://([^/]+)")
    if domain then
      domain = domain:gsub("^www%.", "")
      table.insert(parts, domain)
    end
  elseif frontmatter.source and frontmatter.source ~= "other" then
    table.insert(parts, frontmatter.source)
  end

  -- Add language hint (treesitter detection > frontmatter)
  local lang = detected_lang or frontmatter.source_lang
  if lang then
    table.insert(parts, lang)
  end

  if #parts > 0 then
    return "Capture from " .. table.concat(parts, " · ")
  end

  -- Priority 3: Just indicate it's a text capture
  return "Text capture"
end

--- Get daily note path for today
---@return string path
local function get_daily_note_path()
  local notes_home = vim.env.NOTES_HOME or (vim.env.HOME .. "/notes")
  local year = os.date("%Y")
  local date = os.date("%Y%m%d")
  return string.format("%s/daily/%s/%s.md", notes_home, year, date)
end

--- Append capture link to daily note
---@param capture_filename string Filename without extension
---@param description string Descriptive text for the link
---@return boolean success
---@return string|nil reason If false, why (e.g., "exists", "error")
local function append_to_daily_note(capture_filename, description)
  local daily_path = get_daily_note_path()
  local timestamp = os.date("%H:%M")

  -- Read daily note
  local f = io.open(daily_path, "r")
  if not f then
    vim.notify("Daily note not found: " .. daily_path, vim.log.levels.WARN)
    return false, "not_found"
  end
  local content = f:read("*a")
  f:close()

  -- Check if entry already exists for this capture
  -- Pattern matches [[filename or [[filename| to catch both styles
  local existing_pattern = "%[%[" .. capture_filename:gsub("%-", "%%-") .. "[%]|]"
  if content:match(existing_pattern) then
    -- Entry already exists (likely from image capture), skip
    return false, "exists"
  end

  -- Build the entry with Obsidian alias syntax: [[filename|display text]]
  local entry = string.format("- %s [[%s|%s]]", timestamp, capture_filename, description)

  -- Find ## Captures section
  local captures_section = "## Captures"
  local captures_pos = content:find(captures_section, 1, true)

  if captures_pos then
    -- Find end of Captures section (next ## or end of file)
    local next_section = content:find("\n## ", captures_pos + #captures_section)
    if next_section then
      -- Insert before next section, ensure single newline separation
      local before = content:sub(1, next_section - 1):gsub("%s+$", "") -- trim trailing whitespace
      content = before .. "\n" .. entry .. "\n" .. content:sub(next_section + 1)
    else
      -- Append to end, ensure single newline before entry
      content = content:gsub("%s+$", "") .. "\n" .. entry .. "\n"
    end
  else
    -- Add Captures section at end
    content = content:gsub("%s+$", "") .. "\n\n" .. captures_section .. "\n\n" .. entry .. "\n"
  end

  -- Write back
  f = io.open(daily_path, "w")
  if not f then
    vim.notify("Failed to write daily note", vim.log.levels.ERROR)
    return false
  end
  f:write(content)
  f:close()

  return true
end

M.augroup("NotesCaptureLink", {
  {
    event = { "BufWritePost" },
    pattern = "*/captures/*.md",
    desc = "Link text captures to daily note on save",
    command = function(args)
      -- Skip if already linked (check buffer variable)
      if vim.b[args.buf].capture_linked then
        return
      end

      local lines = vim.api.nvim_buf_get_lines(args.buf, 0, -1, false)

      -- Skip empty files
      if #lines == 0 then return end

      -- Parse frontmatter
      local frontmatter, fm_end = parse_frontmatter(lines)

      -- Skip if no frontmatter (not a proper capture)
      if fm_end == 0 then return end

      -- Check for actual content (not just frontmatter)
      local has_content = false
      for i = fm_end + 1, #lines do
        local line = lines[i]:match("^%s*(.-)%s*$")
        if line and line ~= "" then
          has_content = true
          break
        end
      end

      -- Skip if file is just frontmatter with no content
      if not has_content then
        vim.notify("Capture empty - not linking to daily note", vim.log.levels.INFO)
        return
      end

      -- Extract first content line
      local first_content = extract_first_content(lines, fm_end)

      -- Detect language via treesitter (parses markdown code fences)
      local detected_lang = detect_code_fence_language(args.buf)

      -- Build description
      local description = build_description(frontmatter, first_content, detected_lang)

      -- Get filename without path and extension
      local filename = vim.fn.expand("%:t:r")

      -- Append to daily note
      local success, reason = append_to_daily_note(filename, description)
      if success then
        vim.b[args.buf].capture_linked = true
        vim.notify(string.format("Linked to daily: [[%s|%s]]", filename, description), vim.log.levels.INFO)
      elseif reason == "exists" then
        -- Entry already exists (e.g., image capture added it), mark as linked and skip silently
        vim.b[args.buf].capture_linked = true
      end
    end,
  },
})

Load_macros(M)

return M

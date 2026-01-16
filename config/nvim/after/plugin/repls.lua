-- repls.lua - Language-specific REPL launcher using megaterm
-- Provides context-aware REPL commands with keybindings

if not Plugin_enabled("lsp") then return end

--------------------------------------------------------------------------------
-- REPL Commands by Filetype
--------------------------------------------------------------------------------

---@class mega.repl.ReplConfig
---@field cmd string|fun(): string Command to execute
---@field detect? fun(): boolean Optional detection function for context-awareness
---@field keymap string Keymap suffix (e.g., "l" for <leader>rl)
---@field desc string Description for keymap
---@field position? "bottom"|"right"|"tab"|"float"

---@type table<string, mega.repl.ReplConfig>
local repl_configs = {
  lua = {
    cmd = function()
      -- Detect Hammerspoon files by pattern matching
      local current_file = vim.fn.expand("%:p")
      if current_file:match("hammerspoon") or current_file:match("init%.lua$") or current_file:match("%.spoon/") then
        return "hs"
      end
      return "lua"
    end,
    keymap = "l",
    desc = "Launch Lua REPL (or hs for Hammerspoon)",
  },

  python = {
    cmd = "python",
    keymap = "p",
    desc = "Launch Python REPL",
  },

  ruby = {
    cmd = function()
      -- Check for Rails project (Gemfile presence)
      local root = vim.fn.findfile("Gemfile", ".;")
      if root ~= "" then
        return "rails console"
      end
      return "irb"
    end,
    keymap = "r",
    desc = "Launch Ruby REPL (IRB or Rails console)",
  },

  elixir = {
    cmd = function()
      -- Check for Mix project
      local root = vim.fn.findfile("mix.exs", ".;")
      if root ~= "" then
        return "iex -S mix"
      end
      return "iex"
    end,
    keymap = "e",
    desc = "Launch Elixir REPL (IEx or Mix)",
  },

  javascript = {
    cmd = "node",
    keymap = "n",
    desc = "Launch Node.js REPL",
  },

  typescript = {
    cmd = "node",
    keymap = "n",
    desc = "Launch Node.js REPL",
  },

  javascriptreact = {
    cmd = "node",
    keymap = "n",
    desc = "Launch Node.js REPL",
  },

  typescriptreact = {
    cmd = "node",
    keymap = "n",
    desc = "Launch Node.js REPL",
  },
}

--------------------------------------------------------------------------------
-- REPL Launcher
--------------------------------------------------------------------------------

---@class mega.repl.Manager
local M = {}

--- Launch REPL for given filetype
---@param ft? string Filetype (defaults to current buffer)
---@param opts? { execute?: boolean } Options (execute = run current file)
function M.launch(ft, opts)
  ft = ft or vim.bo.filetype
  opts = opts or {}

  local config = repl_configs[ft]
  if not config then
    vim.notify("No REPL configured for filetype: " .. ft, vim.log.levels.WARN)
    return nil
  end

  -- Resolve command (may be function)
  local cmd = type(config.cmd) == "function" and config.cmd() or config.cmd

  -- If execute flag, append current file to command
  if opts.execute then
    local current_file = vim.fn.expand("%:p")
    cmd = string.format("%s %s", cmd, vim.fn.shellescape(current_file))
  end

  -- Create terminal with REPL command
  local term = Megaterm.create({
    cmd = cmd,
    position = config.position or "bottom",
    temp = false, -- Keep REPL persistent
    on_open = function(terminal)
      -- Set buffer variables for statusline integration
      vim.api.nvim_buf_set_var(terminal.buf, "repl_type", ft)
      vim.api.nvim_buf_set_var(terminal.buf, "repl_cmd", cmd)
    end,
  })

  return term
end

--- Get or create REPL terminal for current filetype
---@return mega.term.Terminal?
function M.get_or_create()
  local ft = vim.bo.filetype
  local config = repl_configs[ft]
  if not config then
    return nil
  end

  -- Look for existing REPL terminal for this filetype
  for _, term in ipairs(Megaterm.list()) do
    if term:is_valid() then
      local ok, repl_type = pcall(vim.api.nvim_buf_get_var, term.buf, "repl_type")
      if ok and repl_type == ft then
        return term
      end
    end
  end

  -- No existing REPL, create one
  return M.launch(ft)
end

--- Toggle REPL for current filetype
function M.toggle()
  local term = M.get_or_create()
  if term then
    term:toggle()
  end
end

--- Send text to REPL (creates if needed)
---@param text string
---@param opts? { newline?: boolean }
function M.send(text, opts)
  local term = M.get_or_create()
  if term then
    if not term:is_visible() then
      term:show({ start_insert = false })
    end
    term:send(text, opts)
  end
end

--- Send line to REPL
---@param text string
function M.send_line(text)
  M.send(text, { newline = true })
end

--- Send current line to REPL
function M.send_current_line()
  local line = vim.api.nvim_get_current_line()
  M.send_line(line)
end

--- Send visual selection to REPL
function M.send_selection()
  -- Get visual selection
  local start_pos = vim.fn.getpos("'<")
  local end_pos = vim.fn.getpos("'>")
  local lines = vim.api.nvim_buf_get_lines(0, start_pos[2] - 1, end_pos[2], false)

  if #lines == 0 then return end

  -- Handle single line selection
  if #lines == 1 then
    lines[1] = string.sub(lines[1], start_pos[3], end_pos[3])
  else
    -- Multi-line: trim first and last
    lines[1] = string.sub(lines[1], start_pos[3])
    lines[#lines] = string.sub(lines[#lines], 1, end_pos[3])
  end

  local text = table.concat(lines, "\n")
  M.send_line(text)
end

--- Execute current file in REPL
function M.execute_file()
  M.launch(vim.bo.filetype, { execute = true })
end

--------------------------------------------------------------------------------
-- Keymaps Setup
--------------------------------------------------------------------------------

--- Setup keymaps for all configured REPLs
function M.setup_keymaps()
  -- Global toggle (independent of filetype)
  vim.keymap.set("n", "<leader>rt", M.toggle, { desc = "Toggle REPL" })

  -- Send operations (work across filetypes)
  vim.keymap.set("n", "<leader>rs", M.send_current_line, { desc = "Send line to REPL" })
  vim.keymap.set("v", "<leader>rs", function()
    M.send_selection()
    -- Return to normal mode after sending
    vim.api.nvim_feedkeys(vim.api.nvim_replace_termcodes("<Esc>", true, false, true), "n", true)
  end, { desc = "Send selection to REPL" })

  -- Language-specific launchers (only available in supported filetypes)
  for ft, config in pairs(repl_configs) do
    vim.api.nvim_create_autocmd("FileType", {
      pattern = ft,
      callback = function(ev)
        local opts = { buffer = ev.buf, silent = true }

        -- Lowercase = launch REPL
        vim.keymap.set(
          "n",
          "<leader>r" .. config.keymap,
          function() M.launch(ft) end,
          vim.tbl_extend("force", opts, { desc = config.desc })
        )

        -- Uppercase = execute current file
        vim.keymap.set(
          "n",
          "<leader>r" .. config.keymap:upper(),
          function() M.launch(ft, { execute = true }) end,
          vim.tbl_extend("force", opts, { desc = config.desc .. " (execute file)" })
        )
      end,
    })
  end
end

--------------------------------------------------------------------------------
-- Commands
--------------------------------------------------------------------------------

vim.api.nvim_create_user_command("Repl", function(opts)
  if opts.bang then
    -- :Repl! executes current file
    M.execute_file()
  elseif opts.args and #opts.args > 0 then
    -- :Repl <filetype>
    M.launch(opts.args)
  else
    -- :Repl toggles for current filetype
    M.toggle()
  end
end, {
  bang = true,
  nargs = "?",
  complete = function()
    return vim.tbl_keys(repl_configs)
  end,
  desc = "Launch or toggle REPL",
})

vim.api.nvim_create_user_command("ReplSend", function(opts)
  if opts.range == 2 then
    -- Visual selection
    M.send_selection()
  else
    -- Send provided text
    M.send_line(opts.args)
  end
end, {
  range = true,
  nargs = "*",
  desc = "Send text to REPL",
})

--------------------------------------------------------------------------------
-- Initialize
--------------------------------------------------------------------------------

M.setup_keymaps()

-- Global exposure
_G.Repl = M

return M

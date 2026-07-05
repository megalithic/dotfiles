--- Capture note utilities
--- Shared between shade integration and after/plugin/notes.lua
---
--- @module notes.capture

local M = {}

--- Check if a line is template content (not user-written)
---@param trimmed string Trimmed line content
---@param state table Mutable state { in_frontmatter, frontmatter_closed, in_code_block, in_callout }
---@return boolean is_template True if line is template content
local function is_template_line(trimmed, state)
  -- Track frontmatter (--- to ---)
  if trimmed == "---" then
    if not state.frontmatter_closed then
      if state.in_frontmatter then
        state.frontmatter_closed = true
      end
      state.in_frontmatter = not state.in_frontmatter
    end
    return true
  end

  -- Skip frontmatter content
  if state.in_frontmatter then return true end

  -- Track code blocks (``` to ```)
  if trimmed:match("^```") then
    state.in_code_block = not state.in_code_block
    return true
  end

  -- Skip code block content
  if state.in_code_block then return true end

  -- Track callout blocks (> [!info]- ... until non-> line)
  if trimmed:match("^> %[!") or (state.in_callout and trimmed:match("^>")) then
    state.in_callout = trimmed:match("^>") ~= nil
    return true
  else
    state.in_callout = false
  end

  -- Skip empty lines
  if trimmed == "" then return true end

  -- Skip image embeds: ![[...]] or ![...](...)
  if trimmed:match("^!%[%[.+%]%]$") or trimmed:match("^!%[.*%]%(.*%)$") then return true end

  -- Skip placeholder comments: <!-- shade:pending:... -->
  if trimmed:match("^<!%-%- shade:pending:.* %-%->$") then return true end

  -- Skip template section headers
  if trimmed:match("^##%s+Notes%s*$") or trimmed:match("^##%s+OCR Text%s*$") then return true end

  -- Not a template line
  return false
end

--- Check if a capture note is "empty" (contains only template content, no user-written text)
--- A note is considered empty if it only contains:
---   - YAML frontmatter
---   - Capture context callout (> [!info]- Capture Context ...)
---   - Code blocks (capture_selection)
---   - Image embeds (![[...]])
---   - Placeholder comments (<!-- shade:pending:... -->)
---   - Section headers (## Notes, ## OCR Text, etc.)
---@param bufnr number|nil Buffer number (default: current buffer)
---@return boolean is_empty True if the note has no user-written content
---@return string|nil filepath Path to the file if it's a capture note, nil otherwise
function M.is_empty(bufnr)
  bufnr = bufnr or vim.api.nvim_get_current_buf()

  local filepath = vim.api.nvim_buf_get_name(bufnr)
  if filepath == "" then return false, nil end

  -- Only process captures directory
  if not filepath:match("/captures/") then return false, nil end

  local lines = vim.api.nvim_buf_get_lines(bufnr, 0, -1, false)
  if #lines == 0 then return true, filepath end

  -- State machine for parsing
  local state = {
    in_frontmatter = false,
    frontmatter_closed = false,
    in_code_block = false,
    in_callout = false,
  }

  for _, line in ipairs(lines) do
    local trimmed = line:match("^%s*(.-)%s*$") or ""
    if not is_template_line(trimmed, state) then
      -- Found user content
      return false, filepath
    end
  end

  -- No user content found
  return true, filepath
end

--- Prompt user to delete empty capture note and perform deletion if confirmed
---@param filepath string Path to the file to delete
---@param callback? function Optional callback after user responds (receives boolean: deleted)
function M.cleanup(filepath, callback)
  if not filepath then
    if callback then callback(false) end
    return
  end

  local filename = vim.fn.fnamemodify(filepath, ":t")

  vim.ui.select({ "Yes, delete it", "No, keep it" }, {
    prompt = string.format("Capture note '%s' is empty. Delete it?", filename),
  }, function(choice)
    if choice == "Yes, delete it" then
      local ok, err = os.remove(filepath)
      if ok then
        vim.notify(string.format("Deleted empty capture: %s", filename), vim.log.levels.INFO)
        if callback then callback(true) end
      else
        vim.notify(string.format("Failed to delete %s: %s", filename, err or "unknown error"), vim.log.levels.ERROR)
        if callback then callback(false) end
      end
    else
      vim.notify("Kept empty capture note", vim.log.levels.DEBUG)
      if callback then callback(false) end
    end
  end)
end

return M

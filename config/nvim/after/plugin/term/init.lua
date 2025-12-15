if not Plugin_enabled("lsp") then return end

local ok, Terminal = pcall(dofile, vim.fn.stdpath("config") .. "/after/plugin/term/term.lua")
if not ok then return end

-- local term_group = vim.api.nvim_create_augroup("mega_mvim.term", { clear = true })

--- @class mega.TerminalManager
local Manager = {
  --- @type mega.Terminal[]
  terms = {},
  --- @type mega.Terminal[]
  term_history = {},
}

-- Keep track of terminal history
vim.api.nvim_create_autocmd("BufEnter", {
  callback = vim.schedule_wrap(function(ev)
    for _, term in ipairs(Manager.get_terms()) do
      if term.buf == ev.buf then
        local term_history = Manager.get_term_history()

        -- Remove from history if it's already there
        for i, v in ipairs(term_history) do
          if v == term then
            table.remove(term_history, i)
            break
          end
        end

        table.insert(term_history, 1, term)
        return
      end
    end
  end),
})

-- Update left side padding when a buffer enters a window
vim.api.nvim_create_autocmd("BufWinEnter", {
  callback = function()
    for _, term in ipairs(Manager.get_terms()) do
      term:update_padding()
    end
  end,
})

-- Run on BufLeave as well since ModeChanged doesn't fire when switching from terminal buffer
-- to another buffer, even though the mode changes
vim.api.nvim_create_autocmd("ModeChanged", {
  callback = function()
    for _, term in ipairs(Manager.get_terms()) do
      term:update_cursorline_highlight()
    end
  end,
})

--- @return mega.Terminal[]
function Manager.get_terms()
  local terms = vim.tbl_filter(function(term) return term:is_valid() end, Manager.terms)
  Manager.terms = terms
  return terms
end

function Manager.get_term_history()
  local term_history = vim.tbl_filter(function(term) return term:is_valid() end, Manager.term_history)
  Manager.term_history = term_history
  return term_history
end

--- @param win number?
--- @return mega.Terminal?
function Manager.get_current_term(win)
  local terms = Manager.get_terms()
  for _, term in ipairs(terms) do
    if term:is_focused(win) then return term end
  end
end

--- @param win number?
--- @return number?
function Manager.get_current_term_idx(win)
  local terms = Manager.get_terms()
  for idx, term in ipairs(terms) do
    if term:is_focused(win) then return idx end
  end
end

function Manager.cycle()
  local terms = Manager.get_terms()
  local current_term_idx = Manager.get_current_term_idx()

  -- No terminal focused
  if current_term_idx == nil then
    -- Focus the only existing terminal
    if #terms == 1 then
      terms[1]:focus_existing_and_enter_insert()
    -- Focus the last terminal
    elseif #terms > 0 then
      Manager.focus_last()
    -- Create a new terminal and focus it
    else
      Manager.create()
    end
  -- Terminal focused
  else
    if #terms == 1 then
      -- No other terminals exist
      vim.notify("No other terminals exist")
    else
      -- Focus the next terminal
      local next_term_idx = (current_term_idx % #terms) + 1
      return terms[next_term_idx]:focus()
    end
  end
end

function Manager.focus_last()
  -- Focus the last term that isn't currently visible
  for _, term in ipairs(Manager.get_term_history()) do
    if not term:is_visible() then return term:focus_and_enter_insert() end
  end

  -- Focus the first term instead
  local terms = Manager.get_terms()
  if #terms > 0 then return terms[1]:focus_and_enter_insert() end

  error("No terminals found")
end

--- @return mega.Terminal
function Manager.create()
  local term = Terminal.new()
  table.insert(Manager.terms, term)
  return term
end

return Manager

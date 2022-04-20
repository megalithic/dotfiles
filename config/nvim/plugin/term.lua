local fmt = string.format
local system = vim.fn.system

local nil_buf_id = 999999
local term_buf_id = nil_buf_id

local terminal_notifier_notifier = function(c, exit)
  if exit == 0 then
    print("Success!")
    system(string.format([[terminal-notifier -title "Neovim" -subtitle "%s" -message "Success\!"]], c))
  else
    print("Failure!")
    system(string.format([[terminal-notifier -title "Neovim" -subtitle "%s" -message "Failure\!"]], c))
  end
end

--- @class Direction
--- @field horiz string,
--- @field vert string,

--- @class TermOpts
--- @field cmd string,
--- @field precmd string,
--- @field direction Direction,
--- @field on_after_open function,
--- @field on_exit function,
--- @field winnr number,
--- @field notifier function,
--- @field height integer,
--- @field width integer,

---Opens a custom terminal
---@param opts TermOpts
function mega.term_open(opts)
  local cmd = opts.cmd
  local custom_on_exit = opts.on_exit or nil
  local precmd = opts.precmd or nil
  local on_after_open = opts.on_after_open or nil
  local winnr = opts.winnr
  local direction = opts.direction or "horiz"
  local notifier = opts.notifier or terminal_notifier_notifier
  local height = opts.height or 25
  local width = opts.width or 80

  -- delete the current buffer if it's still open
  if vim.api.nvim_buf_is_valid(term_buf_id) then
    vim.api.nvim_buf_delete(term_buf_id, { force = true })
    term_buf_id = nil_buf_id
  end

  local horiz_direction_cmd = fmt("botright new | lua vim.api.nvim_win_set_height(0, %s)", height)

  if direction == "horiz" then
    vim.cmd(horiz_direction_cmd)
  elseif direction == "vert" then
    vim.cmd("vnew | lua vim.api.nvim_win_set_width(0, %s)", width)
  else
    vim.cmd(horiz_direction_cmd)
  end

  term_buf_id = vim.api.nvim_get_current_buf()
  vim.opt_local.filetype = "terminal"

  -- make sure we can close/exit this thing
  nmap("q", function()
    vim.api.nvim_buf_delete(term_buf_id, { force = true })
    term_buf_id = nil_buf_id

    -- jump back to our last window
    vim.cmd(winnr .. [[wincmd w]])
  end, { buffer = term_buf_id })

  if precmd ~= nil then
    cmd = fmt("%s; %s", precmd, cmd)
  end

  vim.fn.termopen(cmd, {
    ---@diagnostic disable-next-line: unused-local
    on_exit = function(jobid, exit_code, event)
      -- if we get a custom on_exit, run it instead...
      if custom_on_exit ~= nil and type(custom_on_exit) == "function" then
        custom_on_exit(jobid, exit_code, event, cmd)
      else
        if notifier then
          notifier(cmd, exit_code)
        end

        if exit_code == 0 then
          vim.api.nvim_buf_delete(term_buf_id, { force = true })
          term_buf_id = nil_buf_id
        end
      end
    end,
  })

  P(cmd)

  if on_after_open ~= nil and type(on_after_open) == "function" then
    on_after_open()
  else
    vim.cmd([[normal! G]])
    vim.cmd(winnr .. [[wincmd w]])
  end
end

-- Convience; because i'm bad about remembering which it is
mega.open_term = mega.term_open

mega.command("TermIex", function()
  local precmd = ""
  local cmd = ""
  if require("mega.utils").root_has_file("Deskfile") then
    precmd = "eval $(desk load)"
  end
  if require("mega.utils").root_has_file("mix.exs") then
    cmd = "iex -S mix"
  else
    cmd = "iex"
  end

  mega.open_term({
    winnr = vim.fn.winnr(),
    cmd = cmd,
    precmd = precmd,
    on_exit = function() end,
    on_after_open = function()
      -- FIXME: should i add the ability to just startinsert via bool?
      vim.cmd("startinsert")
      -- table.insert(commands, {
      --   "BufEnter",
      --   fmt("<buffer=%d>", term.bufnr),
      --   "startinsert",
      -- })
    end,
  })
end)

mega.command("TermRails", function()
  local precmd = ""
  local cmd = "rails c"
  if require("mega.utils").root_has_file("Deskfile") then
    precmd = "eval $(desk load)"
  end

  mega.open_term({
    winnr = vim.fn.winnr(),
    cmd = cmd,
    precmd = precmd,
    on_exit = function() end,
    on_after_open = function()
      -- FIXME: should i add the ability to just startinsert via bool?
      vim.cmd("startinsert")
      -- table.insert(commands, {
      --   "BufEnter",
      --   fmt("<buffer=%d>", term.bufnr),
      --   "startinsert",
      -- })
    end,
  })
end)

require("which-key").register({
  t = {
    name = "terminal",
    e = { "<cmd>TermIex<cr>", "repl > elixir" },
    r = { "<cmd>TermRails<cr>", "repl > rails" },
  },
}, {
  prefix = "<leader>",
})

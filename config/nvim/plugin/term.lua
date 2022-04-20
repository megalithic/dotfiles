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

function mega.term_open(opts) -- cmd, winnr, notifier, precmd, on_exit, direction, postcmd
  local cmd = opts.cmd
  local custom_on_exit = opts.on_exit or nil
  local precmd = opts.precmd or nil
  local postcmd = opts.postcmd or nil
  local winnr = opts.winnr
  local direction = opts.direction or "horiz"
  local notifier = opts.notifier or terminal_notifier_notifier

  -- delete the current buffer if it's still open
  if vim.api.nvim_buf_is_valid(term_buf_id) then
    vim.api.nvim_buf_delete(term_buf_id, { force = true })
    term_buf_id = nil_buf_id
  end

  if direction == "horiz" then
    vim.cmd("botright new | lua vim.api.nvim_win_set_height(0, 20)")
  elseif direction == "vert" then
    vim.cmd("vnew | lua vim.api.nvim_win_set_width(0, 35)")
  else
    vim.cmd("botright new | lua vim.api.nvim_win_set_height(0, 20)")
  end

  term_buf_id = vim.api.nvim_get_current_buf()
  vim.opt_local.filetype = "terminal"
  vim.opt_local.number = false
  vim.opt_local.cursorline = false

  -- make sure we can close/exit this thing
  nmap("q", function()
    vim.api.nvim_buf_delete(term_buf_id, { force = true })
    term_buf_id = nil_buf_id
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

  if postcmd ~= nil and type(postcmd) == "function" then
    postcmd()
  else
    vim.cmd([[normal! G]])
    vim.cmd(winnr .. [[wincmd w]])
  end
end

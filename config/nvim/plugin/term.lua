local fmt = string.format

local nil_buf_id = 999999
local term_buf_id = nil_buf_id

local function set_keymaps(bufnr, winnr)
  local opts = { buffer = bufnr }
  -- quit terminal and go back to last window
  nmap("q", function()
    vim.api.nvim_buf_delete(bufnr, { force = true })
    bufnr = nil_buf_id

    -- jump back to our last window
    vim.cmd(winnr .. [[wincmd w]])
  end, opts)

  -- get back to normal mode
  tmap("<esc>", [[<C-\><C-n>]], opts)

  -- move around splits
  tmap("<C-h>", [[<C-\><C-n><C-W>h]], opts)
  tmap("<C-j>", [[<C-\><C-n><C-W>j]], opts)
  tmap("<C-k>", [[<C-\><C-n><C-W>k]], opts)
  tmap("<C-l>", [[<C-\><C-n><C-W>l]], opts)
end

--- @class TermOpts
--- @field cmd string,
--- @field precmd string,
--- @field direction "horizontal"|"vertical",
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
  local direction = opts.direction or "horizontal"
  local notifier = opts.notifier
  local height = opts.height or 25
  local width = opts.width or 80

  -- delete the current buffer if it's still open
  if vim.api.nvim_buf_is_valid(term_buf_id) then
    vim.api.nvim_buf_delete(term_buf_id, { force = true })
    term_buf_id = nil_buf_id
  end

  local h_direction_cmd = fmt("botright new | lua vim.api.nvim_win_set_height(0, %s)", height)

  if direction == "horizontal" then
    vim.cmd(h_direction_cmd)
  elseif direction == "vertical" then
    vim.cmd("vnew | lua vim.api.nvim_win_set_width(0, %s)", width)
  else
    vim.notify("[megaterm] direction must either be `horizontal` or `vertical`.", "WARN")
    vim.cmd(h_direction_cmd)
  end

  term_buf_id = vim.api.nvim_get_current_buf()
  vim.opt_local.filetype = "megaterm"

  set_keymaps(term_buf_id, winnr)

  if precmd ~= nil then
    cmd = fmt("%s; %s", precmd, cmd)
  end

  vim.fn.termopen(cmd, {
    ---@diagnostic disable-next-line: unused-local
    on_exit = function(jobid, exit_code, event)
      -- if we get a custom on_exit, run it instead...
      if custom_on_exit ~= nil and type(custom_on_exit) == "function" then
        custom_on_exit(jobid, exit_code, event, cmd, winnr, term_buf_id)
      else
        if notifier ~= nil and type(notifier) == "function" then
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
    on_after_open(term_buf_id, winnr)
  else
    vim.cmd([[normal! G]])
    vim.cmd(winnr .. [[wincmd w]])
  end
end

-- Convenience
mega.open_term = mega.term_open

-- Commands that wrap open_term:
mega.command("TermElixir", function()
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
    ---@diagnostic disable-next-line: unused-local
    on_after_open = function(bufnr, _winnr)
      vim.api.nvim_buf_set_var(bufnr, "cmd", cmd)
      vim.cmd("startinsert")
    end,
  })
end)

mega.command("TermRuby", function()
  local precmd = ""
  local cmd = ""
  if require("mega.utils").root_has_file("Deskfile") then
    precmd = "eval $(desk load)"
  end
  if require("mega.utils").root_has_file("Gemfile") then
    cmd = "rails c"
  else
    cmd = "irb"
  end

  mega.open_term({
    winnr = vim.fn.winnr(),
    cmd = cmd,
    precmd = precmd,
    on_exit = function() end,
    ---@diagnostic disable-next-line: unused-local
    on_after_open = function(bufnr, _winnr)
      vim.api.nvim_buf_set_var(bufnr, "cmd", cmd)
      vim.cmd("startinsert")
    end,
  })
end)

require("which-key").register({
  t = {
    name = "terminal",
    e = { "<cmd>TermElixir<cr>", "repl > elixir" },
    r = { "<cmd>TermRuby<cr>", "repl > ruby" },
  },
}, {
  prefix = "<leader>",
})

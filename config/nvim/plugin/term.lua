local fmt = string.format
local api = vim.api

local nil_buf_id = 999999
local term_buf_id = nil_buf_id

-- REF: https://github.com/outstand/titan.nvim/blob/main/lua/titan/plugins/toggleterm.lua
local function set_keymaps(bufnr, winnr)
  local opts = { buffer = bufnr, silent = false }
  -- quit terminal and go back to last window
  nmap("q", function()
    api.nvim_buf_delete(bufnr, { force = true })
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

  tmap("<C-h>", function() vim.cmd([[<C-\><C-n>]] .. winnr .. [[wincmd w]]) end, opts)
  tmap("<C-k>", function() vim.cmd([[<C-\><C-n>]] .. winnr .. [[wincmd w]]) end, opts)
end

--- @class TermOpts
--- @field cmd string,
--- @field precmd string,
--- @field direction "horizontal"|"vertical"|"float",
--- @field on_after_open function,
--- @field on_exit function,
--- @field winnr number,
--- @field notifier function,
--- @field height integer,
--- @field width integer,

---Opens a custom terminal
---@param opts TermOpts
function mega.term_open(opts)
  local cmd = opts.cmd or "zsh -i"
  local custom_on_exit = opts.on_exit or nil
  local precmd = opts.precmd or nil
  local on_after_open = opts.on_after_open or nil
  local winnr = opts.winnr
  local direction = opts.direction or "horizontal"
  local notifier = opts.notifier
  local height = opts.height or 25
  local width = opts.width or 80

  -- delete the current buffer if it's still open
  if api.nvim_buf_is_valid(term_buf_id) then
    api.nvim_buf_delete(term_buf_id, { force = true })
    term_buf_id = nil_buf_id
  end

  local h_direction_cmd = fmt("botright new | lua vim.api.nvim_win_set_height(0, %s)", height)

  if direction == "horizontal" then
    vim.cmd(h_direction_cmd)
    term_buf_id = api.nvim_get_current_buf()
    vim.opt_local.filetype = "megaterm"
  elseif direction == "vertical" then
    vim.cmd(fmt("vnew | lua vim.api.nvim_win_set_width(0, %s)", width))
    vim.opt_local.filetype = "megaterm"
  elseif direction == "float" then
    local buf_id = api.nvim_create_buf(true, true)
    local win_id = api.nvim_open_win(buf_id, true, {
      relative = "editor",
      style = "minimal",
      border = mega.get_border(),
      width = math.floor(0.8 * vim.o.columns),
      height = math.floor(0.8 * vim.o.lines),
      row = math.floor(0.1 * vim.o.lines),
      col = math.floor(0.1 * vim.o.columns),
      zindex = 99,
    })
    api.nvim_win_set_option(win_id, "number", false)
    api.nvim_win_set_option(win_id, "relativenumber", false)
    api.nvim_buf_set_option(buf_id, "filetype", "megaterm")
    api.nvim_win_set_option(
      win_id,
      "winhl",
      table.concat({
        "Normal:NormalFloat",
        "FloatBorder:FloatBorder",
        "CursorLine:Visual",
        "Search:None",
      }, ",")
    )

    vim.cmd("setlocal bufhidden=wipe")

    term_buf_id = buf_id
  else
    vim.notify("[megaterm] direction must either be `horizontal` or `vertical`.", "WARN")
    vim.cmd(h_direction_cmd)
  end

  set_keymaps(term_buf_id, winnr)

  if precmd ~= nil then cmd = fmt("%s; %s", precmd, cmd) end

  -- REF: https://github.com/seblj/dotfiles/commit/fcdfc17e2987631cbfd4727c9ba94e6294948c40#diff-bbe1851dbfaaa99c8fdbb7229631eafc4f8048e09aa116ef3ad59cde339ef268L56-R90
  vim.fn.termopen(cmd, {
    ---@diagnostic disable-next-line: unused-local
    on_exit = function(jobid, exit_code, event)
      set_keymaps(term_buf_id, winnr)

      -- if we get a custom on_exit, run it instead...
      if custom_on_exit ~= nil and type(custom_on_exit) == "function" then
        custom_on_exit(jobid, exit_code, event, cmd, winnr, term_buf_id)
      else
        if notifier ~= nil and type(notifier) == "function" then notifier(cmd, exit_code) end

        -- test passed/process ended with an "ok" exit code, so let's close it.
        if exit_code == 0 then
          -- TODO: send results to quickfixlist
          api.nvim_buf_delete(term_buf_id, { force = true })
          term_buf_id = nil_buf_id
        end
      end
    end,
  })

  -- P(cmd)

  if on_after_open ~= nil and type(on_after_open) == "function" then
    on_after_open(term_buf_id, winnr)
  else
    vim.cmd([[normal! G]])
    if direction ~= "float" then vim.cmd(winnr .. [[wincmd w]]) end
  end
end

-- Convenience
mega.open_term = mega.term_open

-- Commands that wrap open_term:
mega.command("TermElixir", function()
  local precmd = ""
  local cmd = ""
  if require("mega.utils").root_has_file("Deskfile") then precmd = "eval $(desk load)" end
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
      api.nvim_buf_set_var(bufnr, "cmd", cmd)
      vim.cmd("startinsert")
    end,
  })
end)

mega.command("TermRuby", function()
  local precmd = ""
  local cmd = ""
  if require("mega.utils").root_has_file("Deskfile") then precmd = "eval $(desk load)" end
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
      api.nvim_buf_set_var(bufnr, "cmd", cmd)
      vim.cmd("startinsert")
    end,
  })
end)

mega.command("TermLua", function()
  local cmd = "lua"

  mega.open_term({
    winnr = vim.fn.winnr(),
    cmd = cmd,
    direction = "horizontal",
    on_exit = function() end,
    ---@diagnostic disable-next-line: unused-local
    on_after_open = function(bufnr, _winnr)
      api.nvim_buf_set_var(bufnr, "cmd", cmd)
      vim.cmd("startinsert")
    end,
  })
end)

mega.command("TermPython", function()
  local cmd = "python"

  mega.open_term({
    winnr = vim.fn.winnr(),
    cmd = cmd,
    on_exit = function() end,
    ---@diagnostic disable-next-line: unused-local
    on_after_open = function(bufnr, _winnr)
      api.nvim_buf_set_var(bufnr, "cmd", cmd)
      vim.cmd("startinsert")
    end,
  })
end)

mega.command("TermNode", function()
  local cmd = "node"

  mega.open_term({
    winnr = vim.fn.winnr(),
    cmd = cmd,
    on_exit = function() end,
    ---@diagnostic disable-next-line: unused-local
    on_after_open = function(bufnr, _winnr)
      api.nvim_buf_set_var(bufnr, "cmd", cmd)
      vim.cmd("startinsert")
    end,
  })
end)

mega.command("Term", function()
  mega.open_term({
    winnr = vim.fn.winnr(),
    on_exit = function() end,
    ---@diagnostic disable-next-line: unused-local
    on_after_open = function(bufnr, _winnr) vim.cmd("startinsert") end,
  })
end)

local has_wk, wk = mega.require("which-key")
if has_wk then
  wk.register({
    t = {
      name = "terminal",
      e = { "<cmd>TermElixir<cr>", "repl > elixir" },
      r = { "<cmd>TermRuby<cr>", "repl > ruby" },
      l = { "<cmd>TermLua<cr>", "repl > lua" },
      n = { "<cmd>TermNode<cr>", "repl > node" },
      p = { "<cmd>TermPython<cr>", "repl > python" },
      t = { "<cmd>Term<cr>", "term" },
    },
  }, {
    prefix = "<leader>",
  })
end

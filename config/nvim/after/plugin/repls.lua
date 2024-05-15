if not mega then return end

local U = require("mega.utils")
local command = vim.api.nvim_create_user_command
local fmt = string.format
local nnoremap = require("mega.mappings").nnoremap

local cmds_by_ft = {
  ["lua"] = function(args)
    if string.match(vim.fn.expand("%"), "hammerspoon") ~= nil then
      return "hs"
    else
      return "lua"
    end
  end,
  ["python"] = "python",
  ["javascript"] = "node",
  ["javascriptreact"] = "node",
  ["typescript"] = "node",
  ["typescriptreact"] = "node",
  ["ruby"] = function(args)
    if U.root_has_file("Gemfile") then
      return "rails c"
    else
      return "irb"
    end
  end,
  ["elixir"] = function(args)
    if U.root_has_file("mix.exs") then
      return "iex -S mix"
    else
      return "iex"
    end
  end,
}

command("TermElixir", function(args)
  -- local pre_cmd = ""
  local cmd = "iex"
  -- load up our Deskfile if we have one..
  -- if require("mega.utils").root_has_file("Deskfile") then pre_cmd = "eval $(desk load)" end

  if args.bang then
    cmd = fmt("elixir %s", vim.fn.expand("%"))
  elseif U.root_has_file("mix.exs") then
    cmd = "iex -S mix"
  end

  mega.term({
    cmd = cmd,
    -- pre_cmd = pre_cmd,
    -- temp = true,
    ---@diagnostic disable-next-line: unused-local
    on_after_open = function(bufnr, _winnr)
      vim.api.nvim_buf_set_var(bufnr, "term_cmd", cmd)
      vim.cmd("startinsert")
    end,
  })
end, { bang = true })

command("TermRuby", function(args)
  -- local pre_cmd = ""
  local cmd = ""
  -- if U.root_has_file("Deskfile") then pre_cmd = "eval $(desk load)" end

  if args.bang then
    cmd = fmt("ruby %s", vim.fn.expand("%"))
  elseif U.root_has_file("Gemfile") then
    cmd = "rails c"
  else
    cmd = "irb"
  end

  mega.term({
    cmd = cmd,
    -- pre_cmd = pre_cmd,
    temp = true,
    ---@diagnostic disable-next-line: unused-local
    on_after_open = function(bufnr, _winnr)
      vim.api.nvim_buf_set_var(bufnr, "term_cmd", cmd)
      vim.cmd("startinsert")
    end,
  })
end, { bang = true })

command("TermLua", function()
  local cmd = "lua"

  mega.term({
    cmd = cmd,
    direction = "horizontal",
    temp = true,
    ---@diagnostic disable-next-line: unused-local
    on_after_open = function(bufnr, _winnr)
      vim.api.nvim_buf_set_var(bufnr, "term_cmd", cmd)
      vim.cmd("startinsert")
    end,
  })
end, {})

command("TermHammerspoon", function()
  local cmd = "hs"

  mega.term({
    cmd = cmd,
    direction = "horizontal",
    temp = true,
    ---@diagnostic disable-next-line: unused-local
    on_after_open = function(bufnr, _winnr)
      vim.api.nvim_buf_set_var(bufnr, "term_cmd", cmd)
      vim.cmd("startinsert")
    end,
  })
end, {})

command("TermPython", function()
  local cmd = "python"

  mega.term({
    cmd = cmd,
    temp = true,
    ---@diagnostic disable-next-line: unused-local
    on_after_open = function(bufnr, _winnr)
      vim.api.nvim_buf_set_var(bufnr, "term_cmd", cmd)
      vim.cmd("startinsert")
    end,
  })
end, {})

command("TermNode", function(args)
  local cmd = "node"
  if args.bang then cmd = fmt("node %s", vim.fn.expand("%")) end

  mega.term({
    cmd = cmd,
    temp = true,
    ---@diagnostic disable-next-line: unused-local
    on_after_open = function(bufnr, _winnr)
      vim.api.nvim_buf_set_var(bufnr, "term_cmd", cmd)
      vim.cmd("startinsert")
    end,
  })
end, { bang = true })

command("TermRepl", function(args)
  local bufnr = args.buf or 0
  local ft = vim.bo[bufnr].ft
  local cmd = cmds_by_ft[ft]

  if type(cmd) == "function" then cmd = cmd(args) end

  -- if args.bang then cmd = fmt("node %s", vim.fn.expand("%")) end

  mega.term({
    cmd = cmd,
    temp = true,
    ---@diagnostic disable-next-line: unused-local
    on_after_open = function(bn, _winnr)
      vim.api.nvim_buf_set_var(bn, "term_cmd", cmd)
      vim.cmd("startinsert")
    end,
  })
end, { bang = true })

nnoremap("<localleader>r", "<cmd>TermRepl<cr>", "repl (ft)")

nnoremap("<leader>re", "<cmd>TermElixir<cr>", "elixir")
nnoremap("<leader>rE", "<cmd>TermElixir!<cr>", "elixir (current file)")
nnoremap("<leader>rr", "<cmd>TermRuby<cr>", "ruby")
nnoremap("<leader>rR", "<cmd>TermRuby!<cr>", "ruby (current file)")
nnoremap("<leader>rl", "<cmd>TermLua<cr>", "lua")
nnoremap("<leader>rL", "<cmd>TermLua!<cr>", "lua (current file)")
nnoremap("<leader>rn", "<cmd>TermNode<cr>", "node")
nnoremap("<leader>rN", "<cmd>TermNode!<cr>", "node (current file)")
nnoremap("<leader>rp", "<cmd>TermPython<cr>", "python")
nnoremap("<leader>rP", "<cmd>TermPython!<cr>", "python (current file)")
nnoremap("<leader>rh", "<cmd>TermHammerspoon<cr>", "hammerspoon")

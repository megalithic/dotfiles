if not mega then return end
if not vim.g.enabled_plugin["repls"] then return end

mega.command("TermElixir", function()
  local precmd = ""
  local cmd = ""
  -- load up our Deskfile if we have one..
  if require("mega.utils").root_has_file("Deskfile") then precmd = "eval $(desk load)" end
  if require("mega.utils").root_has_file("mix.exs") then
    cmd = "iex -S mix"
  else
    cmd = "iex"
  end

  mega.term.open({
    cmd = cmd,
    precmd = precmd,
    ---@diagnostic disable-next-line: unused-local
    on_after_open = function(bufnr, _winnr)
      vim.api.nvim_buf_set_var(bufnr, "cmd", cmd)
      vim.cmd("startinsert")
    end,
  })
end)

mega.command("TermRuby", function(args)
  local precmd = ""
  local cmd = ""
  if require("mega.utils").root_has_file("Deskfile") then precmd = "eval $(desk load)" end

  if args.bang then
    cmd = fmt("ruby %s", vim.fn.expand("%"))
  elseif require("mega.utils").root_has_file("Gemfile") then
    cmd = "rails c"
  else
    cmd = "irb"
  end

  mega.term.open({
    cmd = cmd,
    precmd = precmd,
    ---@diagnostic disable-next-line: unused-local
    on_after_open = function(bufnr, _winnr)
      vim.api.nvim_buf_set_var(bufnr, "cmd", cmd)
      vim.cmd("startinsert")
    end,
  })
end, { bang = true })

mega.command("TermLua", function()
  local cmd = "lua"

  mega.term.open({
    cmd = cmd,
    direction = "horizontal",
    ---@diagnostic disable-next-line: unused-local
    on_after_open = function(bufnr, _winnr)
      vim.api.nvim_buf_set_var(bufnr, "cmd", cmd)
      vim.cmd("startinsert")
    end,
  })
end)

mega.command("TermPython", function()
  local cmd = "python"

  mega.term.open({
    cmd = cmd,
    ---@diagnostic disable-next-line: unused-local
    on_after_open = function(bufnr, _winnr)
      vim.api.nvim_buf_set_var(bufnr, "cmd", cmd)
      vim.cmd("startinsert")
    end,
  })
end)

mega.command("TermNode", function()
  local cmd = "node"

  mega.term.open({
    cmd = cmd,
    ---@diagnostic disable-next-line: unused-local
    on_after_open = function(bufnr, _winnr)
      vim.api.nvim_buf_set_var(bufnr, "cmd", cmd)
      vim.cmd("startinsert")
    end,
  })
end)

nnoremap("<leader>re", "<cmd>TermElixir<cr>")
nnoremap("<leader>rE", "<cmd>TermElixir!<cr>")
nnoremap("<leader>rr", "<cmd>TermRuby<cr>")
nnoremap("<leader>rR", "<cmd>TermRuby!<cr>")
nnoremap("<leader>rl", "<cmd>TermLua<cr>")
nnoremap("<leader>rL", "<cmd>TermLua!<cr>")
nnoremap("<leader>rn", "<cmd>TermNode<cr>")
nnoremap("<leader>rN", "<cmd>TermNode!<cr>")
nnoremap("<leader>rp", "<cmd>TermPython<cr>")
nnoremap("<leader>rP", "<cmd>TermPython!<cr>")

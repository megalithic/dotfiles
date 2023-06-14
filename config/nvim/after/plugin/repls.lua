if not mega then return end
if not vim.g.enabled_plugin["repls"] then return end

mega.command("TermElixir", function(args)
  -- local pre_cmd = ""
  local cmd = "iex"
  -- load up our Deskfile if we have one..
  -- if require("mega.utils").root_has_file("Deskfile") then pre_cmd = "eval $(desk load)" end

  if args.bang then
    cmd = fmt("elixir %s", vim.fn.expand("%"))
  elseif require("mega.utils").root_has_file("mix.exs") then
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

mega.command("TermRuby", function(args)
  -- local pre_cmd = ""
  local cmd = ""
  -- if require("mega.utils").root_has_file("Deskfile") then pre_cmd = "eval $(desk load)" end

  if args.bang then
    cmd = fmt("ruby %s", vim.fn.expand("%"))
  elseif require("mega.utils").root_has_file("Gemfile") then
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

mega.command("TermLua", function()
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
end)

mega.command("TermHammerspoon", function()
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
end)

mega.command("TermPython", function()
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
end)

mega.command("TermNode", function(args)
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

nnoremap("<leader>rs", "<cmd>TSendCurrentLine<cr>", "send current line to active repl")
vnoremap("<leader>rs", "<cmd>TSendVisualSelection<cr>", "send visual selection to active repl")
vnoremap("<leader>rS", "<cmd>TSendVisualLines<cr>", "send visual lines to active repl")

nnoremap("<leader>re", "<cmd>TermElixir<cr>", "elixir")
nnoremap("<leader>rE", "<cmd>TermElixir!<cr>", "elixir (current file)")
nnoremap("<leader>rr", "<cmd>TermRuby<cr>", "ruby")
nnoremap("<leader>rR", "<cmd>TermRuby!<cr>", "ruby (current file)")
nnoremap("<leader>rl", "<cmd>TermLua<cr>", "lua")
nnoremap("<leader>rL", "<cmd>TermLua!<cr>", "lua (current file)")
nnoremap("<leader>rn", "<cmd>TermNode<cr>", "node")
nnoremap("<leader>rN", "<cmd>TermNode!<cr>", "node (current file)")
nnoremap("<leader>rp", "<cmd>TermPython<cr>", "python")
-- nnoremap("<leader>rP", "<cmd>TermPython!<cr>", "python (current file)")
nnoremap("<leader>rh", "<cmd>TermHammerspoon<cr>", "hammerspoon")

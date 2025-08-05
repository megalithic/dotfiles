if not Plugin_enabled() then return end

local U = require("config.utils")
-- local nnoremap = require("config.keymaps").nnoremap

local cmds_by_ft = {
  ["lua"] = function(_args)
    if string.match(vim.fn.expand("%"), "([hs][hammerspoon]+)") ~= nil then
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
  ["ruby"] = function(_args)
    if U.root_has_file("Gemfile") then
      return "rails c"
    else
      return "irb"
    end
  end,
  ["elixir"] = function(_args)
    if U.root_has_file("mix.exs") then
      return "iex -S mix"
    else
      return "iex"
    end
  end,
}

Command("TermElixir", function(args)
  -- local pre_cmd = ""
  local cmd = "iex"
  -- load up our Deskfile if we have one..
  -- if require("config.utils").root_has_file("Deskfile") then pre_cmd = "eval $(desk load)" end

  if args.bang then
    cmd = string.format("elixir %s", vim.fn.expand("%"))
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
      vim.cmd.startinsert()
    end,
  })
end, { bang = true })

Command("TermRuby", function(args)
  -- local pre_cmd = ""
  local cmd = ""
  -- if U.root_has_file("Deskfile") then pre_cmd = "eval $(desk load)" end

  if args.bang then
    cmd = string.format("ruby %s", vim.fn.expand("%"))
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
      vim.cmd.startinsert()
    end,
  })
end, { bang = true })

Command("TermLua", function()
  local cmd = "lua"

  mega.term({
    cmd = cmd,
    position = "horizontal",
    temp = true,
    ---@diagnostic disable-next-line: unused-local
    on_after_open = function(bufnr, _winnr)
      vim.api.nvim_buf_set_var(bufnr, "term_cmd", cmd)
      vim.cmd.startinsert()
    end,
  })
end, {})

Command("TermHammerspoon", function()
  local cmd = "hs"

  mega.term({
    cmd = cmd,
    position = "horizontal",
    temp = true,
    ---@diagnostic disable-next-line: unused-local
    on_after_open = function(bufnr, _winnr)
      vim.api.nvim_buf_set_var(bufnr, "term_cmd", cmd)
      vim.cmd.startinsert()
    end,
  })
end, {})

Command("TermPython", function()
  local cmd = "python"

  mega.term({
    cmd = cmd,
    temp = true,
    ---@diagnostic disable-next-line: unused-local
    on_after_open = function(bufnr, _winnr)
      vim.api.nvim_buf_set_var(bufnr, "term_cmd", cmd)
      vim.cmd.startinsert()
    end,
  })
end, {})

Command("TermNode", function(args)
  local cmd = "node"
  if args.bang then cmd = string.format("node %s", vim.fn.expand("%")) end

  mega.term({
    cmd = cmd,
    temp = true,
    ---@diagnostic disable-next-line: unused-local
    on_after_open = function(bufnr, _winnr)
      vim.api.nvim_buf_set_var(bufnr, "term_cmd", cmd)
      vim.cmd.startinsert()
    end,
  })
end, { bang = true })

Command("TermRepl", function(args)
  local bufnr = args.buf or 0
  local ft = vim.bo[bufnr].ft
  if ft == "megaterm" then
    -- This prevent me from trying to launch a repl within an existing megaterm;
    -- and instead, simply toggles hidden the existing megaterm.
    mega.term({
      id = "megaterm_term",
    })
  end

  local cmd = cmds_by_ft[ft]

  if type(cmd) == "function" then cmd = cmd(args) end

  mega.term({
    id = "repl_" .. ft,
    cmd = cmd,
    ---@diagnostic disable-next-line: unused-local
    on_open = function(buf, _winnr)
      vim.api.nvim_buf_set_var(buf, "term_cmd", cmd)
      vim.cmd.startinsert()
    end,
  })
end, {})

-- vim.keymap.set({ "n", "v", "t" }, "<localleader>x", function()
--   mega.tt.runner({
--     id = "run_and_build_term",
--     pos = "vsp",
--     cmd = function()
--       local file = vim.fn.expand("%")
--       local sfile = vim.fn.expand("%:r")
--       print(file)
--       local ft = vim.bo.ft
--       local ft_cmds = {
--         sh = "bash " .. file,
--         elixir = "elixir " .. file,
--         lua = "lua " .. file,
--         rust = "cargo " .. file,
--         python = "python3 " .. file,
--         javascript = "node " .. file,
--         java = "javac " .. file .. " && java " .. sfile,
--         go = "go build && go run " .. file,
--         c = "g++ " .. file .. " -o " .. sfile .. " && ./" .. sfile,
--         cpp = "g++ " .. file .. " -o " .. sfile .. " && ./" .. sfile,
--         typescript = "deno compile " .. file .. " && deno run " .. file,
--       }

--       -- don't execute this for certain filetypes
--       if vim.tbl_contains({ "markdown" }, ft) then return end

--       return ft_cmds[ft]
--     end,
--   })
-- end, { desc = "term: build and run file" })

-- map({ "n", "t" }, "<C-x>", "<cmd>TermRepl<cr>", { desc = "repl (ft)" })
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

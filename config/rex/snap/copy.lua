-- Copy mode: Vim motions over the snapshot, s jumps with flash, any yank
-- copies to the clipboard and closes. q or Esc closes without copying.
local M = {}

function M.start(buf, meta)
  vim.pack.add({ { src = "https://github.com/folke/flash.nvim", version = "5f0f270fdc7c5b0c21d903ee85b9cb06f2ac636a" } }, { confirm = false })
  require("flash").setup({})

  local function map(mode, lhs, rhs)
    vim.keymap.set(mode, lhs, rhs, { buffer = buf, nowait = true, silent = true })
  end
  map({ "n", "x", "o" }, "s", function() require("flash").jump() end)
  -- Same as config/nvim/lua/keymaps.lua.
  map("n", "H", "^")
  map("n", "L", "$")
  map("x", "H", "g^")
  map("x", "L", "g_")
  map("n", "q", "<Cmd>qa!<CR>")
  map("n", "<Esc>", "<Cmd>qa!<CR>")
  map("t", "<Esc>", [[<C-\><C-n>]])

  vim.api.nvim_create_autocmd("TextYankPost", {
    buffer = buf,
    callback = function()
      local event = vim.v.event
      if event.operator ~= "y" then return end
      -- A linewise yank ends in a newline; copy V selections without it.
      local text = event.regtype == "V" and table.concat(event.regcontents, "\n")
      vim.schedule(function()
        if text then vim.fn.setreg("+", text, "v") end
        vim.cmd("qa!")
      end)
    end,
  })

  if meta.jump then vim.schedule(function() require("flash").jump() end) end
end

return M

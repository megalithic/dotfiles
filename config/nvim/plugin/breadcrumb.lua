if not mega then return end
if not vim.g.enabled_plugin["breadcrumb"] then return end

-- adapted from https://github.com/ethanholz/nvim-lastplace/blob/main/lua/nvim-lastplace/init.lua
-- REF: from https://github.com/neovim/neovim/issues/16339#issuecomment-1348133829
local ignore_buftype = { "quickfix", "nofile", "help" }
local ignore_filetype = { "gitcommit", "neogitcommit", "gitrebase", "svn", "hgcommit", "terminal", "megaterm" }

local function run()
  if vim.tbl_contains(ignore_buftype, vim.bo.buftype) then return end

  if vim.tbl_contains(ignore_filetype, vim.bo.filetype) then
    -- reset cursor to first line
    vim.cmd.normal({ "gg", bang = true })
    return
  end

  -- If a line has already been specified on the command line, we are done
  --   nvim file +num
  if vim.fn.line(".") > 1 then return end

  local last_line = vim.fn.line([['"]])
  local buff_last_line = vim.fn.line("$")

  -- If the last line is set and the less than the last line in the buffer
  if last_line > 0 and last_line <= buff_last_line then
    local win_last_line = vim.fn.line("w$")
    local win_first_line = vim.fn.line("w0")
    -- Check if the last line of the buffer is the same as the win
    if win_last_line == buff_last_line then
      -- Set line to last line edited
      vim.cmd.normal({ [[g`"]], bang = true })
      -- Try to center
    elseif buff_last_line - last_line > ((win_last_line - win_first_line) / 2) - 1 then
      vim.cmd.normal({ [[g`"zz]], bang = true })
    else
      vim.cmd.normal({ [[G'"<c-e>]], bang = true })
    end
  end
end

vim.api.nvim_create_autocmd({ "BufWinEnter", "FileType" }, {
  group = vim.api.nvim_create_augroup("nvim-lastplace", {}),
  callback = run,
})

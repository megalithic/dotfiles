if not mega then return end
if not vim.g.enabled_plugin["breadcrumb"] then return end

local fn = vim.fn
local augroup = mega.augroup
local ignore_buftype = { "quickfix", "nofile", "help" }
local ignore_filetype = { "gitcommit", "gitrebase", "svn", "hgcommit", "terminal", "megaterm" }

augroup("LastPlace", {
  event = { "VimEnter", "BufWinEnter", "FileType" },
  desc = "Recall your last place in a file",
  callback = function(args)
    P("in breadcrumb plugin with mega and should be here?")
    P(args)
    dd("in lastplace autocmd")
    if vim.tbl_contains(ignore_buftype, vim.bo.buftype) then return end

    if vim.tbl_contains(ignore_filetype, vim.bo.filetype) then
      -- reset cursor to first line
      vim.cmd([[normal! gg]])
      return
    end

    -- If a line has already been specified on the command line, we are done e.g. nvim file +num
    if fn.line(".") > 1 then return end

    local last_line = fn.line([['"]])
    local buff_last_line = fn.line("$")

    -- If the last line is set and the less than the last line in the buffer
    if last_line > 0 and last_line <= buff_last_line then
      local win_last_line = fn.line("w$")
      local win_first_line = fn.line("w0")
      -- Check if the last line of the buffer is the same as the win
      if win_last_line == buff_last_line then
        vim.cmd([[normal! g`"]]) -- Set line to last line edited
      -- Try to center
      elseif buff_last_line - last_line > ((win_last_line - win_first_line) / 2) - 1 then
        vim.cmd([[normal! g`"zz]])
      else
        vim.cmd([[normal! G'"<c-e>]])
      end
    end
  end,
})

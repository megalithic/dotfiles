local M = {}
local api = vim.api

M.insertCell = function()
  local line = vim.fn.line('.')
  api.nvim_command('execute "normal! A\\n"')
  api.nvim_buf_set_lines(0, line-1, line+1, false, {'#{', '', '#}'})
end

M.findNextCell = function()
  local line = vim.fn.line('.') + 1
  local total_line = vim.fn.line('$')
  while line <= total_line do
    current_line = api.nvim_buf_get_lines(0, line-1, line, false)
    if string.match(current_line[1], '^#{.*') then
      api.nvim_command('execute'..line)
      return
    end
    line = line + 1
  end
  api.nvim_command("echohl WarningMsg | echo 'no next cell' | echohl None")
end

M.findPrevCell = function()
  local line = vim.fn.line('.') - 1
  local total_line = vim.fn.line('$')
  while line > 0 do
    current_line = api.nvim_buf_get_lines(0, line-1, line, false)
    if string.match(current_line[1], '^#}.*') then
      while line > 0 do
        current_line = api.nvim_buf_get_lines(0, line-1, line, false)
        if string.match(current_line[1], '^#{.*') then
          api.nvim_command('execute'..line)
          return
        end
        line = line - 1
      end
    end
    line = line - 1
  end
  api.nvim_command("echohl WarningMsg | echo 'no previous cell' | echohl None")
end

return M

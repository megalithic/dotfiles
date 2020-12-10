local M = {}

function M.trigger_ft()
  if vim.bo.filetype and vim.bo.filetype ~= "" then
    vim.cmd([[doautocmd FileType ]] .. vim.bo.filetype)
  end
end

function M.handle()
  if vim.bo.filetype and vim.bo.filetype ~= "" then
    local ft_exists, ft_plugin = pcall(require, "mega.ft." .. vim.bo.filetype)
    if ft_exists then
      local bufnr = vim.api.nvim_get_current_buf()
      pcall(
        function()
          ft_plugin(bufnr)
        end
      )
    end
  end
end

function M.setup()
  mega.augroup(
    "mega.ft",
    function()
      vim.api.nvim_exec([[autocmd FileType * lua require('mega.ft').handle()]], true)
    end
  )
end

-- TODO:
-- we could do some of this inline for some simple things, rather than littering with tons of ft files on disk:
-- https://github.com/ellisonleao/dotfiles/blob/main/nvim/.config/nvim/lua/editor.lua#L189-L205

return M

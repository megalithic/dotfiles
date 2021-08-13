local M = {}

function M.trigger_ft()
  vim.cmd("doautoall FileType")

  -- if vim.bo.ft and vim.bo.ft ~= "" then
  --   vim.cmd("doautocmd FileType " .. vim.bo.ft)
  -- end
end

function M.handle()
  if vim.bo.ft and vim.bo.ft ~= "" then
    local status, ft_plugin = pcall(require, "ftplugin." .. vim.bo.ft)
    if status then
      local bufnr = vim.api.nvim_get_current_buf()
      pcall(
        function()
          ft_plugin(bufnr)
        end
      )
    else
      mega.inspect("ftplugin loading failed", {vim.bo.ft, ft_plugin}, 4)
    end
  end
end

function M.setup()
  mega.augroup_cmds(
    "ftplugin",
    {
      {
        events = {"FileType"},
        targets = {"*"},
        command = "lua require('ftplugin').handle()"
      }
    }
  )
end

-- TODO:
-- we could do some of this inline for some simple things, rather than littering with tons of ft files on disk:
-- https://github.com/ellisonleao/dotfiles/blob/main/nvim/.config/nvim/lua/editor.lua#L189-L205

return M
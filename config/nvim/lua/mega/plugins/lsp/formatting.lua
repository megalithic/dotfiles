local M = {}

-- vim.lsp.handlers["textDocument/hover"] = function(_, method, result)
--   print(vim.inspect(result))
-- end

M.autoformat = true

function M.toggle()
  M.autoformat = not M.autoformat
  if M.autoformat then
    mega.info("enabled format on save", "Formatting")
  else
    mega.warn("disabled format on save", "Formatting")
  end
end

function M.format()
  if M.autoformat then
    if vim.lsp.buf.format then
      vim.lsp.buf.format()
    else
      vim.lsp.buf.formatting_sync()
    end
  end
end

function M.setup(client, buf)
  local ft = vim.api.nvim_buf_get_option(buf, "filetype")
  local nls = require("mega.plugins.null-ls")

  local enable = false
  if nls.has_formatter(ft) then
    enable = client.name == "null-ls"
  else
    enable = not (client.name == "null-ls")
  end

  if client.name == "tsserver" then
    enable = false
  end

  -- mega.info(client.name .. " " .. (enable and "yes" or "no"), "format")

  client.server_capabilities.documentFormattingProvider = enable
  -- format on save
  if client.server_capabilities.documentFormattingProvider then
    vim.cmd([[
      augroup LspFormat
        autocmd! * <buffer>
        autocmd BufWritePre <buffer> lua require("mega.plugins.lsp.formatting").format()
      augroup END
    ]])
  end
end

return M

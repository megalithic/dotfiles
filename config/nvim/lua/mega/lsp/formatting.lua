local M = {}
local api, fn, g, lsp = vim.api, vim.fn, vim.g, vim.lsp
local vcmd = vim.cmd
local fmt = string.format

-- REF: https://github.com/lukas-reineke/dotfiles/blob/master/vim/lua/lsp/formatting.lua
function M.setup(client, bufnr)
  -- format on save
  M.null_ls(client, bufnr)

  -- disable formatting for the following language-servers (let null-ls takeover):
  -- tags: #ignored, #disabled, #formatting
  local disabled_formatting_ls = { "jsonls", "tailwindcss", "html", "tsserver", "ls_emmet", "sumneko_lua" }
  for i = 1, #disabled_formatting_ls do
    if disabled_formatting_ls[i] == client.name then
      client.resolved_capabilities.document_formatting = false
      client.resolved_capabilities.document_range_formatting = false
    end
  end
end

function M.null_ls(client, bufnr)
  local function has_nls_formatter(ft)
    local sources = require("null-ls.sources")
    local available = sources.get_available(ft, "NULL_LS_FORMATTING")
    return #available > 0
  end

  local ftype = api.nvim_buf_get_option(bufnr, "filetype")

  if client.name == "null-ls" then
    if has_nls_formatter(ftype) then
      client.resolved_capabilities.document_formatting = true
    else
      client.resolved_capabilities.document_formatting = false
    end
  end

  if client.resolved_capabilities.document_formatting then
    vcmd([[
    augroup Format
      autocmd! * <buffer>
      mkview!
      autocmd BufWritePre <buffer> lua vim.lsp.buf.formatting_sync(nil, 1500)
      loadview
    augroup END
  ]])
  end
end

return M

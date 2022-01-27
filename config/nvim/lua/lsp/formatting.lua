local M = {}
local api, fn, g, lsp = vim.api, vim.fn, vim.g, vim.lsp
local vcmd = vim.cmd
local fmt = string.format

-- REF: https://github.com/lukas-reineke/dotfiles/blob/master/vim/lua/lsp/formatting.lua
function M.setup(client, bufnr, formatter_ls)
  -- format on save
  if formatter_ls == "null-ls" then
    M.null_ls(client, bufnr)
  elseif formatter_ls == "efm-ls" then
    M.efm_ls(client, bufnr)
  end

  -- disable formatting for the following language-servers (let null-ls takeover):
  -- tags: #ignored, #disabled, #formatting
  local disabled_formatting_ls = { "jsonls", "tailwindcss", "html", "tsserver", "ls_emmet" }
  for i = 1, #disabled_formatting_ls do
    if disabled_formatting_ls[i] == client.name then
      client.resolved_capabilities.document_formatting = false
      client.resolved_capabilities.document_range_formatting = false
    end
  end
end

function M.null_ls(client, bufnr)
  local ft = api.nvim_buf_get_option(bufnr, "filetype")
  local nls = mega.load("lsp.null-ls")

  -- this SHOULD help prevent from colliding formatters
  if client.name == "null-ls" then
    if nls.has_nls_formatter(ft) then
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
      autocmd BufWritePre <buffer> lua vim.lsp.buf.formatting_sync(nil, 500)
      loadview
    augroup END
  ]])
  end
end

function M.efm_ls(client, bufnr) -- bufnr
  local format_options_var = function()
    return string.format("format_options_%s", vim.bo.filetype)
  end

  local format_options_prettier = {
    tabWidth = 2,
    singleQuote = false,
    trailingComma = "all",
    configPrecedence = "prefer-file",
  }
  g.format_options_typescript = format_options_prettier
  g.format_options_javascript = format_options_prettier
  g.format_options_typescriptreact = format_options_prettier
  g.format_options_javascriptreact = format_options_prettier
  g.format_options_json = format_options_prettier
  g.format_options_css = format_options_prettier
  g.format_options_scss = format_options_prettier
  g.format_options_html = format_options_prettier
  g.format_options_yaml = format_options_prettier
  g.format_options_yaml = {
    tabWidth = 2,
    singleQuote = true,
    trailingComma = "all",
    configPrecedence = "prefer-file",
  }
  g.format_options_markdown = format_options_prettier
  g.format_options_sh = {
    tabWidth = 4,
  }

  if client.resolved_capabilities.document_formatting then
    vcmd([[
    augroup Format
      autocmd! * <buffer>
      mkview!
      autocmd BufWritePre <buffer> lua vim.lsp.buf.formatting_sync(nil, 500)
      loadview
    augroup END
  ]])
  end
end

return M

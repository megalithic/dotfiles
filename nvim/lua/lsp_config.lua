-- [ debugging ] ---------------------------------------------------------------

-- Can set this lower if needed (used in tandem with utils.inspect) ->
-- require('vim.lsp.log').set_level("trace")
-- require('vim.lsp.log').set_level("debug")

local utils = require('utils')
utils.inspect("loading lsp_config.lua")

-- To execute in :cmd ->
-- :lua <the_command>

-- LSP log location ->
-- `tail -n150 -f $HOME/.local/share/nvim/lsp.log`


-- [ requires ] ----------------------------------------------------------------

local has_lsp, _ = pcall(require, "nvim_lsp")
if not has_lsp then
  print("[WARN] nvim_lsp not found/installed/loaded..")

  return
end

local has_diagnostic, diagnostic = pcall(require, "diagnostic") -- theirs
local has_completion, completion = pcall(require, "completion") -- theirs
-- local has_extensions = pcall(require, 'lsp_extensions') -- theirs
local status = require('lsp_status') -- mine

status.activate()

-- [ custom on_attach ] --------------------------------------------------------
local on_attach = function(client, bufnr)
  utils.inspect("client.resolved_capabilities", client.resolved_capabilities)

  vim.api.nvim_buf_set_option(bufnr, "omnifunc", "v:lua.vim.lsp.omnifunc")

  if has_diagnostic then
    diagnostic.on_attach(client, bufnr)
  end

  if has_completion then
    completion.on_attach(client, bufnr)
  end

  status.on_attach(client, bufnr)


  -- [ mappings ] --------------------------------------------------------------

  if client.resolved_capabilities.document_formatting then
    vim.api.nvim_command([[au BufWritePre <buffer> lua vim.lsp.buf.formatting_sync(nil, 1000)]])
    utils.bmap("n", "<Leader>lf", "<cmd>lua vim.lsp.buf.formatting_sync(nil, 1000)<CR>")
    utils.bmap("n", "<Leader>lF", "<cmd>lua vim.lsp.buf.formatting(nil, 1000)<CR>")
  end

  utils.bmap("n", "<Leader>lgd", "<cmd>lua vim.lsp.buf.definition()<CR>")
  utils.bmap("n", "<c-]>", "<cmd>lua vim.lsp.buf.definition()<CR>")
  utils.bmap("n", "<Leader>lr", "<cmd>lua vim.lsp.buf.references()<CR>")
  utils.bmap('n', '<Leader>lgr', '<cmd>lua require("telescope.builtin").lsp_references()<CR>')
  utils.bmap("n", "<Leader>lgi", "<cmd>lua vim.lsp.buf.implementation()<CR>")
  utils.bmap("n", "<Leader>lgt", "<cmd>lua vim.lsp.buf.type_definition()<CR>")
  utils.bmap("n", "<Leader>lgs", "<cmd>lua vim.lsp.buf.document_symbol()<CR>")
  utils.bmap("n", "<Leader>lgS", "<cmd>lua vim.lsp.buf.workspace_symbol()<CR>")
  utils.bmap("n", "<Leader>dE", "<cmd>lua vim.lsp.buf.declaration()<CR>")
  utils.bmap("n", "<Leader>ln", "<cmd>lua vim.lsp.buf.rename()<CR>")
  utils.bmap("n", "<Leader>la", "<cmd>lua vim.lsp.buf.code_action()<CR>")

  utils.bmap("n", "[d", "<cmd>PrevDiagnosticCycle<CR>")
  utils.bmap("n", "]d", "<cmd>NextDiagnosticCycle<CR>")

  utils.bmap("n", "<Leader>lD", "<cmd>lua vim.lsp.util.show_line_diagnostics()<CR>")
  utils.bmap("n", "<Leader>ld", "<cmd>lua vim.lsp.util.show_line_diagnostics()<CR>")
  utils.bmap("n", "<Leader>e", "<cmd>lua vim.lsp.util.show_line_diagnostics()<CR>")

  utils.augroup('LSP', function ()
    vim.api.nvim_command('autocmd CursorHold <buffer> lua vim.lsp.util.show_line_diagnostics()')

    -- if client.resolved_capabilities.document_highlight then
    --   vim.api.nvim_command('autocmd CursorHold  <buffer> lua vim.lsp.buf.document_highlight()')
    --   vim.api.nvim_command('autocmd CursorHoldI <buffer> lua vim.lsp.buf.document_highlight()')
    --   vim.api.nvim_command('autocmd CursorMoved <buffer> lua vim.lsp.util.buf_clear_references()')
    -- end
  end)
end


-- [ lsp server config ] -------------------------------------------------------

local lsp_servers_loaded, lsp_servers = pcall(require, 'lsp_servers')
if lsp_servers_loaded then
  lsp_servers.activate(on_attach)
else
  utils.inspect('', lsp_servers, 4)
end

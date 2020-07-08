local nvim_lsp = require('nvim_lsp')
local lsp_status = require('lsp-status')

lsp_status.register_progress()

local function preview_location_callback(_, method, result)
  if result == nil or vim.tbl_isempty(result) then
    -- vim.lsp.log.info(method, 'No location found')
    return nil
  end
  if vim.tbl_islist(result) then
    vim.lsp.util.preview_location(result[1])
  else
    vim.lsp.util.preview_location(result)
  end
end

function peek_definition()
  local params = vim.lsp.util.make_position_params()
  return vim.lsp.buf_request(0, 'textDocument/definition', params, preview_location_callback)
end

local on_attach = function(client, bufnr)
  vim.api.nvim_buf_set_option(bufnr, 'omnifunc', 'v:lua.vim.lsp.omnifunc')

  lsp_status.on_attach(client)
  require'diagnostic'.on_attach()
  require'completion'.on_attach({
      sorter = 'alphabet',
      matcher = {'exact', 'substring', 'fuzzy'}
    })

  local opts = { noremap=true, silent=true }
  vim.api.nvim_buf_set_keymap(bufnr, 'n', '<Leader>lgd', '<cmd>lua vim.lsp.buf.definition()<CR>', opts)
  vim.api.nvim_buf_set_keymap(bufnr, 'n', '<Leader>lK',  '<cmd>lua vim.lsp.buf.hover()<CR>', opts)
  vim.api.nvim_buf_set_keymap(bufnr, 'n', '<Leader>K',  '<cmd>lua vim.lsp.buf.hover()<CR>', opts)
  vim.api.nvim_buf_set_keymap(bufnr, 'n', '<Leader>lr', '<cmd>lua vim.lsp.buf.references()<CR>', opts)
  vim.api.nvim_buf_set_keymap(bufnr, 'n', '<Leader>lgD', '<cmd>lua vim.lsp.util.show_line_diagnostics()<CR>', opts)
  vim.api.nvim_buf_set_keymap(bufnr, 'n', '<Leader>lgi', '<cmd>lua vim.lsp.buf.implementation()<CR>', opts)
  vim.api.nvim_buf_set_keymap(bufnr, 'n', '<Leader>ls', '<cmd>lua vim.lsp.buf.signature_help()<CR>', opts)
  vim.api.nvim_buf_set_keymap(bufnr, 'n', '<Leader>lgt', '<cmd>lua vim.lsp.buf.type_definition()<CR>', opts)
  vim.api.nvim_buf_set_keymap(bufnr, 'n', '<Leader>lgs', '<cmd>lua vim.lsp.buf.document_symbol()<CR>', opts)
  vim.api.nvim_buf_set_keymap(bufnr, 'n', '<Leader>lgS', '<cmd>lua vim.lsp.buf.workspace_symbol()<CR>', opts)
  vim.api.nvim_buf_set_keymap(bufnr, 'n', '<Leader>de', '<cmd>lua vim.lsp.buf.declaration()<CR>', opts)
  vim.api.nvim_buf_set_keymap(bufnr, 'n', '<Leader>rn', '<cmd>lua vim.lsp.buf.rename()<CR>', opts)
  vim.api.nvim_buf_set_keymap(bufnr, 'n', '<Leader>l,', '<cmd>lua vim.lsp.buf.rename()<CR>', opts)
  vim.api.nvim_buf_set_keymap(bufnr, 'n', '<Leader>lrn', '<cmd>lua vim.lsp.buf.rename()<CR>', opts)
  vim.api.nvim_buf_set_keymap(bufnr, 'n', '<Leader>lcf', '<cmd>lua vim.lsp.buf.formatting()<CR>', opts)
  vim.api.nvim_buf_set_keymap(bufnr, 'n', '<Leader>lca', '<cmd>lua vim.lsp.buf.code_action()<CR>', opts)
  vim.api.nvim_buf_set_keymap(bufnr, 'n', '<Leader>lpd', '<cmd>lua peek_definition()<CR>', opts)
  vim.api.nvim_buf_set_keymap(bufnr, 'n', '[d', ':PrevDiagnostic<CR>', opts)
  vim.api.nvim_buf_set_keymap(bufnr, 'n', ']d', ':NextDiagnostic<CR>', opts)
  vim.api.nvim_buf_set_keymap(bufnr, 'n', '[D', ':PrevDiagnosticCycle<CR>', opts)
  vim.api.nvim_buf_set_keymap(bufnr, 'n', ']D', ':NextDiagnosticCycle<CR>', opts)
end

-- DEFAULT config for all LSPs
local servers = {'cssls', 'html', 'jsonls', 'tsserver', 'vimls'}
-- local servers = {'cssls', 'bashls', 'diagnosticls', 'dockerls', 'elixirls', 'elmls', 'html', 'intelephense', 'tsserver', 'jsonls', 'pyls', 'rls', 'rust_analyzer', 'sourcekit', 'vimls'}
for _, lsp in ipairs(servers) do
  nvim_lsp[lsp].setup({
      on_attach = on_attach,
      capabilities = lsp_status.capabilities
    })
end

-- CUSTOM config for all LSPs
nvim_lsp.elixirls.setup({
    cmd = {"/Users/replicant/.cache/nvim/nvim_lsp/elixirls/elixir-ls/release/language_server.sh"},
    on_attach = on_attach,
    capabilities = lsp_status.capabilities,
  })

nvim_lsp.elmls.setup({
    cmd = {"/Users/replicant/.cache/nvim/nvim_lsp/elmls/node_modules/.bin/elm-language-server"},
    on_attach = on_attach,
    capabilities = lsp_status.capabilities,
  })

nvim_lsp.bashls.setup({
    cmd = {"/Users/replicant/.cache/nvim/nvim_lsp/bashls/node_modules/.bin/bash-language-server", "start"},
    filetypes = {"sh", "zsh", "bash", "fish"},
    root_dir = function()
      local cwd = vim.fn.getcwd()
      return cwd
    end,
    on_attach = on_attach,
    capabilities = lsp_status.capabilities,
  })

nvim_lsp.pyls.setup({
    enable=true,
    plugins={
      pyls_mypy={
        enabled=true,
        live_mode=false
      }
    },
    on_attach = on_attach,
    capabilities = lsp_status.capabilities,
  })

-- nvim_lsp.diagnosticls.setup({
--     cmd = {"/Users/replicant/.cache/nvim/nvim_lsp/diagnosticls/node_modules/.bin/diagnostic-languageserver", "--stdio"},
--     on_attach = on_attach,
--   })

local sumneko_settings = {
  runtime={
    version="LuaJIT",
  },
  diagnostics={
    enable=true,
    globals={
      "vim", "Color", "c", "Group", "g", "s", "describe", "it", "before_each", "after_each", "hs"
    },
  },
}
sumneko_settings.Lua = vim.deepcopy(sumneko_settings)

nvim_lsp.sumneko_lua.setup({
    -- Lua LSP configuration
    settings=sumneko_settings,
    -- Runtime configurations
    filetypes = {"lua"},
    cmd = {
      "/Users/replicant/.cache/nvim/nvim_lsp/sumneko_lua/lua-language-server/bin/macOS/lua-language-server",
      "-E",
      "/Users/replicant/.cache/nvim/nvim_lsp/sumneko_lua/lua-language-server/main.lua"
    },
    on_attach = on_attach,
    capabilities = lsp_status.capabilities,
  })

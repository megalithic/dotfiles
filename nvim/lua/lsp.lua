local has_lsp, nvim_lsp = pcall(require, 'nvim_lsp')
if not has_lsp then
  return
end

local has_diagnostic, diagnostic = pcall(require, 'diagnostic')
local has_completion, completion = pcall(require, 'completion')
local lsp_status = require('lsp-status')

lsp_status.register_progress()

-- local function preview_location_callback(_, method, result)
--   if result == nil or vim.tbl_isempty(result) then
--     vim.lsp.log.info(method, 'No location found')
--     return nil
--   end
--   if vim.tbl_islist(result) then
--     vim.lsp.util.preview_location(result[1])
--   else
--     vim.lsp.util.preview_location(result)
--   end
-- end

-- function peek_definition()
--   local params = vim.lsp.util.make_position_params()
--   return vim.lsp.buf_request(0, 'textDocument/definition', params, preview_location_callback)
-- end

function preview_location(location, context)
  -- location may be LocationLink or Location (more useful for the former)
  context = context or 5
  local uri = location.targetUri or location.uri
  if uri == nil then
    return
  end
  local bufnr = vim.uri_to_bufnr(uri)
  if not vim.api.nvim_buf_is_loaded(bufnr) then
    vim.fn.bufload(bufnr)
  end
  local range = location.targetRange or location.range
  local contents =
  vim.api.nvim_buf_get_lines(bufnr, range.start.line - context, range["end"].line + 1 + context, false)
  local filetype = vim.api.nvim_buf_get_option(bufnr, "filetype")
  return vim.lsp.util.open_floating_preview(contents, filetype)
end

function switch_header_source()
  vim.lsp.buf_request(
    0,
    "textDocument/switchSourceHeader",
    vim.lsp.util.make_text_document_params(),
    function(err, _, result, _, _)
      if err then
        print(err)
      else
        vim.cmd("e " .. vim.uri_to_fname(result))
      end
    end
    )
end

function preview_location_callback(_, method, result, context)
  context = context or 5
  if result == nil or vim.tbl_isempty(result) then
    vim.lsp.log.info(method, "No location found")
    return nil
  end
  if vim.tbl_islist(result) then
    preview_location(result[1])
  else
    preview_location(result)
  end
end

function peek_definition(context)
  context = context or 5
  local params = vim.lsp.util.make_position_params()
  return vim.lsp.buf_request(0, "textDocument/definition", params, preview_location_callback, context)
end

local on_attach = function(client, bufnr)
  vim.api.nvim_buf_set_option(bufnr, 'omnifunc', 'v:lua.vim.lsp.omnifunc')

  -- TODO/REF: https://github.com/delianides/dotfiles/blob/1b3ee23e9e254b8a654e85c743ff761b1dfc9d5e/tag-vim/vim/lua/lsp.lua#L39
  -- local resolved_capabilities = client.resolved_capabilities

  lsp_status.on_attach(client)

  if has_diagnostic then
    diagnostic.on_attach()
  end

  if has_completion then
    completion.on_attach()
   -- completion.on_attach({
    --     sorter = 'alphabet',
    --     matcher = {'exact', 'substring', 'fuzzy'}
    --   })
  end

  local opts = { noremap=true, silent=true }
  vim.api.nvim_buf_set_keymap(bufnr, 'n', '<Leader>lgd', '<cmd>lua vim.lsp.buf.definition()<CR>', opts)
  vim.api.nvim_buf_set_keymap(bufnr, 'n', '<Leader>lr', '<cmd>lua vim.lsp.buf.references()<CR>', opts)
  vim.api.nvim_buf_set_keymap(bufnr, 'n', '<Leader>lgi', '<cmd>lua vim.lsp.buf.implementation()<CR>', opts)
  vim.api.nvim_buf_set_keymap(bufnr, 'n', '<Leader>ls', '<cmd>lua vim.lsp.buf.signature_help()<CR>', opts)
  vim.api.nvim_buf_set_keymap(bufnr, 'n', '<Leader>lgt', '<cmd>lua vim.lsp.buf.type_definition()<CR>', opts)
  vim.api.nvim_buf_set_keymap(bufnr, 'n', '<Leader>lgs', '<cmd>lua vim.lsp.buf.document_symbol()<CR>', opts)
  vim.api.nvim_buf_set_keymap(bufnr, 'n', '<Leader>lgS', '<cmd>lua vim.lsp.buf.workspace_symbol()<CR>', opts)
  -- vim.api.nvim_buf_set_keymap(bufnr, 'n', '<Leader>de', '<cmd>lua vim.lsp.buf.declaration()<CR>', opts)

  vim.api.nvim_buf_set_keymap(bufnr, 'n', '<Leader>ln', '<cmd>lua vim.lsp.buf.rename()<CR>', opts)

  vim.api.nvim_buf_set_keymap(bufnr, 'n', '<Leader>lf', '<cmd>lua vim.lsp.buf.formatting()<CR>', opts)
  vim.api.nvim_buf_set_keymap(bufnr, 'n', '<Leader>la', '<cmd>lua vim.lsp.buf.code_action()<CR>', opts)

  vim.api.nvim_buf_set_keymap(bufnr, 'n', '<Leader>lk',  '<cmd>lua vim.lsp.buf.hover()<CR>', opts)
  vim.api.nvim_buf_set_keymap(bufnr, 'n', '<Leader>ld', '<cmd>lua vim.lsp.util.show_line_diagnostics()<CR>', opts)
  vim.api.nvim_buf_set_keymap(bufnr, 'n', '<Leader>lp', '<cmd>lua peek_definition()<CR>', opts)

  vim.api.nvim_buf_set_keymap(bufnr, 'n', '[d', ':PrevDiagnosticCycle<CR>', opts)
  vim.api.nvim_buf_set_keymap(bufnr, 'n', ']d', ':NextDiagnosticCycle<CR>', opts)
end

-- DEFAULT config for all LSPs
local servers = {'cssls', 'elmls', 'elixirls', 'html', 'tsserver', 'vimls'}
-- local servers = {'cssls', 'bashls', 'diagnosticls', 'dockerls', 'elixirls', 'elmls', 'html', 'intelephense', 'tsserver', 'jsonls', 'pyls', 'rls', 'rust_analyzer', 'sourcekit', 'vimls'}
for _, lsp in ipairs(servers) do
  nvim_lsp[lsp].setup({
      on_attach = on_attach,
      capabilities = lsp_status.capabilities
    })
end

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
      "vim", "Color", "c", "Group", "g", "s", "describe", "it", "before_each", "after_each", "hs", "config"
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


nvim_lsp.yamlls.setup({
    on_attach = on_attach,
    capabilities = lsp_status.capabilities,
    settings = {
      yaml = {
        schemas = {
          ['http://json.schemastore.org/github-workflow'] = '.github/workflows/*.{yml,yaml}',
          ['http://json.schemastore.org/github-action'] = '.github/action.{yml,yaml}',
          ['http://json.schemastore.org/ansible-stable-2.9'] = 'roles/tasks/*.{yml,yaml}',
          ['http://json.schemastore.org/prettierrc'] = '.prettierrc.{yml,yaml}',
          ['http://json.schemastore.org/stylelintrc'] = '.stylelintrc.{yml,yaml}',
          ['http://json.schemastore.org/circleciconfig'] = '.circleci/**/*.{yml,yaml}'
        }
      }
    },
  })

nvim_lsp.jsonls.setup({
    on_attach = on_attach,
    capabilities = lsp_status.capabilities,
    settings = {
      json = {
        format = { enable = true },
        schemas = {
          {
            description = 'TypeScript compiler configuration file',
            fileMatch = {'tsconfig.json', 'tsconfig.*.json'},
            url = 'http://json.schemastore.org/tsconfig'
          },
          {
            description = 'Lerna config',
            fileMatch = {'lerna.json'},
            url = 'http://json.schemastore.org/lerna'
          },
          {
            description = 'Babel configuration',
            fileMatch = {'.babelrc.json', '.babelrc', 'babel.config.json'},
            url = 'http://json.schemastore.org/lerna'
          },
          {
            description = 'ESLint config',
            fileMatch = {'.eslintrc.json', '.eslintrc'},
            url = 'http://json.schemastore.org/eslintrc'
          },
          {
            description = 'Bucklescript config',
            fileMatch = {'bsconfig.json'},
            url = 'https://bucklescript.github.io/bucklescript/docson/build-schema.json'
          },
          {
            description = 'Prettier config',
            fileMatch = {'.prettierrc', '.prettierrc.json', 'prettier.config.json'},
            url = 'http://json.schemastore.org/prettierrc'
          },
          {
            description = 'Vercel Now config',
            fileMatch = {'now.json', 'vercel.json'},
            url = 'http://json.schemastore.org/now'
          },
          {
            description = 'Stylelint config',
            fileMatch = {'.stylelintrc', '.stylelintrc.json', 'stylelint.config.json'},
            url = 'http://json.schemastore.org/stylelintrc'
          },
        }
      },
    },
  })

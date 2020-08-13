-- DEBUGGING LUA and LSP THINGS:
-- :lua require('vim.lsp.log').set_level("debug")
-- :lua print(vim.lsp.get_log_path())
-- :lua print(vim.inspect(vim.tbl_keys(vim.lsp.callbacks)))

local has_lsp, nvim_lsp = pcall(require, 'nvim_lsp')
if not has_lsp then return end

local has_diagnostic, diagnostic = pcall(require, 'diagnostic')
local has_completion, completion = pcall(require, 'completion')

-- REF: setup treesitter thigns:
-- https://github.com/cossonleo/nvim_config/blob/master/lua/cossonleo/devplug.lua#L12

local on_attach = function(client, bufnr)
  vim.api.nvim_buf_set_option(bufnr, 'omnifunc', 'v:lua.vim.lsp.omnifunc')

  -- TODO/REF: https://github.com/delianides/dotfiles/blob/1b3ee23e9e254b8a654e85c743ff761b1dfc9d5e/tag-vim/vim/lua/lsp.lua#L39
  -- local resolved_capabilities = client.resolved_capabilities
  -- if resolved_capabilities.document_highlight then
  --   vim.api.nvim_command[[autocmd CursorHold  <buffer> lua vim.lsp.buf.document_highlight()]]
  --   vim.api.nvim_command[[autocmd CursorHoldI <buffer> lua vim.lsp.buf.document_highlight()]]
  --   vim.api.nvim_command[[autocmd CursorMoved <buffer> lua vim.lsp.util.buf_clear_references()]]
  -- end
  -- print(vim.inspect(vim.tbl_keys(resolved_capabilities)))

  local server_capabilities = client.server_capabilities
  local resolved_capabilities = client.server_capabilities

  -- print(vim.inspect(client.name))
  -- print(vim.inspect(vim.tbl_keys(resolved_capabilities)))
  -- print(vim.inspect(vim.tbl_keys(server_capabilities)))

  if has_diagnostic then
    diagnostic.on_attach()
  end

  if has_completion then
    completion.on_attach()
  end

  -- This came from https://github.com/tjdevries/config_manager/blob/master/xdg_config/nvim/lua/lsp_config.lua
  local mapper = function(mode, key, result)
    vim.fn.nvim_buf_set_keymap(0, mode, key, result, {noremap=true, silent=true})
  end

  if server_capabilities.documentFormattingProvider then
    -- use vim-go built-in formatting which uses goimports
    -- if client.name ~= "gopls" then
    vim.api.nvim_command([[au BufWritePre <buffer> lua vim.lsp.buf.formatting_sync(nil, 1000)]])
    mapper('n', '<Leader>lf', '<cmd>lua vim.lsp.buf.formatting_sync(nil, 1000)<CR>')
    mapper('n', '<Leader>lF', '<cmd>lua vim.lsp.buf.formatting(nil, 1000)<CR>')
    -- end
  end

  mapper('n', '<Leader>lgd', '<cmd>lua vim.lsp.buf.definition()<CR>')
  mapper('n', '<Leader>lr', '<cmd>lua vim.lsp.buf.references()<CR>')
  mapper('n', '<Leader>lgi', '<cmd>lua vim.lsp.buf.implementation()<CR>')
  mapper('n', '<Leader>lgt', '<cmd>lua vim.lsp.buf.type_definition()<CR>')
  mapper('n', '<Leader>lgs', '<cmd>lua vim.lsp.buf.document_symbol()<CR>')
  mapper('n', '<Leader>lgS', '<cmd>lua vim.lsp.buf.workspace_symbol()<CR>')
  -- mapper('n', '<Leader>de', '<cmd>lua vim.lsp.buf.declaration()<CR>')
  mapper('n', '<Leader>ln', '<cmd>lua vim.lsp.buf.rename()<CR>')
  mapper('n', '<Leader>la', '<cmd>lua vim.lsp.buf.code_action()<CR>')

  if vim.api.nvim_buf_get_option(0, 'filetype') ~= 'vim' then
    mapper('n', '<Leader>lh',  '<cmd>lua vim.lsp.buf.hover()<CR>')
    mapper('n', '<Leader>lk', '<cmd>lua vim.lsp.buf.signature_help()<CR>')
  end
  mapper('n', '<Leader>lD', '<cmd>lua vim.lsp.util.show_line_diagnostics()<CR>')

  mapper('n', '[d', ':PrevDiagnosticCycle<CR>')
  mapper('n', ']d', ':NextDiagnosticCycle<CR>')

  -- vim.api.nvim_command [[autocmd CursorHold  <buffer> lua vim.lsp.buf.hover() ]]
  -- vim.api.nvim_command [[autocmd CursorHoldI <buffer> lua vim.lsp.buf.hover() ]]

  -- disable LSP highlighted for TS enabled buffers (completion-treesitter)
  -- local ft = vim.api.nvim_buf_get_option(bufnr, 'filetype')
  -- if ft ~= 'ql' and ft ~= 'lua' then
  --   vim.api.nvim_command [[autocmd CursorHold  <buffer> lua vim.lsp.buf.document_highlight()]]
  --   vim.api.nvim_command [[autocmd CursorHoldI <buffer> lua vim.lsp.buf.document_highlight()]]
  --   vim.api.nvim_command [[autocmd CursorMoved <buffer> lua vim.lsp.util.buf_clear_references()]]
  -- end

  -- vim.api.nvim_command [[autocmd CursorHold  <buffer> lua vim.lsp.util.show_line_diagnostics()]]
  -- vim.api.nvim_command [[autocmd CursorMoved <buffer> lua vim.lsp.util.buf_clear_references()]]
end

-- REF: https://github.com/ahmedelgabri/dotfiles/blob/master/roles/vim/files/.vim/lua/lsp.lua#L47
--      https://github.com/delianides/dotfiles/blob/master/tag-vim/vim/lua/lsp.lua#L144
--      https://github.com/aktau/dotfiles/blob/master/.vim/lua/lsp.lua#L162
-- local server_config = {'bashls', 'cssls', 'elmls', 'elixirls', 'html', 'jsonls', 'pyls', 'sumneko_lua', 'tsserver', 'vimls', 'yamlls'}
-- for _, lsp in ipairs(servers) do
--   nvim_lsp[lsp].setup({
--     on_attach = on_attach,
--     callbacks = require('callbacks'),
--     callbacks = vim.tbl_deep_extend('keep', {}, require('callbacks'), vim.lsp.callbacks),
--     capabilities = vim.tbl_deep_extend('keep', {}, { textDocument = {completion = {completionItem = {snippetSupport = false}}}; }, require('vim.lsp.protocol').make_client_capabilities()),
--     config
--   })
-- end

nvim_lsp.tsserver.setup({
  cmd = {"typescript-language-server", "--stdio"},
  filetypes = {
    "javascript",
    "javascriptreact",
    "javascript.jsx",
    "typescript",
    "typescriptreact",
    "typescript.tsx"
  },
  on_attach = on_attach,
  callbacks = vim.tbl_deep_extend('keep', {}, require('callbacks'), vim.lsp.callbacks),
  -- capabilities = vim.tbl_deep_extend('keep', {}, { textDocument = {completion = {completionItem = {snippetSupport = false}}} })
})

nvim_lsp.clangd.setup({
  cmd = {"clangd", "--background-index"},
  on_attach = on_attach,

  -- Required for lsp-status
  init_options = {
    clangdFileStatus = true
  },
  callbacks = vim.tbl_deep_extend('keep', {}, require('callbacks'), vim.lsp.callbacks),
  -- capabilities = vim.tbl_deep_extend('keep', {}, { textDocument = {completion = {completionItem = {snippetSupport = false}}} })
  -- callbacks = nvim_status.extensions.clangd.setup(),
  -- capabilities = nvim_status.capabilities,
})

nvim_lsp.rust_analyzer.setup({
  cmd = {"rust-analyzer"},
  filetypes = {"rust"},
  on_attach = on_attach,
  callbacks = vim.tbl_deep_extend('keep', {}, require('callbacks'), vim.lsp.callbacks),
  -- capabilities = vim.tbl_deep_extend('keep', {}, { textDocument = {completion = {completionItem = {snippetSupport = false}}} })
})

-- REF:
-- https://github.com/mjlbach/nix-dotfiles/blob/master/nixpkgs/configs/neovim/init.vim#L413
-- nvim_lsp.diagnosticls.setup{
--   filetypes = {"sh", "bash", "zsh", "elixir", "eelixir"},
--   init_options = {
--     linters = {
--       mix_credo= {
--         command= "mix",
--         debounce= 100,
--         rootPatterns= {"mix.exs", ".git"},
--         args= {"credo", "suggest", "--format", "flycheck", "--read-from-stdin"},
--         offsetLine= 0,
--         offsetColumn= 0,
--         sourceName= "mix_credo",
--         formatLines= 1,
--         formatPattern= {
--           "^[^ ]+?:([0-9]+)(:([0-9]+))?:\\s+([^ ]+):\\s+(.*)(\\r|\\n)*$",
--           {
--             line= 1,
--             column= 3,
--             message= 5,
--             security= 4
--           }
--         },
--         securities= {
--           F= "warning",
--           C= "warning",
--           D= "info",
--           R= "info"
--         },
--       },
--       mix_credo_compile= {
--         command= "mix",
--         debounce= 100,
--         rootPatterns= {"mix.exs", ".git"},
--         args= {"credo", "suggest", "--format", "flycheck", "--read-from-stdin"},
--         offsetLine= -1,
--         offsetColumn= 0,
--         sourceName= "mix_credo",
--         formatLines= 1,
--         formatPattern= {
--           "^([^ ]+)\\s+\\(([^)]+)\\)\\s+([^ ]+?):([0-9]+):\\s+(.*)(\\r|\\n)*$",
--           {
--             line= -1,
--             column= -1,
--             message= {"[", 2, "]: ", 3, ": ", 5},
--             security= 1
--           }
--         },
--         securities= {
--           -- '**': "error"
--           F= "error",
--           C= "error",
--           D= "error",
--           R= "error"
--         },
--       },
--       shellcheck = {
--         command = "shellcheck",
--         debounce = 100,
--         args = { "--format=gcc", "--shell=sh", "-" },
--         offsetLine = 0,
--         offsetColumn = 0,
--         sourceName = "shellcheck",
--         formatLines = 1,
--         formatPattern = {
--           "^[^:]+:(\\d+):(\\d+):\\s+([^:]+):\\s+(.*)$",
--           {
--             line = 1,
--             column = 2,
--             message = 4,
--             security = 3
--           }
--         },
--         securities = {
--           refactor = "info",
--           convention = "info",
--           error = "error",
--           warning = "warning",
--           note = "info"
--         },
--       },
--       pylint = {
--         command = "pylint",
--         args = {
--           "--output-format=text",
--           "--score=no",
--           "--msg-template='{line}:{column}:{category}:{msg} ({msg_id}:{symbol})'",
--           "%file"
--         },
--         offsetLine = 1,
--         offsetColumn = 1,
--         sourceName = "pylint",
--         formatLines = 1,
--         formatPattern = {
--           "^[^:]+:(\\d+):(\\d+):\\s+([^:]+):\\s+(.*)$",
--           {
--             line = 1,
--             column = 2,
--             message = 4,
--             security = 3
--           }
--         },
--         rootPatterns = {
--           ".git", "setup.py"
--         },
--         securities = {
--           informational = "hint",
--           refactor = "info",
--           convention = "info",
--           warning = "warning",
--           error = "error",
--           fatal = "error"
--         }
--       }
--     },
--     filetypes = {
--       sh = "shellcheck",
--       elixir =  {"mix_credo", "mix_credo_compile"},
--       eelixir =  {"mix_credo", "mix_credo_compile"},
--     },
--     formatters = {
--       jq = {
--         command = "jq",
--         args = {"--indent", "4", "."}
--       },
--       shfmt = {
--         command = "shfmt",
--         args = {"-i", "4", "-sr", "-ci"}
--       }
--     },
--     formatFiletypes = {
--       json = "jq",
--       sh = "shfmt"
--     }
--   },
-- on_attach = on_attach,
callbacks = vim.tbl_deep_extend('keep', {}, require('callbacks'), vim.lsp.callbacks),
-- capabilities = vim.tbl_deep_extend('keep', {}, { textDocument = {completion = {completionItem = {snippetSupport = false}}} })
-- }

nvim_lsp.elixirls.setup({
  settings = {
    elixirLS = {
      dialyzerEnabled = false,
    },
  },
  filetypes = {"elixir", "eelixir"},
  root_dir = nvim_lsp.util.root_pattern("mix.lock", ".git", "mix.exs") or vim.loop.os_homedir(),
  on_attach = on_attach,
  callbacks = vim.tbl_deep_extend('keep', {}, require('callbacks'), vim.lsp.callbacks),
  -- capabilities = vim.tbl_deep_extend('keep', {}, { textDocument = {completion = {completionItem = {snippetSupport = false}}} })
})

nvim_lsp.elmls.setup({
  filetypes = {"elm"},
  root_dir = nvim_lsp.util.root_pattern("elm.lock", ".git", "elm.json") or vim.loop.os_homedir(),
  on_attach = on_attach,
  callbacks = vim.tbl_deep_extend('keep', {}, require('callbacks'), vim.lsp.callbacks),
  -- capabilities = vim.tbl_deep_extend('keep', {}, { textDocument = {completion = {completionItem = {snippetSupport = false}}} })
})

nvim_lsp.cssls.setup({
  on_attach = on_attach,
  callbacks = vim.tbl_deep_extend('keep', {}, require('callbacks'), vim.lsp.callbacks),
  -- capabilities = vim.tbl_deep_extend('keep', {}, { textDocument = {completion = {completionItem = {snippetSupport = false}}} })
})

nvim_lsp.html.setup({
  on_attach = on_attach,
  callbacks = vim.tbl_deep_extend('keep', {}, require('callbacks'), vim.lsp.callbacks),
  -- capabilities = vim.tbl_deep_extend('keep', {}, { textDocument = {completion = {completionItem = {snippetSupport = false}}} })
})

nvim_lsp.vimls.setup({
  on_attach = on_attach,
  callbacks = vim.tbl_deep_extend('keep', {}, require('callbacks'), vim.lsp.callbacks),
  -- capabilities = vim.tbl_deep_extend('keep', {}, { textDocument = {completion = {completionItem = {snippetSupport = false}}} })
})

nvim_lsp.bashls.setup({
  cmd = {vim.fn.stdpath('cache') .. "/nvim_lsp/bashls/node_modules/.bin/bash-language-server", "start"},
  filetypes = {"sh", "zsh", "bash", "fish"},
  root_dir = function()
    local cwd = vim.fn.getcwd()
    return cwd
  end,
  on_attach = on_attach,
  callbacks = vim.tbl_deep_extend('keep', {}, require('callbacks'), vim.lsp.callbacks),
  -- capabilities = vim.tbl_deep_extend('keep', {}, { textDocument = {completion = {completionItem = {snippetSupport = false}}} })
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
  callbacks = vim.tbl_deep_extend('keep', {}, require('callbacks'), vim.lsp.callbacks),
  -- capabilities = vim.tbl_deep_extend('keep', {}, { textDocument = {completion = {completionItem = {snippetSupport = false}}} })
})

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
    vim.fn.stdpath('cache') .. "/nvim_lsp/sumneko_lua/lua-language-server/bin/macOS/lua-language-server",
    "-E",
    vim.fn.stdpath('cache') .. "/nvim_lsp/sumneko_lua/lua-language-server/main.lua"
  },
  on_attach = on_attach,
  callbacks = vim.tbl_deep_extend('keep', {}, require('callbacks'), vim.lsp.callbacks),
  -- capabilities = vim.tbl_deep_extend('keep', {}, { textDocument = {completion = {completionItem = {snippetSupport = false}}} })
})


nvim_lsp.yamlls.setup({
  settings = {
    yaml = {
      schemas = {
        ['http://json.schemastore.org/github-workflow'] = '.github/workflows/*.{yml,yaml}',
        ['http://json.schemastore.org/github-action'] = '.github/action.{yml,yaml}',
        ['http://json.schemastore.org/ansible-stable-2.9'] = 'roles/tasks/*.{yml,yaml}',
        ['http://json.schemastore.org/prettierrc'] = '.prettierrc.{yml,yaml}',
        ['http://json.schemastore.org/stylelintrc'] = '.stylelintrc.{yml,yaml}',
        ['http://json.schemastore.org/circleciconfig'] = '.circleci/**/*.{yml,yaml}'
      },
      format = {
        enable = true
      },
      validate = true,
      hover = true,
      completion = true
    }
  },
  on_attach = on_attach,
  callbacks = vim.tbl_deep_extend('keep', {}, require('callbacks'), vim.lsp.callbacks),
  -- capabilities = vim.tbl_deep_extend('keep', {}, { textDocument = {completion = {completionItem = {snippetSupport = false}}} })
})

nvim_lsp.jsonls.setup({
  settings = {
    json = {
      format = { enable = true },
      schemas = {
        {
          description = 'Lua sumneko setting schema validation',
          fileMatch = {'*.lua'},
          url = "https://raw.githubusercontent.com/sumneko/vscode-lua/master/setting/schema.json"
        },
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
  on_attach = on_attach,
  callbacks = vim.tbl_deep_extend('keep', {}, require('callbacks'), vim.lsp.callbacks),
  -- capabilities = vim.tbl_deep_extend('keep', {}, { textDocument = {completion = {completionItem = {snippetSupport = false}}} })
})

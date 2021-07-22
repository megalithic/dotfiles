local cmd, lsp, opt, api = vim.cmd, vim.lsp, vim.opt, vim.api
local map, bufmap, au, inspect = mega.map, mega.bufmap, mega.au, mega.inspect

do --- Auto-completion
  require("compe").setup {
    enabled = true,
    debug = false,
    min_length = 2,
    preselect = "disable",
    allow_prefix_unmatch = false,
    throttle_time = 120,
    source_timeout = 200,
    incomplete_delay = 400,
    documentation = {
      border = { "╭", "─", "╮", "│", "╯", "─", "╰", "│" },
    },
    source = {
      nvim_lsp = {menu = "[lsp]", priority = 10},
      vsnip = {menu = "[vsnip]", priority = 10},
      nvim_lua = {menu = "[lua]", priority = 9},
      path = {menu = "[path]", priority = 9},
      treesitter = {menu = "[ts]", priority = 9},
      buffer = {menu = "[buf]", priority = 8},
      spell = {menu = "[spl]", filetypes = {"markdown"}},
      orgmode = {menu = "[org]"}
    }
  }

  local t = function(str)
    return vim.api.nvim_replace_termcodes(str, true, true, true)
  end

  local check_back_space = function()
    local col = vim.fn.col('.') - 1
    return col == 0 or vim.fn.getline('.'):sub(col, col):match('%s') ~= nil
  end

  -- Use (s-)tab to:
  --- move to prev/next item in completion menuone
  --- jump to prev/next snippet's placeholder
  _G.tab_complete = function()
    if vim.fn.pumvisible() == 1 then
      return t "<C-n>"
    elseif vim.fn['vsnip#available'](1) == 1 then
      return t "<Plug>(vsnip-expand-or-jump)"
    elseif check_back_space() then
      return t "<Tab>"
    else
      return vim.fn['compe#complete']()
    end
  end

  _G.s_tab_complete = function()
    if vim.fn.pumvisible() == 1 then
      return t "<C-p>"
    elseif vim.fn['vsnip#jumpable'](-1) == 1 then
      return t "<Plug>(vsnip-jump-prev)"
    else
      -- If <S-Tab> is not working in your terminal, change it to <C-h>
      return t "<S-Tab>"
    end
  end

  mega.map("i", "<Tab>", "v:lua.tab_complete()", {expr = true, noremap = true})
  mega.map("s", "<Tab>", "v:lua.tab_complete()", {expr = true, noremap = true})
  mega.map("i", "<S-Tab>", "v:lua.s_tab_complete()", {expr = true, noremap = true})
  mega.map("s", "<S-Tab>", "v:lua.s_tab_complete()", {expr = true, noremap = true})
end


do --- LSP
  local lspconfig = require("lspconfig")
  local function on_attach(client, bufnr)
    if client.config.flags then
      client.config.flags.allow_incremental_sync = true
    end

    --
    --- goto mappings
    bufmap("gd", "lua vim.lsp.buf.definition()")
    bufmap("gr", "lua vim.lsp.buf.references()")
    bufmap("gs", "lua vim.lsp.buf.document_symbol()")

    --
    --- diagnostics navigation mappings
    bufmap("dn", "lua vim.lsp.diagnostic.goto_prev()")
    bufmap("dN", "lua vim.lsp.diagnostic.goto_next()")

    --
    --- misc mappings
    bufmap("<leader>ln", "lua vim.lsp.buf.rename()")
    bufmap("<leader>la", "lua vim.lsp.buf.code_action()")
    bufmap("<leader>ld",  "lua vim.lsp.diagnostic.show_line_diagnostics()")
    bufmap("<C-k>",     "lua vim.lsp.buf.signature_help()")
    bufmap("<C-k>",     "lua vim.lsp.buf.signature_help()", "i")
    bufmap("<leader>lf",  "lua vim.lsp.buf.formatting()")

    --
    --- trouble mappings
    map("n", "<leader>lt", "<cmd>LspTroubleToggle<cr>")

    --
    --- auto-commands
    au "BufWritePre <buffer> lua vim.lsp.buf.formatting_seq_sync()"
    au "CursorHold <buffer> lua vim.lsp.diagnostic.show_line_diagnostics()"
    -- au "BufWritePost <buffer> lua vim.lsp.buf.formatting(nil, 1000)"
    -- au "BufWritePre *.rs,*.c,*.lua lua vim.lsp.buf.formatting_sync()"
    -- au "CursorHold *.rs,*.c,*.lua lua vim.lsp.diagnostic.show_line_diagnostics()"

    --
    --- commands
    FormatRange = function()
      local start_pos = api.nvim_buf_get_mark(0, '<')
      local end_pos = api.nvim_buf_get_mark(0, '>')
      lsp.buf.range_formatting({}, start_pos, end_pos)
    end
    cmd [[ command! -range FormatRange execute 'lua FormatRange()' ]]
    cmd [[ command! Format execute 'lua vim.lsp.buf.formatting()' ]]
    cmd [[ command! LspLog lua vim.cmd('e'..vim.lsp.get_log_path()) ]]

    opt.omnifunc = "v:lua.vim.lsp.omnifunc"
  end

  --
  --- capabilities
  local capabilities = lsp.protocol.make_client_capabilities()
  capabilities.textDocument.completion.completionItem.snippetSupport = true
  capabilities.textDocument.completion.completionItem.resolveSupport = {
    properties = {
      'documentation',
      'detail',
      'additionalTextEdits',
    }
  }

  --
  --- handlers
  -- diagnostics
  lsp.handlers["textDocument.publishDiagnostics"] = lsp.with(
    lsp.diagnostic.on_publish_diagnostics,
    {
      virtual_text = false,
      signs = true,
      update_in_insert = true,
    }
  )

  -- hover
  local overridden_hover = vim.lsp.with(vim.lsp.handlers.hover, { border = "single" })
  vim.lsp.handlers['textDocument/hover'] = function(...)
    local bufnr = overridden_hover(...)
    vim.api.nvim_buf_set_keymap(bufnr, 'n', 'K', '<Cmd>wincmd p<CR>', { noremap = true, silent = true })
  end

  -- signature-help
  lsp.handlers["textDocument/signatureHelp"] =  lsp.with(lsp.handlers.hover, {border = "single"})

  --
  --- server setup
  local function root_pattern(...)
    local patterns = vim.tbl_flatten {...}

    return function(startpath)
      for _, pattern in ipairs(patterns) do
        return lspconf.util.search_ancestors(
          startpath,
          function(path)
            if lspconf.util.path.exists(vim.fn.glob(lspconf.util.path.join(path, pattern))) then
              return path
            end
          end
        )
      end
    end
  end

  local function get_lua_runtime()
    local result = {}
    for _, path in pairs(vim.api.nvim_list_runtime_paths()) do
      local lua_path = path .. "/lua/"
      if vim.fn.isdirectory(lua_path) then
        result[lua_path] = true
      end
    end

    result[vim.fn.expand("$VIMRUNTIME/lua")] = true
    result[vim.fn.expand("$VIMRUNTIME/lua/vim/lsp")] = true
    result[vim.fn.expand("/Applications/Hammerspoon.app/Contents/Resources/extensions/hs")] = true

    return result
  end

  local servers = {
    zk = {
      cmd = {"zk", "lsp", "--log", "/tmp/zk-lsp.log"},
      filetypes = {"markdown", "md"},
      root_dir = function()
        return vim.loop.cwd()
      end,
      settings = {}
    },
    bashls = {
      filetypes = {"bash", "sh", "zsh"}
    },
    clangd = {},
    cssls = {
      filetypes = {"css", "scss", "less", "sass"},
      root_dir = root_pattern("package.json", ".git")
    },
    elmls = {
      filetypes = {"elm"},
      root_dir = root_pattern("elm.json", ".git")
    },
    elixirls = {
      cmd = {vim.fn.expand("$XDG_CONFIG_HOME/lsp/elixir_ls/release") .. "/language_server.sh"},
      settings = {
        elixirLS = {
          fetchDeps = false,
          dialyzerEnabled = false,
          suggestSpecs = true
        }
      },
      filetypes = {"elixir", "eelixir"},
      root_dir = root_pattern("mix.exs", ".git")
    },
    html = {},
    jsonls = {
      commands = {
        Format = {
          function()
            vim.lsp.buf.range_formatting({}, {0, 0}, {vim.fn.line("$"), 0})
          end
        }
      },
      settings = {
        json = {
          format = {enable = true},
          schemas = {
            {
              description = "Lua sumneko setting schema validation",
              fileMatch = {"*.lua"},
              url = "https://raw.githubusercontent.com/sumneko/vscode-lua/master/setting/schema.json"
            },
            {
              description = "TypeScript compiler configuration file",
              fileMatch = {"tsconfig.json", "tsconfig.*.json"},
              url = "http://json.schemastore.org/tsconfig"
            },
            {
              description = "Lerna config",
              fileMatch = {"lerna.json"},
              url = "http://json.schemastore.org/lerna"
            },
            {
              description = "Babel configuration",
              fileMatch = {
                ".babelrc.json",
                ".babelrc",
                "babel.config.json"
              },
              url = "http://json.schemastore.org/lerna"
            },
            {
              description = "ESLint config",
              fileMatch = {".eslintrc.json", ".eslintrc"},
              url = "http://json.schemastore.org/eslintrc"
            },
            {
              description = "Bucklescript config",
              fileMatch = {"bsconfig.json"},
              url = "https://bucklescript.github.io/bucklescript/docson/build-schema.json"
            },
            {
              description = "Prettier config",
              fileMatch = {
                ".prettierrc",
                ".prettierrc.json",
                "prettier.config.json"
              },
              url = "http://json.schemastore.org/prettierrc"
            },
            {
              description = "Vercel Now config",
              fileMatch = {"now.json", "vercel.json"},
              url = "http://json.schemastore.org/now"
            },
            {
              description = "Stylelint config",
              fileMatch = {
                ".stylelintrc",
                ".stylelintrc.json",
                "stylelint.config.json"
              },
              url = "http://json.schemastore.org/stylelintrc"
            }
          }
        }
      }
    },
    pyls = {
      enable = true,
      plugins = {pyls_mypy = {enabled = true, live_mode = false}}
    },
    rust_analyzer = {},
    sumneko_lua = {
      settings = {
        Lua = {
          completion = {keywordSnippet = "Disable"},
          runtime = {
            version = "LuaJIT",
            path = vim.split(package.path, ";")
          },
          workspace = {
            maxPreload = 1000,
            preloadFileSize = 1000,
            library = get_lua_runtime()
          },
          diagnostics = {
            enable = true,
            globals = {
              "vim",
              "Color",
              "c",
              "Group",
              "g",
              "s",
              "describe",
              "it",
              "before_each",
              "after_each",
              "hs",
              "spoon",
              "config",
              "watchers",
              "mega"
            }
          },
          telemetry = {
            enable = false,
          },
        }
      },
      cmd = {
        vim.fn.expand("$XDG_CONFIG_HOME") .. "/lsp/sumneko_lua/bin/" .. vim.fn.expand("$PLATFORM") .. "/lua-language-server", "-E",
        vim.fn.expand("$XDG_CONFIG_HOME") .. "/lsp/sumneko_lua/main.lua"
      }
    },
    tsserver = {
      filetypes = {
        "javascript",
        "javascriptreact",
        "javascript.jsx",
        "typescript",
        "typescriptreact",
        "typescript.tsx"
      },
      -- See https://github.com/neovim/nvim-lsp/issues/237
      root_dir = root_pattern("tsconfig.json", "package.json", ".git")
    },
    vimls = {},
    yamlls = {
      settings = {
        yaml = {
          schemas = {
            ["http://json.schemastore.org/github-workflow"] = ".github/workflows/*.{yml,yaml}",
            ["http://json.schemastore.org/github-action"] = ".github/action.{yml,yaml}",
            ["http://json.schemastore.org/ansible-stable-2.9"] = "roles/tasks/*.{yml,yaml}",
            ["http://json.schemastore.org/prettierrc"] = ".prettierrc.{yml,yaml}",
            ["http://json.schemastore.org/stylelintrc"] = ".stylelintrc.{yml,yaml}",
            ["http://json.schemastore.org/circleciconfig"] = ".circleci/**/*.{yml,yaml}"
          },
          format = {enable = true},
          validate = true,
          hover = true,
          completion = true
        }
      }
    }
  }

  for server, config in pairs(servers) do
    local server_disabled = (config.disabled ~= nil and config.disabled) or false

    if lspconfig[server] == nil or config == nil or lspconfig == nil or server == nil then
      inspect("-> unable to load lsp config", {server, config, lspconfig})
      return
    end

    if not server_disabled then
      lspconfig[server].setup(
        vim.tbl_deep_extend(
          "force",
          {
            on_attach = on_attach,
            capabilities = capabilities,
            flags = {debounce_text_changes = 150}
          },
          config
        )
      )
    end
  end

  -- for _, server in ipairs {"clangd", "rust_analyzer"} do
  --   conf[server].setup {
  --     capabilities = capabilities,
  --     on_attach = on_attach,
  --     flags = {debounce_text_changes = 150}
  --   }
  -- end
end

local has_lsp, lsp = pcall(require, "nvim_lsp")
if not has_lsp then
  print("[WARN] nvim_lsp not found/installed/loaded..")

  return
end

local M = {}

local function root_pattern(...)
  local patterns = vim.tbl_flatten {...}

  return function(startpath)
    for _, pattern in ipairs(patterns) do
      return lsp.util.search_ancestors(startpath, function(path)
        if lsp.util.path.exists(vim.fn.glob(lsp.util.path.join(path, pattern))) then
          return path
        end
      end)
    end
  end
end

local servers = {
  bashls = {},
  cssls = {
    filetypes = {"css", "scss", "less", "sass"},
    root_dir = root_pattern("package.json", ".git")
  },
  diagnosticls = {
    disabled = true,
    filetypes = { "javascript", "javascript.jsx", "elixir", "eelixir" },
    init_options = {
      filetypes = {
        javascript = "eslint",
        ["javascript.jsx"] = "eslint",
        javascriptreact = "eslint",
        typescriptreact = "eslint",
        elixir = {"mix_credo", "mix_credo_compile"},
        eelixir = {"mix_credo", "mix_credo_compile"},
      },
      linters = {
        mix_credo = {
          command= "mix",
          debounce= 100,
          rootPatterns= {"mix.exs"},
          args= {
            "credo",
            "suggest",
            "--format",
            "flycheck",
            "--read-from-stdin"
          },
          offsetLine= 0,
          offsetColumn= 0,
          sourceName= "mix_credo",
          formatLines= 1,
          formatPattern= {
            "^[^ ]+?:([0-9]+)(:([0-9]+))?:\\s+([^ ]+):\\s+(.*)$",
            {
              ["line"]= 1,
              ["column"]= 3,
              ["message"]= 5,
              ["security"]= 4
            }
          },
          securities= {
            ["F"]= "warning",
            ["C"]= "warning",
            ["D"]= "info",
            ["R"]= "info"
          }
        },
        eslint = {
          sourceName = "eslint",
          command = "./node_modules/.bin/eslint",
          rootPatterns = { ".git" },
          debounce = 100,
          args = {
            "--stdin",
            "--stdin-filename",
            "%filepath",
            "--format",
            "json",
          },
          parseJson = {
            errorsRoot = "[0].messages",
            line = "line",
            column = "column",
            endLine = "endLine",
            endColumn = "endColumn",
            message = "${message} [${ruleId}]",
            security = "severity",
          };
          securities = {
            [2] = "error",
            [1] = "warning"
          }
        }
      }
    },
  },
  -- efm = {
  --   disabled = true,
  --   cmd = {vim.loop.os_homedir() .. "/.go/bin/efm-langserver", "-c", vim.fn.stdpath("config") .. "/efm-config.yml" },
  --   -- filetypes = {"elixir", "eelixir", "md", "json"},
  --   -- root_dir = root_pattern("mix.lock", ".git", "mix.exs") or vim.loop.os_homedir()
  -- },
  elmls = {
    cmd = {vim.fn.stdpath("cache") .. "/nvim_lsp/elmls/node_modules/.bin/elm-language-server"},
    filetypes = {"elm"},
    root_dir = root_pattern("elm.json", ".git")
  },
  elixirls = {
    settings = {
      elixirLS = {
        dialyzerEnabled = true
      }
    },
    filetypes = {"elixir", "eelixir"},
    root_dir = root_pattern("mix.lock", "mix.exs", ".git")
  },
  html = {},
  jsonls = {
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
            fileMatch = {".babelrc.json", ".babelrc", "babel.config.json"},
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
            fileMatch = {".prettierrc", ".prettierrc.json", "prettier.config.json"},
            url = "http://json.schemastore.org/prettierrc"
          },
          {
            description = "Vercel Now config",
            fileMatch = {"now.json", "vercel.json"},
            url = "http://json.schemastore.org/now"
          },
          {
            description = "Stylelint config",
            fileMatch = {".stylelintrc", ".stylelintrc.json", "stylelint.config.json"},
            url = "http://json.schemastore.org/stylelintrc"
          }
        }
      }
    }
  },
  pyls = {
    enable = true,
    plugins = {
      pyls_mypy = {
        enabled = true,
        live_mode = false
      }
    }
  },
  rust_analyzer = {},
  sumneko_lua = {
    settings = {
      Lua = {
        completion = { keywordSnippet = 'Disable' },
        runtime = {
          version = 'LuaJIT',
          path = vim.split(package.path, ';')
        },
        workspace = {
          library = {
            [vim.fn.expand("$VIMRUNTIME/lua")] = true,
            [vim.fn.expand("$VIMRUNTIME/lua/vim/lsp")] = true
          }
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
            "watchers"
          }
        }
      }
    },
    cmd = {
      vim.fn.stdpath("cache") .. "/nvim_lsp/sumneko_lua/lua-language-server/bin/macOS/lua-language-server",
      "-E",
      vim.fn.stdpath("cache") .. "/nvim_lsp/sumneko_lua/lua-language-server/main.lua"
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
    root_dir = root_pattern("tsconfig.json",  "package.json", ".git"),
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
        format = {
          enable = true
        },
        validate = true,
        hover = true,
        completion = true
      }
    }
  },
}

function M.activate(on_attach_fn)
  for server, config in pairs(servers) do
    local server_disabled = (config.disabled ~= nil and config.disabled) or false

    if not server_disabled then
      lsp[server].setup(vim.tbl_deep_extend('force', {
        on_attach = on_attach_fn,
        callbacks = vim.tbl_deep_extend("keep", {}, require("lsp_callbacks"), vim.lsp.callbacks),
      }, config))
    end
  end
end

return M

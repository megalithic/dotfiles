local has_lsp, lspconfig = pcall(require, "lspconfig")
if not has_lsp then
  print("[WARN] lspconfig not found/installed/loaded..")

  return
end

local M = {}

local function root_pattern(...)
  local patterns = vim.tbl_flatten {...}

  return function(startpath)
    for _, pattern in ipairs(patterns) do
      return lspconfig.util.search_ancestors(
        startpath,
        function(path)
          if lspconfig.util.path.exists(vim.fn.glob(lspconfig.util.path.join(path, pattern))) then
            return path
          end
        end
      )
    end
  end
end

local servers = {
  bashls = {
    filetypes = {"bash", "sh", "zsh"}
  },
  clangd = {},
  cssls = {
    filetypes = {"css", "scss", "less", "sass"},
    root_dir = root_pattern("package.json", ".git")
  },
  efm = {init_options = {documentFormatting = true}},
  elmls = {
    filetypes = {"elm"},
    root_dir = root_pattern("elm.json", ".git")
  },
  elixirls = {
    cmd = {vim.fn.expand("$XDG_CONFIG_HOME/lsp/elixir_ls/release") .. "/language_server.sh"},
    settings = {elixirLS = {dialyzerEnabled = true}},
    filetypes = {"elixir", "eelixir"},
    root_dir = root_pattern("mix.lock", "mix.exs", ".git")
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
  solargraph = {
    cmd = {"solargraph", "stdio"},
    filetypes = {"ruby"},
    root_dir = root_pattern("Gemfile", ".git"),
    settings = {
      solargraph = {
        diagnostics = true,
        completion = true,
        formatting = true
      }
    }
  },
  sumneko_lua = {
    settings = {
      Lua = {
        completion = {keywordSnippet = "Disable"},
        runtime = {
          version = "LuaJIT",
          path = vim.split(package.path, ";")
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
      vim.fn.expand("$XDG_CONFIG_HOME") ..
        "/lsp/sumneko_lua/bin/" .. vim.fn.expand("$PLATFORM") .. "/lua-language-server",
      "-E",
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

function M.activate(on_attach_fn)
  for server, config in pairs(servers) do
    local server_disabled = (config.disabled ~= nil and config.disabled) or false

    if not server_disabled then
      lspconfig[server].setup(
        vim.tbl_deep_extend(
          "force",
          {
            on_attach = on_attach_fn,
            handlers = vim.tbl_deep_extend("keep", {}, require("mega.lc.handlers"), vim.lsp.handlers)
            -- TODO: give this a look:
            -- https://github.com/RishabhRD/nvim-lsputils
          },
          config
        )
      )
    end
  end
end

return M

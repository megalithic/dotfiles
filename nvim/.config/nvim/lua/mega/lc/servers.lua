local has_lsp, lspconf = pcall(require, "lspconfig")
if not has_lsp then
  print("[WARN] lspconfig not found/installed/loaded..")

  return
end

local M = {}

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

-- REFS:
-- https://github.com/lukas-reineke/dotfiles/blob/master/vim/lua/lsp.lua#L208-L253
-- https://github.com/Xuyuanp/vimrc/blob/master/lua/dotvim/lsp/init.lua#L79-L91
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

local efm_languages = mega.load("efm", "mega.lc.efm")

do
  local configs = require("lspconfig/configs")
  configs["zk"] = {
    default_config = {
      cmd = {"zk", "lsp", "--log", "/tmp/zk-lsp.log"},
      filetypes = {"markdown"},
      get_language_id = function()
        return "markdown"
      end,
      root_dir = function()
        return vim.loop.cwd()
      end,
      settings = {}
    }
  }
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
  efm = {
    init_options = {documentFormatting = true},
    filetypes = vim.tbl_keys(efm_languages),
    settings = {
      rootMarkers = {"mix.lock", "mix.exs", "elm.json", "package.json", ".git/"},
      lintDebounce = 500,
      logLevel = 2,
      logFile = vim.fn.expand("$XDG_CACHE_HOME/nvim") .. "/efm-lsp.log",
      languages = efm_languages
    }
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

    local capabilities = vim.lsp.protocol.make_client_capabilities()
    capabilities.textDocument.completion.completionItem.snippetSupport = true

    -- mega.inspect("server to configure", server)
    -- mega.inspect("config to use", config)

    if not server_disabled then
      lspconf[server].setup(
        vim.tbl_deep_extend(
          "force",
          {
            on_attach = on_attach_fn,
            handlers = vim.tbl_deep_extend("keep", {}, require("mega.lc.handlers"), vim.lsp.handlers),
            capabilities = capabilities
          },
          config
        )
      )
    end
  end
end

return M

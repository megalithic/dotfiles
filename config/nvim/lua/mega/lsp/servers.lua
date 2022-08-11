return function(on_attach)
  local fn = vim.fn
  local api = vim.api
  local lsp = vim.lsp
  local lspconfig = require("lspconfig")
  local lsputil = require("lspconfig.util")

  -- [ UTILS ] -----------------------------------------------------------------

  local function root_pattern(...)
    local patterns = vim.tbl_flatten({ ... })

    return function(startpath)
      for _, pattern in ipairs(patterns) do
        return lsputil.search_ancestors(startpath, function(path)
          if lsputil.path.exists(fn.glob(lsputil.path.join(path, pattern))) then return path end
        end)
      end
    end
  end

  local function get_server_capabilities()
    local capabilities = lsp.protocol.make_client_capabilities()
    capabilities.offsetEncoding = { "utf-16" }
    capabilities.textDocument.codeLens = { dynamicRegistration = false }
    capabilities.textDocument.colorProvider = { dynamicRegistration = false }
    capabilities.textDocument.completion.completionItem.documentationFormat = { "markdown" }
    capabilities.textDocument.foldingRange = {
      dynamicRegistration = false,
      lineFoldingOnly = true,
    }
    capabilities.textDocument.codeAction = {
      dynamicRegistration = false,
      codeActionLiteralSupport = {
        codeActionKind = {
          valueSet = {
            "",
            "quickfix",
            "refactor",
            "refactor.extract",
            "refactor.inline",
            "refactor.rewrite",
            "source",
            "source.organizeImports",
          },
        },
      },
    }

    local nvim_lsp_ok, cmp_nvim_lsp = mega.require("cmp_nvim_lsp")
    if nvim_lsp_ok then capabilities = cmp_nvim_lsp.update_capabilities(capabilities) end

    return capabilities
  end

  -- [ SERVERS ] ---------------------------------------------------------------

  local servers = {
    bashls = true,
    dockerls = function()
      return {
        single_file_support = true,
        settings = {
          docker = {
            languageserver = {
              formatter = {
                ignoreMultilineInstructions = true,
              },
            },
          },
        },
      }
    end,
    elmls = true,
    clangd = true,
    rust_analyzer = true,
    vimls = true,
    zk = true,
    pyright = function()
      return {
        single_file_support = false,
        settings = {
          python = {
            analysis = {
              autoSearchPaths = true,
              diagnosticMode = "workspace",
              useLibraryCodeForTypes = true,
            },
          },
        },
      }
    end,
    jsonls = function()
      return {
        commands = {
          Format = {
            function() lsp.buf.range_formatting({}, { 0, 0 }, { fn.line("$"), 0 }) end,
          },
        },
        init_options = { provideFormatter = false },
        single_file_support = true,
        settings = {
          json = {
            format = { enable = false },
            schemas = require("schemastore").json.schemas(),
          },
        },
      }
    end,
    yamlls = function()
      return {
        settings = {
          yaml = {
            format = { enable = true },
            validate = true,
            hover = true,
            completion = true,
            schemas = require("schemastore").json.schemas(),
            customTags = {
              "!reference sequence", -- necessary for gitlab-ci.yaml files
            },
          },
        },
      }
    end,

    -- @see https://gist.github.com/folke/fe5d28423ea5380929c3f7ce674c41d8
    -- NOTE: we return a function here so that the lua dev dependency is not
    -- required until the setup function is called.
    sumneko_lua = function()
      local path = vim.split(package.path, ";")
      table.insert(path, "lua/?.lua")
      table.insert(path, "lua/?/init.lua")

      local plugins = ("%s/site/pack/paq"):format(fn.stdpath("data"))
      local emmy = ("%s/start/emmylua-nvim"):format(plugins)
      local plenary = ("%s/start/plenary.nvim"):format(plugins)
      -- local paq = ('%s/opt/paq-nvim'):format(plugins)

      return {
        handlers = {
          -- Don't open quickfix list in case of multiple definitions. At the
          -- moment, this conflicts the `a = function()` code style because
          -- sumneko_lua treats both `a` and `function()` to be definitions of `a`.
          ["textDocument/definition"] = function(_, result, ctx, _)
            -- Adapted from source:
            -- https://github.com/neovim/neovim/blob/master/runtime/lua/vim/lsp/handlers.lua#L341-L366
            if result == nil or vim.tbl_isempty(result) then return nil end
            local client = vim.lsp.get_client_by_id(ctx.client_id)

            local res = vim.tbl_islist(result) and result[1] or result
            vim.lsp.util.jump_to_location(res, client.offset_encoding)
          end,
        },
        settings = {
          Lua = {
            runtime = {
              path = path,
              version = "LuaJIT",
            },
            format = { enable = false },
            diagnostics = {
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
                "mega",
                "map",
                "nmap",
                "vmap",
                "xmap",
                "smap",
                "omap",
                "imap",
                "lmap",
                "cmap",
                "tmap",
                "noremap",
                "nnoremap",
                "vnoremap",
                "xnoremap",
                "snoremap",
                "onoremap",
                "inoremap",
                "lnoremap",
                "cnoremap",
                "tnoremap",
              },
            },
            completion = { keywordSnippet = "Replace", callSnippet = "Replace" },
            workspace = {
              -- Don't analyze code from submodules
              ignoreSubmodules = true,
              library = { vim.fn.expand("$VIMRUNTIME/lua"), emmy, plenary },
              checkThirdParty = false,
            },
            telemetry = {
              enable = false,
            },
          },
        },
      }
    end,

    tailwindcss = function()
      return {
        cmd = { "tailwindcss-language-server", "--stdio" },
        init_options = {
          userLanguages = {
            elixir = "phoenix-heex",
            eruby = "erb",
            heex = "phoenix-heex",
          },
        },
        handlers = {
          ["tailwindcss/getConfiguration"] = function(_, _, params, _, bufnr, _)
            vim.lsp.buf_notify(bufnr, "tailwindcss/getConfigurationResponse", { _id = params._id })
          end,
        },
        settings = {
          includeLanguages = {
            typescript = "javascript",
            typescriptreact = "javascript",
            ["html-eex"] = "html",
            ["phoenix-heex"] = "html",
            heex = "html",
            eelixir = "html",
            elm = "html",
            erb = "html",
          },
          tailwindCSS = {
            lint = {
              cssConflict = "warning",
              invalidApply = "error",
              invalidConfigPath = "error",
              invalidScreen = "error",
              invalidTailwindDirective = "error",
              invalidVariant = "error",
              recommendedVariantOrder = "warning",
            },
            experimental = {
              classRegex = {
                [[class= "([^"]*)]],
                [[class: "([^"]*)]],
                "~H\"\"\".*class=\"([^\"]*)\".*\"\"\"",
              },
            },
            validate = true,
          },
        },
        filetypes = {
          "css",
          "scss",
          "sass",
          "html",
          "heex",
          "elixir",
          "javascript",
          "javascriptreact",
          "typescript",
          "typescriptreact",
        },
        root_dir = root_pattern(
          "./assets/tailwind.config.js",
          "tailwind.config.js",
          "tailwind.config.ts",
          "postcss.config.js",
          "postcss.config.ts",
          "package.json",
          "node_modules",
          ".git"
        ),
      }
    end,
    elixirls = function()
      return {
        cmd = { require("mega.utils").lsp.elixirls_cmd() },
        settings = {
          elixirLS = {
            fetchDeps = false,
            dialyzerEnabled = true,
            dialyzerFormat = "dialyxir_short",
            enableTestLenses = false,
            suggestSpecs = true,
          },
        },
        filetypes = { "elixir", "eelixir", "heex" },
        root_dir = root_pattern("mix.exs", ".git") or vim.loop.os_homedir(),
      }
    end,
    solargraph = function()
      return {
        cmd = { "solargraph", "stdio" },
        filetypes = { "ruby" },
        settings = {
          solargraph = {
            diagnostics = true,
            useBundler = true,
          },
        },
      }
    end,
    cssls = function()
      return {
        -- REF: https://github.com/microsoft/vscode/issues/103163
        --      - custom css linting rules and custom data
        cmd = { "vscode-css-language-server", "--stdio" },
        filetypes = { "css", "scss" },
        settings = {
          css = {
            lint = {
              unknownProperties = "ignore",
              unknownAtRules = "ignore",
            },
          },
          scss = {
            lint = {
              idSelector = "warning",
              zeroUnits = "warning",
              duplicateProperties = "warning",
            },
            completion = {
              completePropertyWithSemicolon = true,
              triggerPropertyValueCompletion = true,
            },
          },
        },
      }
    end,
    html = function()
      return {
        cmd = { "vscode-html-language-server", "--stdio" },
        filetypes = { "html", "javascriptreact", "typescriptreact", "eelixir", "html.heex", "heex" },
        init_options = {
          configurationSection = { "html", "css", "javascript", "eelixir", "heex", "html.heex" },
          embeddedLanguages = {
            css = true,
            javascript = true,
            elixir = true,
            heex = true,
          },
        },
      }
    end,
    tsserver = function()
      local function do_organize_imports()
        local params = {
          command = "_typescript.organizeImports",
          arguments = { api.nvim_buf_get_name(0) },
          title = "",
        }
        lsp.buf.execute_command(params)
      end
      return {
        filetypes = {
          "javascript",
          "javascriptreact",
          "javascript.jsx",
          "typescript",
          "typescriptreact",
          "typescript.tsx",
        },
        commands = {
          OrganizeImports = {
            do_organize_imports,
            description = "Organize Imports",
          },
        },
      }
    end,
  }

  local function get_server_config(server)
    local conf = servers[server]
    local conf_type = type(conf)
    local config = conf_type == "table" and conf or conf_type == "function" and conf() or {}

    config.flags = { debounce_text_changes = 150 }
    config.capabilities = get_server_capabilities()
    config.on_attach = on_attach

    -- TODO: json loaded lsp config; also @akinsho is a beast.
    -- https://github.com/akinsho/dotfiles/commit/c087fd471f0d80b8bf41502799aeb612222333ff
    -- config.on_init = mega.lsp.on_init

    return config
  end

  -- Load lspconfig servers with their configs
  for server, _ in pairs(servers) do
    if server == nil or lspconfig[server] == nil then
      vim.notify("unable to setup ls for " .. server)
      return
    end

    local config = get_server_config(server)
    lspconfig[server].setup(config)
  end
end

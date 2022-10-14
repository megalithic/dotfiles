return function(on_attach)
  local fn = vim.fn
  local api = vim.api
  local lsp = vim.lsp

  local ok_lsp, lspconfig = mega.require("lspconfig")
  if not ok_lsp then return end

  local mason_lspconfig = require("mason-lspconfig")
  local lsputil = require("lspconfig.util")

  -- [ UTILS ] -----------------------------------------------------------------

  local function root_pattern(...)
    local patterns = vim.tbl_flatten({ ... })

    return function(startpath)
      for _, pattern in ipairs(patterns) do
        return lspconfig.util.search_ancestors(startpath, function(path)
          if lspconfig.util.path.exists(fn.glob(lspconfig.util.path.join(path, pattern))) then return path end
        end)
      end
    end
  end

  local function dir_has_file(dir, name)
    return lsputil.path.exists(lsputil.path.join(dir, name)), lsputil.path.join(dir, name)
  end

  local function workspace_root()
    local cwd = vim.loop.cwd()

    if dir_has_file(cwd, "compose.yml") or dir_has_file(cwd, "docker-compose.yml") then return cwd end

    local function cb(dir, _) return dir_has_file(dir, "compose.yml") or dir_has_file(dir, "docker-compose.yml") end

    local root, _ = lsputil.path.traverse_parents(cwd, cb)
    return root
  end

  local function workspace_has_file(name)
    local root = workspace_root()
    if not root then root = vim.loop.cwd() end

    return dir_has_file(root, name)
  end

  local function build_command(server_name, cmd_path, args)
    args = args or {}

    local exists, dir = workspace_has_file(cmd_path)

    if exists then
      logger.debug(fmt("workspace_has_file: %s", dir))
      dir = fn.expand(dir)
      logger.fmt_debug("%s: %s %s", server_name, dir, args)
      return vim.list_extend({ dir }, args)
    else
      return nil
    end
  end

  local function lsp_cmd_override(server_name, opts, cmd_path, args)
    args = args or {}

    local cmd = build_command(server_name, cmd_path, args)
    if cmd ~= nil then opts.cmd = cmd end

    opts.on_new_config = function(new_config, _)
      local new_cmd = build_command(server_name, cmd_path, args)
      if new_cmd ~= nil then new_config.cmd = new_cmd end
    end
  end

  local function lsp_setup(server_name, opts) lspconfig[server_name].setup(opts or {}) end

  -- all the server capabilities we could want
  local function get_server_capabilities()
    local capabilities = lsp.protocol.make_client_capabilities()
    capabilities.offsetEncoding = { "utf-16" }
    capabilities.textDocument.codeLens = { dynamicRegistration = false }
    -- TODO: what is dynamicRegistration doing here? should I not always set to true?
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

    -- local nvim_tokens_ok, nvim_semantic_tokens = mega.require("nvim-semantic-tokens")
    -- if nvim_tokens_ok then capabilities = nvim_semantic_tokens.update_capabilities(capabilities) end

    return capabilities
  end

  -- default opts for each lsp server
  local server_opts = {}
  server_opts.flags = { debounce_text_changes = 150 }
  server_opts.capabilities = get_server_capabilities()
  -- server_opts.on_attach = on_attach

  -- [ SERVERS ] ---------------------------------------------------------------

  -- require("mason").setup()

  -- NEAT! @REF: https://github.com/folke/dot/blob/master/config/nvim/lua/config/mason.lua
  mason_lspconfig.setup({
    automatic_installation = true,
    ensure_installed = {
      "bashls",
      "clangd",
      "cssls",
      "dockerls",
      "elixirls",
      "elmls",
      "emmet_ls",
      "erlangls",
      "html",
      "jsonls",
      "marksman",
      "pyright",
      "rust_analyzer",
      "solargraph",
      "sumneko_lua",
      "tailwindcss",
      "terraformls",
      "tsserver",
      "vimls",
      "yamlls",
      "zk",
    },
  })

  mason_lspconfig.setup_handlers({
    -- The first entry (without a key) will be the default handler
    -- and will be called for each installed server that doesn't have
    -- a dedicated handler.
    function(server_name) -- default handler (optional)
      lsp_setup(server_name, server_opts)
    end,
    cssls = function(server_name)
      local opts = vim.tbl_extend("keep", server_opts, {
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
      })

      lsp_setup(server_name, opts)
    end,
    dockerls = function(server_name)
      local opts = vim.tbl_extend("keep", server_opts, {
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
      })

      lsp_setup(server_name, opts)
    end,
    elixirls = function(server_name)
      local opts = vim.tbl_extend("keep", server_opts, {
        filetypes = { "elixir", "eelixir", "heex", "eex", "surface" },
        settings = {
          elixirLS = {
            mixEnv = "test",
            fetchDeps = false,
            dialyzerEnabled = true,
            dialyzerFormat = "dialyxir_short",
            enableTestLenses = false,
            suggestSpecs = true,
          },
        },
      })

      lsp_cmd_override(server_name, opts, ".elixir-ls-release/language_server.sh")

      lsp_setup(server_name, opts)
    end,
    html = function(server_name)
      local opts = vim.tbl_extend("keep", server_opts, {
        filetypes = {
          "html",
          "javascriptreact",
          "typescriptreact",
          "eelixir",
          "html.heex",
          "heex",
          "html_heex",
          "html_eex",
        },
        init_options = {
          configurationSection = {
            "html",
            "css",
            "javascript",
            "eelixir",
            "heex",
            "html.heex",
            "html_heex",
            "html_eex",
          },
          embeddedLanguages = {
            css = true,
            javascript = true,
            elixir = true,
            eelixir = true,
            heex = true,
            html_heex = true,
            html_eex = true,
          },
        },
      })

      lsp_setup(server_name, opts)
    end,
    jsonls = function(server_name)
      local opts = vim.tbl_extend("keep", server_opts, {
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
      })

      lsp_setup(server_name, opts)
    end,
    marksman = function(server_name) lsp_setup(server_name) end,
    pyright = function(server_name)
      local opts = vim.tbl_extend("keep", server_opts, {
        single_file_support = false,
        settings = {
          python = {
            format = false,
            analysis = {
              autoSearchPaths = true,
              diagnosticMode = "workspace",
              useLibraryCodeForTypes = true,
            },
          },
        },
      })

      lsp_setup(server_name, opts)
    end,
    solargraph = function(server_name)
      local opts = vim.tbl_extend("keep", server_opts, {
        settings = {
          solargraph = {
            diagnostics = true,
            useBundler = true,
            folding = false,
            logLevel = "debug",
          },
        },
      })

      lsp_cmd_override(server_name, opts, ".bin/solargraph", { "stdio" })

      lsp_setup(server_name, opts)
    end,
    sumneko_lua = function(server_name)
      local path = vim.split(package.path, ";")
      table.insert(path, "lua/?.lua")
      table.insert(path, "lua/?/init.lua")

      local plugins = ("%s/site/pack/paq"):format(fn.stdpath("data"))
      local emmy = ("%s/start/emmylua-nvim"):format(plugins)
      local plenary = ("%s/start/plenary.nvim"):format(plugins)
      -- local paq = ('%s/opt/paq-nvim'):format(plugins)

      local opts = vim.tbl_extend("keep", server_opts, {
        handlers = {
          -- Don't open quickfix list in case of multiple definitions. At the
          -- moment, this conflicts the `a = function()` code style because
          -- sumneko_lua treats both `a` and `function()` to be definitions of `a`.
          ["textDocument/definition"] = function(_, result, ctx, _)
            -- Adapted from source:
            -- https://github.com/neovim/neovim/blob/master/runtime/lua/vim/lsp/handlers.lua#L341-L366
            if result == nil or vim.tbl_isempty(result) then return nil end
            local client = lsp.get_client_by_id(ctx.client_id)

            local res = vim.tbl_islist(result) and result[1] or result
            lsp.util.jump_to_location(res, client.offset_encoding)
          end,
        },
        settings = {
          Lua = {
            runtime = {
              path = path,
              version = "LuaJIT",
            },
            format = { enable = false },
            hint = {
              enable = true,
              arrayIndex = "Disable", -- "Enable", "Auto", "Disable"
              await = true,
              paramName = "Disable", -- "All", "Literal", "Disable"
              paramType = false,
              semicolon = "Disable", -- "All", "SameLine", "Disable"
              setType = true,
            },
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
              library = { fn.expand("$VIMRUNTIME/lua"), emmy, plenary },
              checkThirdParty = false,
            },
            telemetry = {
              enable = false,
            },
          },
        },
      })

      lsp_setup(server_name, opts)
    end,
    tailwindcss = function(server_name)
      local opts = vim.tbl_extend("keep", server_opts, {
        init_options = {
          userLanguages = {
            elixir = "phoenix-heex",
            eruby = "erb",
            heex = "phoenix-heex",
          },
        },
        handlers = {
          ["tailwindcss/getConfiguration"] = function(_, _, params, _, bufnr, _)
            lsp.buf_notify(bufnr, "tailwindcss/getConfigurationResponse", { _id = params._id })
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
      })

      lsp_setup(server_name, opts)
    end,
    -- TODO: @trial: https://github.com/jose-elias-alvarez/typescript.nvim
    tsserver = function(server_name)
      local function do_organize_imports()
        local params = {
          command = "_typescript.organizeImports",
          arguments = { api.nvim_buf_get_name(0) },
          title = "",
        }
        lsp.buf.execute_command(params)
      end

      local opts = vim.tbl_extend("keep", server_opts, {
        init_options = {
          hostInfo = "neovim",
          logVerbosity = "verbose",
        },
        commands = {
          OrganizeImports = {
            do_organize_imports,
            description = "Organize Imports",
          },
        },
        filetypes = {
          "javascript",
          "javascriptreact",
          "javascript.jsx",
          "typescript",
          "typescriptreact",
          "typescript.tsx",
        },
        settings = {
          typescript = {
            inlayHints = {
              includeInlayParameterNameHints = "all",
              includeInlayParameterNameHintsWhenArgumentMatchesName = false,
              includeInlayFunctionParameterTypeHints = true,
              includeInlayVariableTypeHints = true,
              includeInlayPropertyDeclarationTypeHints = true,
              includeInlayFunctionLikeReturnTypeHints = true,
              includeInlayEnumMemberValueHints = true,
            },
          },
          javascript = {
            inlayHints = {
              includeInlayParameterNameHints = "all",
              includeInlayParameterNameHintsWhenArgumentMatchesName = false,
              includeInlayFunctionParameterTypeHints = true,
              includeInlayVariableTypeHints = true,
              includeInlayPropertyDeclarationTypeHints = true,
              includeInlayFunctionLikeReturnTypeHints = true,
              includeInlayEnumMemberValueHints = true,
            },
          },
        },
      })

      lsp_cmd_override(server_name, opts, ".bin/typescript-language-server", { "stdio" })

      lsp_setup(server_name, opts)
    end,
    vimls = function(server_name) lsp_setup(server_name, { init_options = { isNeovim = true } }) end,
    yamlls = function(server_name)
      local opts = vim.tbl_extend("keep", server_opts, {
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
      })

      lsp_setup(server_name, opts)
    end,
  })
end

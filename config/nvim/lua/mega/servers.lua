local M = {}

local fn, lsp = vim.fn, vim.lsp
local ok_lsp, lspconfig = mega.require("lspconfig")
if not ok_lsp then return end
-- local lsputil = require("lspconfig.util")

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

return {
  ccls = {},
  cssls = {
    settings = {
      css = {
        validate = false,
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
  },
  dockerls = {
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
  },
  elmls = {},
  emmet_ls = {
    settings = {
      includeLanguages = {
        ["html-eex"] = "html",
        ["phoenix-heex"] = "html",
        eruby = "html",
      },
    },
    filetypes = {
      "html",
      "javascriptreact",
      "typescriptreact",
      -- "elixir",
      -- "eelixir",
      "html.heex",
      "heex",
      "html_heex",
      "html_eex",
      "phoenix-heex",
      "phoenix_heex",
      "eruby",
    },
  },
  html = {
    settings = {
      includeLanguages = {
        ["html-eex"] = "html",
        ["phoenix-heex"] = "html",
        eruby = "html",
      },
    },
    filetypes = {
      "html",
      "javascriptreact",
      "typescriptreact",
      "elixir",
      "eelixir",
      "html.heex",
      "heex",
      "html_heex",
      "html_eex",
      "phoenix-heex",
      "phoenix_heex",
      "eruby",
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
        "phoenix-heex",
        "phoenix_heex",
        "eruby",
      },
      embeddedLanguages = {
        css = true,
        javascript = true,
      },
      provideFormatter = false,
    },
  },
  tsserver = function()
    local function do_organize_imports()
      local params = {
        command = "_typescript.organizeImports",
        arguments = { vim.api.nvim_buf_get_name(0) },
        title = "",
      }
      lsp.buf.execute_command(params)
    end

    return {
      -- cmd = lsp_cmd_override({ ".bin/typescript-language-server", "typescript-language-server" }, { "stdio" }),
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
    }
  end,
  graphql = {},
  jsonls = {
    commands = {
      Format = {
        function() lsp.buf.range_formatting({}, { 0, 0 }, { fn.line("$"), 0 }) end,
      },
    },
    init_options = { provideFormatter = false },
    single_file_support = true,
    on_new_config = function(new_config)
      new_config.settings.json.schemas = new_config.settings.json.schemas or {}
      vim.list_extend(new_config.settings.json.schemas, require("schemastore").json.schemas())
    end,
    settings = {
      json = {
        format = { enable = false },
        -- schemas = require("schemastore").json.schemas(),
        validate = { enable = true },
      },
    },
  },
  -- bashls = false,
  vimls = { init_options = { isNeovim = true } },
  teal_ls = {},
  terraformls = {},
  rust_analyzer = {
    settings = {
      ["rust-analyzer"] = {
        cargo = { allFeatures = true },
        checkOnSave = {
          command = "clippy",
          extraArgs = { "--no-deps" },
        },
      },
    },
  },
  marksman = {},
  pyright = {
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
  },
  ruby_ls = {},
  solargraph = {
    single_file_support = false,
    settings = {
      solargraph = {
        diagnostics = true,
        useBundler = true,
        formatting = true,
        folding = false,
        logLevel = "debug",
      },
    },
  },
  prosemd_lsp = {},
  --- https://github.com/golang/tools/blob/master/gopls/doc/settings.md
  gopls = {
    settings = {
      gopls = {
        gofumpt = true,
        codelenses = {
          generate = true,
          gc_details = false,
          test = true,
          tidy = true,
        },
        hints = {
          assignVariableTypes = true,
          compositeLiteralFields = true,
          constantValues = true,
          functionTypeParameters = true,
          parameterNames = true,
          rangeVariableTypes = true,
        },
        analyses = {
          unusedparams = true,
        },
        usePlaceholders = true,
        completeUnimported = true,
        staticcheck = true,
        directoryFilters = { "-node_modules" },
      },
    },
  },
  sourcekit = {
    filetypes = { "swift", "objective-c", "objective-cpp" },
  },
  yamlls = {
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
  },
  sqls = function()
    return {
      root_dir = require("lspconfig").util.root_pattern(".git"),
      single_file_support = false,
      on_new_config = function(new_config, new_rootdir)
        table.insert(new_config.cmd, "-config")
        table.insert(new_config.cmd, new_rootdir .. "/.config.yaml")
      end,
    }
  end,
  --- @see https://gist.github.com/folke/fe5d28423ea5380929c3f7ce674c41d8
  lua_ls = function()
    local path = vim.split(package.path, ";")
    table.insert(path, "lua/?.lua")
    table.insert(path, "lua/?/init.lua")

    -- FIXME: use lazy location now
    local plugins = ("%s/site/pack/packer"):format(fn.stdpath("data"))
    local emmy = ("%s/start/emmylua-nvim"):format(plugins)
    local plenary = ("%s/start/plenary.nvim"):format(plugins)
    local packer = ("%s/opt/packer.nvim"):format(plugins)

    return {
      settings = {
        Lua = {
          runtime = {
            path = path,
            version = "LuaJIT",
          },
          format = {
            enable = false,
            defaultConfig = {
              indent_style = "space",
              indent_size = "2",
              continuation_indent_size = "2",
            },
          },
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
              "packer_plugins",
              "Color",
              "Group",
              "after_each",
              "before_each",
              "c",
              "cmap",
              "cnoremap",
              "config",
              "describe",
              "g",
              "hs",
              "imap",
              "import",
              "inoremap",
              "it",
              "lmap",
              "lnoremap",
              "map",
              "mega",
              "nmap",
              "nnoremap",
              "noremap",
              "omap",
              "onoremap",
              "s",
              "smap",
              "snoremap",
              "spoon",
              "tmap",
              "tnoremap",
              "vim",
              "vmap",
              "vnoremap",
              "watchers",
              "xmap",
              "xnoremap",
            },
            -- groupSeverity = {
            --   strong = "Warning",
            --   strict = "Warning",
            -- },
            -- groupFileStatus = {
            --   ["ambiguity"] = "Opened",
            --   ["await"] = "Opened",
            --   ["codestyle"] = "None",
            --   ["duplicate"] = "Opened",
            --   ["global"] = "Opened",
            --   ["luadoc"] = "Opened",
            --   ["redefined"] = "Opened",
            --   ["strict"] = "Opened",
            --   ["strong"] = "Opened",
            --   ["type-check"] = "Opened",
            --   ["unbalanced"] = "Opened",
            --   ["unused"] = "Opened",
            -- },
            unusedLocalExclude = { "_*" },
          },
          completion = {
            keywordSnippet = "Replace",
            workspaceWord = true,
            callSnippet = "Both",
          },
          misc = {
            parameters = {
              "--log-level=trace",
            },
          },
          workspace = {
            ignoreSubmodules = true,
            library = { fn.expand("$VIMRUNTIME/lua"), emmy, packer, plenary },
            checkThirdParty = false,
          },
          telemetry = {
            enable = false,
          },
        },
      },
    }
  end,
  tailwindcss = {
    init_options = {
      userLanguages = {
        eelixir = "phoenix-heex",
        elixir = "phoenix-heex",
        eruby = "erb",
        heex = "phoenix-heex",
      },
    },
    handlers = {
      ["tailwindcss/getConfiguration"] = function(_, _, params, _, bufnr, _)
        lsp.buf_notify(bufnr, "tailwindcss/getConfigurationResponse", { _id = params._id })
        P("tailwindcss getConfiguration callback")
      end,
    },
    settings = {
      includeLanguages = {
        typescript = "javascript",
        typescriptreact = "javascript",
        ["html-eex"] = "html",
        ["phoenix-heex"] = "html",
        elixir = "html",
        heex = "html",
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
            "~H\"\"\".*additional_classes=\"([^\"]*)\".*\"\"\"",
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
      "eelixir",
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
  },
}

-- ----------------------------------------------------------------------------//
-- -- Language servers
-- -----------------------------------------------------------------------------//
-- ---@type lspconfig.options
-- local servers = {
--   eslint = {},
--   tsserver = {},
--   ccls = {},
--   graphql = {
--     on_attach = function(client)
--       -- Disable workspaceSymbolProvider because this prevents
--       -- searching for symbols in typescript files which this server
--       -- is also enabled for.
--       -- @see: https://github.com/nvim-telescope/telescope.nvim/issues/964
--       client.server_capabilities.workspaceSymbolProvider = false
--     end,
--   },
--   jsonls = {},
--   bashls = {},
--   vimls = {},
--   terraformls = {},
--   marksman = {},
--   pyright = {},
--   bufls = {},
--   prosemd_lsp = {},
--   docker_compose_language_service = {},
--   --- https://github.com/golang/tools/blob/master/gopls/doc/settings.md
--   gopls = {
--     settings = {
--       gopls = {
--         gofumpt = true,
--         codelenses = {
--           generate = true,
--           gc_details = false,
--           test = true,
--           tidy = true,
--         },
--         hints = {
--           assignVariableTypes = true,
--           compositeLiteralFields = true,
--           constantValues = true,
--           functionTypeParameters = true,
--           parameterNames = true,
--           rangeVariableTypes = true,
--         },
--         analyses = {
--           unusedparams = true,
--         },
--         usePlaceholders = true,
--         completeUnimported = true,
--         staticcheck = true,
--         directoryFilters = { '-node_modules' },
--       },
--     },
--   },
--   sourcekit = {
--     filetypes = { 'swift', 'objective-c', 'objective-cpp' },
--   },
--   yamlls = {
--     settings = {
--       yaml = {
--         customTags = {
--           '!reference sequence', -- necessary for gitlab-ci.yaml files
--         },
--       },
--     },
--   },
--   sqls = function()
--     return {
--       root_dir = require('lspconfig').util.root_pattern('.git'),
--       single_file_support = false,
--       on_new_config = function(new_config, new_rootdir)
--         table.insert(new_config.cmd, '-config')
--         table.insert(new_config.cmd, new_rootdir .. '/.config.yaml')
--       end,
--     }
--   end,
--   lua_ls = {
--     settings = {
--       Lua = {
--         codeLens = { enable = true },
--         hint = { enable = true, arrayIndex = 'Disable', setType = true },
--         format = { enable = false },
--         diagnostics = {
--           globals = {
--             'vim',
--             'P',
--             'describe',
--             'it',
--             'before_each',
--             'after_each',
--             'packer_plugins',
--             'pending',
--           },
--         },
--         completion = { keywordSnippet = 'Replace', callSnippet = 'Replace' },
--         workspace = { checkThirdParty = false },
--         telemetry = { enable = false },
--       },
--     },
--   },
-- }
--
-- ---Get the configuration for a specific language server
-- ---@param name string?
-- ---@return table<string, any>?
-- return function(name)
--   local config = name and servers[name] or {}
--   if not config then return end
--   if type(config) == 'function' then config = config() end
--   local ok, cmp_nvim_lsp = mega.require('cmp_nvim_lsp')
--   if ok then config.capabilities = cmp_nvim_lsp.default_capabilities() end
--   config.capabilities = vim.tbl_deep_extend('keep', config.capabilities or {}, {
--     workspace = { didChangeWatchedFiles = { dynamicRegistration = true } },
--     textDocument = { foldingRange = { dynamicRegistration = false, lineFoldingOnly = true } },
--   })
--   return config
-- end

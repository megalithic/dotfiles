local fn, lsp = vim.fn, vim.lsp
local ok_lsp = mega.require("lspconfig")
if not ok_lsp then return end

local lsputil = require("lspconfig.util")

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

local M = {}

M.list = {
  bashls = {},
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
  docker_compose_language_service = {},
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
  graphql = {},
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
  lexical = {},
  --- @see https://gist.github.com/folke/fe5d28423ea5380929c3f7ce674c41d8
  lua_ls = function()
    local path = vim.split(package.path, ";")
    table.insert(path, "lua/?.lua")
    table.insert(path, "lua/?/init.lua")

    -- TODO: investigate using neoconf and then this:
    -- https://github.com/Hammerspoon/hammerspoon/discussions/3451#discussioncomment-5545150
    local plugins = ("%s/nvim/lazy"):format(fn.stdpath("data"))
    local plenary = ("%s/start/plenary.nvim"):format(plugins)
    local hammerspoon = ("%s/annotations"):format(vim.g.hs_emmy_path)

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
            paramType = true,
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
            library = { fn.expand("$VIMRUNTIME/lua"), plugins, plenary, hammerspoon },
            checkThirdParty = false,
          },
          telemetry = {
            enable = false,
          },
        },
      },
    }
  end,
  marksman = {},
  prosemd_lsp = {},
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
  sourcekit = {
    filetypes = { "swift", "objective-c", "objective-cpp" },
  },
  sqlls = function()
    return {
      root_dir = root_pattern(".git"),
      single_file_support = false,
      on_new_config = function(new_config, new_rootdir)
        table.insert(new_config.cmd, "-config")
        table.insert(new_config.cmd, new_rootdir .. "/.config.yaml")
      end,
    }
  end,
  tailwindcss = {
    init_options = {
      userLanguages = {
        eelixir = "phoenix-heex",
        elixir = "phoenix-heex",
        eruby = "erb",
        heex = "phoenix-heex",
        surface = "phoenix-heex",
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
        eelixir = "html",
        elixir = "html",
        heex = "html",
        elm = "html",
        surface = "html",
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
        classAttributes = {
          "class",
          "className",
          "classList",
          "ngClass",
        },
        experimental = {
          classRegex = {
            [[class= "([^"]*)]],
            [[additional_classes= "([^"]*)]],
            [[class: "([^"]*)]],
            [[~H""".*class="([^"]*)".*"""]],
            [[~H""".*additional_classes="([^"]*)".*"""]],
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
  teal_ls = {},
  terraformls = {},
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
            includeInlayParameterNameHints = "literal", -- alts: all
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
            includeInlayFunctionParameterTypeHints = false,
            includeInlayVariableTypeHints = true,
            includeInlayPropertyDeclarationTypeHints = true,
            includeInlayFunctionLikeReturnTypeHints = true,
            includeInlayEnumMemberValueHints = true,
          },
        },
      },
    }
  end,
  vimls = { init_options = { isNeovim = true } },
  --- https://github.com/golang/tools/blob/master/gopls/doc/settings.md
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
}
M.experimental = {
  lexical = function()
    local lspconfig = require("lspconfig")
    local configs = require("lspconfig.configs")

    function lex()
      return {
        cmd = {
          "/Users/zimakki/code/lexical-lsp/lexical/_build/dev/rel/lexical/start_lexical.sh",
        },
        filetypes = { "elixir", "eelixir", "heex", "surface" },
        root_dir = function(fname)
          local lspconfig = require("lspconfig")
          -- Set `~/Code/lexical` as root_dir for lexical project
          local project = lspconfig.util.root_pattern(".git")(fname)
          if project and string.sub(project, -12) == "code/lexical" then
            return project
          else
            return lspconfig.util.root_pattern("mix.exs", ".git")(fname) or vim.loop.os_homedir()
          end
        end,
      }
    end

    if not configs.lexical then
      configs.lexical = {
        default_config = {
          cmd = { vim.env.XDG_DATA_HOME .. "/lsp/lexical/_build/dev/rel/lexical/start_lexical.sh" },
          filetypes = { "elixir", "eelixir", "heex", "surface" },
          root_dir = root_pattern("mix.exs", ".git"), -- or vim.loop.os_homedir(),
          settings = {},
        },
      }
    end
  end,
}

M.load_experimental = function()
  for _server_name, loader in pairs(M.experimental) do
    loader()
  end
end

return M

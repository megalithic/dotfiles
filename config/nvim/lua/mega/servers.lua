local fn, lsp = vim.fn, vim.lsp
local fmt = string.format
local L = vim.log.levels
local U = require("mega.utils")
local ok_lsp, lspconfig = pcall(require, "lspconfig")
if not ok_lsp then return nil end

local M = {}
-- local root_pattern = require("mega.utils.lsp").root_pattern
local root_pattern = lspconfig.util.root_pattern

M.list = function()
  return {
    bashls = {},
    -- biome = {
    --   manual_install = true,
    --   root_dir = root_pattern({ "biome.json", ".biome.json", ".eslintrc.js", ".prettierrc.js" }),
    -- },
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
            unknownAtRules = "ignore",
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
    lexical = function()
      if not U.lsp.is_enabled_elixir_ls("lexical") then return false end

      -- local function cmd() return vim.env.XDG_DATA_HOME .. "/lsp/lexical/_build/dev/package/lexical/bin/start_lexical.sh" end

      return {
        manual_install = true,
        cmd = { vim.env.XDG_DATA_HOME .. "/lsp/lexical/_build/dev/package/lexical/bin/start_lexical.sh" },
        single_file_support = true,
        filetypes = { "elixir", "eelixir", "heex", "surface" },
        root_dir = root_pattern("mix.exs", ".git"),
        -- log_level = vim.lsp.protocol.MessageType.Log,
        -- message_level = vim.lsp.protocol.MessageType.Log,
        -- settings = {
        --   dialyzerEnabled = true,
        -- },
      }
    end,
    elixirls = function()
      if not U.lsp.is_enabled_elixir_ls("elixirls") then return false end

      return {
        manual_install = true,
        cmd = { fmt("%s/lsp/elixir-ls/%s", vim.env.XDG_DATA_HOME, "language_server.sh") },
        filetypes = { "elixir", "eelixir", "heex", "surface" },
        root_dir = function(fname)
          local matches = vim.fs.find({ "mix.exs" }, { upward = true, limit = 2, path = fname })
          local child_or_root_path, maybe_umbrella_path = unpack(matches)
          local root_dir = vim.fs.dirname(maybe_umbrella_path or child_or_root_path)

          return root_dir
        end,
        single_file_support = true,
        settings = {
          mixEnv = "dev",
          mix_env = "dev",
          autoBuild = true,
          fetchDeps = true,
          incrementalDialyzer = true,
          dialyzerEnabled = true,
          -- dialyzerFormat = "dialyxir_long",
          enableTestLenses = true,
          suggestSpecs = true,
          autoInsertRequiredAlias = true,
          signatureAfterComplete = true,
        },
        -- on_attach = function(client, buffer) vim.pprint({ client, buffer }) end,
      }
    end,
    elmls = {},
    emmet_ls = {
      settings = {
        includeLanguages = {
          -- ["html-eex"] = "html",
          -- ["phoenix-heex"] = "html",
          eruby = "html",
        },
      },
      filetypes = {
        "html",
        "javascriptreact",
        "typescriptreact",
        -- "elixir",
        -- "eelixir",
        -- "html.heex",
        -- "heex",
        -- "html_heex",
        -- "html_eex",
        -- "phoenix-heex",
        -- "phoenix_heex",
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
        format = false,
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
      init_options = {
        configurationSection = {
          "html",
          "css",
          "javascript",
          -- "elixir",
          -- "eelixir",
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
    lua_ls = function()
      local path = vim.split(package.path, ";")
      table.insert(path, "lua/?.lua")
      table.insert(path, "lua/?/init.lua")

      -- TODO: investigate using neoconf and then this:
      -- https://github.com/Hammerspoon/hammerspoon/discussions/3451#discussioncomment-5545150
      local plugins = ("%s/nvim/lazy"):format(fn.stdpath("data"))
      local plenary = ("%s/start/plenary.nvim"):format(plugins)
      local hammerspoon = ("%s/annotations"):format(vim.g.hs_emmy_path)
      local wezterm = ("%s/nvim/lazy/wezterm-types/types"):format(fn.stdpath("data"))

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
            semantic = { enable = false },
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
              library = { fn.expand("$VIMRUNTIME/lua"), plugins, plenary, hammerspoon, wezterm },
              checkThirdParty = false,
            },
            telemetry = {
              enable = false,
            },
          },
        },
      }
    end,
    -- marksman = function() return (vim.g.started_by_firenvim or vim.env.TMUX_POPUP) and nil or {} end,
    nextls = function()
      if not U.lsp.is_enabled_elixir_ls("nextls") then return false end

      local cmd = function(use_homebrew)
        local arch = {
          ["arm64"] = "arm64",
          ["aarch64"] = "arm64",
          ["amd64"] = "amd64",
          ["x86_64"] = "amd64",
        }

        local os_name = string.lower(vim.uv.os_uname().sysname)
        local current_arch = arch[string.lower(vim.uv.os_uname().machine)]
        local build_bin = fmt("next_ls_%s_%s", os_name, current_arch)

        if use_homebrew then return { "nextls", "--stdio" } end
        -- P({ fmt("%s/lsp/next-ls/burrito_out/%s", vim.env.XDG_DATA_HOME, build_bin), "--stdio" })
        -- return { fmt("%s/lsp/next-ls/burrito_out/%s", vim.env.XDG_DATA_HOME, build_bin), "--stdio" }
        return { fmt("%s/lsp/bin/nextls", vim.env.XDG_DATA_HOME), "--stdio" }
      end

      local homebrew_enabled = false

      return {
        manual_install = true,
        cmd = cmd(homebrew_enabled),
        single_file_support = true,
        filetypes = { "elixir", "eelixir", "heex", "surface" },
        root_dir = function(fname)
          local matches = vim.fs.find({ "mix.exs" }, { upward = true, limit = 2, path = fname })
          local child_or_root_path, maybe_umbrella_path = unpack(matches)
          local root_dir = vim.fs.dirname(maybe_umbrella_path or child_or_root_path)

          return root_dir
        end,
        log_level = "verbose", --vim.lsp.protocol.MessageType.Error,
        message_level = "verbose", -- vim.lsp.protocol.MessageType.Error,
        cmd_env = {
          NEXTLS_SPITFIRE_ENABLED = 1,
        },
        env = {
          NEXTLS_SPITFIRE_ENABLED = 1,
        },
        spitfire = true,
        init_options = {
          cmd_env = {
            NEXTLS_SPITFIRE_ENABLED = 1,
          },
          env = {
            NEXTLS_SPITFIRE_ENABLED = 1,
          },
          mix_env = "dev",
          mix_target = "host",
          experimental = {
            completions = {
              enable = true,
            },
          },
        },
        settings = {
          cmd_env = {
            NEXTLS_SPITFIRE_ENABLED = 1,
          },
          env = {
            NEXTLS_SPITFIRE_ENABLED = 1,
          },
          experimental = {
            completions = {
              enable = true,
            },
          },
          mix_env = "dev",
          mix_target = "host",
          fetchDeps = true,
          dialyzerEnabled = true,
          dialyzerFormat = "dialyxir_long",
          enableTestLenses = false,
          suggestSpecs = true,
        },
      }
    end,
    -- prosemd_lsp = function() return (vim.g.started_by_firenvim or vim.env.TMUX_POPUP) and nil or {} end,
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
    -- ruby_lsp = {},
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
      manual_install = true,
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
    -- sourcekit = {
    --   filetypes = { 'swift', 'objective-c', 'objective-cpp' },
    -- },
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
      settings = {
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
        "elixir", -- this is causing a delay on bufenter for elixir files (white then coloured)
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
    -- NOTE: presently enabled via typescript-tools
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
          "typescript",
          "typescriptreact",
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
end

return M

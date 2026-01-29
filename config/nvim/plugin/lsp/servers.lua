local fn, lsp = vim.fn, vim.lsp
local fmt = string.format
local L = vim.log.levels
local U = require("config.utils")

local mason_bin_path = vim.fs.joinpath(vim.env.XDG_DATA_HOME, "lsp/mason/bin/")

local function mason_bin(opts)
  if type(opts) == "table" then
    local cmd, args = U.tshift(opts)

    return { mason_bin_path .. cmd, unpack(args) }
  else
    return mason_bin_path .. opts
  end
end

-- -- Some LSP are part of npm packages, so the binaries live inside node_modules/.bin
-- -- this function helps getting the correct path to the binary and falling
-- -- back to a global binary if none is found in the local node_modules
-- local function get_lsp_bin(bin)
--   -- Get the closest `node_modules` first
--   local root = vim.fs.root(0, "node_modules/.bin")
--   local bin_path = string.format("%s/.bin/%s", root, bin)
--
--   if vim.uv.fs_stat(bin_path) ~= nil then
--     return bin_path
--   end
--
--   -- Then maybe we might be in a monorepo, so get the root `node_modules`, maybe it's hoisted up there
--   root = vim.fs.root(0, ".git")
--   bin_path = string.format("%s/node_modules/.bin/%s", root, bin)
--
--   if vim.uv.fs_stat(bin_path) ~= nil then
--     return bin_path
--   end
--
--   return bin
-- end

local M = {}

--
-- TODO:
-- custom LSP actions and commands..
-- REF: examples of that: https://github.com/clifinger/nvim/blob/main/lua/plugins/lsp.lua#L83
--
-- code_action:
-- vim.lsp.buf.code_action { context = { only = { 'source.addMissingImports.ts' } }, apply = true }
--
-- command:
--[[
  local params = vim.lsp.util.make_position_params()
  client.request('workspace/executeCommand', {
    command = 'typescript.goToSourceDefinition',
    arguments = { params.textDocument.uri, params.position },
    open = true,
  }, function(err, result)
    if err then
      print('Error executing goToSourceDefinition:', vim.inspect(err))
    end
  end)

  client.request('workspace/executeCommand', {
    command = 'typescript.findAllFileReferences',
    arguments = { vim.uri_from_bufnr(buffer) },
    open = true,
  }, function(err, result)
    if err then
      print('Error executing findAllFileReferences:', vim.inspect(err))
    end
  end)
--]]

local function root_pattern(bufnr, on_dir, markers)
  markers = markers == nil and { ".git" } or markers
  markers = type(markers) == "string" and { markers } or markers

  local fname = vim.api.nvim_buf_get_name(bufnr)
  local matches = vim.fs.find(markers, { upward = true, limit = 2, path = fname })
  local child_or_root_path, maybe_umbrella_path = unpack(matches)
  local root_dir = vim.fs.dirname(maybe_umbrella_path or child_or_root_path)

  on_dir(root_dir)
end

M = {
  bashls = {
    filetypes = { "sh", "zsh", "bash" }, -- work in zsh as well
    settings = {
      bashIde = {
        shellcheckPath = "", -- disable while using efm
        shellcheckArguments = "--shell=bash", -- PENDING https://github.com/bash-lsp/bash-language-server/issues/1064
        shfmt = { spaceRedirects = true },
        globPattern = "*@(.sh|.inc|.bash|.command|.zsh|zshrc|zsh_*)",
      },
    },
  },
  cssls = {
    settings = {
      css = {
        validate = false,
        lint = {
          unknownProperties = "ignore",
          unknownAtRules = "ignore",
          vendorPrefix = "ignore", -- needed for scrollbars
          duplicateProperties = "warning",
          zeroUnits = "warning",
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
  expertls = function()
    return {
      manual_install = true,
      cmd = { "expert", "--stdio" },
      filetypes = { "elixir", "eelixir", "heex" },
      root_markers = { "mix.exs", ".git" },
      root_dir = function(bufnr, on_dir)
        local fname = vim.api.nvim_buf_get_name(bufnr)
        --- Elixir workspaces may have multiple `mix.exs` files, for an "umbrella" layout or monorepo.
        --- So we specify `limit=2` and treat the highest one (if any) as the root of an umbrella app.
        local matches = vim.fs.find({ "mix.exs" }, { upward = true, limit = 2, path = fname })
        local child_or_root_path, maybe_umbrella_path = unpack(matches)
        local root_dir = vim.fs.dirname(maybe_umbrella_path or child_or_root_path)

        on_dir(root_dir)
      end,
      -- root_dir = function(bufnr, on_dir)
      --   local fname = vim.api.nvim_buf_get_name(bufnr)
      --   local matches = vim.fs.find({ "mix.exs" }, { upward = true, limit = 2, path = fname })
      --   local child_or_root_path, maybe_umbrella_path = unpack(matches)
      --   local root_dir = vim.fs.dirname(maybe_umbrella_path or child_or_root_path)
      --
      --   on_dir(root_dir)
      -- end,
      single_file_support = true,
      settings = {
        elixir = {
          formatting = {
            command = { "mix", "format" },
          },
        },
      },
    }
  end,
  elmls = {},
  emmet_language_server = {
    cmd = { "emmet-language-server", "--stdio" },
    init_options = {
      showSuggestionsAsSnippets = false,
    },
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
  -- gopls = {
  --   settings = {
  --     gopls = {
  --       gofumpt = true,
  --       codelenses = {
  --         generate = true,
  --         gc_details = false,
  --         test = true,
  --         tidy = true,
  --       },
  --       hints = {
  --         assignVariableTypes = true,
  --         compositeLiteralFields = true,
  --         constantValues = true,
  --         functionTypeParameters = true,
  --         parameterNames = true,
  --         rangeVariableTypes = true,
  --       },
  --       analyses = {
  --         unusedparams = true,
  --       },
  --       usePlaceholders = true,
  --       completeUnimported = true,
  --       staticcheck = true,
  --       directoryFilters = { "-node_modules" },
  --     },
  --   },
  -- },
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
  jsonls = function()
    local ok_schemastore = pcall(require, "schemastore")
    return {
      -- commands = {
      --   Format = {
      --     function() lsp.buf.range_formatting({}, { 0, 0 }, { fn.line("$"), 0 }) end,
      --   },
      -- },
      init_options = { provideFormatter = false },
      single_file_support = true,
      on_new_config = function(new_config)
        new_config.settings.json.schemas = new_config.settings.json.schemas or {}
        vim.list_extend(
          new_config.settings.json.schemas,
          ok_schemastore and require("schemastore").json.schemas() or {}
        )
      end,
      settings = {
        json = {
          format = { enable = false },
          schemas = ok_schemastore and require("schemastore").json.schemas() or {},
          validate = { enable = true },
        },
      },
    }
  end,
  -- emmylua_ls = {},
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
      enabled = true,
      cmd = { "lua-language-server" },
      manual_install = true,
      filetypes = { "lua" },
      root_markers = {
        ".luarc.json",
        ".luarc.jsonc",
        ".luacheckrc",
        ".stylua.toml",
        "stylua.toml",
        "selene.toml",
        "selene.yml",
        ".git",
      },
      settings = {
        Lua = {
          runtime = {
            path = path,
            version = "LuaJIT",
          },
          signatureHelp = { enabled = true },
          format = {
            enable = false,
            defaultConfig = {
              indent_style = "space",
              indent_size = "2",
              continuation_indent_size = "2",
            },
          },
          -- semantic = { enable = false },
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
            disable = {
              "missing-parameter",
              "return-type-mismatch",
              "undefined-global",
              "need-check-nil",
            },
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
              "Snacks",
              "P",
              "L",
              "H",
              "U",
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
              "--log-level=error",
            },
          },
          workspace = {
            ignoreSubmodules = true,
            library = {
              vim.fn.expand("$VIMRUNTIME/lua"),
              plugins,
              plenary,
              hammerspoon,
              wezterm,
              vim.api.nvim_get_runtime_file("", true),
            },
            checkThirdParty = false,
          },
          telemetry = {
            enable = false,
          },
        },
      },
      handlers = {
        -- always go to the first definition
        ["textDocument/definition"] = function(err, result, ...)
          if vim.islist(result) or type(result) == "table" then result = result[1] end
          vim.lsp.handlers["textDocument/definition"](err, result, ...)
        end,
      },
    }
  end,
  -- markdown_oxide = function()
  --   -- Enabled for obsidian.nvim integration (Obsidian-aware LSP for wikilinks, daily notes, tags)
  --   return (vim.g.started_by_firenvim or vim.env.TMUX_POPUP) and nil
  --     or {
  --       capabilities = {
  --         workspace = {
  --           didChangeWatchedFiles = {
  --             dynamicRegistration = true,
  --           },
  --         },
  --       },
  --     }
  -- end,
  nixd = {
    settings = {
      nixd = {
        nixpkgs = {
          expr = vim.fs.root(0, { "shell.nix" }) ~= nil and "import <nixpkgs> { }" or string.format(
            'import (builtins.getFlake "%s").inputs.nixpkgs { }',
            vim.fs.root(0, { "flake.nix" }) or vim.fn.expand("$DOTFILES")
          ),
        },
        formatting = {
          command = { "alejandra" },
        },
        -- options = vim.tbl_extend("force", {
        --   -- home_manager = {
        --   -- 	expr = string.format(
        --   -- 		'(builtins.getFlake "%s").homeConfigurations.%s.options',
        --   -- 		vim.fn.expand '$DOTFILES',
        --   -- 		vim.fn.hostname()
        --   -- 	),
        --   -- },
        -- }, vim.fn.has("macunix") and {
        --   ["nix-darwin"] = {
        --     expr = string.format(
        --       '(builtins.getFlake "%s").darwinConfigurations.%s.options',
        --       vim.fn.expand("$DOTFILES"),
        --       vim.fn.hostname()
        --     ),
        --   },
        -- } or {
        --   nixos = {
        --     expr = string.format(
        --       '(builtins.getFlake "%s").nixosConfigurations.%s.options',
        --       vim.fn.expand("$DOTFILES"),
        --       vim.fn.hostname()
        --     ),
        --   },
        -- }),
      },
    },
  },
  -- nil_ls = {},
  -- TODO: nil -> nixd?
  -- REF: https://github.com/ahmedelgabri/dotfiles/commit/5dd61158f6872d4c4b85ddf5df550e0222093ae8
  -- nixd = {
  --   -- https://github.com/nix-community/nixvim/issues/2390#issuecomment-2408101568
  --   -- offset_encoding = 'utf-8',
  --   settings = {
  --     nixd = {
  --       nixpkgs = {
  --         expr = vim.fs.root(0, { "shell.nix" }) ~= nil and "import <nixpkgs> { }"
  --           or string.format("import (builtins.getFlake \"%s\").inputs.nixpkgs { }", vim.fs.root(0, { "flake.nix" }) or vim.fn.expand("$DOTFILES")),
  --       },
  --       formatting = {
  --         command = { "nixpkgs-fmt" },
  --       },
  --       options = vim.tbl_extend("force", {
  --         -- home_manager = {
  --         -- 	expr = string.format(
  --         -- 		'(builtins.getFlake "%s").homeConfigurations.%s.options',
  --         -- 		vim.fn.expand '$DOTFILES',
  --         -- 		vim.fn.hostname()
  --         -- 	),
  --         -- },
  --       }, vim.fn.has("macunix") and {
  --         ["nix-darwin"] = {
  --           expr = string.format("(builtins.getFlake \"%s\").darwinConfigurations.%s.options", vim.fn.expand("$DOTFILES"), vim.fn.hostname()),
  --         },
  --       } or {
  --         nixos = {
  --           expr = string.format("(builtins.getFlake \"%s\").nixosConfigurations.%s.options", vim.fn.expand("$DOTFILES"), vim.fn.hostname()),
  --         },
  --       }),
  --     },
  --   },
  -- },
  -- prosemd_lsp = function() return (vim.g.started_by_firenvim or vim.env.TMUX_POPUP) and nil or {} end,
  postgres_lsp = {
    -- manual_install = true,
    cmd = mason_bin({ "postgrestools", "lsp-proxy" }),
    -- cmd = { "postgrestools", "lsp-proxy" },
    capabilities = {
      workspace = {
        didChangeConfiguration = { dynamicRegistration = true },
      },
    },
    filetypes = { "sql" },
    single_file_support = true,
    settings = {
      db = {
        username = vim.env.USER,
        password = vim.env.USER,
      },
    },
  },

  -- pyright = {
  --   enabled = false,
  --   single_file_support = false,
  --   settings = {
  --     pyright = {
  --       -- Using Ruff's import organizer
  --       disableOrganizeImports = true,
  --     },
  --     python = {
  --       format = false,
  --       analysis = {
  --         autoSearchPaths = true,
  --         diagnosticMode = "workspace",
  --         useLibraryCodeForTypes = true,
  --         -- Ignore all files for analysis to exclusively use Ruff for linting
  --         ignore = { "*" },
  --       },
  --     },
  --   },
  -- },
  -- pylsp = {
  --   settings = {
  --     pylsp = {
  --       -- :PyLspInstall <tab>
  --       plugins = {
  --         -- Unklar, was es macht, wird ggfl. auch von ruff[-lsp] übernommen
  --         rope = {
  --           enabled = false,
  --         },
  --         -- All disabled to avoid overlap with ruff
  --         -- list from python-lsp-ruff
  --         pycodestyle = {
  --           enabled = false,
  --           maxLineLength = 150,
  --         },
  --         mccabe = {
  --           enabled = false,
  --         },
  --         pydocstyle = {
  --           enabled = false,
  --         },
  --         -- autopep8, yapf formatieren beide, Unterschied unklar. yapf = false, autopep8 = true macht es so, wie ich es möchte
  --         yapf = {
  --           enabled = false,
  --         },
  --         autopep8 = {
  --           enabled = false,
  --         },
  --       },
  --     },
  --   },
  -- },

  basedpyright = {
    enabled = true,
    single_file_support = false,
    settings = {
      basedpyright = {
        -- Using Ruff's import organizer
        disableOrganizeImports = true,
        -- analysis = {
        --   useLibraryCodeForTypes = true,
        --   typeCheckingMode = "standard",
        --   diagnosticMode = "workspace",
        --   autoSearchPath = true,
        --   inlayHints = {
        --     callArgumentNames = true,
        --   },
        --   extraPaths = {
        --     "...",
        --     "...",
        --   },
        -- },
        -- reportImplicitOverride = false,
        reportMissingSuperCall = "none",
        -- reportUnusedImport = false,
        -- basedpyright very intrusive with errors, this calms it down
        typeCheckingMode = "standard",
        -- works, if pyproject.toml is used
        reportAttributeAccessIssue = false,
        -- doesn't work, even if pyproject.toml is used
        analysis = {
          inlayHints = {
            callArgumentNames = true, -- = basedpyright.analysis.inlayHints.callArgumentNames
          },
          autoSearchPaths = true,
          diagnosticMode = "openFilesOnly",
          useLibraryCodeForTypes = true,
          typeCheckingMode = "standard",
          diagnosticSeverityOverrides = {
            reportAny = false,
            reportMissingTypeArgument = false,
            reportMissingTypeStubs = false,
            reportUnknownArgumentType = false,
            reportUnknownMemberType = false,
            reportUnknownParameterType = false,
            reportUnknownVariableType = false,
            reportUnusedCallResult = false,
          },
        },
      },
      python = {
        format = false,
        analysis = {
          autoSearchPaths = true,
          diagnosticMode = "workspace",
          useLibraryCodeForTypes = true,
          -- Ignore all files for analysis to exclusively use Ruff for linting
          ignore = { "*" },
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

  sqlls = function()
    return {
      cmd = { "sql-language-server", "up", "--method", "stdio" },
      root_dir = function(bufnr, on_dir) root_pattern(bufnr, on_dir) end,
      single_file_support = false,
      on_new_config = function(new_config, new_rootdir)
        table.insert(new_config.cmd, "-config")
        table.insert(new_config.cmd, new_rootdir .. "/.config.yaml")
      end,
    }
  end,
  tailwindcss = {
    settings = {
      tailwindCSS = {
        validate = true,
        files = {
          exclude = {
            "**/.git/**",
            "**/node_modules/**",
            "**/.direnv/**",
            "**/deps/**",
            "**/_build/**",
          },
        },
        includeLanguages = {
          elixir = "phoenix-heex",
          eruby = "erb",
          heex = "phoenix-heex",
          surface = "phoenix-heex",
        },
        lint = {
          cssConflict = "warning",
          invalidApply = "error",
          invalidScreen = "error",
          invalidVariant = "error",
          invalidConfigPath = "error",
          invalidTailwindDirective = "error",
          recommendedVariantOrder = "warning",
        },
        classAttributes = {
          "class",
          "className",
          "class:list",
          "classList",
          "ngClass",
        },
        experimental = {
          classRegex = {
            [[class:\s*"([^"]*)]],
            [[class=\s*"([^"]*)]],
            [[class="([^"]*)]],
            [[class:"([^"]*)]],
            [[additional_classes="([^"]*)]],
          },
        },
      },
    },
    filetypes = { "elixir", "eelixir", "html", "liquid", "heex", "surface", "css" },
  },
  taplo = {
    settings = {
      -- Use the defaults that the VSCode extension uses: https://github.com/tamasfe/taplo/blob/2e01e8cca235aae3d3f6d4415c06fd52e1523934/editors/vscode/package.json
      taplo = {
        configFile = { enabled = true },
        schema = {
          enabled = true,
          catalogs = {
            "https://www.schemastore.org/api/json/catalog.json",
          },
          cache = {
            memoryExpiration = 60,
            diskExpiration = 600,
          },
        },
      },
    },
  },
  terraformls = {},
  -- NOTE: presently enabled via typescript-tools
  tinymist = {},

  -- ts_ls = {
  --   cmd = { "typescript-language-server", "--stdio" },
  --   filetypes = {
  --     "javascript",
  --     "javascriptreact",
  --     "javascript.jsx",
  --     "typescript",
  --     "typescriptreact",
  --     "typescript.tsx",
  --     "vue",
  --   },
  --   -- workspace_required = true,
  --   root_dir = function(_, on_dir)
  --     on_dir(not vim.fs.root(0, { ".flowconfig", "deno.json", "deno.jsonc" }) and vim.fs.root(0, {
  --       "tsconfig.json",
  --       "jsconfig.json",
  --       "package.json",
  --       ".git",
  --       vim.api.nvim_buf_get_name(0),
  --     }))
  --   end,
  -- },
  -- ts_ls = {
  --
  --   init_options = { hostInfo = "neovim" },
  --   cmd = { "typescript-language-server", "--stdio" },
  --   filetypes = {
  --     "javascript",
  --     "javascriptreact",
  --     "javascript.jsx",
  --     "typescript",
  --     "typescriptreact",
  --     "typescript.tsx",
  --     "vue",
  --   },
  --   root_dir = function(bufnr, on_dir)
  --     -- The project root is where the LSP can be started from
  --     -- As stated in the documentation above, this LSP supports monorepos and simple projects.
  --     -- We select then from the project root, which is identified by the presence of a package
  --     -- manager lock file.
  --     local root_markers = { "package-lock.json", "yarn.lock", "pnpm-lock.yaml", "bun.lockb", "bun.lock" }
  --     -- Give the root markers equal priority by wrapping them in a table
  --     root_markers = vim.fn.has("nvim-0.11.3") == 1 and { root_markers, { ".git" } }
  --       or vim.list_extend(root_markers, { ".git" })
  --     -- We fallback to the current working directory if no project root is found
  --     local project_root = vim.fs.root(bufnr, root_markers) or vim.fn.getcwd()
  --
  --     on_dir(project_root)
  --   end,
  --   handlers = {
  --     -- handle rename request for certain code actions like extracting functions / types
  --     ["_typescript.rename"] = function(_, result, ctx)
  --       local client = assert(vim.lsp.get_client_by_id(ctx.client_id))
  --       vim.lsp.util.show_document({
  --         uri = result.textDocument.uri,
  --         range = {
  --           start = result.position,
  --           ["end"] = result.position,
  --         },
  --       }, client.offset_encoding)
  --       vim.lsp.buf.rename()
  --       return vim.NIL
  --     end,
  --   },
  --   commands = {
  --     ["editor.action.showReferences"] = function(command, ctx)
  --       local client = assert(vim.lsp.get_client_by_id(ctx.client_id))
  --       local file_uri, position, references = unpack(command.arguments)
  --
  --       local quickfix_items = vim.lsp.util.locations_to_items(references, client.offset_encoding)
  --       vim.fn.setqflist({}, " ", {
  --         title = command.title,
  --         items = quickfix_items,
  --         context = {
  --           command = command,
  --           bufnr = ctx.bufnr,
  --         },
  --       })
  --
  --       vim.lsp.util.show_document({
  --         uri = file_uri,
  --         range = {
  --           start = position,
  --           ["end"] = position,
  --         },
  --       }, client.offset_encoding)
  --
  --       vim.cmd("botright copen")
  --     end,
  --   },
  --   on_attach = function(client, bufnr)
  --     -- ts_ls provides `source.*` code actions that apply to the whole file. These only appear in
  --     -- `vim.lsp.buf.code_action()` if specified in `context.only`.
  --     vim.api.nvim_buf_create_user_command(bufnr, "LspTypescriptSourceAction", function()
  --       local source_actions = vim.tbl_filter(function(action)
  --         return vim.startswith(action, "source.")
  --       end, client.server_capabilities.codeActionProvider.codeActionKinds)
  --
  --       vim.lsp.buf.code_action({
  --         context = {
  --           only = source_actions,
  --         },
  --       })
  --     end, {})
  --   end,
  -- },
  tsgo = {
    cmd = { "tsgo", "--lsp", "--stdio" },
    filetypes = {
      "javascript",
      "javascriptreact",
      "javascript.jsx",
      "typescript",
      "typescriptreact",
      "typescript.tsx",
    },
    root_dir = function(bufnr, on_dir)
      -- The project root is where the LSP can be started from
      -- As stated in the documentation above, this LSP supports monorepos and simple projects.
      -- We select then from the project root, which is identified by the presence of a package
      -- manager lock file.
      local root_markers = { "package-lock.json", "yarn.lock", "pnpm-lock.yaml", "bun.lockb", "bun.lock" }
      -- Give the root markers equal priority by wrapping them in a table
      root_markers = vim.fn.has("nvim-0.11.3") == 1 and { root_markers, { ".git" } }
        or vim.list_extend(root_markers, { ".git" })
      -- We fallback to the current working directory if no project root is found
      local project_root = vim.fs.root(bufnr, root_markers) or vim.fn.getcwd()

      on_dir(project_root)
    end,
  },
  -- tsgo = {
  --   cmd = { "tsgo", "lsp", "--stdio" },
  --   filetypes = { "typescript", "javascript", "vue" },
  --   workspace_required = true,
  --   root_dir = function(_, on_dir)
  --     on_dir(not vim.fs.root(0, { ".flowconfig", "deno.json", "deno.jsonc" }) and vim.fs.root(0, {
  --       "tsconfig.json",
  --       "jsconfig.json",
  --       "package.json",
  --       ".git",
  --       vim.api.nvim_buf_get_name(0),
  --     }))
  --   end,
  -- },
  typos_lsp = {
    filetypes = { "markdown" },
    cmd_env = { RUST_LOG = "error" },
    init_options = {
      -- Custom config. Used together with a config file found in the workspace or its parents,
      -- taking precedence for settings declared in both.
      -- Equivalent to the typos `--config` cli argument.
      -- config = '~/code/typos-lsp/crates/typos-lsp/tests/typos.toml',
      -- How typos are rendered in the editor, can be one of an Error, Warning, Info or Hint.
      -- Defaults to error.
      config = "~/.config/typos.toml",
      diagnosticSeverity = "Hint",
    },
  },
  vimls = { init_options = { isNeovim = true } },
  vtsls = {
    package = "vtsls",
    settings = {
      vtsls = {
        enableMoveToFileCodeAction = true,
        autoUseWorkspaceTsdk = true,
      },
      typescript = {
        updateImportsOnFileMove = { enabled = "always" },
        suggest = { completeFunctionCalls = true },
        inlayHints = {
          -- Disable to save some memory
          parameterNames = { enabled = "none" },
          propertyDeclarationTypes = { enabled = false },
          variableTypes = { enabled = false },
        },
      },
    },
  },
  --- https://github.com/golang/tools/blob/master/gopls/doc/settings.md
  yamlls = function()
    local ok_schemastore = pcall(require, "schemastore")

    return {
      settings = {
        yaml = {
          format = { enable = true },
          validate = true,
          hover = true,
          completion = true,
          schemas = ok_schemastore and require("schemastore").json.schemas() or {},
          customTags = {
            "!reference sequence", -- necessary for gitlab-ci.yaml files
          },
        },
      },
    }
  end,
}

return M

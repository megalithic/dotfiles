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
  lexical = function()
    if not U.lsp.is_enabled_elixir_ls("lexical") then return false end

    return {
      manual_install = true,
      cmd = { vim.env.XDG_DATA_HOME .. "/lsp/lexical/_build/dev/package/lexical/bin/start_lexical.sh" },
      single_file_support = true,
      filetypes = { "elixir", "eelixir", "heex", "surface" },
      -- root_dir = function(fname)
      --   local matches = vim.fs.find({ "mix.exs" }, { upward = true, limit = 2, path = fname })
      --   local child_or_root_path, maybe_umbrella_path = unpack(matches)
      --   local root_dir = vim.fs.dirname(maybe_umbrella_path or child_or_root_path)

      --   -- right now i just want lexical for handling eelixir files (aka .exs files);
      --   -- if string.match(fname, "%.exs") ~= nil then return root_dir end

      --   return root_dir
      -- end,
      settings = { dialyzerEnabled = true },
      root_markers = { "mix.exs", ".git" },
      -- root_dir = function(bufnr, on_dir) root_pattern(bufnr, on_dir, { "mix.exs", ".git" }) end,

      root_dir = function(bufnr, on_dir)
        local fname = vim.api.nvim_buf_get_name(bufnr)
        local matches = vim.fs.find({ "mix.exs" }, { upward = true, limit = 2, path = fname })
        local child_or_root_path, maybe_umbrella_path = unpack(matches)
        local root_dir = vim.fs.dirname(maybe_umbrella_path or child_or_root_path)

        on_dir(root_dir)
      end,
    }
  end,
  elixirls = function()
    if not U.lsp.is_enabled_elixir_ls("elixirls") then return false end

    return {
      manual_install = true,
      cmd = { string.format("%s/lsp/elixir-ls/%s", vim.env.XDG_DATA_HOME, "language_server.sh") },
      filetypes = { "elixir", "eelixir", "heex", "surface" },
      root_markers = { "mix.exs", ".git" },
      root_dir = function(bufnr, on_dir)
        local fname = vim.api.nvim_buf_get_name(bufnr)
        local matches = vim.fs.find({ "mix.exs" }, { upward = true, limit = 2, path = fname })
        local child_or_root_path, maybe_umbrella_path = unpack(matches)
        local root_dir = vim.fs.dirname(maybe_umbrella_path or child_or_root_path)

        on_dir(root_dir)
      end,
      single_file_support = true,
      settings = {
        elixirLS = {
          mixEnv = "dev",
          mixTarget = "host",
          autoBuild = true,
          fetchDeps = true,
          dialyzerEnabled = false,
          dialyzerFormat = "dialyxir_long",
          incrementalDialyzer = false,
          enableTestLenses = true,
          dotFormatter = nil,
          suggestSpecs = true,
          autoInsertRequiredAlias = true,
          signatureAfterComplete = true,
        },
      },
    }
  end,
  expert = function()
    if not U.lsp.is_enabled_elixir_ls("expert") then return false end

    return {
      manual_install = true,
      cmd = { string.format("%s/lsp/expert/%s", vim.env.XDG_DATA_HOME, "expert_darwin_arm64") },
      filetypes = { "elixir", "eelixir", "heex", "surface" },
      root_markers = { "mix.exs", ".git" },
      root_dir = function(bufnr, on_dir)
        local fname = vim.api.nvim_buf_get_name(bufnr)
        local matches = vim.fs.find({ "mix.exs" }, { upward = true, limit = 2, path = fname })
        local child_or_root_path, maybe_umbrella_path = unpack(matches)
        local root_dir = vim.fs.dirname(maybe_umbrella_path or child_or_root_path)

        on_dir(root_dir)
      end,
      single_file_support = true,
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
        vim.list_extend(new_config.settings.json.schemas, ok_schemastore and require("schemastore").json.schemas() or {})
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
  emmylua_ls = {},
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
      enabled = false,
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
            library = { vim.fn.expand("$VIMRUNTIME/lua"), plugins, plenary, hammerspoon, wezterm, vim.api.nvim_get_runtime_file("", true) },
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
  markdown_oxide = function()
    if vim.g.note_taker ~= "markdown_oxide" then return nil end

    return (vim.g.started_by_firenvim or vim.env.TMUX_POPUP) and nil
      or {
        capabilities = {
          workspace = {
            didChangeWatchedFiles = {
              dynamicRegistration = true,
            },
          },
        },
      }
  end,
  marksman = function()
    if vim.g.note_taker ~= "marksman" then return nil end

    return (vim.g.started_by_firenvim or vim.env.TMUX_POPUP) and nil
      or {
        single_file_support = false,
        capabilities = {
          workspace = {
            didChangeWatchedFiles = {
              dynamicRegistration = true,
            },
          },
        },
        -- on_attach = function(client, bufnr)
        --   default_on_attach(client, bufnr, function()
        --     if string.match(vim.fn.expand("%:p:h"), "_notes") then
        --       vim.keymap.set(
        --         "n",
        --         "<leader>ff",
        --         function() mega.picker.find_files({ cwd = vim.g.notes_path }) end,
        --         { desc = "[f]ind in [n]otes", buffer = bufnr }
        --       )

        --       vim.keymap.set("n", "gd", "<cmd>lua vim.lsp.buf.definition()<CR>", { desc = "[g]o to note [d]efinition", noremap = true, buffer = bufnr })

        --       vim.keymap.set("n", "g.", function()
        --         local note_title = require("config.utils").notes.get_md_link_dest()
        --         if note_title == nil or note_title == "" then
        --           vim.notify("Unable to create new note from link text", L.WARN)
        --           return
        --         end

        --         os.execute("note -c " .. note_title)
        --         vim.diagnostic.enable(false)
        --         vim.cmd("LspRestart " .. client.name)
        --         vim.defer_fn(function() vim.diagnostic.enable(true) end, 50)
        --       end, { desc = "[g]o create note from link title", buffer = bufnr })
        --     end
        --   end)
        -- end,
      }
  end,
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

      return { fmt("%s/lsp/next-ls/burrito_out/%s", vim.env.XDG_DATA_HOME, build_bin), "--stdio" }
      -- return { fmt("%s/lsp/bin/nextls", vim.env.XDG_DATA_HOME), "--stdio" }
    end

    local homebrew_enabled = false

    return {
      manual_install = true,
      cmd = cmd(homebrew_enabled),
      single_file_support = true,
      filetypes = { "elixir", "eelixir", "heex", "surface" },
      root_dir = function(bufnr, on_dir)
        local fname = vim.api.nvim_buf_get_name(bufnr)
        local matches = vim.fs.find({ "mix.exs" }, { upward = true, limit = 2, path = fname })
        local child_or_root_path, maybe_umbrella_path = unpack(matches)
        local root_dir = vim.fs.dirname(maybe_umbrella_path or child_or_root_path)

        on_dir(root_dir)
      end,
      root_markers = { "mix.exs", ".git" },
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
  nil_ls = {},
  -- TODO: nil -> nixd
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
  tailwindcss = {},
  -- tailwindcss = function()
  --   -- bypasses my config and uses tailwind-tools instead..
  --   if package.loaded["tailwind-tools"] ~= nil then return nil end

  --   return {
  --     manual_install = true,
  --     cmd = { "tailwindcss-language-server", "--stdio" },
  --     filetypes = {
  --       "aspnetcorerazor",
  --       "astro",
  --       "astro-markdown",
  --       "blade",
  --       "clojure",
  --       "django-html",
  --       "htmldjango",
  --       "edge",
  --       "eelixir",
  --       "elixir",
  --       "ejs",
  --       "erb",
  --       "eruby",
  --       "gohtml",
  --       "gohtmltmpl",
  --       "haml",
  --       "handlebars",
  --       "hbs",
  --       "html",
  --       "htmlangular",
  --       "html-eex",
  --       "heex",
  --       "jade",
  --       "leaf",
  --       "liquid",
  --       -- "markdown",
  --       "mdx",
  --       "mustache",
  --       "njk",
  --       "nunjucks",
  --       "php",
  --       "razor",
  --       "slim",
  --       "twig",
  --       "phoenix-heex",
  --       "css",
  --       "less",
  --       "postcss",
  --       "sass",
  --       "scss",
  --       "stylus",
  --       "sugarss",
  --       "javascript",
  --       "javascriptreact",
  --       "reason",
  --       "rescript",
  --       "typescript",
  --       "typescriptreact",
  --       "vue",
  --       "svelte",
  --       "templ",
  --     },
  --     -- init_options = {
  --     --   userLanguages = {
  --     --     eruby = "erb",
  --     --     eelixir = "html-eex",
  --     --     elixir = "phoenix-heex",
  --     --     heex = "phoenix-heex",
  --     --     -- elixir = "html-eex",
  --     --     -- eelixir = "html-eex",
  --     --     -- heex = "html-eex",
  --     --   },
  --     -- },
  --     filetypes_include = { "heex" },
  --     settings = {
  --       tailwindCSS = {
  --         validate = true,
  --         lint = {
  --           cssConflict = "warning",
  --           invalidApply = "error",
  --           invalidScreen = "error",
  --           invalidVariant = "error",
  --           invalidConfigPath = "error",
  --           invalidTailwindDirective = "error",
  --           recommendedVariantOrder = "warning",
  --         },
  --         classAttributes = {
  --           "class",
  --           "classes",
  --           "additional_classes",
  --           "additional_class",
  --           "className",
  --           "class:list",
  --           "classList",
  --           "ngClass",
  --         },
  --         includeLanguages = {
  --           eruby = "erb",
  --           eelixir = "html-eex",
  --           elixir = "phoenix-heex",
  --           heex = "phoenix-heex",
  --           -- elixir = "html-eex",
  --           -- eelixir = "html-eex",
  --           -- heex = "html-eex",
  --         },
  --         experimental = {
  --           configFile = "",
  --           classRegex = {
  --             [[class="([^"]*)]],
  --             [[additional_classes="([^"]*)]],
  --             [[class:"([^"]*)]],

  --             -- [[class= "([^"]*)]],
  --             -- [[*class= "([^"]*)]],
  --             -- [[*_class= "([^"]*)]],
  --             -- [[class: "([^"]*)]],
  --             -- [[classes= "([^"]*)]],
  --             -- [[*classes= "([^"]*)]],
  --             -- [[*_classes= "([^"]*)]],
  --             -- [[classes: "([^"]*)]],

  --             [[~H""".*class="([^"]*)".*"""]],
  --             [[~H""".*additional_classes="([^"]*)".*"""]],
  --             "~H\"\"\".*class=\"([^\"]*)\".*\"\"\"",
  --             "~H\"\"\".*additional_classes=\"([^\"]*)\".*\"\"\"",
  --           },
  --         },
  --       },
  --     },
  --     before_init = function(_, config)
  --       if not config.settings then config.settings = {} end
  --       if not config.settings.editor then config.settings.editor = {} end
  --       if not config.settings.editor.tabSize then config.settings.editor.tabSize = vim.lsp.util.get_effective_tabstop() end
  --     end,
  --     workspace_required = true,
  --     -- root_dir = function(bufnr, on_dir)
  --     --   local util = require("lspconfig.util")
  --     --   local fname = vim.api.nvim_buf_get_name(bufnr)

  --     --   local root_files = {
  --     --     -- Generic
  --     --     "tailwind.config.js",
  --     --     "tailwind.config.cjs",
  --     --     "tailwind.config.mjs",
  --     --     "tailwind.config.ts",
  --     --     "postcss.config.js",
  --     --     "postcss.config.cjs",
  --     --     "postcss.config.mjs",
  --     --     "postcss.config.ts",
  --     --     -- Phoenix
  --     --     "assets/tailwind.config.js",
  --     --     "assets/tailwind.config.cjs",
  --     --     "assets/tailwind.config.mjs",
  --     --     "assets/tailwind.config.ts",
  --     --     -- Django
  --     --     "theme/static_src/tailwind.config.js",
  --     --     "theme/static_src/tailwind.config.cjs",
  --     --     "theme/static_src/tailwind.config.mjs",
  --     --     "theme/static_src/tailwind.config.ts",
  --     --     "theme/static_src/postcss.config.js",
  --     --     -- Rails
  --     --     "app/assets/stylesheets/application.tailwind.css",
  --     --     "app/assets/tailwind/application.css",
  --     --   }

  --     --   local elixir_root_dir = root_pattern(bufnr, on_dir, { "mix.exs" })
  --     --   root_files = util.insert_package_json(root_files, "tailwindcss", fname)
  --     --   root_files = util.root_markers_with_field(root_files, { "mix.exs" }, "tailwind", fname)

  --     --   -- P(vim.fs.dirname(vim.fs.find(root_matches or root_files, { path = fname, upward = true })[1]))
  --     --   on_dir(vim.fs.dirname(vim.fs.find(root_matches or root_files, { path = fname, upward = true })[1]))
  --     -- end,
  --   }
  -- end,
  terraformls = {},
  -- NOTE: presently enabled via typescript-tools
  tinymist = {},
  ts_ls = {},
  vimls = { init_options = { isNeovim = true } },
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

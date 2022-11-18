-----------------------------------------------------------------------------//
-- Language servers
-----------------------------------------------------------------------------//
local fn, fmt, lsp = vim.fn, string.format, vim.lsp
local ok_lsp, lspconfig = mega.require("lspconfig")
if not ok_lsp then return end
local lsputil = require("lspconfig.util")

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
  local joined_path = lsputil.path.join(dir, name)
  return lsputil.path.exists(joined_path), joined_path
end

local function workspace_root()
  local cwd = vim.loop.cwd()

  if dir_has_file(cwd, "compose.yml") or dir_has_file(cwd, "docker-compose.yml") then return cwd end

  local function cb(dir, _) return dir_has_file(dir, "compose.yml") or dir_has_file(dir, "docker-compose.yml") end

  local root, _ = lsputil.path.traverse_parents(cwd, cb)
  return root
end

local function get_root()
  local root = workspace_root()
  if not root then root = vim.loop.cwd() end

  return root
end

local function workspace_has_file(path)
  local root = get_root()
  if vim.tbl_contains({ "~", "/" }, path:sub(1, 1)) then return true, path end
  return dir_has_file(root, path)
end

local function lsp_cmd_override(cmd_paths, args)
  args = args or {}
  if type(cmd_paths) == "string" then cmd_paths = { cmd_paths } end

  for _, path in ipairs(cmd_paths) do
    local exists, dir = workspace_has_file(path)
    if exists then
      -- vim.notify(fmt("lsp cmd: %s", vim.fn.expand(dir)), vim.log.levels.INFO, { title = "lsp" })
      return vim.list_extend({ vim.fn.expand(dir) }, args)
    end
  end
end

-- This function allows reading a per project "settings.json" file in the `.vim` directory of the project.
---@param client table<string, any>
---@return boolean
local function on_init(client)
  local settings = client.workspace_folders[1].name .. "/.vim/settings.json"

  if fn.filereadable(settings) == 0 then return true end
  local ok, json = pcall(fn.readfile, settings)
  if not ok then return true end

  local overrides = vim.json.decode(table.concat(json, "\n"))

  for name, config in pairs(overrides) do
    if name == client.name then
      client.config = vim.tbl_deep_extend("force", client.config, config)
      client.notify("workspace/didChangeConfiguration")

      vim.schedule(function()
        local path = fn.fnamemodify(settings, ":~:.")
        local msg = fmt("loaded local settings for %s from %s", client.name, path)
        vim.notify_once(msg, vim.log.levels.INFO, { title = "LSP Settings" })
      end)
    end
  end
  return true
end

local servers = {
  ccls = true,
  cssls = {
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
  elixirls = function()
    return {
      cmd = lsp_cmd_override({
        ".elixir-ls-release/language_server.sh",
        fmt("%s/lsp/elixir-ls/%s", vim.env.XDG_DATA_HOME, "language_server.sh"),
        "elixir-ls",
      }),
      settings = {
        elixirLS = {
          mixEnv = "test",
          fetchDeps = true,
          dialyzerEnabled = true,
          dialyzerFormat = "dialyxir_short",
          enableTestLenses = false,
          suggestSpecs = true,
        },
      },
    }
  end,
  elmls = true,
  emmet_ls = {
    settings = {
      includeLanguages = {
        ["html-eex"] = "html",
        ["phoenix-heex"] = "html",
        eruby = "html",
      },
    },
  },
  html = {
    filetypes = {
      "html",
      "javascriptreact",
      "typescriptreact",
      "eelixir",
      "html.heex",
      "heex",
      "html_heex",
      "html_eex",
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
        arguments = { api.nvim_buf_get_name(0) },
        title = "",
      }
      lsp.buf.execute_command(params)
    end

    return {
      cmd = lsp_cmd_override({ ".bin/typescript-language-server", "typescript-language-server" }, { "stdio" }),
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
  graphql = true,
  jsonls = {
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
  },
  bashls = true,
  vimls = { init_options = { isNeovim = true } },
  terraformls = true,
  rust_analyzer = true,
  marksman = true,
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
  prosemd_lsp = true,
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
  sumneko_lua = function()
    local path = vim.split(package.path, ";")
    table.insert(path, "lua/?.lua")
    table.insert(path, "lua/?/init.lua")

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
            unusedLocalExclude = { "_*" },
          },
          completion = { keywordSnippet = "Replace", callSnippet = "Replace" },
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
  if nvim_lsp_ok then capabilities = cmp_nvim_lsp.default_capabilities(capabilities) end

  -- local nvim_tokens_ok, nvim_semantic_tokens = mega.require("nvim-semantic-tokens")
  -- if nvim_tokens_ok then capabilities = nvim_semantic_tokens.update_capabilities(capabilities) end

  return capabilities
end

---Get the configuration for a specific language server
---@param name string
---@return table<string, any>?
return function(name)
  local config = servers[name]
  if not config then return end
  local t = type(config)
  if t == "boolean" then config = {} end
  if t == "function" then config = config() end
  config.on_init = on_init
  config.flags = { debounce_text_changes = 150 }
  -- config.capabilities = config.capabilities or vim.lsp.protocol.make_client_capabilities()
  -- config.capabilities.textDocument.foldingRange = { dynamicRegistration = false, lineFoldingOnly = true }
  -- local ok, cmp_nvim_lsp = mega.require("cmp_nvim_lsp")
  -- if ok then cmp_nvim_lsp.default_capabilities(config.capabilities) end
  config.capabilities = get_server_capabilities()
  return config
end

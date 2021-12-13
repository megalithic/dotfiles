---@diagnostic disable-next-line: unused-local

local vcmd, lsp, api, fn, set = vim.cmd, vim.lsp, vim.api, vim.fn, vim.opt
local map, bufmap, bmap, au = mega.map, mega.bufmap, mega.bmap, mega.au
local lspconfig = require("lspconfig")
local utils = require("utils")

set.completeopt = { "menu", "menuone", "noselect", "noinsert" }
set.shortmess:append("c") -- Don't pass messages to |ins-completion-menu|

local function setup_diagnostics()
  -- LSP signs default
  fn.sign_define("DiagnosticSignError", { texthl = "DiagnosticSignError", text = "", numhl = "DiagnosticSignError" })
  fn.sign_define("DiagnosticSignWarn", { texthl = "DiagnosticSignWarn", text = "", numhl = "DiagnosticSignWarn" })
  fn.sign_define("DiagnosticSignInfo", { texthl = "DiagnosticSignInfo", text = "", numhl = "DiagnosticSignInfo" })
  fn.sign_define("DiagnosticSignHint", { texthl = "DiagnosticSignHint", text = "", numhl = "DiagnosticSignHint" })

  -- NOTE: recent updates to neovim vim.lsp.diagnostic to vim.diagnostic:
  -- REF: https://github.com/neovim/neovim/pull/15585
  vim.diagnostic.config({
    underline = true,
    virtual_text = false,
    signs = true, -- {severity_limit = "Warning"},
    update_in_insert = false,
    severity_sort = true,
    float = {
      show_header = true,
      source = "if_many",
      border = "single",
      focusable = false,
      severity_sort = true,
    },
  })

  --- This overwrites the diagnostic show/set_signs function to replace it with a custom function
  --- that restricts nvim's diagnostic signs to only the single most severe one per line
  local ns = api.nvim_create_namespace("severe-diagnostics")
  local show = vim.diagnostic.show
  local function display_signs(bufnr)
    -- Get all diagnostics from the current buffer
    local diagnostics = vim.diagnostic.get(bufnr)
    local filtered = utils.lsp.filter_diagnostics(diagnostics, bufnr)
    show(ns, bufnr, filtered, {
      virtual_text = false,
      underline = false,
      signs = true,
    })
  end

  function vim.diagnostic.show(namespace, bufnr, ...)
    show(namespace, bufnr, ...)
    display_signs(bufnr)
  end
end

-- some of our custom LSP handlers
local function setup_lsp_handlers()
  -- local border_opts = { border = "single", focusable = false, scope = "line" }
  -- hover
  -- NOTE: the hover handler returns the bufnr,winnr so can be used for mappings
  lsp.handlers["textDocument/hover"] = lsp.with(vim.lsp.handlers.hover, {
    border = "single",
    max_width = math.max(math.floor(vim.o.columns * 0.7), 100),
    max_height = math.max(math.floor(vim.o.lines * 0.3), 30),
  })

  -- lsp.handlers["textDocument/signatureHelp"] = lsp.with(lsp.handlers.signature_help, border_opts)
end

-- our on_attach function to pass to each language server config..
local function on_attach(client, bufnr)
  if client.config.flags then
    client.config.flags.allow_incremental_sync = true
  end

  require("lsp-status").on_attach(client)
  utils.lsp.format_setup(client, bufnr)

  require("lsp_signature").on_attach({
    bind = true,
    fix_pos = function(signatures, _client)
      if signatures[1].activeParameter >= 0 and #signatures[1].parameters == 1 then
        return false
      end
      if _client.name == "sumneko_lua" then
        return true
      end
      return false
    end,
    auto_close_after = 15, -- close after 15 seconds
    hint_enable = false,
    handler_opts = { border = "rounded" },
  })

  --- # goto mappings
  if pcall(require, "fzf-lua") then
    --- # via fzf-lua
    --  * https://github.com/ibhagwan/fzf-lua/issues/39#issuecomment-897099304 (LSP async/sync)
    bmap("n", "gd", "lua require('fzf-lua').lsp_definitions()", { label = "lsp: go to definition" })
    bmap("n", "gD", "lua require('utils').lsp.preview('textDocument/definition')")
    bmap("n", "gr", "lua require('fzf-lua').lsp_references()", { label = "lsp: go to references" })
    bmap("n", "gt", "lua require('fzf-lua').lsp_typedefs()", { label = "lsp: go to type definitions" })
    bmap("n", "gs", "lua require('fzf-lua').lsp_document_symbols()", { label = "lsp: go to document symbols" })
    bmap("n", "gw", "lua require('fzf-lua').lsp_workspace_symbols()", { label = "lsp: go to workspace symbols" })
    bmap("n", "gi", "lua require('fzf-lua').lsp_implementations()", { label = "lsp: go to implementations" })
    bmap("n", "<leader>la", "lua require('fzf-lua').lsp_code_actions()", { label = "lsp: go to code actions" })
    bmap("n", "<leader>ca", "lua require('fzf-lua').lsp_code_actions()", { label = "lsp: go to code actions" })
  else
    -- # via defaults
    bufmap("gd", "lua vim.lsp.buf.definition()")
    bufmap("gr", "lua vim.lsp.buf.references()")
    bufmap("gs", "lua vim.lsp.buf.document_symbol()")
    bufmap("gi", "lua vim.lsp.buf.implementation()")
    bufmap("<leader>la", "lua vim.lsp.buf.code_action()")
  end

  --- # diagnostics navigation mappings
  bmap("n", "[d", "lua vim.diagnostic.goto_prev()", { label = "lsp: jump to prev diagnostic" })
  bmap("n", "]d", "lua vim.diagnostic.goto_next()", { label = "lsp: jump to next diagnostic" })
  bmap("n", "[e", "lua vim.diagnostic.goto_prev({severity = vim.diagnostic.severity.ERROR})")
  bmap("n", "]e", "lua vim.diagnostic.goto_next({severity = vim.diagnostic.severity.ERROR})")

  --- # misc mappings
  bmap("n", "<leader>ln", "lua require('utils').lsp.rename()", { label = "lsp: rename document symbol" })
  bmap("n", "<leader>ld", "lua require('utils').lsp.line_diagnostics()", { label = "lsp: show line diagnostics" })
  -- bufmap(
  --   "<leader>ld",
  --   [[lua vim.diagnostic.open_float(0, {scope='line', close_events = { "CursorMoved", "CursorMovedI", "BufHidden", "InsertCharPre", "BufLeave" }})]]
  -- )
  bufmap("K", "lua vim.lsp.buf.hover()")
  bufmap("<C-k>", "<cmd>lua vim.lsp.buf.signature_help()<cr>", "i")
  bufmap("<leader>lf", "lua require('utils').lsp.format()")

  if client.resolved_capabilities.code_lens then
    bufmap("<leader>ll", "lua vim.lsp.codelens.run()")
  end

  --- # trouble mappings
  nmap(
    "<leader>lt",
    "<cmd>LspTroubleToggle lsp_document_diagnostics<cr>",
    { label = "lsp: toggle LspTrouble for document" }
  )

  --- # autocommands/autocmds
  au([[CursorHold,CursorHoldI <buffer> lua require('utils').lsp.line_diagnostics()]])
  au([[CursorMoved,BufLeave <buffer> lua vim.lsp.buf.clear_references()]])
  vcmd([[command! FormatDisable lua require('utils').lsp.formatToggle(true)]])
  vcmd([[command! FormatEnable lua require('utils').lsp.formatToggle(false)]])

  if client.resolved_capabilities.code_lens then
    au("CursorHold,CursorHoldI,InsertLeave <buffer> lua vim.lsp.codelens.refresh()")
  end

  --- # commands
  FormatRange = function()
    local start_pos = api.nvim_buf_get_mark(0, "<")
    local end_pos = api.nvim_buf_get_mark(0, ">")
    lsp.buf.range_formatting({}, start_pos, end_pos)
  end
  vcmd([[ command! -range FormatRange execute 'lua FormatRange()' ]])
  vcmd([[ command! Format execute 'lua vim.lsp.buf.formatting_sync(nil, 1000)' ]])
  vcmd([[ command! LspLog lua vim.cmd('vnew'..vim.lsp.get_log_path()) ]])

  --- # ls client-specific configs
  -- (zk)
  if client.name == "zk" then
    au([[BufNewFile,BufWritePost <buffer> call jobstart('zk index') ]])
    bufmap("<CR>", "<cmd>'<,'>lua vim.lsp.buf.range_code_action()<CR>", "v")
    bufmap("<CR>", "lua vim.lsp.buf.definition()")
    bufmap("K", "lua vim.lsp.buf.hover()")

    -- REF: special thanks @mhanberg ->
    -- https://github.com/mhanberg/.dotfiles/blob/main/config/nvim/lua/plugin/zk.lua
  end

  -- disable formatting for the following language-server clients:
  local disabled_formatting_ls = { "jsonls", "tailwindcss", "html" }
  for i = 1, #disabled_formatting_ls do
    if disabled_formatting_ls[i] == client.name then
      client.resolved_capabilities.document_formatting = false
      client.resolved_capabilities.document_range_formatting = false
    end
  end

  -- (typescript/tsserver)
  if client.name == "tsserver" then
    local ts = require("nvim-lsp-ts-utils")
    ts.setup({
      debug = false,
      disable_commands = false,
      enable_import_on_completion = false,
      import_on_completion_timeout = 5000,

      -- linting
      eslint_enable_code_actions = true,
      eslint_enable_disable_comments = true,
      eslint_bin = "eslint_d",
      eslint_enable_diagnostics = true,
      eslint_opts = {},

      -- formatting
      enable_formatting = false,
      formatter = "prettierd",
      formatter_opts = {},

      -- filter diagnostics
      -- {
      --    80001 - require modules
      --    6133 - import is declared but never used
      --    2582 - cannot find name {describe, test}
      --    2304 - cannot find name {expect, beforeEach, afterEach}
      --    2503 - cannot find name {jest}
      -- }
      filter_out_diagnostics_by_code = { 80001, 2582, 2304, 2503 },

      -- inlay hints
      auto_inlay_hints = true,
      inlay_hints_highlight = "Comment",
    })

    ts.setup_client(client)
  end

  api.nvim_buf_set_option(bufnr, "omnifunc", "v:lua.vim.lsp.omnifunc")
end

local function setup_lsp_capabilities()
  local capabilities = vim.lsp.protocol.make_client_capabilities()
  capabilities = require("cmp_nvim_lsp").update_capabilities(capabilities)
  capabilities = vim.tbl_extend("keep", capabilities or {}, require("lsp-status").capabilities)
  capabilities.textDocument.codeLens = { dynamicRegistration = false }
  capabilities.textDocument.completion.completionItem.documentationFormat = { "markdown" }
  return capabilities
end

local function setup_lsp_servers()
  local function lsp_with_defaults(opts)
    opts = opts or {}
    local lsp_config = vim.tbl_deep_extend("keep", opts, {
      autorstart = true,
      on_attach = on_attach,
      capabilities = setup_lsp_capabilities(),
      flags = { debounce_text_changes = 150 },
      root_dir = vim.loop.cwd,
    })

    return lsp_config
  end

  local function root_pattern(...)
    local patterns = vim.tbl_flatten({ ... })

    return function(startpath)
      for _, pattern in ipairs(patterns) do
        return lspconfig.util.search_ancestors(startpath, function(path)
          if lspconfig.util.path.exists(fn.glob(lspconfig.util.path.join(path, pattern))) then
            return path
          end
        end)
      end
    end
  end

  local servers = {
    "bashls",
    "clangd",
    -- "dockerfile",
    "elmls",
    "pyright",
    "rust_analyzer",
    "tailwindcss",
    "vimls",
  }
  for _, ls in ipairs(servers) do
    -- handle language servers not installed/found; TODO: should probably handle
    -- logging/install them at some point
    if ls == nil or lspconfig[ls] == nil then
      mega.inspect("unable to setup ls", { ls })
      return
    end
    lspconfig[ls].setup(lsp_with_defaults())
  end

  -- local null-ls config
  require("lsp.null-ls").setup()
  lspconfig["null-ls"].setup(lsp_with_defaults())

  lspconfig["solargraph"].setup(lsp_with_defaults({
    cmd = { "solargraph", "stdio" },
    filetypes = { "ruby" },
    root_dir = root_pattern("Gemfile", ".git"),
    settings = {
      solargraph = {
        diagnostics = true,
        useBundler = true,
      },
    },
  }))

  lspconfig["yamlls"].setup(lsp_with_defaults({
    settings = {
      yaml = {
        format = { enable = true },
        validate = true,
        hover = true,
        completion = true,
      },
    },
  }))

  lspconfig["tailwindcss"].setup(lsp_with_defaults({
    -- TODO: https://github.com/sethlowie/dotfiles/blob/master/vim/lua/sethlowie/tailwind.lua
    cmd = { "tailwindcss-language-server", "--stdio" },
    init_options = {
      userLanguages = {
        eelixir = "html-eex",
        eruby = "erb",
        ["phoenix-html"] = "html-eex",
        ["phoenix-heex"] = "html-eex",
        heex = "html-eex",
      },
    },
    handlers = {
      ["tailwindcss/getConfiguration"] = function(_, _, context)
        -- tailwindcss lang server waits for this repsonse before providing hover
        vim.lsp.buf_notify(context.bufnr, "tailwindcss/getConfigurationResponse", { _id = context.params._id })
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
      -- tailwindCSS = {
      --   experimental = {
      --     classRegex = {
      --       -- REF:
      --       -- https://github.com/tailwindlabs/tailwindcss-intellisense/issues/129
      --       [[class: "([^"]*)]],
      --       'class="([^"]*)',
      --       "tw`([^`]*)",
      --       'tw="([^"]*)',
      --       'tw={"([^"}]*)',
      --       "tw\\.\\w+`([^`]*)",
      --       "tw\\(.*?\\)`([^`]*)",
      --       [["classnames\\(([^)]*)\\)", "'([^']*)'"]],
      --       [["%\\w+([^\\s]*)", "\\.([^\\.]*)"]],
      --       [[":class\\s*=>\\s*\"([^\"]*)"]],
      --       [["class:\\s+\"([^\"]*)"]],
      --       [[":\\s*?[\"'`]([^\"'`]*).*?,"]],
      --      "\\bclass\\s+\"([^\"]*)\""
      --     },
      --   },
      -- },
    },
    filetypes = {
      "elixir",
      "eelixir",
      "css",
      "scss",
      "sass",
      "html",
      "heex",
      "leex",
      "html-eex",
      "phoenix-html",
      "phoenix-eex",
      "phoenix-heex",
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
  }))

  do -- elixirls
    local manipulate_pipes = function(command)
      return function()
        local position_params = lsp.util.make_position_params()
        lsp.buf.execute_command({
          command = "manipulatePipes:" .. command,
          arguments = {
            command,
            position_params.textDocument.uri,
            position_params.position.line,
            position_params.position.character,
          },
        })
      end
    end

    lspconfig["elixirls"].setup(lsp_with_defaults({
      cmd = { utils.lsp.elixirls_cmd() },
      settings = {
        elixirLS = {
          fetchDeps = false,
          dialyzerEnabled = false,
          dialyzerFormat = "dialyxir_short",
          enableTestLenses = true,
          suggestSpecs = true,
        },
      },
      filetypes = { "elixir", "eelixir", "heex" },
      root_dir = root_pattern("mix.exs", ".git") or vim.loop.os_homedir(),
      commands = {
        ToPipe = { manipulate_pipes("toPipe"), "Convert function call to pipe operator" },
        FromPipe = { manipulate_pipes("fromPipe"), "Convert pipe operator to function call" },
      },
      -- on_init = function(client)
      --   client.notify("workspace/didChangeConfiguration")
      --   return true
      -- end,
    }))
  end

  do -- lua
    local sumneko_lua_settings = lsp_with_defaults({
      settings = {
        Lua = {
          completion = { keywordSnippet = "Replace", callSnippet = "Replace" }, -- or `Disable`
          runtime = {
            version = "LuaJIT",
            path = vim.split(package.path, ";"),
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
              -- mapx.lua:
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
              "mapbang",
              "noremapbang",
            },
          },
          workspace = {
            preloadFileSize = 500,
            maxPreload = 500,
            library = vim.api.nvim_get_runtime_file("", true),
            -- library = {
            --   [vim.fn.expand("$VIMRUNTIME/lua")] = true,
            --   [vim.fn.expand("$VIMRUNTIME/lua/vim/lsp")] = true,
            -- },
          },
          telemetry = {
            enable = false,
          },
        },
      },
    })
    local luadev = require("lua-dev").setup({
      lspconfig = sumneko_lua_settings,
    })
    lspconfig["sumneko_lua"].setup(luadev)
  end

  lspconfig["jsonls"].setup(lsp_with_defaults({
    cmd = { "vscode-json-language-server", "--stdio" },
    commands = {
      Format = {
        function()
          lsp.buf.range_formatting({}, { 0, 0 }, { fn.line("$"), 0 })
        end,
      },
    },
    settings = {
      json = {
        format = { enable = false },
        schemas = require("schemastore").json.schemas(),
      },
    },
  }))

  -- REF: https://github.com/microsoft/vscode/issues/103163
  --      - custom css linting rules and custom data
  lspconfig["cssls"].setup(lsp_with_defaults({
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
  }))
  lspconfig["html"].setup(lsp_with_defaults({
    cmd = { "vscode-html-language-server", "--stdio" },
    filetypes = { "html", "javascriptreact", "typescriptreact", "eelixir", "heex" },
    init_options = {
      configurationSection = { "html", "css", "javascript", "eelixir", "heex" },
      embeddedLanguages = {
        css = true,
        javascript = true,
        elixir = true,
        heex = true,
      },
    },
  }))

  do
    local function do_organize_imports()
      local params = {
        command = "_typescript.organizeImports",
        arguments = { api.nvim_buf_get_name(0) },
        title = "",
      }
      lsp.buf.execute_command(params)
    end
    lspconfig["tsserver"].setup(lsp_with_defaults({
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
    }))
  end

  do
    -- local configs = require("lspconfig/configs")
    -- configs.emmet_ls = {
    -- 	default_config = {
    -- 		cmd = { "emmet-ls", "--stdio" },
    -- 		filetypes = { "html", "css", "eelixir", "eruby", "javascriptreact", "typescriptreact" },
    -- 		root_dir = function(_)
    -- 			return vim.loop.cwd()
    -- 		end,
    -- 		settings = {},
    -- 	},
    -- }
    -- lspconfig.emmet_ls.setup(lsp_with_defaults())
  end

  do
    local configs = require("lspconfig/configs")
    configs.zk = {
      default_config = {
        cmd = { "zk", "lsp", "--log", "/tmp/zk-lsp.log" },
        filetypes = { "markdown" },
        root_dir = function(...)
          local dir = lspconfig.util.root_pattern(".zk/")(...)
            or lspconfig.util.root_pattern(".git/")(...)
            or vim.loop.cwd()
          return dir
        end,
        settings = {},
      },
    }

    -- # REF:
    --  * https://github.com/kaile256/dotfiles/blob/master/.config/nvim/lua/rc/lsp/config/ls/zk.lua
    --  * https://github.com/mhanberg/.dotfiles/blob/main/config/nvim/lua/plugin/zk.lua
    configs.zk.index = function()
      lsp.buf.execute_command({
        command = "zk.index",
        arguments = { api.nvim_buf_get_name(0) },
      })
    end

    configs.zk.new = function(...)
      lsp.buf_request(0, "workspace/executeCommand", {
        command = "zk.new",
        arguments = {
          api.nvim_buf_get_name(0),
          ...,
        },
      }, function(_, _, result)
        if not (result and result.path) then
          return
        end
        vcmd("vnew " .. result.path)
      end)
    end

    lspconfig["zk"].setup(lsp_with_defaults())
  end
end

setup_lsp_handlers()
setup_diagnostics()
require("lsp.completion").setup()
setup_lsp_servers()

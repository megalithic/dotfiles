---@diagnostic disable-next-line: unused-local

local vcmd, lsp, api, fn, set = vim.cmd, vim.lsp, vim.api, vim.fn, vim.opt
local bufmap, bmap, au, autocmd = mega.bufmap, mega.bmap, mega.au, mega.autocmd
local fmt = string.format
local lspconfig = require("lspconfig")
local utils = require("utils")

set.completeopt = { "menu", "menuone", "noselect", "noinsert" }
set.shortmess:append("c") -- Don't pass messages to |ins-completion-menu|

-- vim.lsp.set_log_level("trace")
require("vim.lsp.log").set_format_func(vim.inspect)

local function setup_diagnostics()
  fn.sign_define(vim.tbl_map(function(t)
    local hl = "DiagnosticSign" .. t[1]
    return {
      name = hl,
      text = t.icon,
      texthl = hl,
      numhl = hl,
      linehl = fmt("%sLine", hl),
    }
  end, utils.lsp.diagnostic_types))

  --- This overwrites the diagnostic show/set_signs function to replace it with a custom function
  --- that restricts nvim's diagnostic signs to only the single most severe one per line
  local ns = api.nvim_create_namespace("lsp-diagnostics")
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

  -- Monkey-patch vim.diagnostic.show() with our own impl to filter sign severity
  function vim.diagnostic.show(namespace, bufnr, ...)
    show(namespace, bufnr, ...)
    display_signs(bufnr)
  end

  -- Monkey-patch vim.diagnostic.open_float() with our own impl..
  -- REF: https://neovim.discourse.group/t/lsp-diagnostics-how-and-where-to-retrieve-severity-level-to-customise-border-color/1679
  vim.diagnostic.open_float = (function(orig)
    return function(bufnr, opts)
      local lnum = vim.api.nvim_win_get_cursor(0)[1] - 1
      opts = opts or {}
      -- A more robust solution would check the "scope" value in `opts` to
      -- determine where to get diagnostics from, but if you're only using
      -- this for your own purposes you can make it as simple as you like
      local diagnostics = vim.diagnostic.get(opts.bufnr or 0, { lnum = lnum })
      local max_severity = vim.diagnostic.severity.HINT
      for _, d in ipairs(diagnostics) do
        -- Equality is "less than" based on how the severities are encoded
        if d.severity < max_severity then
          max_severity = d.severity
        end
      end
      local border_color = ({
        [vim.diagnostic.severity.HINT] = "DiagnosticHint",
        [vim.diagnostic.severity.INFO] = "DiagnosticInfo",
        [vim.diagnostic.severity.WARN] = "DiagnosticWarn",
        [vim.diagnostic.severity.ERROR] = "DiagnosticError",
      })[max_severity]
      opts.border = mega.get_border(border_color)
      orig(bufnr, opts)
    end
  end)(vim.diagnostic.open_float)

  vim.diagnostic.config({
    underline = true,
    virtual_text = false,
    signs = true, -- {severity_limit = "Warning"},
    update_in_insert = false,
    severity_sort = true,
    float = {
      show_header = true,
      source = "if_many", -- or "always"
      border = mega.get_border(),
      focusable = false,
      severity_sort = true,
    },
  })
end

-- some of our custom LSP handlers
local function setup_lsp_handlers()
  -- hover
  -- NOTE: the hover handler returns the bufnr,winnr so can be used for mappings
  local opts = {
    border = mega.get_border(),
    max_width = math.max(math.floor(vim.o.columns * 0.7), 100),
    max_height = math.max(math.floor(vim.o.lines * 0.3), 30),
    focusable = false,
    silent = true,
    severity_sort = true,
    close_events = {
      "CursorMoved",
      "BufHidden",
      "InsertCharPre",
      "BufLeave",
      "InsertEnter",
      "FocusLost",
    },
  }
  lsp.handlers["textDocument/hover"] = lsp.with(vim.lsp.handlers.hover, opts)
  lsp.handlers["textDocument/signatureHelp"] = lsp.with(lsp.handlers.signature_help, opts)
  lsp.handlers["textDocument/publishDiagnostics"] = lsp.with(lsp.diagnostic.on_publish_diagnostics, opts)
end

-- our on_attach function to pass to each language server config..
local function on_attach(client, bufnr)
  if client.config.flags then
    client.config.flags.allow_incremental_sync = true
  end

  require("lsp-status").on_attach(client)
  utils.lsp.format_setup(client, bufnr)

  if client.resolved_capabilities.colorProvider then
    require("lsp.document_colors").buf_attach(bufnr, { single_column = true })
  end

  -- if client.resolved_capabilities.document_highlight then
  --   -- TODO: do we want this?
  --     api.nvim_exec(
  --       [[
  --     hi LspReferenceRead cterm=bold ctermbg=red guibg=#464646
  --     hi LspReferenceText cterm=bold ctermbg=red guibg=#464646
  --     hi LspReferenceWrite cterm=bold ctermbg=red guibg=#464646
  --     augroup lsp_document_highlight
  --       autocmd! * <buffer>
  --       autocmd CursorHold <buffer> lua vim.lsp.buf.document_highlight()
  --       autocmd CursorMoved <buffer> lua vim.lsp.buf.clear_references()
  --     augroup END
  --   ]],
  --       false
  --     )
  -- end

  --- # goto mappings
  -- bmap("n", "gd", "lua vim.lsp.buf.definition()")
  -- bmap("n", "gD", "lua TroubleToggle lsp_definitions")
  -- bmap("n", "gr", "lua vim.lsp.buf.references()")
  -- bmap("n", "gR", "lua TroubleToggle lsp_references")
  -- bmap("n", "gs", "lua vim.lsp.buf.document_symbol()")
  -- bmap("n", "gs", "lua vim.lsp.buf.workspace_symbol()")
  -- bmap("n", "gi", "lua vim.lsp.buf.implementation()")
  -- bmap("n", "gca", "lua vim.lsp.buf.code_action()")
  -- bmap("x", "gca", "<esc><cmd>lua vim.lsp.buf.range_code_action()<cr>")

  --- # diagnostics navigation mappings
  bmap("n", "[d", "lua vim.diagnostic.goto_prev()", { label = "lsp: jump to prev diagnostic" })
  bmap("n", "]d", "lua vim.diagnostic.goto_next()", { label = "lsp: jump to next diagnostic" })
  bmap("n", "[e", "lua vim.diagnostic.goto_prev({severity = vim.diagnostic.severity.ERROR})")
  bmap("n", "]e", "lua vim.diagnostic.goto_next({severity = vim.diagnostic.severity.ERROR})")
  bmap("n", "<leader>ld", "lua require('utils').lsp.line_diagnostics()", { label = "lsp: show line diagnostics" })
  bmap(
    "n",
    "<leader>lD",
    [[lua vim.diagnostic.open_float(nil, { focusable = false,  close_events = { "BufLeave", "CursorMoved", "InsertEnter", "FocusLost" }, source = "always" })]]
  )
  bmap("n", "<leader>lp", "lua require('utils').lsp.peek_definition()", { label = "lsp: peek definition" })

  --- # misc mappings
  bmap("n", "<leader>ln", "lua require('utils').lsp.rename()", { label = "lsp: rename document symbol" })
  bufmap("K", "lua vim.lsp.buf.hover()")
  bufmap("<C-k>", "<cmd>lua vim.lsp.buf.signature_help()<cr>", "i")
  bufmap("<leader>lf", "lua require('utils').lsp.format()")

  if client.resolved_capabilities.code_lens then
    bufmap("<leader>ll", "lua vim.lsp.codelens.run()")
  end

  --- # trouble mappings
  nmap(
    "<leader>lt",
    "<cmd>TroubleToggle document_diagnostics<cr>",
    { label = "lsp: toggle Trouble for document diagnostics" }
  )

  --- # autocommands/autocmds
  au([[CursorHold <buffer> lua require('utils').lsp.line_diagnostics()]])
  -- autocmd("CursorHold", "<buffer>", function()
  --   vim.diagnostic.open_float(nil, {
  --     focusable = false,
  --     close_events = {
  --       "BufLeave",
  --       "CursorMoved",
  --       "InsertEnter",
  --       "FocusLost",
  --     },
  --     source = "always",
  --   })
  -- end)
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

  -- disable formatting for the following language-servers:
  local disabled_formatting_ls = { "jsonls", "tailwindcss", "html", "tsserver" }
  for i = 1, #disabled_formatting_ls do
    if disabled_formatting_ls[i] == client.name then
      client.resolved_capabilities.document_formatting = false
      client.resolved_capabilities.document_range_formatting = false
    end
  end

  -- (typescript/tsserver)
  if client.name == "tsserver" then
    local ts = require("nvim-lsp-ts-utils")
    -- REF: https://github.com/Iamafnan/my-nvimrc/blob/main/lua/afnan/lsp/language-servers.lua#L65
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
      -- filter_out_diagnostics_by_code = { 80001, 2582, 2304, 2503 },

      -- inlay hints
      auto_inlay_hints = true,
      inlay_hints_highlight = "Comment",
    })

    ts.setup_client(client)
  end

  api.nvim_buf_set_option(bufnr, "omnifunc", "v:lua.vim.lsp.omnifunc")

  local b_mappings = {
    ["<leader>"] = {
      l = {
        name = "LSP",
        [","] = { "LSP stop" },
        [",a"] = { "<cmd>LspStop<cr>", "stop all" },
        [",s"] = { "select" },
        A = "code actions (range)",
        D = "diagnostics (project)",
        S = "symbols (project)",
        a = "code actions (cursor)",
        c = "clear diagnostics",
        d = "diagnostics (buffer)",
        f = "format",
        g = { name = "go to" },
        gD = "declaration",
        gd = "definition",
        gi = "implementation",
        gr = "references",
        gy = "type definition",
        h = "hover",
        i = "LSP info",
        k = "signature help",
        l = "line diagnostics",
        p = "peek definition",
        r = "rename",
        n = "rename",
        s = "symbols (buffer)",
      },
    },
    ["g"] = {
      ["D"] = {
        [[<cmd>lua require('telescope.builtin').lsp_type_definitions()<cr>]],
        "LSP type definitions",
        buffer = bufnr,
      },
      ["d"] = { [[<cmd>lua require('telescope.builtin').lsp_definitions()<cr>]], "LSP definitions", buffer = bufnr },
      ["S"] = {
        [[<cmd>lua require('telescope.builtin').lsp_document_symbols()<cr>]],
        "LSP document symbols",
        buffer = bufnr,
      },
      ["a"] = { [[<cmd>lua require('telescope.builtin').lsp_code_actions()<cr>]], "LSP document symbols", buffer = bufnr },
      ["SS"] = {
        [[<cmd>lua require('telescope.builtin').lsp_workspace_symbols()<cr>]],
        "LSP workspace symbols",
        buffer = bufnr,
      },
      ["i"] = {
        [[<cmd>lua require('telescope.builtin').lsp_implementations()<cr>]],
        "LSP implementations",
        buffer = bufnr,
      },
      ["r"] = { [[<cmd>lua require('telescope.builtin').lsp_references()<cr>]], "LSP references", buffer = bufnr },
      ["n"] = { [[<cmd>lua require('utils').lsp.rename()<cr>]], "LSP rename", buffer = bufnr },
    },
  }

  local wk = require("which-key")
  wk.register(b_mappings)
end

local function setup_lsp_capabilities()
  local capabilities = vim.lsp.protocol.make_client_capabilities()
  capabilities = require("cmp_nvim_lsp").update_capabilities(capabilities)
  capabilities = vim.tbl_extend("keep", capabilities or {}, require("lsp-status").capabilities)
  capabilities.textDocument.codeLens = { dynamicRegistration = false }
  capabilities.textDocument.colorProvider = { dynamicRegistration = false }
  capabilities.textDocument.completion.completionItem.snippetSupport = true
  capabilities.textDocument.completion.completionItem.documentationFormat = { "markdown" }
  capabilities.textDocument.completion.completionItem.snippetSupport = true
  capabilities.textDocument.completion.completionItem.preselectSupport = true
  capabilities.textDocument.completion.completionItem.insertReplaceSupport = true
  capabilities.textDocument.completion.completionItem.labelDetailsSupport = true
  capabilities.textDocument.completion.completionItem.deprecatedSupport = true
  capabilities.textDocument.completion.completionItem.commitCharactersSupport = true
  capabilities.textDocument.completion.completionItem.tagSupport = { valueSet = { 1 } }
  capabilities.textDocument.completion.completionItem.resolveSupport = {
    properties = {
      "documentation",
      "detail",
      "additionalTextEdits",
    },
  }
  return capabilities
end

local function setup_lsp_servers()
  local function lsp_with_defaults(opts)
    opts = opts or {}
    local config = vim.tbl_deep_extend("keep", opts, {
      autorstart = true,
      on_attach = on_attach,
      capabilities = setup_lsp_capabilities(),
      flags = { debounce_text_changes = 150 },
      root_dir = vim.loop.cwd,
    })

    return config
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
    "dockerls",
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

  -- null-ls setup
  require("lsp.null-ls").setup(on_attach)

  do -- ruby/solargraph
    lspconfig["solargraph"].setup(lsp_with_defaults({
      cmd = { "solargraph", "stdio" },
      filetypes = { "ruby" },
      -- root_dir = root_pattern("Gemfile", ".git"),
      settings = {
        solargraph = {
          diagnostics = true,
          useBundler = true,
        },
      },
    }))
  end

  do -- yamlls
    lspconfig["yamlls"].setup(lsp_with_defaults({
      settings = {
        yaml = {
          format = { enable = true },
          validate = true,
          hover = true,
          completion = true,
          schemas = require("schemastore").json.schemas(),
        },
      },
    }))
  end

  do -- tailwindcss
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
            -- https://github.com/tailwindlabs/tailwindcss-intellisense/issues/129
            classRegex = {
              [[class: "([^"]*)]],
              [[class= "([^"]*)]],
            },
          },
          validate = true,
        },
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
  end

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

  do -- lua/sumneko
    local runtime_path = vim.split(package.path, ";")
    table.insert(runtime_path, "lua/?.lua")
    table.insert(runtime_path, "lua/?/init.lua")
    local sumneko_lua_settings = lsp_with_defaults({
      settings = {
        Lua = {
          completion = { keywordSnippet = "Replace", callSnippet = "Replace" }, -- or `Disable`
          runtime = {
            version = "LuaJIT",
            path = runtime_path,
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

  do -- jsonls
    lspconfig["jsonls"].setup(lsp_with_defaults({
      cmd = { "vscode-json-language-server", "--stdio" },
      commands = {
        Format = {
          function()
            lsp.buf.range_formatting({}, { 0, 0 }, { fn.line("$"), 0 })
          end,
        },
      },
      init_options = { provideFormatter = true },
      single_file_support = true,
      settings = {
        json = {
          format = { enable = false },
          schemas = require("schemastore").json.schemas(),
        },
      },
    }))
  end

  do -- cssls
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
  end

  do -- html
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
  end

  do -- ls_emmet/emmetls/emmet-ls/emmet_ls
    local configs = require("lspconfig.configs")
    configs.ls_emmet = {
      default_config = {
        cmd = { "ls_emmet", "--stdio" },
        filetypes = { "html", "css", "eelixir", "eruby", "javascriptreact", "typescriptreact", "heex", "tsx", "jsx" },
        single_file_support = true,
      },
    }
    lspconfig["ls_emmet"].setup(lsp_with_defaults({}))
  end

  do -- typescript/javascript
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
end

return {
  setup = function()
    setup_lsp_handlers()
    setup_diagnostics()
    require("lsp.completion").setup()
    setup_lsp_servers()
  end,
  on_attach = on_attach,
}

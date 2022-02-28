local vcmd, lsp, api, fn, set = vim.cmd, vim.lsp, vim.api, vim.fn, vim.opt
local bufmap, bmap = mega.bufmap, mega.bmap
local lspconfig = require("lspconfig")
local command = mega.command
local fmt = string.format
local C = require("mega.colors")
local diagnostic = vim.diagnostic

set.completeopt = { "menu", "menuone", "noselect", "noinsert" }
set.shortmess:append("c") -- Don't pass messages to |ins-completion-menu|

-- vim.lsp.set_log_level("trace")
require("vim.lsp.log").set_format_func(vim.inspect)

-- [ commands ] ----------------------------------------------------------------

command({
  "LspLog",
  function()
    vim.cmd("vnew " .. vim.lsp.get_log_path())
  end,
})

command({
  "LspFormat",
  function()
    vim.lsp.buf.formatting_sync(nil, 2000)
  end,
})

-- [ autocmds ] ----------------------------------------------------------------

-- [ diagnostics ] -------------------------------------------------------------

require("mega.lsp.diagnostics").setup()

-- -- ( signs ) --
-- local diagnostic_types = {
--   { "Error", icon = C.icons.error },
--   { "Warn", icon = C.icons.warn },
--   { "Hint", icon = C.icons.hint },
--   { "Info", icon = C.icons.info },
-- }

-- fn.sign_define(vim.tbl_map(function(t)
--   local hl = "DiagnosticSign" .. t[1]
--   return {
--     name = hl,
--     text = t.icon,
--     texthl = hl,
--     linehl = fmt("%sLine", hl),
--   }
-- end, diagnostic_types))

-- ---Override diagnostics signs helper to only show the single most relevant sign
-- ---@see: http://reddit.com/r/neovim/comments/mvhfw7/can_built_in_lsp_diagnostics_be_limited_to_show_a
-- ---@param diagnostics table[]
-- ---@param _ number buffer number
-- ---@return table[]
-- local function filter_diagnostics(diagnostics, _)
--   if not diagnostics then
--     return {}
--   end
--   -- Work out max severity diagnostic per line
--   local max_severity_per_line = {}
--   for _, d in pairs(diagnostics) do
--     local lnum = d.lnum
--     if max_severity_per_line[lnum] then
--       local current_d = max_severity_per_line[lnum]
--       if d.severity < current_d.severity then
--         max_severity_per_line[lnum] = d
--       end
--     else
--       max_severity_per_line[lnum] = d
--     end
--   end

--   -- map to list
--   local filtered_diagnostics = {}
--   for _, v in pairs(max_severity_per_line) do
--     table.insert(filtered_diagnostics, v)
--   end
--   return filtered_diagnostics
-- end

-- --- This overwrites the diagnostic show/set_signs function to replace it with a custom function
-- --- that restricts nvim's diagnostic signs to only the single most severe one per line
-- local ns = api.nvim_create_namespace("severe-diagnostics")
-- local show = vim.diagnostic.show
-- local function display_signs(bufnr)
--   -- Get all diagnostics from the current buffer
--   local diagnostics = vim.diagnostic.get(bufnr)
--   local filtered = filter_diagnostics(diagnostics, bufnr)
--   show(ns, bufnr, filtered, {
--     virtual_text = false,
--     underline = false,
--     signs = true,
--   })
-- end

-- function vim.diagnostic.show(namespace, bufnr, ...)
--   show(namespace, bufnr, ...)
--   display_signs(bufnr)
-- end

-- -- ( config ) --
-- -- diagnostic.config({
-- --   underline = true,
-- --   signs = false,
-- --   update_in_insert = false,
-- --   severity_sort = true,
-- --   virtual_text = false,
-- -- })

-- [ handlers ] ----------------------------------------------------------------
-- require("mega.lsp.handlers").setup()
do
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

  -- NOTE: presently andled by fidget.nvim
  -- lsp.handlers["$/progress"] = lsp_progress_notification

  -- NOTE: the hover handler returns the bufnr,winnr so can be used for mappings
  lsp.handlers["textDocument/hover"] = lsp.with(lsp.handlers.hover, opts)
  lsp.handlers["textDocument/signatureHelp"] = lsp.with(lsp.handlers.signature_help, opts)
  lsp.handlers["window/showMessage"] = function(_, result, ctx)
    local client = vim.lsp.get_client_by_id(ctx.client_id)
    local lvl = ({ "ERROR", "WARN", "INFO", "DEBUG" })[result.type]
    vim.notify(result.message, lvl, {
      title = "LSP | " .. client.name,
      timeout = 10000,
      keep = function()
        return lvl == "ERROR" or lvl == "WARN"
      end,
    })
  end
end

-- [ on_attach ] ---------------------------------------------------------------

function mega.lsp.on_attach(client, bufnr)
  if not client then
    vim.notify("No LSP client found; aborting on_attach.")
    return
  end

  if client.config.flags then
    client.config.flags.allow_incremental_sync = true
  end

  require("mega.lsp.formatting").setup(client, bufnr)

  require("lsp_signature").on_attach({
    bind = true,
    fix_pos = false,
    auto_close_after = 15, -- close after 15 seconds
    hint_enable = false,
    handler_opts = { border = "rounded" },
    --   hi_parameter = "QuickFixLine",
    --   handler_opts = {
    --     border = vim.g.floating_window_border,
    --   },
  })

  if client.server_capabilities.colorProvider then
    require("mega.lsp.document_colors").buf_attach(bufnr, { single_column = true, col_count = 2 })
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

  --- # diagnostics navigation mappings
  bmap("n", "[d", "lua vim.diagnostic.goto_prev()", { label = "lsp: jump to prev diagnostic" })
  bmap("n", "]d", "lua vim.diagnostic.goto_next()", { label = "lsp: jump to next diagnostic" })
  bmap("n", "[e", "lua vim.diagnostic.goto_prev({severity = vim.diagnostic.severity.ERROR})")
  bmap("n", "]e", "lua vim.diagnostic.goto_next({severity = vim.diagnostic.severity.ERROR})")
  bmap(
    "n",
    "<leader>ld",
    "lua require('mega.lsp.diagnostics').line_diagnostics()",
    { label = "lsp: show line diagnostics" }
  )
  bmap(
    "n",
    "<leader>lD",
    [[lua vim.diagnostic.open_float(nil, { focusable = false,  close_events = { "BufLeave", "CursorMoved", "InsertEnter", "FocusLost" }, source = "always" })]]
  )

  --- # misc mappings
  bmap("n", "<leader>ln", "lua require('mega.utils').lsp.rename()", { label = "lsp: rename document symbol" })
  bufmap("K", "lua vim.lsp.buf.hover()")
  bufmap("<C-k>", "<cmd>lua vim.lsp.buf.signature_help()<cr>", "i")

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
  mega.au([[CursorHold <buffer> lua require('mega.lsp.diagnostics').line_diagnostics()]])
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
  mega.au([[CursorMoved,BufLeave <buffer> lua vim.lsp.buf.clear_references()]])
  vcmd([[command! FormatDisable lua require('mega.utils').lsp.formatToggle(true)]])
  vcmd([[command! FormatEnable lua require('mega.utils').lsp.formatToggle(false)]])

  if client.resolved_capabilities.code_lens then
    mega.au("CursorHold,CursorHoldI,InsertLeave <buffer> lua vim.lsp.codelens.refresh()")
  end

  --- # commands
  FormatRange = function()
    local start_pos = api.nvim_buf_get_mark(0, "<")
    local end_pos = api.nvim_buf_get_mark(0, ">")
    lsp.buf.range_formatting({}, start_pos, end_pos)
  end
  vcmd([[ command! -range LspFormatRange execute 'lua FormatRange()' ]])
  vcmd([[ command! LspFormat execute 'lua vim.lsp.buf.formatting_sync(nil, 1000)' ]])
  vcmd([[ command! LspLog lua vim.cmd('vnew'..vim.lsp.get_log_path()) ]])

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
        ["'"] = { "<cmd>LspStart<cr>", "LSP start" },
        [","] = { "LSP stop" },
        [",a"] = { "<cmd>LspStop<cr>", "stop all" },
        [",s"] = { "select" },
        A = "code actions (range)",
        -- D = "diagnostics (project)",
        a = "code actions (cursor)",
        c = "clear diagnostics",
        -- d = "diagnostics (buffer)",
        f = "format",
        g = { name = "go to" },
        gD = "declaration",
        gd = "definition",
        gi = "implementation",
        gr = "references",
        gy = "type definition",
        h = "hover",
        i = { "<cmd>LspInfo<cr>", "LSP info", buffer = bufnr },
        k = "signature help",
        l = { "<cmd>LspLog<cr>", "LSP logs", buffer = bufnr },
        p = "peek definition",
        r = "rename",
        n = "rename",
        s = {
          [[<cmd>lua require('telescope.builtin').lsp_document_symbols()<cr>]],
          "symbols (buffer/document)",
          buffer = bufnr,
        },
        S = {
          [[<cmd>lua require('telescope.builtin').lsp_workspace_symbols()<cr>]],
          "symbols (workspace)",
        },
      },
    },
    ["g"] = {
      ["d"] = { [[<cmd>lua require('telescope.builtin').lsp_definitions()<cr>]], "LSP definitions", buffer = bufnr },
      ["D"] = {
        [[<cmd>lua require('telescope.builtin').lsp_type_definitions()<cr>]],
        "LSP type definitions",
        buffer = bufnr,
      },
      ["a"] = { [[<cmd>lua require('telescope.builtin').lsp_code_actions()<cr>]], "LSP code actions", buffer = bufnr },
      ["i"] = {
        [[<cmd>lua require('telescope.builtin').lsp_implementations()<cr>]],
        "LSP implementations",
        buffer = bufnr,
      },
      ["r"] = { [[<cmd>lua require('telescope.builtin').lsp_references()<cr>]], "LSP references", buffer = bufnr },
      -- ["n"] = { [[<cmd>lua require('mega.utils').lsp.rename()<cr>]], "LSP rename", buffer = bufnr },
      ["l"] = { [[<cmd>lua require('mega.utils').lsp.rename()<cr>]], "LSP rename", buffer = bufnr },
    },
  }

  local wk = require("which-key")
  wk.register(b_mappings)

  -- P(fmt("LSP client capabilities: %s", vim.inspect(client.resolved_capabilities)))
end

local function setup_lsp_capabilities()
  local capabilities = vim.lsp.protocol.make_client_capabilities()
  capabilities.textDocument.codeLens = { dynamicRegistration = false }
  capabilities.textDocument.colorProvider = { dynamicRegistration = false }
  capabilities.textDocument.completion.completionItem.documentationFormat = { "markdown" }
  capabilities = require("cmp_nvim_lsp").update_capabilities(capabilities)

  return capabilities
end

local function setup_lsp_servers()
  local function lsp_with_defaults(opts)
    opts = opts or {}
    local config = vim.tbl_deep_extend("keep", opts, {
      autostart = true,
      on_attach = mega.lsp.on_attach,
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
    -- handle language servers not installed/found;
    -- TODO: should probably handle logging/install them at some point
    if ls == nil or lspconfig[ls] == nil then
      mega.inspect("unable to setup ls", { ls })
      return
    end
    lspconfig[ls].setup(lsp_with_defaults())
  end

  require("mega.lsp.null-ls").setup(mega.lsp.on_attach)

  do -- ruby/solargraph
    lspconfig["solargraph"].setup(lsp_with_defaults({
      cmd = { "solargraph", "stdio" },
      filetypes = { "ruby" },
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
          -- elixir = "phoenix-heex",
          eruby = "erb",
          heex = "phoenix-heex",
        },
      },
      handlers = {
        ["tailwindcss/getConfiguration"] = function(_, _, params, _, bufnr, _)
          -- TailwindCSS waits for this repsonse before providing hover
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
          -- eelixir = "html",
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
              -- https://github.com/tailwindlabs/tailwindcss-intellisense/issues/129
              -- [[class: "([^"]*)]],
              -- [[class= "([^"]*)]],
              -- Configure TailwindCSS to consider all double-quote strings
              -- as class attributes so we autocomplete
              "\"([^\"]*)",
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

    local lsputil = require("lspconfig.util")

    local function dir_has_file(dir, name)
      return lsputil.path.exists(lsputil.path.join(dir, name)), lsputil.path.join(dir, name)
    end

    local function workspace_root()
      local cwd = vim.loop.cwd()

      if dir_has_file(cwd, "compose.yml") or dir_has_file(cwd, "docker-compose.yml") then
        return cwd
      end

      local function cb(dir, _)
        return dir_has_file(dir, "compose.yml") or dir_has_file(dir, "docker-compose.yml")
      end

      local root, _ = lsputil.path.traverse_parents(cwd, cb)
      return root
    end

    --- Build the language server command.
    -- @param opts options
    -- @param opts.locations table Locations to search relative to the workspace root
    -- @param opts.fallback_dir string Path to use if locations don't contain the binary
    -- @return a string containing the command
    local function language_server_cmd(opts)
      opts = opts or {}
      local fallback_dir = opts.fallback_dir
      local locations = opts.locations or {}

      local root = workspace_root()
      if not root then
        root = vim.loop.cwd()
      end

      for _, location in ipairs(locations) do
        local exists, dir = dir_has_file(root, location)
        if exists then
          -- logger.fmt_debug("language_server_cmd: %s", vim.fn.expand(dir))
          return vim.fn.expand(dir)
        end
      end

      local fallback = vim.fn.expand(fallback_dir)
      -- logger.fmt_debug("language_server_cmd: %s", fallback)
      return fallback
    end

    --- Build the elixir-ls command.
    -- @param opts options
    -- @param opts.fallback_dir string Path to use if locations don't contain the binary
    local function elixirls_cmd(opts)
      opts = opts or {}
      opts = vim.tbl_deep_extend("force", opts, {
        locations = {
          ".elixir-ls-release/language_server.sh",
          ".elixir_ls/release/language_server.sh",
        },
      })

      opts.fallback_dir = opts.fallback_dir or vim.env.XDG_DATA_HOME or "~/.local/share"
      opts.fallback_dir = string.format("%s/lsp/elixir-ls/%s", opts.fallback_dir, "language_server.sh")

      return language_server_cmd(opts)
    end

    lspconfig["elixirls"].setup(lsp_with_defaults({
      cmd = { elixirls_cmd() },
      settings = {
        elixirLS = {
          fetchDeps = false,
          dialyzerEnabled = false,
          dialyzerFormat = "dialyxir_short",
          enableTestLenses = true,
          suggestSpecs = true,
        },
      },
      filetypes = { "elixir", "eelixir" },
      root_dir = root_pattern("mix.exs", ".git") or vim.loop.os_homedir(),
      commands = {
        ToPipe = { manipulate_pipes("toPipe"), "Convert function call to pipe operator" },
        FromPipe = { manipulate_pipes("fromPipe"), "Convert pipe operator to function call" },
      },
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
            library = vim.api.nvim_get_runtime_file("", true),
            maxPreload = 2000,
            preloadFileSize = 500,
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
    }))
  end

  do -- ls_emmet/emmetls/emmet-ls/emmet_ls
    local configs = require("lspconfig.configs")
    configs.ls_emmet = {
      default_config = {
        cmd = { "ls_emmet", "--stdio" },
        filetypes = {
          "html",
          "css",
          "eelixir",
          "eruby",
          "javascriptreact",
          "typescriptreact",
          "heex",
          "html.heex",
          "tsx",
          "jsx",
        },
        single_file_support = true,
      },
    }
    lspconfig["ls_emmet"].setup(lsp_with_defaults({
      settings = {
        includeLanguages = {
          ["html-eex"] = "html",
          ["phoenix-heex"] = "html",
          heex = "html",
          eelixir = "html",
        },
      },
    }))
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

require("mega.lsp.completion").setup()
setup_lsp_servers()

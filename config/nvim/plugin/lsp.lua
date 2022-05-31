local fn = vim.fn
local api = vim.api
local lsp = vim.lsp
local vcmd = vim.cmd
-- local bufmap, bmap = mega.bufmap, mega.bmap
local lspconfig = require("lspconfig")
local command = mega.command
local augroup = mega.augroup
local fmt = string.format
local diagnostic = vim.diagnostic

vim.opt.completeopt = { "menu", "menuone", "noselect", "noinsert" }
vim.opt.shortmess:append("c") -- Don't pass messages to |ins-completion-menu|

vim.lsp.set_log_level("ERROR")
require("vim.lsp.log").set_format_func(vim.inspect)

-- TODO: all references to `resolved_capabilities.capability_name` will need to be changed to
-- `server_capabilities.camelCaseCapabilityName`
-- https://github.com/neovim/neovim/issues/14090#issuecomment-1113956767

-- [ HELPERS ] -----------------------------------------------------------------

-- Show the popup diagnostics window, but only once for the current cursor location
-- by checking whether the word under the cursor has changed.
local function diagnostic_popup()
  local cword = vim.fn.expand("<cword>")
  if cword ~= vim.w.lsp_diagnostics_cword then
    vim.w.lsp_diagnostics_cword = cword
    vim.diagnostic.open_float(0, { scope = "cursor", focus = false })
  end
end

local format_exclusions = {}
local function formatting_filter(client)
  return not vim.tbl_contains(format_exclusions, client.name)
end

---@param opts table<string, any>
local format = function(opts)
  opts = opts or {}
  -- if vim.fn.bufloaded(bufnr) then
  vim.lsp.buf.format({
    bufnr = opts.bufnr,
    async = opts.async, -- NOTE: this is super dangerous
    filter = formatting_filter,
  })
  -- end
end

-- [ COMMANDS ] ----------------------------------------------------------------

local function setup_commands()
  FormatRange = function()
    local start_pos = api.nvim_buf_get_mark(0, "<")
    local end_pos = api.nvim_buf_get_mark(0, ">")
    lsp.buf.range_formatting({}, start_pos, end_pos)
  end
  vcmd([[ command! -range LspFormatRange execute 'lua FormatRange()' ]])

  command("LspLog", function()
    vim.cmd("vnew " .. vim.lsp.get_log_path())
  end)

  command("LspFormat", function()
    format({ bufnr = 0, async = false })
  end)

  -- A helper function to auto-update the quickfix list when new diagnostics come
  -- in and close it once everything is resolved. This functionality only runs while
  -- the list is open.
  -- REF:
  -- * https://github.com/akinsho/dotfiles/blob/main/.config/nvim/plugin/lsp.lua#L28-L58
  -- * https://github.com/onsails/diaglist.nvim
  local function make_diagnostic_qf_updater()
    local cmd_id = nil
    return function()
      vim.diagnostic.setqflist({ open = false })
      mega.toggle_list("quickfix")
      if not mega.is_vim_list_open() and cmd_id then
        api.nvim_del_autocmd(cmd_id)
        cmd_id = nil
      end
      if cmd_id then
        return
      end
      cmd_id = api.nvim_create_autocmd("DiagnosticChanged", {
        callback = function()
          if mega.is_vim_list_open() then
            vim.diagnostic.setqflist({ open = false })
            if #vim.fn.getqflist() == 0 then
              mega.toggle_list("quickfix")
            end
          end
        end,
      })
    end
  end

  command("LspDiagnostics", make_diagnostic_qf_updater())
end

-- [ AUTOCMDS ] ----------------------------------------------------------------
---@param client table<string, any>
---@param bufnr number
local function setup_autocommands(client, bufnr)
  augroup("LspCodeLens", {
    {
      event = { "BufEnter", "CursorHold", "InsertLeave" }, -- CursorHoldI
      buffer = 0,
      command = function()
        if not vim.tbl_isempty(vim.lsp.codelens.get(bufnr)) then
          vim.lsp.codelens.refresh()
        end
      end,
    },
  })

  -- augroup("LspDocumentHighlight", {
  --   {
  --     event = { "CursorHold", "CursorHoldI" },
  --     buffer = bufnr,
  --     command = function()
  --       vim.lsp.buf.document_highlight()
  --     end,
  --   },
  --   {
  --     event = { "CursorMoved", "BufLeave" },
  --     buffer = bufnr,
  --     command = function()
  --       vim.lsp.buf.clear_references()
  --     end,
  --   },
  -- })
  --
  augroup("LspDiagnostics", {
    {
      event = { "CursorHold" },
      command = function()
        diagnostic_popup()
      end,
    },
  })

  -- format on save
  augroup("LspFormat", {
    {
      event = { "BufWritePre" },
      command = function()
        format({ async = false, bufnr = 0 }) -- prefer `false` here
      end,
    },
  })
end

-- [ MAPPINGS ] ----------------------------------------------------------------

local function setup_mappings(client, bufnr)
  local desc = function(desc)
    return { desc = desc, buffer = bufnr }
  end

  nnoremap("[d", function()
    diagnostic.goto_prev()
  end, desc("lsp: prev diagnostic"))
  nnoremap("]d", function()
    diagnostic.goto_next()
  end, desc("lsp: next diagnostic"))
  nnoremap("gd", vim.lsp.buf.definition, desc("lsp: definition"))
  nnoremap("gr", vim.lsp.buf.references, desc("lsp: references"))
  nnoremap("gt", vim.lsp.buf.type_definition, desc("lsp: type definition"))
  nnoremap("gi", vim.lsp.buf.implementation, desc("lsp: implementation"))
  nnoremap("gI", vim.lsp.buf.incoming_calls, desc("lsp: incoming calls"))
  nnoremap("<leader>lc", vim.lsp.buf.code_action, desc("lsp: code action"))
  xnoremap("<leader>lc", "<esc><Cmd>lua vim.lsp.buf.range_code_action()<CR>", desc("lsp: code action"))
  nnoremap("gl", vim.lsp.codelens.run, desc("lsp: code lens"))
  nnoremap("gn", require("mega.lsp.rename").rename, desc("lsp: rename"))
  nnoremap("K", vim.lsp.buf.hover, desc("lsp: hover"))
  nnoremap("<leader>li", [[<cmd>LspInfo<CR>]], desc("lsp: show client info"))
  nnoremap("<leader>ll", [[<cmd>LspLog<CR>]], desc("lsp: show log"))
  nnoremap("<leader>rf", vim.lsp.buf.format, desc("lsp: format buffer"))
end

-- [ FORMATTING ] ---------------------------------------------------------------

local function setup_formatting(client, bufnr)
  -- disable formatting for the following language-servers (let null-ls takeover):
  local disabled_lsp_formatting = { "tailwindcss", "html", "tsserver", "ls_emmet", "zk", "sumneko_lua" }
  for i = 1, #disabled_lsp_formatting do
    if disabled_lsp_formatting[i] == client.name then
      client.server_capabilities.documentFormattingProvider = false
      client.server_capabilities.documentRangeFormattingProvider = false
    end
  end

  local function has_nls_formatter(ft)
    local sources = require("null-ls.sources")
    local available = sources.get_available(ft, "NULL_LS_FORMATTING")
    return #available > 0
  end

  if client.name == "null-ls" then
    if has_nls_formatter(api.nvim_buf_get_option(bufnr, "filetype")) then
      client.server_capabilities.documentFormattingProvider = true
    else
      client.server_capabilities.documentFormattingProvider = false
    end
  end
end

-- [ DIAGNOSTICS ] -------------------------------------------------------------

local function setup_diagnostics()
  -- ( signs ) --
  local diagnostic_types = {
    { "Error", icon = mega.icons.lsp.error },
    { "Warn", icon = mega.icons.lsp.warn },
    { "Info", icon = mega.icons.lsp.info },
    { "Hint", icon = mega.icons.lsp.hint },
  }

  fn.sign_define(vim.tbl_map(function(t)
    local hl = "DiagnosticSign" .. t[1]
    return {
      name = hl,
      text = t.icon,
      texthl = hl,
      numhl = fmt("%sNumLine", hl),
      linehl = fmt("%sLine", hl),
    }
  end, diagnostic_types))

  --- Restricts nvim's diagnostic signs to only the single most severe one per line
  --- @see `:help vim.diagnostic`
  local ns = api.nvim_create_namespace("severe-diagnostics")
  local function max_diagnostic(callback)
    return function(_, bufnr, _, opts)
      -- Get all diagnostics from the whole buffer rather than just the
      -- diagnostics passed to the handler
      local diagnostics = vim.diagnostic.get(bufnr)
      -- Find the "worst" diagnostic per line
      local max_severity_per_line = {}
      for _, d in pairs(diagnostics) do
        local m = max_severity_per_line[d.lnum]
        if not m or d.severity < m.severity then
          max_severity_per_line[d.lnum] = d
        end
      end
      -- Pass the filtered diagnostics (with our custom namespace) to
      -- the original handler
      callback(ns, bufnr, vim.tbl_values(max_severity_per_line), opts)
    end
  end

  local signs_handler = vim.diagnostic.handlers.signs
  vim.diagnostic.handlers.signs = {
    show = max_diagnostic(signs_handler.show),
    hide = function(_, bufnr)
      signs_handler.hide(ns, bufnr)
    end,
  }

  local virt_text_handler = vim.diagnostic.handlers.virtual_text
  vim.diagnostic.handlers.virtual_text = {
    show = max_diagnostic(virt_text_handler.show),
    hide = function(_, bufnr)
      virt_text_handler.hide(ns, bufnr)
    end,
  }

  diagnostic.config({
    signs = true, -- {severity_limit = "Warning"},
    underline = true,
    virtual_text = false,
    update_in_insert = false,
    severity_sort = true,
    float = {
      show_header = true,
      source = "always", -- or "always", "if_many" (for more than one source)
      border = mega.get_border(),
      focusable = false,
      severity_sort = true,
      max_width = math.min(math.floor(vim.o.columns * 0.7), 100),
      max_height = math.min(math.floor(vim.o.lines * 0.3), 30),
      close_events = {
        "CursorMoved",
        "BufHidden",
        "InsertCharPre",
        "BufLeave",
        "InsertEnter",
        "FocusLost",
        "BufWritePre",
        "BufWritePost",
      },
      header = { "Diagnostics:", "DiagnosticHeader" },
      ---@diagnostic disable-next-line: unused-local
      prefix = function(diag, i, _total)
        -- local icon, highlight
        -- if diag.severity == 1 then
        --   icon = mega.icons.lsp.error
        --   highlight = "DiagnosticError"
        -- elseif diag.severity == 2 then
        --   icon = mega.icons.lsp.warn
        --   highlight = "DiagnosticWarn"
        -- elseif diag.severity == 3 then
        --   icon = mega.icons.lsp.info
        --   highlight = "DiagnosticInfo"
        -- elseif diag.severity == 4 then
        --   icon = mega.icons.lsp.hint
        --   highlight = "DiagnosticHint"
        -- end
        -- -- return i .. "/" .. total .. " " .. icon .. "  ", highlight
        -- return fmt("%s ", icon), highlight
        local level = diagnostic_types[diag.severity]
        local prefix = fmt("%d. %s ", i, level.icon)
        return prefix, "Diagnostic" .. level[1]
      end,
    },
  })
end

-- [ HANDLERS ] ----------------------------------------------------------------
local function setup_handlers()
  local opts = {
    border = mega.get_border(),
    max_width = math.min(math.floor(vim.o.columns * 0.7), 100),
    max_height = math.min(math.floor(vim.o.lines * 0.3), 30),
    focusable = false,
    focus = false,
    silent = true,
    severity_sort = true,
    close_events = {
      "CursorMoved",
      "BufHidden",
      "InsertCharPre",
      "BufLeave",
      "InsertEnter",
      "FocusLost",
      "BufWritePre",
      "BufWritePost",
    },
  }

  -- NOTE: the hover handler returns the bufnr,winnr so can be used for mappings
  -- WIP: colorize color things in a hover buffer
  local function hover_handler(_, result, ctx, config)
    config = config or {}
    config.focus_id = ctx.method
    if not (result and result.contents) then
      vim.notify("No information available")
      return
    end

    local util = require("vim.lsp.util")

    local markdown_lines = util.convert_input_to_markdown_lines(result.contents)
    markdown_lines = util.trim_empty_lines(markdown_lines)
    if vim.tbl_isempty(markdown_lines) then
      vim.notify("No information available")
      return
    end

    -- local lines = vim.split(result.contents.value, "\n")
    -- local bufnr = vim.lsp.util.open_floating_preview(lines, "markdown", { border = mega.get_border() })
    local buf_win = util.open_floating_preview(markdown_lines, "markdown", config)

    require("colorizer").highlight_buffer(
      buf_win,
      nil,
      vim.list_slice(markdown_lines, 2, #markdown_lines),
      0,
      require("colorizer").get_buffer_options(0)
    )

    return buf_win
  end

  lsp.handlers["textDocument/hover"] = lsp.with(hover_handler, opts)
  -- lsp.handlers["textDocument/hover"] = lsp.with(lsp.handlers.hover, opts)
  lsp.handlers["textDocument/signatureHelp"] = lsp.with(lsp.handlers.signature_help, opts)
  do
    vim.lsp.set_log_level(2)
    local convert_lsp_log_level_to_neovim_log_level = function(lsp_log_level)
      if lsp_log_level == 1 then
        return 4
      elseif lsp_log_level == 2 then
        return 3
      elseif lsp_log_level == 3 then
        return 2
      elseif lsp_log_level == 4 then
        return 1
      end
    end
    local levels = {
      "ERROR",
      "WARN",
      "INFO",
      "DEBUG",
      [0] = "TRACE",
    }
    -- lsp.handlers["window/showMessage"] = function(_, result, ...)
    --   if require("vim.lsp.log").should_log(convert_lsp_log_level_to_neovim_log_level(result.type)) then
    --     vim.notify(result.message, levels[result.type])
    --   end
    -- end
    lsp.handlers["window/showMessage"] = function(_, result, ctx)
      if require("vim.lsp.log").should_log(convert_lsp_log_level_to_neovim_log_level(result.type)) then
        local cl = lsp.get_client_by_id(ctx.client_id)
        -- local lvl = ({ "ERROR", "WARN", "INFO", "DEBUG" })[result.type]
        local lvl = levels[result.type]
        -- vim.notify(result.message, levels[result.type])
        vim.notify(result.message, lvl, {
          title = "LSP | " .. cl.name,
          timeout = 10000,
          keep = function()
            return lvl == "ERROR" or lvl == "WARN"
          end,
        })
      end
    end
  end

  -- lsp.handlers["textDocument/definition"] = function(_, result)
  --   if result == nil or vim.tbl_isempty(result) then
  --     print("Definition not found")
  --     return nil
  --   end
  --   local function jumpto(loc)
  --     local split_cmd = vim.uri_from_bufnr(0) == loc.targetUri and "split" or "tabnew"
  --     vim.cmd(split_cmd)
  --     lsp.util.jump_to_location(loc)
  --   end
  --   if vim.tbl_islist(result) then
  --     jumpto(result[1])
  --     if #result > 1 then
  --       fn.setqflist(lsp.util.locations_to_items(result))
  --       api.nvim_command("copen")
  --       api.nvim_command("wincmd p")
  --     end
  --   else
  --     jumpto(result)
  --   end
  -- end

  -- local old_handler = vim.lsp.handlers["window/logMessage"]
  -- lsp.handlers["window/logMessage"] = function(err, result, ...)
  --   if result.type == 3 or result.type == 4 then
  --     print(result.message)
  --   end

  --   old_handler(err, result, ...)
  -- end
end

-- [ HANDLERS ] ----------------------------------------------------------------
local function setup_highlights(client, bufnr)
  -- :h lsp-events
  -- autocmd User LspProgressUpdate redrawstatus
  -- autocmd User LspRequest redrawstatus
  if client then
    mega.augroup(fmt("LspHighlights%s", client.name), {
      event = { "ColorScheme" },
      pattern = bufnr,
      command = function()
        if client.name == "tailwindcss" then
          P(fmt("current client connected is %s; ready for highlights.", client.name))
        end
      end,
    })
  end
end

-- [ ON_ATTACH ] ---------------------------------------------------------------

---Add buffer local mappings, autocommands, tagfunc etc for attaching servers
---@param client table lsp client
---@param bufnr number
function mega.lsp.on_attach(client, bufnr)
  if not client then
    vim.notify("No LSP client found; aborting on_attach.")
    return
  end

  -- P(client.server_capabilities)

  if client.config.flags then
    client.config.flags.allow_incremental_sync = true
  end

  -- Live color highlighting; handy for tailwindcss
  -- HT: kabouzeid
  if client.server_capabilities.colorProvider then
    require("mega.lsp.document_colors").buf_attach(bufnr, { single_column = true, col_count = 2 })
  end

  if client.server_capabilities.definitionProvider then
    vim.bo[bufnr].tagfunc = "v:lua.vim.lsp.tagfunc"
  end

  if client.server_capabilities.documentFormattingProvider then
    vim.bo[bufnr].formatexpr = "v:lua.vim.lsp.formatexpr()"
  end

  setup_formatting(client, bufnr)
  setup_commands()
  setup_autocommands(client, bufnr)
  setup_diagnostics()
  setup_handlers()
  setup_mappings(client, bufnr)
  setup_highlights(client, bufnr)

  api.nvim_buf_set_option(bufnr, "omnifunc", "v:lua.vim.lsp.omnifunc")
end

-- [ SERVERS ] -----------------------------------------------------------------

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

mega.lsp.servers = {
  bashls = true,
  dockerls = function()
    return {
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
    }
  end,
  elmls = true,
  clangd = true,
  rust_analyzer = true,
  vimls = true,
  zk = true,
  pyright = function()
    return {
      single_file_support = false,
      settings = {
        python = {
          analysis = {
            autoSearchPaths = true,
            diagnosticMode = "workspace",
            useLibraryCodeForTypes = true,
          },
        },
      },
    }
  end,
  jsonls = function()
    return {
      commands = {
        Format = {
          function()
            lsp.buf.range_formatting({}, { 0, 0 }, { fn.line("$"), 0 })
          end,
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
    }
  end,
  yamlls = function()
    return {
      settings = {
        yaml = {
          format = { enable = true },
          validate = true,
          hover = true,
          completion = true,
          schemas = require("schemastore").json.schemas(),
        },
      },
    }
  end,

  -- @see https://gist.github.com/folke/fe5d28423ea5380929c3f7ce674c41d8
  -- NOTE: we return a function here so that the lua dev dependency is not
  -- required until the setup function is called.
  sumneko_lua = function()
    local ok, lua_dev = mega.safe_require("lua-dev")
    if not ok then
      return {}
    end

    local config = {
      library = {
        plugins = { "plenary.nvim" },
      },
      lspconfig = {
        settings = {
          Lua = {
            format = {
              enabled = false,
            },
            diagnostics = {
              -- @see https://github.com/sumneko/lua-language-server/tree/master/script/core/diagnostics
              disable = {
                "lowercase-global",
                "unused-vararg",
                "missing-parameter",
              },
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
                "mapbang",
                "noremapbang",
                "packer_plugins",
              },
            },
            completion = { keywordSnippet = "Replace", callSnippet = "Replace" },
          },
        },
      },
    }
    return lua_dev.setup(config)
  end,

  tailwindcss = function()
    return {
      cmd = { "tailwindcss-language-server", "--stdio" },
      init_options = {
        userLanguages = {
          elixir = "phoenix-heex",
          eruby = "erb",
          heex = "phoenix-heex",
        },
      },
      handlers = {
        ["tailwindcss/getConfiguration"] = function(_, _, params, _, bufnr, _)
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
    }
  end,
  elixirls = function()
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

    return {
      cmd = { elixirls_cmd() },
      settings = {
        elixirLS = {
          fetchDeps = false,
          dialyzerEnabled = true,
          dialyzerFormat = "dialyxir_short",
          enableTestLenses = false,
          suggestSpecs = true,
        },
      },
      filetypes = { "elixir", "eelixir", "heex" },
      root_dir = root_pattern("mix.exs", ".git") or vim.loop.os_homedir(),
    }
  end,
  solargraph = function()
    return {
      cmd = { "solargraph", "stdio" },
      filetypes = { "ruby" },
      settings = {
        solargraph = {
          diagnostics = true,
          useBundler = true,
        },
      },
    }
  end,
  cssls = function()
    return {
      -- REF: https://github.com/microsoft/vscode/issues/103163
      --      - custom css linting rules and custom data
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
    }
  end,
  html = function()
    return {

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
    }
  end,
  -- ["ls_emmet"] = function()
  --   local configs = require("lspconfig.configs")
  --   configs.ls_emmet = {
  --     default_config = {
  --       cmd = { "ls_emmet", "--stdio" },
  --       filetypes = {
  --         "html",
  --         "css",
  --         "eelixir",
  --         "eruby",
  --         "javascriptreact",
  --         "typescriptreact",
  --         "heex",
  --         "html.heex",
  --         "tsx",
  --         "jsx",
  --       },
  --       single_file_support = true,
  --     },
  --   }
  --   return {
  --     settings = {
  --       includeLanguages = {
  --         ["html-eex"] = "html",
  --         ["phoenix-heex"] = "html",
  --         heex = "html",
  --         eelixir = "html",
  --       },
  --     },
  --   }
  -- end,
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
    }
  end,
}

require("mega.lsp.null_ls")()

function mega.lsp.get_server_config(server)
  local function server_capabilities()
    local nvim_lsp_ok, cmp_nvim_lsp = mega.safe_require("cmp_nvim_lsp")

    local capabilities = vim.lsp.protocol.make_client_capabilities()
    capabilities.offsetEncoding = { "utf-16" }
    capabilities.textDocument.codeLens = { dynamicRegistration = false }
    capabilities.textDocument.colorProvider = { dynamicRegistration = false }
    capabilities.textDocument.completion.completionItem.documentationFormat = { "markdown" }
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

    if nvim_lsp_ok then
      capabilities = cmp_nvim_lsp.update_capabilities(capabilities)
    end

    return capabilities
  end

  local conf = mega.lsp.servers[server]
  local conf_type = type(conf)
  local config = conf_type == "table" and conf or conf_type == "function" and conf() or {}

  config.flags = { debounce_text_changes = 200 }
  config.capabilities = server_capabilities()

  return config
end

if false then
  local lsp_installer = require("nvim-lsp-installer")
  for server_name, _ in pairs(mega.lsp.servers) do
    local server_is_found, server = lsp_installer.get_server(server_name)
    if server_is_found and not server:is_installed() then
      vim.notify("Installing " .. server_name)
      -- server:install()
    end
  end

  lsp_installer.on_server_ready(function(server)
    server:setup(mega.lsp.get_server_config(server))
  end)
else
  -- Load lspconfig servers with their configs
  for server, _ in pairs(mega.lsp.servers) do
    if server == nil or lspconfig[server] == nil then
      vim.notify("unable to setup ls for " .. server)
      return
    end

    local config = mega.lsp.get_server_config(server)
    lspconfig[server].setup(config)
  end

  --- A set of custom overrides for specific lsp clients
  --- This is a way of adding functionality for specific lsps
  --- without putting all this logic in the general on_attach function
  local client_overrides = {
    -- ["sumneko_lua"] = function(client, bufnr) end,
  }

  mega.augroup("LspSetupCommands", {
    {
      event = "LspAttach",
      desc = "Setup LS things on the buffer when the client attaches",
      command = function(args)
        local bufnr = args.buf
        local client = vim.lsp.get_client_by_id(args.data.client_id)
        mega.lsp.on_attach(client, bufnr)

        if client_overrides[client.name] then
          client_overrides[client.name](client, bufnr)
        end
      end,
    },
  })
end

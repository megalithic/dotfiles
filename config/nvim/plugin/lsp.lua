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

-- vim.lsp.set_log_level("trace")
require("vim.lsp.log").set_format_func(vim.inspect)

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
    vim.lsp.buf.formatting_sync(nil, 2000)
  end)

  command("LspDiagnostics", function()
    vim.diagnostic.setqflist({ open = false })
    mega.toggle_list("quickfix")
    if mega.is_vim_list_open() then
      augroup("LspDiagnosticUpdate", {
        {
          event = { "DiagnosticChanged" },
          command = function()
            if mega.is_vim_list_open() then
              mega.toggle_list("quickfix")
            end
          end,
        },
      })
    elseif fn.exists("#LspDiagnosticUpdate") > 0 then
      vim.cmd("autocmd! LspDiagnosticUpdate")
    end
  end)
  -- nnoremap("<leader>ll", "<Cmd>LspDiagnostics<CR>", "toggle quickfix diagnostics")
end

-- [ AUTOCMDS ] ----------------------------------------------------------------

local function setup_autocommands(client, bufnr)
  if client and client.resolved_capabilities.code_lens then
    augroup("LspCodeLens", {
      {
        event = { "BufEnter", "CursorHold", "InsertLeave" }, -- CursorHoldI
        buffer = 0,
        command = function()
          vim.lsp.codelens.refresh()
        end,
      },
    })
  end
  if client and client.resolved_capabilities.document_highlight then
    augroup("LspDocumentHighlight", {
      {
        event = { "CursorHold", "CursorHoldI" },
        buffer = bufnr,
        command = function()
          vim.lsp.buf.document_highlight()
        end,
      },
      {
        event = { "CursorMoved", "BufLeave" },
        buffer = bufnr,
        command = function()
          vim.lsp.buf.clear_references()
        end,
      },
    })
  end

  if client then
    augroup("LspDiagnostics", {
      {
        event = { "CursorHold" },
        command = function()
          diagnostic.open_float(nil, {
            focusable = false,
            focus = false,
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
          })
        end,
      },
    })
  end

  local ok, lsp_format = pcall(require, "lsp-format")
  if ok then
    lsp_format.on_attach(client)
  else
    if client and client.resolved_capabilities.document_formatting then
      -- format on save
      augroup("LspFormat", {
        {
          event = { "BufWritePre" },
          -- buffer = bufnr,
          command = function()
            -- P(fmt("should be formatting here on bufwritepre for buffer: %s", bufnr))
            -- BUG: folds are are removed when formatting is done, so we save the current state of the
            -- view and re-apply it manually after formatting the buffer
            -- @see: https://github.com/nvim-treesitter/nvim-treesitter/issues/1424#issuecomment-909181939
            vim.cmd("mkview!")
            local format_sync_ok, msg = pcall(vim.lsp.buf.formatting_sync, nil, 2000)
            if not format_sync_ok then
              vim.notify(fmt("Error formatting file: %s", msg))
            end
            vim.cmd("loadview")
          end,
        },
      })
    end
  end
end

-- [ MAPPINGS ] ----------------------------------------------------------------

local function setup_mappings(client, bufnr)
  -- if client.resolved_capabilities.code_lens then
  --   bufmap("<leader>ll", "lua vim.lsp.codelens.run()")
  -- end

  local ok, lsp_format = pcall(require, "lsp-format")
  local do_format = ok and lsp_format.format or vim.lsp.buf.formatting
  local maps = {
    n = {
      ["<leader>rf"] = { do_format, "lsp: format buffer" },
      ["<leader>li"] = { [[<cmd>LspInfo<CR>]], "lsp: show client info" },
      ["<leader>ll"] = { [[<cmd>LspLog<CR>]], "lsp: show log" },
      ["<leader>lt"] = { [[<cmd>TroubleToggle document_diagnostics<CR>]], "lsp: trouble diagnostics" },
      ["gD"] = { [[<cmd>TroubleToggle document_diagnostics<CR>]], "lsp: trouble diagnostics" },
      ["gd"] = { vim.lsp.buf.definition, "lsp: definition" },
      ["gr"] = { vim.lsp.buf.references, "lsp: references" },
      ["gR"] = { [[<cmd>TroubleToggle lsp_references<cr>]], "lsp: trouble references" },
      ["gI"] = { vim.lsp.buf.incoming_calls, "lsp: incoming calls" },
      ["K"] = { vim.lsp.buf.hover, "lsp: hover" },
    },
    x = {},
  }

  maps.n["[d"] = {
    function()
      diagnostic.goto_prev()
    end,
    "lsp: go to prev diagnostic",
  }
  maps.n["]d"] = {
    function()
      diagnostic.goto_next()
    end,
    "lsp: go to next diagnostic",
  }

  if client.resolved_capabilities.implementation then
    maps.n["gi"] = { vim.lsp.buf.implementation, "lsp: implementation" }
  end

  if client.resolved_capabilities.type_definition then
    maps.n["<leader>ltd"] = { vim.lsp.buf.type_definition, "lsp: go to type definition" }
  end

  maps.n["<leader>la"] = { vim.lsp.buf.code_action, "lsp: code action" }
  maps.x["<leader>la"] = { "<esc><Cmd>lua vim.lsp.buf.range_code_action()<CR>", "lsp: code action" }

  if client.supports_method("textDocument/rename") then
    maps.n["<leader>rn"] = { vim.lsp.buf.rename, "lsp: rename" }
    maps.n["<leader>ln"] = { vim.lsp.buf.rename, "lsp: rename" }
    maps.n["<leader>ln"] = { require("mega.lsp.rename").rename, "lsp: rename document symbol" }
  end

  for mode, value in pairs(maps) do
    require("which-key").register(value, { buffer = bufnr, mode = mode })
  end
end

-- [ FORMATTING ] ---------------------------------------------------------------

local function setup_formatting(client, bufnr)
  -- disable formatting for the following language-servers (let null-ls takeover):
  local disabled_lsp_formatting = { "tailwindcss", "html", "tsserver", "ls_emmet", "sumneko_lua", "zk" }
  for i = 1, #disabled_lsp_formatting do
    if disabled_lsp_formatting[i] == client.name then
      client.resolved_capabilities.document_formatting = false
      client.resolved_capabilities.document_range_formatting = false
    end
  end

  local function has_nls_formatter(ft)
    local sources = require("null-ls.sources")
    local available = sources.get_available(ft, "NULL_LS_FORMATTING")
    return #available > 0
  end

  if client.name == "null-ls" then
    if has_nls_formatter(api.nvim_buf_get_option(bufnr, "filetype")) then
      client.resolved_capabilities.document_formatting = true
    else
      client.resolved_capabilities.document_formatting = false
    end
  end
end

-- [ TAGS ] --------------------------------------------------------------------

function mega.lsp.tagfunc(pattern, flags)
  if flags ~= "c" then
    return vim.NIL
  end
  local params = vim.lsp.util.make_position_params()
  local client_id_to_results, err = vim.lsp.buf_request_sync(0, "textDocument/definition", params, 500)
  assert(not err, vim.inspect(err))

  local results = {}
  for _, lsp_results in ipairs(client_id_to_results) do
    for _, location in ipairs(lsp_results.result or {}) do
      local start = location.range.start
      table.insert(results, {
        name = pattern,
        filename = vim.uri_to_fname(location.uri),
        cmd = string.format("call cursor(%d, %d)", start.line + 1, start.character + 1),
      })
    end
  end
  return results
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

  -- REF: https://github.com/nvim-lua/kickstart.nvim/pull/26/commits/c3dd3bdc3d973ef9421aac838b9807496b7ba573
  function mega.lsp.print_diagnostics(opts, bufnr, line_nr, client_id)
    opts = opts or {}

    bufnr = bufnr or 0
    line_nr = line_nr or (vim.api.nvim_win_get_cursor(0)[1] - 1)

    local line_diagnostics = vim.lsp.diagnostic.get_line_diagnostics(bufnr, line_nr, opts, client_id)
    if vim.tbl_isempty(line_diagnostics) then
      return
    end

    local diagnostic_message = ""
    for i, diag in ipairs(line_diagnostics) do
      diagnostic_message = diagnostic_message .. string.format("%d: %s", i, diag.message or "")
      if i ~= #line_diagnostics then
        diagnostic_message = diagnostic_message .. "\n"
      end
    end
    --print only shows a single line, echo blocks requiring enter, pick your poison
    P(diagnostic_message)
  end

  --- Restricts nvim's diagnostic signs to only the single most severe one per line
  --- @see `:help vim.diagnostic`
  local ns = api.nvim_create_namespace("severe_diagnostics")
  --- Get a reference to the original signs handler
  local signs_handler = vim.diagnostic.handlers.signs
  --- Override the built-in signs handler
  vim.diagnostic.handlers.signs = {
    show = function(_, bufnr, _, opts)
      -- Get all diagnostics from the whole buffer rather than just the
      -- diagnostics passed to the handler
      local diagnostics = vim.diagnostic.get(bufnr)
      -- Find the "worst" diagnostic per line
      local max_severity_per_line = {}
      for _, d in pairs(diagnostics) do
        local m = max_severity_per_line[d.lnum]

        -- FIXME; this only seems to be the case for elixir-ls when there are compilation errors;
        -- d.lnum ends up being -1 which crashes the call to show/4 down below.
        if d.lnum == -1 then
          d.lnum = 0
        end

        if not m or d.severity < m.severity then
          max_severity_per_line[d.lnum] = d
        end
      end
      -- Pass the filtered diagnostics (with our custom namespace) to
      -- the original handler
      signs_handler.show(ns, bufnr, vim.tbl_values(max_severity_per_line), opts)
    end,
    hide = function(_, bufnr)
      signs_handler.hide(ns, bufnr)
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
      scope = "cursor",
      header = { "Diagnostics:", "DiagnosticHeader" },
      pos = 1,
      prefix = function(diag, i, total)
        local icon, highlight
        if diag.severity == 1 then
          icon = "E"
          highlight = "DiagnosticError"
        elseif diag.severity == 2 then
          icon = "W"
          highlight = "DiagnosticWarn"
        elseif diag.severity == 3 then
          icon = "I"
          highlight = "DiagnosticInfo"
        elseif diag.severity == 4 then
          icon = "H"
          highlight = "DiagnosticHint"
        end
        return i .. "/" .. total .. " " .. icon .. "  ", highlight
      end,
    },
  })
end

-- [ HANDLERS ] ----------------------------------------------------------------
local function setup_handlers()
  local opts = {
    border = mega.get_border(),
    max_width = math.max(math.floor(vim.o.columns * 0.7), 100),
    max_height = math.max(math.floor(vim.o.lines * 0.3), 30),
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
  lsp.handlers["textDocument/hover"] = lsp.with(lsp.handlers.hover, opts)
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
      events = { "ColorScheme" },
      targets = bufnr,
      command = function()
        if client.name == "tailwindcss" then
          P(fmt("current client connected is %s; ready for highlights.", client.name))
        end
      end,
    })
  end
end

-- [ ON_ATTACH ] ---------------------------------------------------------------

function mega.lsp.on_attach(client, bufnr)
  if not client then
    vim.notify("No LSP client found; aborting on_attach.")
    return
  end

  if client.config.flags then
    client.config.flags.allow_incremental_sync = true
  end

  if client.server_capabilities.colorProvider then
    -- Live color highlighting; handy for tailwindcss
    -- HT: kabouzeid
    require("mega.lsp.document_colors").buf_attach(bufnr, { single_column = true, col_count = 2 })
  end

  if client.resolved_capabilities.goto_definition then
    vim.bo[bufnr].tagfunc = "v:lua.mega.lsp.tagfunc"
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

-- local function setup_tsserver(client)
--   -- (typescript/tsserver)
--   if client.name == "tsserver" then
--     local ts = require("nvim-lsp-ts-utils")
--     -- REF: https://github.com/Iamafnan/my-nvimrc/blob/main/lua/afnan/lsp/language-servers.lua#L65
--     ts.setup({
--       debug = false,
--       disable_commands = false,
--       enable_import_on_completion = false,
--       import_on_completion_timeout = 5000,

--       -- linting
--       eslint_enable_code_actions = true,
--       eslint_enable_disable_comments = true,
--       eslint_bin = "eslint_d",
--       eslint_enable_diagnostics = true,
--       eslint_opts = {},

--       -- formatting
--       enable_formatting = false,
--       formatter = "prettierd",
--       formatter_opts = {},

--       -- filter diagnostics
--       -- {
--       --    80001 - require modules
--       --    6133 - import is declared but never used
--       --    2582 - cannot find name {describe, test}
--       --    2304 - cannot find name {expect, beforeEach, afterEach}
--       --    2503 - cannot find name {jest}
--       -- }
--       -- filter_out_diagnostics_by_code = { 80001, 2582, 2304, 2503 },

--       -- inlay hints
--       auto_inlay_hints = true,
--       inlay_hints_highlight = "Comment",
--     })

--     ts.setup_client(client)
--   end
-- end

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
  -- gopls = true,
  bashls = true,
  -- REF: https://github.com/rcjsuen/dockerfile-language-server-nodejs#language-server-settings
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

    local get_cursor_position = function()
      local rowcol = vim.api.nvim_win_get_cursor(0)
      local row = rowcol[1] - 1
      local col = rowcol[2]

      return row, col
    end

    local manipulate_pipes = function(direction, client)
      local row, col = get_cursor_position()

      client.request_sync("workspace/executeCommand", {
        command = "manipulatePipes:serverid",
        arguments = { direction, "file://" .. vim.api.nvim_buf_get_name(0), row, col },
      }, nil, 0)
    end

    local function from_pipe(client)
      return function()
        manipulate_pipes("fromPipe", client)
      end
    end

    local function to_pipe(client)
      return function()
        manipulate_pipes("toPipe", client)
      end
    end

    return {
      cmd = { elixirls_cmd() },
      settings = {
        elixirLS = {
          fetchDeps = false,
          dialyzerEnabled = true,
          dialyzerFormat = "dialyxir_short",
          enableTestLenses = true,
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

require("mega.lsp.null_ls")(mega.lsp.on_attach)

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
  config.on_attach = config.on_attach or mega.lsp.on_attach
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
end

local cmd, lsp, opt, api, fn = vim.cmd, vim.lsp, vim.opt, vim.api, vim.fn
local map, bufmap, au = mega.map, mega.bufmap, mega.au
local lspconfig = require("lspconfig")
local colors = require("colors")

cmd [[ set completeopt=menu,menuone,noselect ]]
cmd [[ set shortmess+=c ]]

local sign_error = colors.icons.sign_error
local sign_warning = colors.icons.sign_warning
local sign_information = colors.icons.sign_information
local sign_hint = colors.icons.sign_hint

fn.sign_define("LspDiagnosticsSignError", {text = sign_error, numhl = "LspDiagnosticsDefaultError"})
fn.sign_define("LspDiagnosticsSignWarning", {text = sign_warning, numhl = "LspDiagnosticsDefaultWarning"})
fn.sign_define("LspDiagnosticsSignInformation", {text = sign_information, numhl = "LspDiagnosticsDefaultInformation"})
fn.sign_define("LspDiagnosticsSignHint", {text = sign_hint, numhl = "LspDiagnosticsDefaultHint"})

--- LSP handlers
-- diagnostics
lsp.handlers["textDocument/publishDiagnostics"] = function(...)
  lsp.with(
    lsp.diagnostic.on_publish_diagnostics,
    {
      underline = true,
      virtual_text = false, -- FIXME: virtual text still shows up. ¯\_(ツ)_/¯
      signs = true,
      update_in_insert = false,
      severity_sort = true
    }
  )(...)
  pcall(lsp.diagnostic.set_loclist, {open_loclist = false})
end

-- hover
local overridden_hover = lsp.with(lsp.handlers.hover, {border = "single", focusable = false})
lsp.handlers["textDocument/hover"] = function(...)
  local bufnr = overridden_hover(...)
  api.nvim_buf_set_keymap(bufnr, "n", "K", "<cmd>wincmd p<CR>", {noremap = true, silent = true})
end

-- signature-help
lsp.handlers["textDocument/signatureHelp"] = lsp.with(lsp.handlers.signature_help, {border = "single"})

-- formatting
lsp.handlers["textDocument/formatting"] = function(err, _, result, _, bufnr)
  if err ~= nil or result == nil then
    return
  end

  -- If the buffer hasn't been modified before the formatting has finished,
  -- update the buffer
  if not api.nvim_buf_get_option(bufnr, "modified") then
    local view = fn.winsaveview()
    lsp.util.apply_text_edits(result, bufnr)
    fn.winrestview(view)
    if bufnr == api.nvim_get_current_buf() then
      api.nvim_command("noautocmd :update")

      -- Trigger post-formatting autocommand which can be used to refresh gitgutter
      api.nvim_command("silent doautocmd <nomodeline> User FormatterPost")
    end
  end
end

require("compe").setup {
  enabled = true,
  autocomplete = true,
  debug = false,
  min_length = 2,
  preselect = "disable",
  allow_prefix_unmatch = false,
  throttle_time = 80,
  source_timeout = 200,
  incomplete_delay = 400,
  max_abbr_width = 100,
  max_kind_width = 100,
  max_menu_width = 100,
  documentation = {
    border = {"╭", "─", "╮", "│", "╯", "─", "╰", "│"}
  },
  source = {
    nvim_lsp = {menu = "[lsp]", priority = 10},
    vsnip = {menu = "[vsnip]", priority = 10},
    nvim_lua = {menu = "[lua]", priority = 9},
    path = {menu = "[path]", priority = 9},
    treesitter = {menu = "[ts]", priority = 9},
    buffer = {menu = "[buf]", priority = 8},
    spell = {menu = "[spl]", filetypes = {"markdown"}},
    orgmode = {menu = "[org]"}
  }
}

local t = function(str)
  return api.nvim_replace_termcodes(str, true, true, true)
end

local check_back_space = function()
  local col = fn.col(".") - 1
  return col == 0 or fn.getline("."):sub(col, col):match("%s") ~= nil
end

-- Use (s-)tab to:
--- move to prev/next item in completion menuone
--- jump to prev/next snippet's placeholder
_G.tab_complete = function()
  if fn.pumvisible() == 1 then
    return t "<C-n>"
  elseif fn["vsnip#available"](1) == 1 then
    return t "<Plug>(vsnip-expand-or-jump)"
  elseif check_back_space() then
    return t "<Tab>"
  else
    return fn["compe#complete"]()
  end
end

_G.s_tab_complete = function()
  if fn.pumvisible() == 1 then
    return t "<C-p>"
  elseif fn["vsnip#jumpable"](-1) == 1 then
    return t "<Plug>(vsnip-jump-prev)"
  else
    -- If <S-Tab> is not working in your terminal, change it to <C-h>
    return t "<S-Tab>"
  end
end

_G.cr_complete = function()
  if fn.pumvisible() == 1 then
    return fn["compe#confirm"]({keys = "<cr>", select = true})
  else
    return require("nvim-autopairs").autopairs_cr()
  end
end

map("i", "<Tab>", "v:lua.tab_complete()", {expr = true, noremap = true})
map("s", "<Tab>", "v:lua.tab_complete()", {expr = true, noremap = true})
map("i", "<S-Tab>", "v:lua.s_tab_complete()", {expr = true, noremap = true})
map("s", "<S-Tab>", "v:lua.s_tab_complete()", {expr = true, noremap = true})
map("i", "<CR>", "v:lua.cr_complete()", {expr = true, noremap = true})

local function on_attach(client, _)
  if client.config.flags then
    client.config.flags.allow_incremental_sync = true
  end

  require "lsp_signature".on_attach(
    {
      bind = true, -- This is mandatory, otherwise border config won't get registered.
      handler_opts = {
        border = "single"
      }
    }
  )

  --- goto mappings
  bufmap("gd", "lua vim.lsp.buf.definition()")
  bufmap("gr", "lua vim.lsp.buf.references()")
  bufmap("gs", "lua vim.lsp.buf.document_symbol()")

  --- diagnostics navigation mappings
  -- bufmap("dn", "lua vim.lsp.diagnostic.goto_prev()")
  -- bufmap("dN", "lua vim.lsp.diagnostic.goto_next()")

  --- misc mappings
  bufmap("<leader>ln", "lua vim.lsp.buf.rename()")
  bufmap("<leader>la", "lua vim.lsp.buf.code_action()")
  bufmap(
    "<leader>ld",
    "lua vim.lsp.diagnostic.show_line_diagnostics({ border = 'rounded', show_header = false, focusable = false })"
  )
  bufmap("<C-k>", "lua vim.lsp.buf.signature_help()")
  bufmap("<C-k>", "lua vim.lsp.buf.signature_help()", "i")
  bufmap("<leader>lf", "lua vim.lsp.buf.formatting()")

  --- trouble mappings
  map("n", "<leader>lt", "<cmd>LspTroubleToggle<cr>")

  --- auto-commands
  -- au "BufWritePre <buffer> lua vim.lsp.buf.formatting(nil, 1000)"
  au "BufWritePre <buffer> lua vim.lsp.buf.formatting_seq_sync()"
  au "CursorHold <buffer> lua vim.lsp.diagnostic.show_line_diagnostics()"
  -- au "BufWritePost <buffer> lua vim.lsp.buf.formatting(nil, 1000)"
  -- au "BufWritePre *.rs,*.c,*.lua lua vim.lsp.buf.formatting_sync()"
  -- au "CursorHold *.rs,*.c,*.lua lua vim.lsp.diagnostic.show_line_diagnostics()"

  if vim.bo.ft ~= "vim" then
    bufmap("K", "<Cmd>lua vim.lsp.buf.hover()<CR>")
  end

  --- commands
  FormatRange = function()
    local start_pos = api.nvim_buf_get_mark(0, "<")
    local end_pos = api.nvim_buf_get_mark(0, ">")
    lsp.buf.range_formatting({}, start_pos, end_pos)
  end
  cmd [[ command! -range FormatRange execute 'lua FormatRange()' ]]
  cmd [[ command! Format execute 'lua vim.lsp.buf.formatting()' ]]
  cmd [[ command! LspLog lua vim.cmd('vnew'..vim.lsp.get_log_path()) ]]

  opt.omnifunc = "v:lua.vim.lsp.omnifunc"
end

--- capabilities
local capabilities = lsp.protocol.make_client_capabilities()
capabilities.textDocument.codeLens = {dynamicRegistration = false}
capabilities.textDocument.completion.completionItem.snippetSupport = true
capabilities.textDocument.completion.completionItem.resolveSupport = {
  properties = {
    "documentation",
    "detail",
    "additionalTextEdits"
  }
}

--- server setup utils
local function root_pattern(...)
  local patterns = vim.tbl_flatten {...}

  return function(startpath)
    for _, pattern in ipairs(patterns) do
      return lspconfig.util.search_ancestors(
        startpath,
        function(path)
          if lspconfig.util.path.exists(fn.glob(lspconfig.util.path.join(path, pattern))) then
            return path
          end
        end
      )
    end
  end
end

local function get_lua_runtime()
  local result = {}
  for _, path in pairs(api.nvim_list_runtime_paths()) do
    local lua_path = path .. "/lua/"
    if fn.isdirectory(lua_path) then
      result[lua_path] = true
    end
  end

  result[fn.expand("$VIMRUNTIME/lua")] = true
  result[fn.expand("$VIMRUNTIME/lua/vim/lsp")] = true
  result[fn.expand("/Applications/Hammerspoon.app/Contents/Resources/extensions/hs")] = true

  return result
end

local runtime_path = vim.split(package.path, ";")
table.insert(runtime_path, "lua/?.lua")
table.insert(runtime_path, "lua/?/init.lua")
table.insert(runtime_path, fn.expand("/Applications/Hammerspoon.app/Contents/Resources/extensions/hs/?.lua"))
table.insert(runtime_path, fn.expand("/Applications/Hammerspoon.app/Contents/Resources/extensions/hs/?/?.lua"))

--- servers
-- local servers = {
--   zk = {
--     disabled = true,
--     cmd = {"zk", "lsp", "--log", "/tmp/zk-lsp.log"},
--     filetypes = {"markdown", "md"},
--     root_dir = function()
--       return vim.loop.cwd()
--     end,
--     settings = {}
--   },
--   elmls = {
--     filetypes = {"elm"},
--     root_dir = root_pattern("elm.json", ".git")
--   },
--   tsserver = {
--     filetypes = {
--       "javascript",
--       "javascriptreact",
--       "javascript.jsx",
--       "typescript",
--       "typescriptreact",
--       "typescript.tsx"
--     },
--     -- See https://github.com/neovim/nvim-lsp/issues/237
--     root_dir = root_pattern("tsconfig.json", "package.json", ".git")
--   },
-- }
local servers = {
  "bashls",
  "elmls",
  "clangd",
  "cssls",
  "html",
  "rust_analyzer",
  "vimls"
}
for _, ls in ipairs(servers) do
  lspconfig[ls].setup(
    {
      on_attach = on_attach,
      capabilities = capabilities,
      flags = {debounce_text_changes = 150}
    }
  )
end

local efm_languages = require("efm")
lspconfig["efm"].setup(
  {
    init_options = {documentFormatting = true},
    filetypes = vim.tbl_keys(efm_languages),
    settings = {
      rootMarkers = {"mix.lock", "mix.exs", "elm.json", "package.json", ".git"},
      lintDebounce = 500,
      logLevel = 2,
      logFile = fn.expand("$XDG_CACHE_HOME/nvim") .. "/efm-lsp.log",
      languages = efm_languages
    },
    on_attach = on_attach,
    capabilities = capabilities,
    flags = {debounce_text_changes = 150}
  }
)

lspconfig["yamlls"].setup(
  {
    settings = {
      yaml = {
        schemas = {
          ["http://json.schemastore.org/github-workflow"] = ".github/workflows/*.{yml,yaml}",
          ["http://json.schemastore.org/github-action"] = ".github/action.{yml,yaml}",
          ["http://json.schemastore.org/ansible-stable-2.9"] = "roles/tasks/*.{yml,yaml}",
          ["http://json.schemastore.org/prettierrc"] = ".prettierrc.{yml,yaml}",
          ["http://json.schemastore.org/stylelintrc"] = ".stylelintrc.{yml,yaml}",
          ["http://json.schemastore.org/circleciconfig"] = ".circleci/**/*.{yml,yaml}"
        },
        format = {enable = true},
        validate = true,
        hover = true,
        completion = true
      },
      on_attach = on_attach,
      capabilities = capabilities,
      flags = {debounce_text_changes = 150}
    }
  }
)

lspconfig["elixirls"].setup(
  {
    cmd = {fn.expand("$XDG_CONFIG_HOME/lsp/elixir_ls/release") .. "/language_server.sh"},
    settings = {
      elixirLS = {
        fetchDeps = false,
        dialyzerEnabled = false,
        enableTestLenses = true,
        suggestSpecs = true
      }
    },
    filetypes = {"elixir", "eelixir"},
    root_dir = root_pattern("mix.exs", ".git"),
    on_attach = on_attach,
    capabilities = capabilities,
    flags = {debounce_text_changes = 150}
  }
)

lspconfig["sumneko_lua"].setup(
  {
    settings = {
      Lua = {
        completion = {keywordSnippet = "Disable"},
        runtime = {
          -- Tell the language server which version of Lua you're using (most likely LuaJIT in the case of Neovim)
          version = "LuaJIT",
          -- Setup your lua path
          path = runtime_path
        },
        diagnostics = {
          -- Get the language server to recognize the `vim` global
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
            "mega"
          }
        },
        workspace = {
          -- Make the server aware of Neovim runtime files
          library = api.nvim_get_runtime_file("", true)
          --     library = get_lua_runtime()
        },
        -- Do not send telemetry data containing a randomized but unique identifier
        telemetry = {
          enable = false
        }
      }
    },
    cmd = {
      fn.getenv("XDG_CONFIG_HOME") .. "/lsp/sumneko_lua/bin/" .. fn.getenv("PLATFORM") .. "/lua-language-server",
      "-E",
      fn.getenv("XDG_CONFIG_HOME") .. "/lsp/sumneko_lua/main.lua"
    },
    on_attach = on_attach,
    capabilities = capabilities,
    flags = {debounce_text_changes = 150}
  }
)

lspconfig["jsonls"].setup(
  {
    commands = {
      Format = {
        function()
          lsp.buf.range_formatting({}, {0, 0}, {fn.line("$"), 0})
        end
      }
    },
    settings = {
      json = {
        format = {enable = true},
        schemas = {
          {
            description = "Lua sumneko setting schema validation",
            fileMatch = {"*.lua"},
            url = "https://raw.githubusercontent.com/sumneko/vscode-lua/master/setting/schema.json"
          },
          {
            description = "TypeScript compiler configuration file",
            fileMatch = {"tsconfig.json", "tsconfig.*.json"},
            url = "http://json.schemastore.org/tsconfig"
          },
          {
            description = "Lerna config",
            fileMatch = {"lerna.json"},
            url = "http://json.schemastore.org/lerna"
          },
          {
            description = "Babel configuration",
            fileMatch = {
              ".babelrc.json",
              ".babelrc",
              "babel.config.json"
            },
            url = "http://json.schemastore.org/lerna"
          },
          {
            description = "ESLint config",
            fileMatch = {".eslintrc.json", ".eslintrc"},
            url = "http://json.schemastore.org/eslintrc"
          },
          {
            description = "Bucklescript config",
            fileMatch = {"bsconfig.json"},
            url = "https://bucklescript.github.io/bucklescript/docson/build-schema.json"
          },
          {
            description = "Prettier config",
            fileMatch = {
              ".prettierrc",
              ".prettierrc.json",
              "prettier.config.json"
            },
            url = "http://json.schemastore.org/prettierrc"
          },
          {
            description = "Vercel Now config",
            fileMatch = {"now.json", "vercel.json"},
            url = "http://json.schemastore.org/now"
          },
          {
            description = "Stylelint config",
            fileMatch = {
              ".stylelintrc",
              ".stylelintrc.json",
              "stylelint.config.json"
            },
            url = "http://json.schemastore.org/stylelintrc"
          }
        }
      }
    },
    on_attach = on_attach,
    capabilities = capabilities,
    flags = {debounce_text_changes = 150}
  }
)

-- local null_ls_sources = {
-- 	require("null-ls").builtins.formatting.prettier,
-- 	require("null-ls").builtins.formatting.stylua,
-- 	require("null-ls").builtins.diagnostics.eslint.with({ command = "eslint_d" }),
-- 	require("null-ls").builtins.diagnostics.write_good,
-- 	require("null-ls").builtins.code_actions.gitsigns,
-- }

-- require("null-ls").config({
--     sources = null_ls_sources
-- })

-- for server, config in pairs(servers) do
--   local server_disabled = (config.disabled ~= nil and config.disabled) or false

--   inspect("-> unable to load lsp config", {server, config, lspconfig})

--   if lspconfig[server] == nil or config == nil or lspconfig == nil or server == nil then
--     inspect("-> unable to load lsp config", {server, config, lspconfig})
--     return
--   end

--   if not server_disabled then
--     lspconfig[server].setup(
--       vim.tbl_deep_extend(
--         "force",
--         {
--           on_attach = on_attach,
--           capabilities = capabilities,
--           flags = {debounce_text_changes = 150}
--         },
--         config
--       )
--     )
--   end
-- end

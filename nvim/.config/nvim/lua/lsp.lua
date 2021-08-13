local cmd, lsp, api, fn, set = vim.cmd, vim.lsp, vim.api, vim.fn, vim.opt
local map, bufmap, au = mega.map, mega.bufmap, mega.au
local lspconfig = require("lspconfig")
local colors = require("colors")
local utils = require("utils")

set.completeopt = { "menu", "menuone", "noselect", "noinsert" }
set.shortmess:append("c")

do
	local sign_error = colors.icons.sign_error
	local sign_warning = colors.icons.sign_warning
	local sign_information = colors.icons.sign_information
	local sign_hint = colors.icons.sign_hint

	fn.sign_define("LspDiagnosticsSignError", { text = sign_error, numhl = "LspDiagnosticsDefaultError" })
	fn.sign_define("LspDiagnosticsSignWarning", { text = sign_warning, numhl = "LspDiagnosticsDefaultWarning" })
	fn.sign_define(
		"LspDiagnosticsSignInformation",
		{ text = sign_information, numhl = "LspDiagnosticsDefaultInformation" }
	)
	fn.sign_define("LspDiagnosticsSignHint", { text = sign_hint, numhl = "LspDiagnosticsDefaultHint" })
end

--- LSP handlers
-- diagnostics
lsp.handlers["textDocument/publishDiagnostics"] = lsp.with(lsp.diagnostic.on_publish_diagnostics, {
	underline = true,
	virtual_text = {
		prefix = "",
		spacing = 4,
		severity_limit = "Warning",
	},
	signs = true, -- {severity_limit = "Warning"},
	update_in_insert = false,
	severity_sort = true,
})

-- monkeypatch: only show one virtual text prefix for all of the possible diagnostic items on a line..
-- REF: https://www.reddit.com/r/neovim/comments/p0jx12/weird_diagnostic_signs_behavior/h898ft6/
vim.lsp.diagnostic.get_virtual_text_chunks_for_line = function(bufnr, line, line_diags, opts)
	return utils.lsp.set_virtual_text_chunks(bufnr, line, line_diags, opts)
end

-- hover
-- NOTE: the hover handler returns the bufnr,winnr so can be used for mappings
vim.lsp.handlers["textDocument/hover"] = vim.lsp.with(vim.lsp.handlers.hover, {
	border = "rounded",
	max_width = math.max(math.floor(vim.o.columns * 0.7), 100),
	max_height = math.max(math.floor(vim.o.lines * 0.3), 30),
})

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

			-- FIXME: do i need this stuffs?
			-- Trigger post-formatting autocommand which can be used to refresh gitgutter
			api.nvim_command("silent doautocmd <nomodeline> User FormatterPost")
		end
	end
end

--- completion
require("compe").setup({
	enabled = true,
	autocomplete = true,
	debug = false,
	min_length = 1,
	preselect = "disable",
	allow_prefix_unmatch = false,
	throttle_time = 80,
	source_timeout = 200,
	incomplete_delay = 400,
	max_abbr_width = 100,
	max_kind_width = 100,
	max_menu_width = 100,
	documentation = {
		border = "rounded",
		winhighlight = table.concat({
			"NormalFloat:CompeDocumentation",
			"Normal:CompeDocumentation",
			"FloatBorder:CompeDocumentationBorder",
		}, ","),
	},
	source = {
		luasnip = { menu = " [lsnip]", priority = 12 },
		nvim_lua = { menu = "[lua]", priority = 11 },
		nvim_lsp = { menu = " [lsp]", priority = 10 },
		orgmode = { menu = "[org]", priority = 9, filetypes = { "org" } },
		neorg = { menu = "[norg]", priority = 9, filetypes = { "org" } },
		path = { menu = " [path]", priority = 8 },
		emoji = { menu = "ﲃ [emo]", priority = 8, filetypes = { "markdown", "gitcommit" } },
		spell = { menu = " [spl]", priority = 8, filetypes = { "markdown", "org" } },
		buffer = { menu = " [buf]", priority = 7 },
		treesitter = false, --{menu = "[ts]", priority = 9},
	},
})

require("vim.lsp.protocol").CompletionItemKind = {
	-- "", -- Text          = 1;
	-- "", -- Method        = 2;
	-- "ƒ", -- Function      = 3;
	-- "", -- Constructor   = 4;
	-- "", -- Field         = 5;
	-- "", -- Variable      = 6;
	-- "", -- Class         = 7;
	-- "ﰮ", -- Interface     = 8;
	-- "", -- Module        = 9;
	-- "", -- Property      = 10;
	-- "", -- Unit          = 11;
	-- "", -- Value         = 12;
	-- "了", -- Enum          = 13;
	-- "", -- Keyword       = 14;
	-- "﬌", -- Snippet       = 15;
	-- "", -- Color         = 16;
	-- "", -- File          = 17;
	-- "", -- Reference     = 18;
	-- "", -- Folder        = 19;
	-- "", -- EnumMember    = 20;
	-- "", -- Constant      = 21;
	-- "", -- Struct        = 22;
	-- "⌘", -- Event         = 23;
	-- "", -- Operator      = 24;
	-- "♛" -- TypeParameter = 25;

	" Text", -- Text
	" Method", -- Method
	"ƒ Function", -- Function
	" Constructor", -- Constructor
	"識 Field", -- Field
	" Variable", -- Variable
	" Class", -- Class
	"ﰮ Interface", -- Interface
	" Module", -- Module
	" Property", -- Property
	" Unit", -- Unit
	" Value", -- Value
	"了 Enum", -- Enum
	" Keyword", -- Keyword
	" Snippet", -- Snippet
	" Color", -- Color
	" File", -- File
	"渚 Reference", -- Reference
	" Folder", -- Folder
	" Enum", -- Enum
	" Constant", -- Constant
	" Struct", -- Struct
	"鬒 Event", -- Event
	"\u{03a8} Operator", -- Operator
	" Type Parameter", -- TypeParameter
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
		return t("<C-n>")
	elseif require("luasnip").expand_or_jumpable() then
		return t("<cmd>lua require'luasnip'.jump(1)<Cr>")
	elseif check_back_space() then
		return t("<Tab>")
	else
		-- require("cmp").complete()
		-- return ""
		return vim.fn["compe#complete"]()
	end
end

_G.s_tab_complete = function()
	if fn.pumvisible() == 1 then
		return t("<C-p>")
	elseif require("luasnip").jumpable(-1) then
		return t("<cmd>lua require'luasnip'.jump(-1)<CR>")
	else
		return t("<S-Tab>")
	end
end

-- _G.cr_complete = function()
--   local npairs = require("nvim-autopairs")
--   if fn.pumvisible() ~= 0 then
--     return npairs.esc("<cr>")
--   else
--     return npairs.autopairs_cr()
--   end
-- end

-- REF: https://github.com/fsouza/dotfiles/blob/main/nvim/lua/fsouza/lsp/completion.lua#L16-L24
_G.cr_complete = function()
	-- if fn.pumvisible() == 1 then
	--   return fn["compe#confirm"]({keys = "<cr>", select = true})
	-- else
	--   return require("nvim-autopairs").autopairs_cr()
	-- end
	if vim.fn.pumvisible() ~= 0 then
		if vim.fn.complete_info()["selected"] ~= -1 then
			mega.log("none selected!")
			return vim.fn["compe#confirm"](t("<cr>"))
		else
			mega.log("one selected!")
			-- vim.fn["compe#confirm"]({keys = "<cr>", select = false})
			-- vim.defer_fn(
			--   function()
			--     vim.fn["compe#confirm"]({keys = "<cr>", select = false})
			--   end,
			--   20
			-- )
			return t("<c-n>")
		end
	else
		return require("nvim-autopairs").autopairs_cr()
	end
end

map("i", "<Tab>", "v:lua.tab_complete()", { expr = true, noremap = false })
map("s", "<Tab>", "v:lua.tab_complete()", { expr = true, noremap = false })
map("i", "<S-Tab>", "v:lua.s_tab_complete()", { expr = true, noremap = false })
map("s", "<S-Tab>", "v:lua.s_tab_complete()", { expr = true, noremap = false })
map("i", "<CR>", "v:lua.cr_complete()", { expr = true, noremap = true })
map("i", "<C-f>", "compe#scroll({ 'delta': +4 })", { expr = true })
map("i", "<C-d>", "compe#scroll({ 'delta': -4 })", { expr = true })

local function on_attach(client, bufnr)
	if client.config.flags then
		client.config.flags.allow_incremental_sync = true
	end

	require("lsp_signature").on_attach({
		bind = true, -- This is mandatory, otherwise border config won't get registered.
		-- hint_prefix = " ",
		floating_window = true,
		-- hi_parameter = "LspSelectedParam",
		hint_enable = false,
		handler_opts = {
			border = "rounded",
		},
	})

	if client.name == "typescript" or client.name == "tsserver" then
		local ts = require("nvim-lsp-ts-utils")
		ts.setup({
			disable_commands = false,
			enable_import_on_completion = false,
			import_on_completion_timeout = 5000,
			eslint_bin = "eslint_d", -- use eslint_d if possible!
			eslint_enable_diagnostics = true,
			-- eslint_fix_current = false,
			eslint_enable_disable_comments = true,
		})

		ts.setup_client(client)

		-- so tsserver doesn't compete with efm or null-ls
		client.resolved_capabilities.document_formatting = false
	end

	--- goto mappings
	-- bufmap("gd", "lua vim.lsp.buf.definition()")
	-- bufmap("gr", "lua vim.lsp.buf.references()")
	-- bufmap("gs", "lua vim.lsp.buf.document_symbol()")
	-- bufmap("gi", "lua vim.lsp.buf.implementation()")

	--- via fzf-lua
	bufmap("gd", "lua require('fzf-lua').lsp_definitions({ jump_to_single_result = true })")
	bufmap("gD", "lua require('utils').lsp.preview('textDocument/definition')")
	bufmap("gr", "lua require('fzf-lua').lsp_references({ jump_to_single_result = true })")
	bufmap("gs", "lua require('fzf-lua').lsp_symbols({ jump_to_single_result = true })")
	bufmap("gi", "lua require('fzf-lua').lsp_implementations({ jump_to_single_result = true })")

	--- diagnostics navigation mappings
	bufmap("[d", "lua vim.lsp.diagnostic.goto_prev()")
	bufmap("]d", "lua vim.lsp.diagnostic.goto_next()")

	--- misc mappings
	bufmap("<leader>ln", "lua require('utils').lsp.rename()")
	-- bufmap("<leader>ln", "lua vim.lsp.buf.rename()")
	-- bufmap("<leader>la", "lua vim.lsp.buf.code_action()")
	bufmap("<leader>la", "lua require('fzf-lua').lsp_code_actions({ jump_to_single_result = true })")
	bufmap(
		"<leader>ld",
		"lua vim.lsp.diagnostic.show_line_diagnostics({ border = 'rounded', show_header = false, focusable = false })"
	)
	bufmap("<C-k>", "lua vim.lsp.buf.signature_help()")
	bufmap("<C-k>", "<cmd>lua vim.lsp.buf.signature_help()<cr>", "i")
	bufmap("<leader>lf", "lua vim.lsp.buf.formatting()")

	--- trouble mappings
	map("n", "<leader>lt", "<cmd>LspTroubleToggle lsp_document_diagnostics<cr>")

	--- auto-commands
	if client.resolved_capabilities.document_formatting then
		au("BufWritePost <buffer> lua vim.lsp.buf.formatting()")
		-- au "BufWritePre <buffer> lua vim.lsp.buf.formatting_sync()"
		-- au "BufWritePre <buffer> lua vim.lsp.buf.formatting_seq_sync()"
	end

	-- au "CursorHold, CursorHoldI <buffer> lua vim.lsp.diagnostic.show_line_diagnostics({ border = 'rounded', show_header = false, focusable = false })"
	au([[User CompeConfirmDone silent! lua vim.lsp.buf.signature_help()]])

	if vim.bo.ft ~= "vim" then
		bufmap("K", "lua vim.lsp.buf.hover()")
	end

	--- commands
	FormatRange = function()
		local start_pos = api.nvim_buf_get_mark(0, "<")
		local end_pos = api.nvim_buf_get_mark(0, ">")
		lsp.buf.range_formatting({}, start_pos, end_pos)
	end
	cmd([[ command! -range FormatRange execute 'lua FormatRange()' ]])
	cmd([[ command! Format execute 'lua vim.lsp.buf.formatting_sync(nil, 1000)' ]])
	cmd([[ command! LspLog lua vim.cmd('vnew'..vim.lsp.get_log_path()) ]])

	api.nvim_buf_set_option(bufnr, "omnifunc", "v:lua.vim.lsp.omnifunc")
end

--- capabilities
local capabilities = lsp.protocol.make_client_capabilities()
capabilities.textDocument.codeLens = { dynamicRegistration = false }
capabilities.textDocument.completion.completionItem.snippetSupport = true
capabilities.textDocument.completion.completionItem.resolveSupport = {
	properties = {
		"documentation",
		"detail",
		"additionalTextEdits",
	},
}
local status_capabilities = require("lsp-status").capabilities
capabilities = mega.table_merge(status_capabilities, capabilities)

local function lsp_with_defaults(opts)
	opts = opts or {}
	return vim.tbl_deep_extend("keep", opts, {
		on_attach = on_attach,
		capabilities = capabilities,
		flags = { debounce_text_changes = 150 },
		root_dir = vim.loop.cwd,
	})
end

--- server setup utils
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
	"elmls",
	"clangd",
	"rust_analyzer",
	"vimls",
	"solargraph",
	-- "tailwindcss",
	-- "dockerfile",
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

local efm_languages = require("efm")
local efm_log = fn.expand("$XDG_CACHE_HOME/nvim") .. "/efm-lsp.log"
lspconfig["efm"].setup(lsp_with_defaults({
	init_options = { documentFormatting = true },
	filetypes = vim.tbl_keys(efm_languages),
	settings = {
		rootMarkers = { "mix.lock", "mix.exs", "elm.json", "package.json", ".git" },
		lintDebounce = 500,
		logLevel = 2,
		logFile = efm_log,
		languages = efm_languages,
	},
}))

lspconfig["yamlls"].setup(lsp_with_defaults({
	settings = {
		yaml = {
			schemas = {
				["http://json.schemastore.org/github-workflow"] = ".github/workflows/*.{yml,yaml}",
				["http://json.schemastore.org/github-action"] = ".github/action.{yml,yaml}",
				["http://json.schemastore.org/ansible-stable-2.9"] = "roles/tasks/*.{yml,yaml}",
				["http://json.schemastore.org/prettierrc"] = ".prettierrc.{yml,yaml}",
				["http://json.schemastore.org/stylelintrc"] = ".stylelintrc.{yml,yaml}",
				["http://json.schemastore.org/circleciconfig"] = ".circleci/**/*.{yml,yaml}",
			},
			format = { enable = true },
			validate = true,
			hover = true,
			completion = true,
		},
	},
}))
do
	local manipulate_pipes = function(command)
		return function()
			local position_params = vim.lsp.util.make_position_params()
			vim.lsp.buf.execute_command({
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
		cmd = { fn.expand("$XDG_CONFIG_HOME/lsp/elixir_ls/release") .. "/language_server.sh" },
		settings = {
			elixirLS = {
				fetchDeps = false,
				dialyzerEnabled = false,
				enableTestLenses = true,
				suggestSpecs = true,
			},
		},
		filetypes = { "elixir", "eelixir" },
		root_dir = root_pattern("mix.exs", ".git"),
		commands = {
			ToPipe = { manipulate_pipes("toPipe"), "Convert function call to pipe operator" },
			FromPipe = { manipulate_pipes("fromPipe"), "Convert pipe operator to function call" },
		},
	}))
end

do -- lua
	-- local function get_lua_runtime()
	--   local result = {}
	--   for _, path in pairs(api.nvim_list_runtime_paths()) do
	--     local lua_path = path .. "/lua/"
	--     if fn.isdirectory(lua_path) then
	--       result[lua_path] = true
	--     end
	--   end

	--   result[fn.expand("$VIMRUNTIME/lua")] = true
	--   result[fn.expand("$VIMRUNTIME/lua/vim/lsp")] = true
	--   result[fn.expand("/Applications/Hammerspoon.app/Contents/Resources/extensions/hs")] = true

	--   return result
	-- end

	-- (build lua runtime libraries)
	local runtime_path = vim.split(package.path, ";")
	table.insert(runtime_path, "lua/?.lua")
	table.insert(runtime_path, "lua/?/init.lua")
	table.insert(runtime_path, fn.expand("/Applications/Hammerspoon.app/Contents/Resources/extensions/hs/?.lua"))
	table.insert(runtime_path, fn.expand("/Applications/Hammerspoon.app/Contents/Resources/extensions/hs/?/?.lua"))
	table.insert(runtime_path, fn.expand("~/.hammerspoon/Spoons/EmmyLua.spoon/annotations"))
	local luadev = require("lua-dev").setup({
		lspconfig = lsp_with_defaults({
			settings = {
				Lua = {
					completion = { keywordSnippet = "Replace", callSnippet = "Replace" }, -- or `Disable`
					runtime = {
						-- Tell the language server which version of Lua you're using (most likely LuaJIT in the case of Neovim)
						version = "LuaJIT",
						-- Setup your lua path
						path = runtime_path,
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
							"mega",
						},
					},
					workspace = {
						-- Make the server aware of Neovim runtime files
						library = api.nvim_get_runtime_file("", true),
						--     library = get_lua_runtime()
					},
					-- Do not send telemetry data containing a randomized but unique identifier
					telemetry = {
						enable = false,
					},
				},
			},
			cmd = {
				fn.getenv("XDG_CONFIG_HOME")
					.. "/lsp/sumneko_lua/bin/"
					.. fn.getenv("PLATFORM")
					.. "/lua-language-server",
				"-E",
				fn.getenv("XDG_CONFIG_HOME") .. "/lsp/sumneko_lua/main.lua",
			},
		}),
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
			format = { enable = true },
			-- TODO: clean up please!
			-- more useful schemas:
			-- https://github.com/sethigeet/Dotfiles/blob/master/.config/nvim/lua/lsp/language_servers/json.lua#L27
			schemas = {
				{
					description = "Lua sumneko setting schema validation",
					fileMatch = { "*.lua" },
					url = "https://raw.githubusercontent.com/sumneko/vscode-lua/master/setting/schema.json",
				},
				{
					description = "TypeScript compiler configuration file",
					fileMatch = { "tsconfig.json", "tsconfig.*.json" },
					url = "http://json.schemastore.org/tsconfig",
				},
				{
					description = "Lerna config",
					fileMatch = { "lerna.json" },
					url = "http://json.schemastore.org/lerna",
				},
				{
					description = "Babel configuration",
					fileMatch = {
						".babelrc.json",
						".babelrc",
						"babel.config.json",
					},
					url = "http://json.schemastore.org/lerna",
				},
				{
					description = "ESLint config",
					fileMatch = { ".eslintrc.json", ".eslintrc" },
					url = "http://json.schemastore.org/eslintrc",
				},
				{
					description = "Bucklescript config",
					fileMatch = { "bsconfig.json" },
					url = "https://bucklescript.github.io/bucklescript/docson/build-schema.json",
				},
				{
					description = "Prettier config",
					fileMatch = {
						".prettierrc",
						".prettierrc.json",
						"prettier.config.json",
					},
					url = "http://json.schemastore.org/prettierrc",
				},
				{
					description = "Vercel Now config",
					fileMatch = { "now.json", "vercel.json" },
					url = "http://json.schemastore.org/now",
				},
				{
					description = "Stylelint config",
					fileMatch = {
						".stylelintrc",
						".stylelintrc.json",
						"stylelint.config.json",
					},
					url = "http://json.schemastore.org/stylelintrc",
				},
			},
		},
	},
}))

lspconfig["cssls"].setup(lsp_with_defaults({ cmd = { "vscode-css-language-server", "--stdio" } }))
lspconfig["html"].setup(lsp_with_defaults({
	cmd = { "vscode-html-language-server", "--stdio" },
	init_options = {
		configurationSection = { "html", "css", "javascript", "eelixir" },
		embeddedLanguages = {
			css = true,
			javascript = true,
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
	local nls = require("null-ls")
	nls.config({
		debounce = 150,
		save_after_format = false,
		sources = {
			nls.builtins.formatting.trim_whitespace.with({ filetypes = { "*" } }),
			nls.builtins.formatting.prettierd,
			nls.builtins.formatting.stylua,
			nls.builtins.formatting.eslint_d, --https://github.com/wesbos/eslint-config-wesbos
			nls.builtins.formatting.mix,
			nls.builtins.formatting.elm_format,
			-- nls.builtins.formatting.lua_format,
			nls.builtins.diagnostics.shellcheck,
			nls.builtins.diagnostics.markdownlint,
			-- nls.builtins.diagnostics.selene,
			nls.builtins.diagnostics.write_good,
			nls.builtins.diagnostics.eslint.with({ command = "eslint_d" }),
		},
	})
	-- lspconfig["null-ls"].setup(lsp_with_defaults())
end

-- lspconfig["zk"].setup(lsp_with_defaults(
--   {
--     cmd = {"zk", "lsp", "--log", "/tmp/zk-lsp.log"},
--     filetypes = {"markdown", "md"},
--     root_dir = function()
--       return vim.loop.cwd()
--     end,
--     settings = {},
--   })
-- )
---@diagnostic disable-next-line: unused-local
local cmd, lsp, api, fn, set, g = vim.cmd, vim.lsp, vim.api, vim.fn, vim.opt, vim.g
local map, bufmap, au = mega.map, mega.bufmap, mega.au
local lspconfig = require("lspconfig")
local luasnip = require("luasnip")
local colors = require("colors")
local utils = require("utils")

local snippet_provider = "luasnip" -- vsnip or luasnip
local formatting_provider = "efm" -- efm or null-ls
local completion_provider = "cmp" -- cmp or compe

set.completeopt = { "menu", "menuone", "noselect", "noinsert" }
set.shortmess:append("c") -- Don't pass messages to |ins-completion-menu|

local function setup_diagnostics()
	local sign_error = colors.icons.sign_error
	local sign_warning = colors.icons.sign_warning
	local sign_information = colors.icons.sign_information
	local sign_hint = colors.icons.sign_hint

	fn.sign_define(
		"DiagnosticSignError",
		{ text = sign_error, texthl = "DiagnosticDefaultError", numhl = "DiagnosticDefaultError" }
	)
	fn.sign_define(
		"DiagnosticSignWarning",
		{ text = sign_warning, texthl = "DiagnosticDefaultWarning", numhl = "DiagnosticDefaultWarning" }
	)
	fn.sign_define(
		"DiagnosticSignInformation",
		{ text = sign_information, texthl = "DiagnosticDefaultWarning", numhl = "DiagnosticDefaultInformation" }
	)
	fn.sign_define(
		"DiagnosticSignHint",
		{ text = sign_hint, texthl = "DiagnosticDefaultWarning", numhl = "DiagnosticDefaultHint" }
	)

	-- vim.cmd([[
	--     sign define DiagnosticSignError text= texthl=DiagnosticSignError linehl= numhl=
	--     sign define DiagnosticSignWarn text= texthl=DiagnosticSignWarn linehl= numhl=
	--     sign define DiagnosticSignInfo text= texthl=DiagnosticSignInfo linehl= numhl=
	--     sign define DiagnosticSignHint text= texthl=DiagnosticSignHint linehl= numhl=
	--   ]])

	-- NOTE: recent updates to neovim vim.lsp.diagnostic to vim.diagnostic:
	-- REF: https://github.com/neovim/neovim/pull/15585
	vim.diagnostic.config({
		underline = true,
		-- virtual_text = false,
		virtual_text = {
			prefix = "",
			spacing = 4,
			severity_limit = "Warning",
		},
		signs = true, -- {severity_limit = "Warning"},
		update_in_insert = false,
		severity_sort = true,
		source = "if_many",
	})

	-- monkeypatch: only show one virtual text prefix for all of the possible diagnostic items on a line..
	-- lsp.diagnostic.get_virtual_text_chunks_for_line = function(bufnr, line, line_diags, opts)
	-- 	return utils.lsp.set_virtual_text_chunks(bufnr, line, line_diags, opts)
	-- end
end

local function setup_lsp_handlers()
	-- hover
	-- NOTE: the hover handler returns the bufnr,winnr so can be used for mappings
	lsp.handlers["textDocument/hover"] = vim.lsp.with(vim.lsp.handlers.hover, {
		border = "rounded",
		max_width = math.max(math.floor(vim.o.columns * 0.7), 100),
		max_height = math.max(math.floor(vim.o.lines * 0.3), 30),
	})

	-- formatting
	lsp.handlers["textDocument/formatting"] = function(err, _, result, _, bufnr)
		if err ~= nil or result == nil then
			return
		end
		if api.nvim_buf_get_var(bufnr, "init_changedtick") == vim.api.nvim_buf_get_var(bufnr, "changedtick") then
			local view = vim.fn.winsaveview()
			lsp.util.apply_text_edits(result, bufnr)
			fn.winrestview(view)
			if bufnr == vim.api.nvim_get_current_buf() then
				vim.b.saving_format = true
				cmd([[update]])
				api.nvim_command("noautocmd :update")
				vim.b.saving_format = false
			end
		end
	end
end

local function setup_completion()
	if snippet_provider == "luasnip" then
		-- [luasnip] --
		local types = require("luasnip.util.types")
		luasnip.config.set_config({
			history = false,
			updateevents = "TextChanged,TextChangedI",
			store_selection_keys = "<Tab>",
			ext_opts = {
				[types.insertNode] = {
					passive = {
						hl_group = "Substitute",
					},
				},
				[types.choiceNode] = {
					active = {
						virt_text = { { "choiceNode", "IncSearch" } },
					},
				},
			},
			enable_autosnippets = true,
		})
		require("luasnip/loaders/from_vscode").load({
			paths = vim.fn.stdpath("config") .. "/snippets",
			-- TODO: should get these for react/javascript/ts:
			-- https://github.com/Lazytangent/nvim-conf/tree/main/lua/snippets
		})

		--- <tab> to jump to next snippet's placeholder
		local function on_tab()
			return luasnip.jump(1) and "" or utils.t("<Tab>")
		end
		--- <s-tab> to jump to next snippet's placeholder
		local function on_s_tab()
			return luasnip.jump(-1) and "" or utils.t("<S-Tab>")
		end
		local opts = { expr = true, noremap = false }
		map("i", "<Tab>", on_tab, opts)
		map("s", "<Tab>", on_tab, opts)
		map("i", "<S-Tab>", on_s_tab, opts)
		map("s", "<S-Tab>", on_s_tab, opts)
	end

	if completion_provider == "cmp" then
		-- [nvim-cmp] --
		local kind_icons = {
			Text = " text", -- Text
			Method = " method", -- Method
			Function = "ƒ function", -- Function
			Constructor = " constructor", -- Constructor
			Field = "識field", -- Field
			Variable = " variable", -- Variable
			Class = " class", -- Class
			Interface = "ﰮ interface", -- Interface
			Module = " module", -- Module
			Property = " property", -- Property
			Unit = " unit", -- Unit
			Value = " value", -- Value
			Enum = "了enum", -- Enum 
			Keyword = " keyword", -- Keyword
			Snippet = " snippet", -- Snippet
			Color = " color", -- Color
			File = " file", -- File
			Reference = "渚ref", -- Reference
			Folder = " folder", -- Folder
			EnumMember = " enum member", -- EnumMember
			Constant = " const", -- Constant
			Struct = " struct", -- Struct
			Event = "鬒event", -- Event
			Operator = "\u{03a8} operator", -- Operator
			TypeParameter = " type param", -- TypeParameter
		}

		local function tab(fallback)
			if fn.pumvisible() == 1 then
				return fn.feedkeys(utils.t("<C-n>"), "n")
			elseif luasnip and luasnip.expand_or_jumpable() then
				return fn.feedkeys(utils.t("<Plug>luasnip-expand-or-jump"), "")
			elseif utils.check_back_space() then
				fn.feedkeys(utils.t("<Tab>"), "n")
			else
				fallback()
			end
		end

		local function shift_tab(fallback)
			if fn.pumvisible() == 1 then
				fn.feedkeys(utils.t("<C-p>"), "n")
			elseif luasnip and luasnip.jumpable(-1) then
				fn.feedkeys(utils.t("<Plug>luasnip-jump-prev"), "")
			else
				fallback()
			end
		end

		require("cmp_nvim_lsp").setup()
		local cmp = require("cmp")
		-- local types = require("cmp.types")
		cmp.setup({
			experimental = {
				ghost_text = false,
			},
			completion = {
				-- autocomplete = {
				-- 	types.cmp.TriggerEvent.InsertEnter,
				-- 	types.cmp.TriggerEvent.TextChanged,
				-- },
				keyword_length = 1,
			},
			snippet = {
				expand = function(args)
					luasnip.lsp_expand(args.body)
				end,
			},
			documentation = {
				border = "rounded",
			},
			mapping = {
				["<Tab>"] = cmp.mapping(tab, { "i", "s" }),
				["<S-Tab>"] = cmp.mapping(shift_tab, { "i", "s" }),
				["<C-b>"] = cmp.mapping.scroll_docs(-4),
				["<C-f>"] = cmp.mapping.scroll_docs(4),
				["<C-Space>"] = cmp.mapping.complete(),
				["<C-e>"] = cmp.mapping.close(),
			},
			sources = {
				{ name = "luasnip" },
				{ name = "nvim_lua" },
				{ name = "nvim_lsp" },
				{ name = "orgmode" },
				{ name = "spell" },
				{ name = "emoji" },
				{ name = "path" },
				{
					name = "buffer",
					opts = {
						get_bufnrs = function()
							local bufs = {}
							for _, win in ipairs(api.nvim_list_wins()) do
								bufs[api.nvim_win_get_buf(win)] = true
							end
							return vim.tbl_keys(bufs)
						end,
					},
				},
			},
			formatting = {
				format = function(entry, item)
					item.kind = kind_icons[item.kind]
					item.menu = ({
						luasnip = snippet_provider == "luasnip" and "[lsnip]" or false,
						vsnip = snippet_provider == "vsnip" and "[vsnip]" or false,
						nvim_lsp = "[lsp]",
						orgmode = "[org]",
						path = "[path]",
						buffer = "[buf]",
						spell = "[spl]",
						-- calc = "[calc]",
						-- emoji = "[emo]",
					})[entry.source.name]
					return item
				end,
			},
		})
		-- # while using nvim-autopairs we want to fully control what the <CR> key does:
		require("nvim-autopairs.completion.cmp").setup({
			map_cr = true,
			map_complete = true,
			auto_select = false,
		})
	end
end

local function on_attach(client, bufnr)
	if client.config.flags then
		client.config.flags.allow_incremental_sync = true
	end

	require("lsp_signature").on_attach({
		bind = true, -- This is mandatory, otherwise border config won't get registered.
		floating_window = true,
		floating_window_above_cur_line = true, -- try to place the floating above the current line
		floating_window_off_y = 1, -- adjust float windows y position. allow the pum to show a few lines
		hint_enable = false,
		decorator = { "`", "`" },
		handler_opts = {
			border = "rounded",
		},
	})

	--- # goto mappings
	if pcall(require, "fzf-lua") then
		--- # via fzf-lua
		--  * https://github.com/ibhagwan/fzf-lua/issues/39#issuecomment-897099304 (LSP async/sync)
		bufmap("gd", "lua require('fzf-lua').lsp_definitions()")
		bufmap("gD", "lua require('utils').lsp.preview('textDocument/definition')")
		bufmap("gr", "lua require('fzf-lua').lsp_references()")
		bufmap("gs", "lua require('fzf-lua').lsp_symbols()")
		bufmap("gi", "lua require('fzf-lua').lsp_implementations()")
		bufmap("<leader>la", "lua require('fzf-lua').lsp_code_actions()")
		bufmap("<leader>ca", "lua require('fzf-lua').lsp_code_actions()")
	else
		-- # via defaults
		bufmap("gd", "lua vim.lsp.buf.definition()")
		bufmap("gr", "lua vim.lsp.buf.references()")
		bufmap("gs", "lua vim.lsp.buf.document_symbol()")
		bufmap("gi", "lua vim.lsp.buf.implementation()")
		bufmap("<leader>la", "lua vim.lsp.buf.code_action()")
	end

	--- # diagnostics navigation mappings
	bufmap("[d", "lua vim.diagnostic.goto_prev()")
	bufmap("]d", "lua vim.diagnostic.goto_next()")

	--- # misc mappings
	-- bufmap("<leader>ln", "lua vim.lsp.buf.rename()")
	bufmap("<leader>ln", "lua require('utils').lsp.rename()")
	bufmap(
		"<leader>ld",
		"lua vim.lsp.diagnostic.show_line_diagnostics({ border = 'rounded', show_header = false, focusable = false })"
	)
	-- bufmap("K", "lua require('utils').lsp.hover()")
	bufmap("K", "lua vim.lsp.buf.hover()")
	bufmap("<C-k>", "lua vim.lsp.buf.signature_help()")
	bufmap("<C-k>", "<cmd>lua vim.lsp.buf.signature_help()<cr>", "i")
	bufmap("<leader>lf", "lua vim.lsp.buf.formatting()")

	if client.resolved_capabilities.code_lens then
		bufmap("<leader>ll", "lua vim.lsp.codelens.run()")
	end

	--- # trouble mappings
	map("n", "<leader>lt", "<cmd>LspTroubleToggle lsp_document_diagnostics<cr>")

	--- # autocommands/autocmds
	-- au("CursorHold,CursorHoldI <buffer> lua vim.diagnostic.show_line_diagnostics({focusable=false})")

	-- FIXME: totes does the wrong thing with other buffer diagnostics
	-- au([[User LspDiagnosticsChanged :lua require('utils').lsp.refresh_diagnostics()]])
	-- au([[CursorHold,CursorHoldI <buffer> lua require('utils').lsp.show_diagnostics()]])
	--
	-- au([[CursorHoldI <buffer> lua vim.lsp.buf.signature_help()]]) -- using lsp-signature
	au("CursorMoved <buffer> lua vim.lsp.buf.clear_references()")

	if client.resolved_capabilities.document_formatting then
		au("BufWritePre <buffer> lua vim.lsp.buf.formatting_sync()")
	end
	if client.resolved_capabilities.code_lens then
		au("CursorHold,CursorHoldI,InsertLeave <buffer> lua vim.lsp.codelens.refresh()")
	end

	--- # commands
	FormatRange = function()
		local start_pos = api.nvim_buf_get_mark(0, "<")
		local end_pos = api.nvim_buf_get_mark(0, ">")
		lsp.buf.range_formatting({}, start_pos, end_pos)
	end
	cmd([[ command! -range FormatRange execute 'lua FormatRange()' ]])
	cmd([[ command! Format execute 'lua vim.lsp.buf.formatting_sync(nil, 1000)' ]])
	cmd([[ command! LspLog lua vim.cmd('vnew'..vim.lsp.get_log_path()) ]])

	--- # client-specific configs
	-- (zk)
	if client.name == "zk" then
		au([[BufNewFile,BufWritePost <buffer> call jobstart('zk index') ]])
		bufmap("<CR>", "<cmd>'<,'>lua vim.lsp.buf.range_code_action()<CR>", "v")
		bufmap("<CR>", "lua vim.lsp.buf.definition()")
		bufmap("K", "lua vim.lsp.buf.hover()")

		-- REF: special thanks @mhanberg ->
		-- https://github.com/mhanberg/.dotfiles/blob/main/config/nvim/lua/plugin/zk.lua
	end

	if client.name == "jsonls" then
		client.resolved_capabilities.document_formatting = false
	end

	-- (typescript/tsserver)
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

	api.nvim_buf_set_option(bufnr, "omnifunc", "v:lua.vim.lsp.omnifunc")
end

local function setup_lsp_capabilities()
	--- capabilities
	local capabilities = lsp.protocol.make_client_capabilities()
	capabilities.textDocument.codeLens = { dynamicRegistration = false }
	capabilities.textDocument.completion.completionItem.documentationFormat = { "markdown" }

	if completion_provider == "cmp" then
		capabilities = require("cmp_nvim_lsp").update_capabilities(capabilities)
	end

	local status_capabilities = require("lsp-status").capabilities

	return mega.table_merge(status_capabilities, capabilities)
end

local function setup_lsp_servers()
	local function lsp_with_defaults(opts)
		opts = opts or {}
		return vim.tbl_deep_extend("keep", opts, {
			autostart = true,
			on_attach = on_attach,
			capabilities = setup_lsp_capabilities(),
			flags = { debounce_text_changes = 500 },
			root_dir = vim.loop.cwd,
		})
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
		"elmls",
		"clangd",
		"rust_analyzer",
		"vimls",
		"pyright",
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

	do
		if formatting_provider == "efm" then
			local efm_languages = require("efm")
			local efm_log = fn.expand("$XDG_CACHE_HOME/nvim") .. "/efm-lsp.log"
			lspconfig["efm"].setup(lsp_with_defaults({
				init_options = { documentFormatting = true },
				cmd = { "efm-langserver", "-loglevel", "5" },
				filetypes = vim.tbl_keys(efm_languages),
				settings = {
					rootMarkers = { "mix.lock", "mix.exs", "elm.json", "package.json", ".git" },
					lintDebounce = 500,
					logLevel = 5,
					logFile = efm_log,
					languages = efm_languages,
				},
			}))
		elseif formatting_provider == "null-ls" then
			local nls = require("null-ls")
			nls.config({
				debounce = 150,
				save_after_format = false,
				sources = {
					nls.builtins.formatting.trim_whitespace.with({ filetypes = { "*" } }),
					nls.builtins.formatting.prettierd,
					nls.builtins.formatting.stylua,
					nls.builtins.formatting.eslint_d, --https://github.com/wesbos/eslint-config-wesbos
					-- nls.builtins.formatting.mix,
					nls.builtins.formatting.elm_format,
					-- nls.builtins.formatting.lua_format,
					nls.builtins.diagnostics.shellcheck,
					nls.builtins.diagnostics.markdownlint,
					nls.builtins.diagnostics.mix_credo.with({ filetypes = { "elixir", "eelixir" } }),
					-- nls.builtins.diagnostics.selene,
					nls.builtins.diagnostics.write_good,
					nls.builtins.diagnostics.eslint.with({ command = "eslint_d" }),
				},
			})
			lspconfig["null-ls"].setup(lsp_with_defaults())
		end
	end

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
		-- 	local elixirlsp_cmd = function()
		-- 		local project_root = root_pattern("mix.exs")
		-- 		local is_mix = project_root ~= nil and project_root ~= ""
		-- 		local has_elixirls = fn.expand(string.format("%s/.elixir_ls", project_root))
		-- 		print(has_elixirls)

		-- 		-- if has_elixirls
		-- 	end
		-- 	mega.ex_cmd = elixirlsp_cmd

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
		-- (build lua runtime libraries)
		local runtime_path = vim.split(package.path, ";")
		table.insert(runtime_path, "lua/?.lua")
		table.insert(runtime_path, "lua/?/init.lua")
		-- table.insert(runtime_path, fn.expand("/Applications/Hammerspoon.app/Contents/Resources/extensions/hs/?.lua"))
		-- table.insert(runtime_path, fn.expand("/Applications/Hammerspoon.app/Contents/Resources/extensions/hs/?/?.lua"))
		-- table.insert(runtime_path, fn.expand("~/.hammerspoon/Spoons/EmmyLua.spoon/annotations"))

		local sumneko_lua_settings = lsp_with_defaults({
			settings = {
				Lua = {
					completion = { keywordSnippet = "Replace", callSnippet = "Replace" }, -- or `Disable`
					runtime = {
						-- Tell the language server which version of Lua you're using (most likely LuaJIT in the case of Neovim)
						version = "LuaJIT",
						-- Setup your lua path
						-- path = runtime_path,
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
					-- do not send telemetry data containing a randomized but unique identifier
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
				'--logpath="' .. vim.fn.stdpath("cache") .. '/nvim/log"',
				'--metapath="' .. vim.fn.stdpath("cache") .. '/nvim/meta"',
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
		local configs = require("lspconfig/configs")
		configs.emmet_ls = {
			default_config = {
				cmd = { "emmet-ls", "--stdio" },
				filetypes = { "html", "css", "eelixir", "eruby", "javascriptreact", "typescriptreact" },
				root_dir = function(_)
					return vim.loop.cwd()
				end,
				settings = {},
			},
		}
		lspconfig.emmet_ls.setup(lsp_with_defaults())
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
			vim.lsp.buf.execute_command({
				command = "zk.index",
				arguments = { vim.api.nvim_buf_get_name(0) },
			})
		end

		configs.zk.new = function(...)
			vim.lsp.buf_request(0, "workspace/executeCommand", {
				command = "zk.new",
				arguments = {
					vim.api.nvim_buf_get_name(0),
					...,
				},
			}, function(_, _, result)
				if not (result and result.path) then
					return
				end
				vim.cmd("vnew " .. result.path)
			end)
		end

		lspconfig["zk"].setup(lsp_with_defaults())
	end
end

setup_completion()
setup_diagnostics()
setup_lsp_handlers()
setup_lsp_servers()

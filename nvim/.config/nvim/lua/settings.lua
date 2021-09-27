local set, g, api, cmd, fn = vim.opt, vim.g, vim.api, vim.cmd, vim.fn
local dirs, map = mega.dirs, mega.map
local colors = require("colors")

local function setup_nvim_options()
	-- fallback in the event our statusline plugins fail to load
	set.statusline = table.concat({
		"%2{mode()} | ",
		"f", -- relative path
		"m", -- modified flag
		"r",
		"%{gitstatus#name()}",
		"=",
		"{&spelllang}",
		"y", -- filetype
		"8(%l,%c%)", -- line, column
		"8p%% ", -- file percentage
	}, " %")

	-- # really great settings explainers:
	-- https://github.com/sethigeet/Dotfiles/blob/master/.config/nvim/lua/general/settings.lua
	set.copyindent = true
	set.preserveindent = true

	-- FIXME: THIS BREAKS opening *.exs files!
	-- set.foldmethod = "expr"
	-- set.foldexpr = "nvim_treesitter#foldexpr()"
	-- ---------------------------------------

	set.indentexpr = "nvim_treesitter#indent()"
	-- set.shortmess = "IToOlxfitnw" -- https://neovim.io/doc/user/options.html#'shortmess'
	g.no_man_maps = true
	g.vim_json_syntax_conceal = false
	g.vim_json_conceal = false
	g.floating_window_border = { "╭", "─", "╮", "│", "╯", "─", "╰", "│" }
	g.floating_window_border_dark = {
		{ "╭", "FloatBorderDark" },
		{ "─", "FloatBorderDark" },
		{ "╮", "FloatBorderDark" },
		{ "│", "FloatBorderDark" },
		{ "╯", "FloatBorderDark" },
		{ "─", "FloatBorderDark" },
		{ "╰", "FloatBorderDark" },
		{ "│", "FloatBorderDark" },
	}
	set.grepprg = "rg --vimgrep --no-heading --hidden --smart-case --no-ignore-vcs"
	set.grepformat = "%f:%l:%c:%m,%f:%l:%m"
	set.timeoutlen = 300
	-- set.shell = "/usr/local/bin/zsh --login" -- fix this for cross-platform
	-- set.concealcursor = "n" -- Hide * markup for bold and italic

	-- # spelling
	vim.opt.spellsuggest:prepend({ 12 })
	vim.opt.spelloptions = "camel"
	vim.opt.spellcapcheck = "" -- don't check for capital letters at start of sentence
	vim.opt.fileformats = { "unix", "mac", "dos" }

	-- # git editor
	if vim.fn.executable("nvr") then
		vim.env.GIT_EDITOR = "nvr -cc split --remote-wait +'set bufhidden=wipe'"
		vim.env.EDITOR = "nvr -cc split --remote-wait +'set bufhidden=wipe'"
	end
end

local function setup_startuptime()
	g.startuptime_tries = 10
end

local function setup_matchup()
	g.matchup_matchparen_offscreen = {
		method = "popup",
		fullwidth = true,
		highlight = "Normal",
	}
end

local function setup_treesitter()
	require("nvim-treesitter.configs").setup({
		ensure_installed = {
			"bash",
			"c",
			"cpp",
			"css",
			"comment",
			"elixir",
			"elm",
			"erlang",
			"fish",
			"graphql",
			"html",
			"javascript",
			-- "markdown",
			"jsdoc",
			"jsonc",
			"lua",
			"nix",
			"python",
			"query",
			"ruby",
			"rust",
			"scss",
			"toml",
			"tsx",
			"typescript",
		},
		highlight = {
			enable = true,
			additional_vim_regex_highlighting = true,
		},
		indent = { enable = true },
		autotag = { enable = true },
		context_commentstring = {
			enable = true,
			enable_autocmd = false,
			config = {
				css = "// %s",
				lua = "-- %s",
				fish = "# %s",
				toml = "# %s",
				yaml = "# %s",
				["eruby.yaml"] = "# %s",
			},
		},
		matchup = { enable = true },
		rainbow = {
			enable = true,
			extended_mode = true, -- Highlight also non-parentheses delimiters, boolean or table: lang -> boolean
			max_file_lines = 1000, -- Do not enable for files with more than 1000 lines, int
		},
		textsubjects = {
			enable = false,
			keymaps = {
				["."] = "textsubjects-smart",
				[";"] = "textsubjects-container-outer",
				-- [";"] = "textsubjects-big",
			},
		},
		-- REF: https://github.com/stehessel/nix-dotfiles/blob/master/program/editor/neovim/config/lua/plugins/treesitter.lua
		textobjects = {
			select = {
				enable = false,
				lookahead = true, -- Automatically jump forward to textobj, similar to targets.vim
				keymaps = {
					["if"] = "@function.inner",
					["af"] = "@function.outer",
					["ar"] = "@parameter.outer",
					["iC"] = "@class.inner",
					["aC"] = "@class.outer",
					["ik"] = "@call.inner",
					["ak"] = "@call.outer",
					["il"] = "@loop.inner",
					["al"] = "@loop.outer",
					["ic"] = "@conditional.outer",
					["ac"] = "@conditional.inner",
				},
			},
		},
		query_linter = {
			enable = true,
			use_virtual_text = true,
			lint_events = { "BufWrite", "CursorHold" },
		},
		playground = {
			enable = true,
			disable = {},
			updatetime = 25, -- Debounced time for highlighting nodes in the playground from source code
			persist_queries = true, -- Whether the query persists across vim sessions
			keybindings = {
				toggle_query_editor = "o",
				toggle_hl_groups = "i",
				toggle_injected_languages = "t",
				toggle_anonymous_nodes = "a",
				toggle_language_display = "I",
				focus_language = "f",
				unfocus_language = "F",
				update = "R",
				goto_node = "<cr>",
				show_help = "?",
			},
		},
	})
	-- Add Markdown
	local parser_config = require("nvim-treesitter.parsers").get_parser_configs()
	parser_config.jsonc.used_by = "json"
	parser_config.markdown = {
		install_info = {
			url = "https://github.com/ikatyang/tree-sitter-markdown",
			files = { "src/parser.c", "src/scanner.cc" },
		},
		filetype = "md",
	}
	parser_config.org = {
		install_info = {
			url = "https://github.com/milisims/tree-sitter-org",
			revision = "main",
			files = { "src/parser.c", "src/scanner.cc" },
		},
		filetype = "org",
	}
	-- require("spellsitter").setup()
	require("nvim-ts-autotag").setup({
		filetypes = {
			"html",
			"xml",
			"javascript",
			"typescriptreact",
			"javascriptreact",
			"vue",
			"elixir",
			"eelixir",
		},
	})
end

local function setup_hclipboard()
	require("hclipboard").start()
end

local function setup_indent_blankline()
	g.indent_blankline_buftype_exclude = { "terminal", "nofile" }
	g.indent_blankline_filetype_exclude = {
		"help",
		"startify",
		"dashboard",
		"alpha",
		"packer",
		"neogitstatus",
		"NvimTree",
		"Trouble",
		"git",
		"org",
		"orgagenda",
		"NvimTree",
		"fzf",
		"log",
		"fugitive",
		"gitcommit",
		"packer",
		"vimwiki",
		"markdown",
		"json",
		"txt",
	}
	g.indent_blankline_char = "│"
	g.indent_blankline_use_treesitter = true
	g.indent_blankline_show_trailing_blankline_indent = false
	g.indent_blankline_show_current_context = true
	g.indent_blankline_context_patterns = {
		"class",
		"return",
		"function",
		"method",
		"^if",
		"^while",
		"jsx_element",
		"^for",
		"^object",
		"^table",
		"block",
		"arguments",
		"if_statement",
		"else_clause",
		"jsx_element",
		"jsx_self_closing_element",
		"try_statement",
		"catch_clause",
		"import_statement",
		"operation_type",
	}
end

local function setup_neoscroll()
	require("neoscroll").setup({
		mappings = { "<C-u>", "<C-d>", "<C-b>", "<C-f>", "<C-y>", "zt", "zz", "zb" },
		stop_eof = false,
		hide_cursor = false,
		easing_function = "circular",
	})
end

local function setup_devicons()
	require("nvim-web-devicons").setup({ default = false })
end

local function setup_project_nvim()
	require("project_nvim").setup({
		patterns = { ".git", ".hg", ".bzr", ".svn", "Makefile", "package.json", "elm.json", "mix.lock" },
	}) -- REF: https://github.com/ahmedkhalf/project.nvim#%EF%B8%8F-configuration
end

local function setup_orgmode()
	-- REF: https://github.com/akinsho/dotfiles/blob/main/.config/nvim/lua/as/plugins/orgmode.lua
	-- CHEAT: https://github.com/akinsho/dotfiles/blob/main/.config/nvim/after/ftplugin/org.lua
	--        https://github.com/huynle/nvim/blob/master/lua/configs/orgmode.lua
	--        https://github.com/tkmpypy/dotfiles/blob/master/.config/nvim/lua/plugins.lua#L358-L470
	--        https://github.com/tricktux/dotfiles/blob/master/defaults/.config/nvim/lua/config/plugins/orgmode.lua
	-- ENABLE TREESITTER: https://github.com/kristijanhusak/orgmode.nvim/tree/tree-sitter#setup
	require("orgmode").setup({
		-- org_agenda_files = {"~/Library/Mobile Documents/com~apple~CloudDocs/org/*"},
		-- org_default_notes_file = "~/Library/Mobile Documents/com~apple~CloudDocs/org/inbox.org"
		org_agenda_files = { dirs.org .. "/**/*" },
		org_default_notes_file = dirs.org .. "/refile.org",
		org_todo_keywords = { "TODO(t)", "WAITING", "NEXT", "|", "DONE", "CANCELLED", "HACK" },
		org_todo_keyword_faces = {
			NEXT = ":foreground royalblue :weight bold :slant italic",
			CANCELLED = ":foreground darkred",
			HOLD = ":foreground orange :weight bold",
		},
		org_hide_emphasis_markers = true,
		org_hide_leading_stars = true,
		org_agenda_skip_scheduled_if_done = true,
		org_agenda_skip_deadline_if_done = true,
		org_agenda_templates = {
			t = { description = "Task", template = "* TODO %?\n SCHEDULED: %t" },
			l = { description = "Link", template = "* %?\n%a" },
			n = {
				description = "Note",
				template = "* NOTE %?\n  %u",
				target = dirs.org .. "/note.org",
			},
			j = {
				description = "Journal",
				template = "\n*** %<%Y-%m-%d> %<%A>\n**** %U\n\n%?",
				target = dirs.org .. "/journal.org",
			},
			p = {
				description = "Project Todo",
				template = "* TODO %? \nSCHEDULED: %t",
				target = dirs.org .. "/projects.org",
			},
		},
		mappings = {
			org = {
				org_toggle_checkbox = "<leader>x",
			},
		},
		notifications = {
			reminder_time = { 0, 1, 5, 10 },
			repeater_reminder_time = { 0, 1, 5, 10 },
			deadline_warning_reminder_time = { 0 },
			cron_notifier = function(tasks)
				for _, task in ipairs(tasks) do
					local title = string.format("%s (%s)", task.category, task.humanized_duration)
					local subtitle = string.format("%s %s %s", string.rep("*", task.level), task.todo, task.title)
					local date = string.format("%s: %s", task.type, task.time:to_string())

					-- helpful docs for options: https://github.com/julienXX/terminal-notifier#options
					if vim.fn.executable("terminal-notifier") then
						vim.loop.spawn("terminal-notifier", {
							args = {
								"-title",
								title,
								"-subtitle",
								subtitle,
								"-message",
								date,
								"-appIcon ~/.local/share/nvim/site/pack/paqs/start/orgmode.nvim/assets/orgmode_nvim.png",
								"-ignoreDnD",
							},
						})
					end
					-- if vim.fn.executable("notify-send") then
					-- 	vim.loop.spawn("notify-send", {
					-- 		args = {
					-- 			"--icon=~/.local/share/nvim/site/pack/paqs/start/orgmode.nvim/assets/orgmode_nvim.png",
					-- 			string.format("%s\n%s\n%s", title, subtitle, date),
					-- 		},
					-- 	})
					-- end
				end
			end,
		},
	})
	require("org-bullets").setup()
end

local function setup_trouble()
	require("trouble").setup({ auto_close = true })
end

local function setup_bullets()
	g.bullets_enabled_file_types = {
		"markdown",
		"text",
		"gitcommit",
		"scratch",
	}
	g.bullets_checkbox_markers = " ○◐✗"
	g.bullets_set_mappings = 0
	-- g.bullets_outline_levels = { "num" }
end

local function setup_cursorhold()
	-- https://github.com/antoinemadec/FixCursorHold.nvim#configuration
	g.cursorhold_updatetime = 100
end

local function setup_beacon()
	-- TODO: replace with specs
	g.beacon_size = 90
	g.beacon_minimal_jump = 25
	-- g.beacon_shrink = 0
	-- g.beacon_fade = 0
	g.beacon_ignore_filetypes = { "fzf" }
end

local function setup_nvim_comment()
	require("nvim_comment").setup({
		comment_empty = false,
		hook = function()
			require("ts_context_commentstring.internal").update_commentstring()
		end,
	})
end

local function setup_conflict_marker()
	-- disable the default highlight group
	g.conflict_marker_highlight_group = ""
	-- Include text after begin and end markers
	g.conflict_marker_begin = "^<<<<<<< .*$"
	g.conflict_marker_end = "^>>>>>>> .*$"
end

local function setup_colorizer()
	require("colorizer").setup({
		-- '*',
		-- '!vim',
		-- }, {
		css = { rgb_fn = true },
		scss = { rgb_fn = true },
		sass = { rgb_fn = true },
		stylus = { rgb_fn = true },
		vim = { names = false },
		tmux = { names = true },
		"eelixir",
		"javascript",
		"javascriptreact",
		"typescript",
		"typescriptreact",
		"zsh",
		"fish",
		"sh",
		"conf",
		"lua",
		html = {
			mode = "foreground",
		},
	})
end

local function setup_golden_size()
	local golden_size_installed, golden_size = pcall(require, "golden_size")
	if golden_size_installed then
		local function ignore_by_buftype(types)
			local buftype = api.nvim_buf_get_option(api.nvim_get_current_buf(), "buftype")
			for _, type in pairs(types) do
				-- mega.log(string.format("type: %s / buftype: %s", type, buftype))

				if type == buftype then
					return 1
				end
			end
		end
		golden_size.set_ignore_callbacks({
			{
				ignore_by_buftype,
				{
					"Undotree",
					"quickfix",
					"nerdtree",
					"current",
					"Vista",
					"LuaTree",
					"nofile",
					"tsplayground",
				},
			},
			{ golden_size.ignore_float_windows }, -- default one, ignore float windows
			{ golden_size.ignore_by_window_flag }, -- default one, ignore windows with w:ignore_gold_size=1
		})
	end
end

local function setup_lastplace()
	require("nvim-lastplace").setup({
		lastplace_ignore_buftype = { "quickfix", "nofile", "help" },
		lastplace_ignore_filetype = { "gitcommit", "gitrebase", "svn", "hgcommit" },
		lastplace_open_folds = true,
	})
end

local function setup_gps()
	require("nvim-gps").setup({})
end

local function setup_autopairs()
	local npairs = require("nvim-autopairs")
	npairs.setup({
		check_ts = true,
		close_triple_quotes = true,
		-- ts_config = {
		-- 	lua = { "string" },
		-- 	-- it will not add pair on that treesitter node
		-- 	javascript = { "template_string" },
		-- 	java = false,
		-- 	-- don't check treesitter on java
		-- },
	})
	npairs.add_rules(require("nvim-autopairs.rules.endwise-ruby"))
	local endwise = require("nvim-autopairs.ts-rule").endwise
	npairs.add_rules({
		endwise("then$", "end", "lua", nil),
		endwise("do$", "end", "lua", nil),
		endwise(" do$", "end", "elixir", nil),
	})
end

local function setup_lightspeed()
	require("lightspeed").setup({
		jump_to_first_match = true,
		jump_on_partial_input_safety_timeout = 400,
		-- This can get _really_ slow if the window has a lot of content,
		-- turn it on only if your machine can always cope with it.
		highlight_unique_chars = false,
		grey_out_search_area = true,
		match_only_the_start_of_same_char_seqs = true,
		limit_ft_matches = 5,
		-- full_inclusive_prefix_key = '<c-x>',
		-- By default, the values of these will be decided at runtime,
		-- based on `jump_to_first_match`.
		-- labels = nil,
		-- cycle_group_fwd_key = nil,
		-- cycle_group_bwd_key = nil,
	})
end

local function setup_diffview()
	local cb = require("diffview.config").diffview_callback

	require("diffview").setup({
		diff_binaries = false, -- Show diffs for binaries
		use_icons = true, -- Requires nvim-web-devicons
		file_panel = {
			width = 50,
		},
		enhanced_diff_hl = true,
		key_bindings = {
			disable_defaults = false, -- Disable the default key bindings
			-- The `view` bindings are active in the diff buffers, only when the current
			-- tabpage is a Diffview.
			view = {
				["<tab>"] = cb("select_next_entry"), -- Open the diff for the next file
				["<s-tab>"] = cb("select_prev_entry"), -- Open the diff for the previous file
				["<leader>e"] = cb("focus_files"), -- Bring focus to the files panel
				["<leader>b"] = cb("toggle_files"), -- Toggle the files panel.
			},
			file_panel = {
				["j"] = cb("next_entry"), -- Bring the cursor to the next file entry
				["<down>"] = cb("next_entry"),
				["k"] = cb("prev_entry"), -- Bring the cursor to the previous file entry.
				["<up>"] = cb("prev_entry"),
				["<cr>"] = cb("select_entry"), -- Open the diff for the selected entry.
				["o"] = cb("select_entry"),
				["<2-LeftMouse>"] = cb("select_entry"),
				["-"] = cb("toggle_stage_entry"), -- Stage / unstage the selected entry.
				["S"] = cb("stage_all"), -- Stage all entries.
				["U"] = cb("unstage_all"), -- Unstage all entries.
				["R"] = cb("refresh_files"), -- Update stats and entries in the file list.
				["<tab>"] = cb("select_next_entry"),
				["<s-tab>"] = cb("select_prev_entry"),
				["<leader>e"] = cb("focus_files"),
				["<leader>b"] = cb("toggle_files"),
			},
		},
	})
end

local function setup_git()
	require("git").setup({
		keymaps = {
			-- Open blame window
			-- blame = "<Leader>gb",
			-- Close blame window
			quit_blame = "q",
			-- Open blame commit
			blame_commit = "<CR>",
			-- Open file/folder in git repository
			browse = "<Leader>gh",
			-- Open pull request of the current branch
			open_pull_request = "<Leader>gp",
			-- Create a pull request with the target branch is set in the `target_branch` option
			create_pull_request = "<Leader>gn",
			-- Opens a new diff that compares against the current index
			diff = "<Leader>gd",
			-- Close git diff
			diff_close = "<Leader>gD",
			-- Revert to the specific commit
			revert = "<Leader>gr",
			-- Revert the current file to the specific commit
			revert_file = "<Leader>gR",
		},
		-- Default target branch when create a pull request
		target_branch = "main",
	})
end

local function setup_git_messenger()
	g.git_messenger_floating_win_opts = { border = g.floating_window_border_dark }
	g.git_messenger_no_default_mappings = true
	g.git_messenger_max_popup_width = 100
	g.git_messenger_max_popup_height = 100
end

local function setup_vim_test()
	api.nvim_exec(
		[[
    function! TerminalSplit(cmd)
    vert new | set filetype=test | call termopen(['zsh', '-c', a:cmd], {'curwin':1})
    endfunction

    let g:test#custom_strategies = {'terminal_split': function('TerminalSplit')}
    let g:test#strategy = 'terminal_split'
    let g:test#filename_modifier = ':.'
    let g:test#preserve_screen = 0

    nmap <silent> <leader>tf :TestFile<CR>
    nmap <silent> <leader>tt :TestVisit<CR>
    nmap <silent> <leader>tn :TestNearest<CR>
    nmap <silent> <leader>tl :TestLast<CR>
    nmap <silent> <leader>tv :TestVisit<CR>
    nmap <silent> <leader>ta :TestSuite<CR>
    nmap <silent> <leader>tP :A<CR>
    nmap <silent> <leader>tp :AV<CR>
    nmap <silent> <leader>to :copen<CR>
    ]],
		false
	)
	cmd([[let g:test#javascript#jest#file_pattern = '\v(__tests__/.*|(spec|test))\.(js|jsx|coffee|ts|tsx)$']])
end

local function setup_projectionist()
	g.projectionist_heuristics = {
		["&package.json"] = {
			["package.json"] = {
				type = "package",
				alternate = { "yarn.lock", "package-lock.json" },
			},
			["package-lock.json"] = {
				alternate = "package.json",
			},
			["yarn.lock"] = {
				alternate = "package.json",
			},
		},
		["package.json"] = {
			-- outstand'ing (ts/tsx)
			["spec/javascript/*.test.tsx"] = {
				["alternate"] = "app/webpacker/src/javascript/{}.tsx",
				["type"] = "spec",
			},
			["app/webpacker/src/javascript/*.tsx"] = {
				["alternate"] = "spec/javascript/{}.test.tsx",
				["type"] = "source",
			},
			["spec/javascript/*.test.ts"] = {
				["alternate"] = "app/webpacker/src/javascript/{}.ts",
				["type"] = "spec",
			},
			["app/webpacker/src/javascript/*.ts"] = {
				["alternate"] = "spec/javascript/{}.test.ts",
				["type"] = "source",
			},
		},
		["mix.exs"] = {
			["lib/**/views/*_view.ex"] = {
				["type"] = "view",
				["alternate"] = "test/{dirname}/views/{basename}_view_test.exs",
				["template"] = {
					"defmodule {dirname|camelcase|capitalize}.{basename|camelcase|capitalize}View do",
					"  use {dirname|camelcase|capitalize}, :view",
					"end",
				},
			},
			["test/**/views/*_view_test.exs"] = {
				["type"] = "test",
				["alternate"] = "lib/{dirname}/views/{basename}_view.ex",
				["template"] = {
					"defmodule {dirname|camelcase|capitalize}.{basename|camelcase|capitalize}ViewTest do",
					"  use ExUnit.Case, async: true",
					"",
					"  alias {dirname|camelcase|capitalize}.{basename|camelcase|capitalize}View",
					"end",
				},
			},
			["lib/**/live/*_live.ex"] = {
				["type"] = "liveview",
				["alternate"] = "test/{dirname}/views/{basename}_live_test.exs",
				["template"] = {
					"defmodule {dirname|camelcase|capitalize}.{basename|camelcase|capitalize}Live do",
					"  use {dirname|camelcase|capitalize}, :live_view",
					"end",
				},
			},
			["test/**/live/*_live_test.exs"] = {
				["type"] = "test",
				["alternate"] = "lib/{dirname}/live/{basename}_live.ex",
				["template"] = {
					"defmodule {dirname|camelcase|capitalize}.{basename|camelcase|capitalize}LiveTest do",
					"  use ExUnit.Case, async: true",
					"",
					"  alias {dirname|camelcase|capitalize}.{basename|camelcase|capitalize}Live",
					"end",
				},
			},
			["lib/*.ex"] = {
				["type"] = "source",
				["alternate"] = "test/{}_test.exs",
				["template"] = {
					"defmodule {camelcase|capitalize|dot} do",
					"",
					"end",
				},
			},
			["test/*_test.exs"] = {
				["type"] = "test",
				["alternate"] = "lib/{}.ex",
				["template"] = {
					"defmodule {camelcase|capitalize|dot}Test do",
					"  use ExUnit.Case, async: true",
					"",
					"  alias {camelcase|capitalize|dot}",
					"end",
				},
			},
		},
	}
end

local function setup_package_info()
	require("package-info").setup({
		colors = {
			up_to_date = colors.cs.bg2, -- Text color for up to date package virtual text
			outdated = "#d19a66", -- Text color for outdated package virtual text
		},
		icons = {
			enable = true, -- Whether to display icons
			style = {
				up_to_date = "|  ", -- Icon for up to date packages
				outdated = "|  ", -- Icon for outdated packages
			},
		},
		autostart = true, -- Whether to autostart when `package.json` is opened
	})
end

local function setup_numb()
	require("numb").setup()
end

local function setup_zk()
	cmd([[command! -nargs=0 ZkIndex :lua require'lspconfig'.zk.index()]])
	cmd([[command! -nargs=? ZkNew :lua require'lspconfig'.zk.new(<args>)]])
	cmd(
		[[command! ZkList :FloatermNew --autoclose=2 --position=top --opener=edit --width=0.9 --title=notes EDITOR=floaterm zk edit -i]]
	)
	cmd(
		[[command! ZkTags :FloatermNew --autoclose=2 --position=top --opener=edit --width=0.9 --title=tags zk list -q -f json | jq -r '. | map(.tags) | flatten | unique | join("\n")' | fzf | EDITOR=floaterm xargs -o -t zk edit -i -t]]
	)
	cmd(
		[[command! ZkBacklinks :FloatermNew --autoclose=2 --position=top --opener=edit --width=0.9 --title=backlinks EDITOR=floaterm zk edit -i -l %]]
	)
	cmd(
		[[command! ZkLinks :FloatermNew --autoclose=2 --position=top --opener=edit --width=0.9 --title=links EDITOR=floaterm zk edit -i -L %]]
	)

	mega.zk_list = function()
		cmd([[autocmd User FloatermOpen ++once :tnoremap <buffer> <esc> <C-c>]])
		cmd([[ZkList]])
	end

	mega.zk_by_tags = function()
		cmd([[autocmd User FloatermOpen ++once :tnoremap <buffer> <esc> <C-c>]])
		cmd([[ZkTags]])
	end

	mega.zk_backlinks = function()
		cmd([[autocmd User FloatermOpen ++once :tnoremap <buffer> <esc> <C-c>]])
		cmd([[ZkBacklinks]])
	end

	mega.zk_links = function()
		cmd([[autocmd User FloatermOpen ++once :tnoremap <buffer> <esc> <C-c>]])
		cmd([[ZkLinks]])
	end

	local rooter = require("lspconfig").util.root_pattern(".zk")
	local rooted = rooter(api.nvim_buf_get_name(0))
	local is_zk = fn.empty(rooted)
	if is_zk == 0 then
		map("n", "<leader>fz", ":lua mega.zk_list()<cr>")
		map("n", "<leader>zt", ":lua mega.zk_by_tags()<cr>")
		map("n", "<leader>zb", ":lua mega.zk_backlinks()<cr>")
		map("n", "<leader>zl", ":lua mega.zk_links()<cr>")
	end
end

local function setup_fzf_lua()
	local actions = require("fzf-lua.actions")
	require("fzf-lua").setup({
		-- fzf_args = vim.env.FZF_DEFAULT_OPTS .. " --border rounded",
		fzf_layout = "default",
		win_height = 0.6,
		win_width = 0.65,
		default_previewer = "bat",
		previewers = {
			bat = {
				cmd = "bat",
				args = "--style=numbers,changes --color always",
				theme = "base16",
				config = nil, -- nil uses $BAT_CONFIG_PATH
			},
		},
		files = {
			prompt = string.format("files %s ", colors.icons.prompt_symbol),
			fd_opts = [[--type f --follow --hidden --color=always]]
				.. [[ -E '.git' -E 'node_modules' -E '*.png' -E '*.jpg' -E '**/Spoons']]
				.. [[ --ignore-file '~/.gitignore_global' --ignore-file '.gitignore']],
			color_icons = true,
			git_icons = true,
			git_diff_cmd = "git diff --name-status --relative HEAD",
			actions = {
				["default"] = actions.file_vsplit,
				["ctrl-t"] = actions.file_tabedit,
				["ctrl-o"] = actions.file_edit,
			},
		},
		grep = {
			input_prompt = string.format("grep for %s ", colors.icons.prompt_symbol),
			prompt = string.format("grep %s ", colors.icons.prompt_symbol),
			actions = {
				["default"] = actions.file_vsplit,
				["ctrl-t"] = actions.file_tabedit,
				["ctrl-o"] = actions.file_edit,
			},
		},
		lsp = {
			prompt = string.format("%s ", colors.icons.prompt_symbol),
			cwd_only = false, -- LSP/diagnostics for cwd only?
			async_or_timeout = false,
			jump_to_single_result = true,
			actions = {
				["default"] = actions.file_vsplit,
				["ctrl-t"] = actions.file_tabedit,
				["ctrl-o"] = actions.file_edit,
			},
		},
		buffers = {
			prompt = string.format("buffers %s ", colors.icons.prompt_symbol),
		},
	})
	-- nmap ( '<leader>no', ':silent! lua fzf_orgmode{}<CR>' )
	-- nmap ( '<leader>nr', ':silent! lua fzf_orgmode{}<CR>' )
	-- nmap ( '<leader>nd', ":silent! e " .. ROAM .. '/notebook.org<cr>' )
	--   function fzf_orgmode()
	--     local choice = dirs.org
	--     require("fzf-lua").files(
	--       {
	--         prompt = "ORGFILES » ",
	--         cwd = choice
	--       }
	--     )
	--     vim.cmd("chdir " .. choice)
	--   end

	--   function fzf_dotfiles()
	--     local choice = dirs.dots
	--     require("fzf-lua").files(
	--       {
	--         prompt = "DOTS » ",
	--         cwd = choice
	--       }
	--     )
	--     vim.cmd("chdir " .. choice)
	--   end
end

local function setup_which_key()
	local wk = require("which-key")
	wk.setup({
		plugins = {
			spelling = {
				enabled = true,
			},
		},
	})

	wk.register({
		d = {
			f = "treesitter: peek function definition",
			F = "treesitter: peek class definition",
		},
		["]"] = {
			name = "+next",
			["<space>"] = "add space below",
		},
		["["] = {
			name = "+prev",
			["<space>"] = "add space above",
		},
		["g>"] = "show message history",
		["<leader>"] = {
			["0"] = "which_key_ignore",
			["1"] = "which_key_ignore",
			["2"] = "which_key_ignore",
			["3"] = "which_key_ignore",
			["4"] = "which_key_ignore",
			["5"] = "which_key_ignore",
			["6"] = "which_key_ignore",
			["7"] = "which_key_ignore",
			["8"] = "which_key_ignore",
			["9"] = "which_key_ignore",
			n = {
				name = "+new",
				f = "create a new file",
				s = "create new file in a split",
			},
			E = "show token under the cursor",
			p = {
				name = "+packer",
				c = "clean",
				s = "sync",
			},
			q = {
				name = "+quit",
				w = "close window (and buffer)",
				q = "delete buffer",
			},
			g = "grep word under the cursor",
			l = {
				name = "+list",
				i = "toggle location list",
				s = "toggle quickfix",
			},
			e = {
				name = "+edit",
				v = "open vimrc in a vertical split",
				p = "open plugins file in a vertical split",
				z = "open zshrc in a vertical split",
				t = "open tmux config in a vertical split",
			},
			o = {
				name = "+only",
				n = "close all other buffers",
			},
			t = {
				name = "+tab",
				c = "tab close",
				n = "tab edit current buffer",
			},
			sw = "swap buffers horizontally",
			so = "source current buffer",
			sv = "source init.vim",
			U = "uppercase all word",
			["<CR>"] = "repeat previous macro",
			[","] = "go to previous buffer",
			["="] = "make windows equal size",
			[")"] = "wrap with parens",
			["}"] = "wrap with braces",
			['"'] = "wrap with double quotes",
			["'"] = "wrap with single quotes",
			["`"] = "wrap with back ticks",
			["["] = "replace cursor word in file",
			["]"] = "replace cursor word in line",
		},
		["<localleader>"] = {
			name = "local leader",
			w = {
				name = "+window",
				h = "change two vertically split windows to horizontal splits",
				v = "change two horizontally split windows to vertical splits",
				x = "swap current window with the next",
				j = "resize: downwards",
				k = "resize: upwards",
			},
			l = "redraw window",
			z = "center view port",
			[","] = "add comma to end of line",
			[";"] = "add semicolon to end of line",
			["?"] = "search for word under cursor in google",
			["!"] = "search for word under cursor in google",
			["["] = "abolish = subsitute cursor word in file",
			["]"] = "abolish = substitute cursor word on line",
			["/"] = "find matching word in buffer",
			["<space>"] = "Toggle current fold",
			["<tab>"] = "open commandline bufferlist",
		},
	})
end

local function setup_tmux()
	require("tmux").setup({
		navigation = {
			-- enables default keybindings (C-hjkl) for normal mode
			enable_default_keybindings = true,
		},
	})
end

local function setup_distant()
	local actions = require("distant.nav.actions")

	require("distant").setup({
		["198.74.55.152"] = {
			launch = {
				distant = "/home/ubuntu/.asdf/installs/rust/stable/bin/distant",
				username = "ubuntu",
				identity_file = "~/.ssh/seth-Seths-MBP.lan",
				extra_server_args = '"--log-file ~/tmp/distant-seth_dev-server.log --log-level trace --port 8081:8099 --shutdown-after 60"',
				-- lsp = {
				-- 	["outstand/pages (elixirls)"] = {
				-- 		cmd = "",
				-- 		root_dir = "/home/ubuntu/dev/pages",
				-- 		filetypes = { "elixir", "eelixir" },
				-- 		on_attach = function() end,
				-- 		opts = {
				-- 			log_file = "~/tmp/distant-pages-elixirls.log",
				-- 			log_level = "trace",
				-- 		},
				-- 	},
				-- 	["outstand/app (solargraph)"] = {
				-- 		cmd = "",
				-- 		root_dir = "/home/ubuntu/dev/app",
				-- 		filetypes = { "ruby", "eruby" },
				-- 		on_attach = function() end,
				-- 		opts = {
				-- 			log_file = "~/tmp/distant-app-solargraph.log",
				-- 			log_level = "trace",
				-- 		},
				-- 	},
			},
		},

		-- Apply these settings to any remote host
		["*"] = {
			-- max_timeout = 60000,
			-- timeout_interval = 200,
			client = {
				log_file = "~/tmp/distant-client.log",
				log_level = "trace",
			},
			launch = {
				extra_server_args = '"--log-file ~/tmp/distant-all-server.log --log-level trace --port 8080:8999 --shutdown-after 60"',
			},
			file = {
				mappings = {
					["-"] = actions.up,
				},
			},
			dir = {
				mappings = {
					["<Return>"] = actions.edit,
					["-"] = actions.up,
					["K"] = actions.mkdir,
					["N"] = actions.newfile,
					["R"] = actions.rename,
					["D"] = actions.remove,
				},
			},
		},
	})
end

local function setup_lir()
	local actions = require("lir.actions")
	local mark_actions = require("lir.mark.actions")
	local clipboard_actions = require("lir.clipboard.actions")

	require("lir").setup({
		show_hidden_files = false,
		devicons_enable = true,
		mappings = {
			["<CR>"] = actions.edit,
			["<C-s>"] = actions.split,
			["<C-v>"] = actions.vsplit,
			["<C-t>"] = actions.tabedit,

			["-"] = actions.up,
			["q"] = actions.quit,

			["K"] = actions.mkdir,
			["N"] = actions.newfile,
			["R"] = actions.rename,
			["@"] = actions.cd,
			["Y"] = actions.yank_path,
			["."] = actions.toggle_show_hidden,
			["D"] = actions.delete,

			["J"] = function()
				mark_actions.toggle_mark()
				vim.cmd("normal! j")
			end,
			["C"] = clipboard_actions.copy,
			["X"] = clipboard_actions.cut,
			["P"] = clipboard_actions.paste,
		},
		float = {
			winblend = 0,

			-- -- You can define a function that returns a table to be passed as the third
			-- -- argument of nvim_open_win().
			-- win_opts = function()
			--   local width = math.floor(vim.o.columns * 0.8)
			--   local height = math.floor(vim.o.lines * 0.8)
			--   return {
			--     border = require("lir.float.helper").make_border_opts({
			--       "+", "─", "+", "│", "+", "─", "+", "│",
			--     }, "Normal"),
			--     width = width,
			--     height = height,
			--     row = 1,
			--     col = math.floor((vim.o.columns - width) / 2),
			--   }
			-- end,
		},
		hide_cursor = true,
	})
end

local function setup_dirvish()
	vim.g.dirvish_mode = ":sort ,^.*[\\/],"

	function Dirvish_open(cmd, bg)
		local path = vim.fn.getline(".")
		if vim.fn.isdirectory(path) == 1 then
			if cmd == "edit" and not bg then
				vim.fn["dirvish#open"](cmd, 0)
			end
		else
			if bg then
				vim.fn["dirvish#open"](cmd, 1)
			else
				vim.cmd("bwipeout")
				vim.cmd(cmd .. " " .. path)
			end
		end
	end

	function Dirvish_toggle()
		local lines = vim.o.lines
		local columns = vim.o.columns
		local width = vim.fn.float2nr(columns * 0.3)
		local height = vim.fn.float2nr(lines * 0.8)
		local top = ((lines - height) / 2) - 1
		local left = columns - width
		local path = vim.fn.expand("%:p")
		local fdir = vim.fn.expand("%:h")
		vim.api.nvim_open_win(vim.api.nvim_create_buf(false, true), true, {
			relative = "editor",
			row = top,
			col = left,
			width = width,
			height = height,
			style = "minimal",
			border = "single",
		})

		if fdir == "" then
			fdir = "."
		end

		vim.fn["dirvish#open"](fdir)

		if path ~= "" then
			vim.fn.search("\\V\\^" .. vim.fn.escape(path, "\\") .. "\\$", "cw")
		end
	end

	vim.cmd([[nmap <silent> - :<C-U>lua Dirvish_toggle()<CR>]])

	vim.cmd([[augroup dirvish_config | augroup END]])
	vim.cmd(
		[[autocmd dirvish_config FileType dirvish nmap <silent> <buffer> <CR>  :<C-U>lua Dirvish_open('edit'   , false)<CR>]]
	)
	vim.cmd(
		[[autocmd dirvish_config FileType dirvish nmap <silent> <buffer> v     :<C-U>lua Dirvish_open('vsplit' , false)<CR>]]
	)
	vim.cmd(
		[[autocmd dirvish_config FileType dirvish nmap <silent> <buffer> V     :<C-U>lua Dirvish_open('vsplit' , true)<CR>]]
	)
	vim.cmd(
		[[autocmd dirvish_config FileType dirvish nmap <silent> <buffer> s     :<C-U>lua Dirvish_open('split'  , false)<CR>]]
	)
	vim.cmd(
		[[autocmd dirvish_config FileType dirvish nmap <silent> <buffer> S     :<C-U>lua Dirvish_open('split'  , true)<CR>]]
	)
	vim.cmd(
		[[autocmd dirvish_config FileType dirvish nmap <silent> <buffer> t     :<C-U>lua Dirvish_open('tabedit', false)<CR>]]
	)
	vim.cmd(
		[[autocmd dirvish_config FileType dirvish nmap <silent> <buffer> T     :<C-U>lua Dirvish_open('tabedit', true)<CR>]]
	)
	vim.cmd([[autocmd dirvish_config FileType dirvish nmap <silent> <buffer> -     <Plug>(dirvish_up)]])
	vim.cmd([[autocmd dirvish_config FileType dirvish nmap <silent> <buffer> <ESC> :bd<CR>]])
	vim.cmd([[autocmd dirvish_config FileType dirvish nmap <silent> <buffer> q     :bd<CR>]])
	vim.cmd([[autocmd dirvish_config FileType dirvish nmap <buffer> <C-w> <nop>]])
	vim.cmd([[autocmd dirvish_config FileType dirvish nmap <buffer> <C-h> <nop>]])
	vim.cmd([[autocmd dirvish_config FileType dirvish nmap <buffer> <C-j> <nop>]])
	vim.cmd([[autocmd dirvish_config FileType dirvish nmap <buffer> <C-k> <nop>]])
	vim.cmd([[autocmd dirvish_config FileType dirvish nmap <buffer> <C-l> <nop>]])
	vim.cmd([[autocmd dirvish_config FileType dirvish setlocal nocursorline]])
end

setup_nvim_options()
setup_treesitter()
setup_golden_size()
setup_devicons()
setup_matchup()
setup_neoscroll()
setup_lightspeed()
setup_colorizer()
setup_autopairs()
setup_tmux()
setup_fzf_lua()
setup_beacon()
setup_which_key()
setup_startuptime()
setup_indent_blankline()
-- setup_hclipboard()
setup_zk()
setup_numb()
setup_orgmode()
setup_package_info()
setup_projectionist()
setup_project_nvim()
setup_vim_test()
setup_bullets()
setup_trouble()
setup_cursorhold()
setup_nvim_comment()
setup_conflict_marker()
setup_lastplace()
setup_gps()
setup_diffview()
setup_git()
setup_git_messenger()
setup_distant()
setup_dirvish()
-- setup_lir()

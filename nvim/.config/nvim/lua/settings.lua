local set, g, api, cmd = vim.opt, vim.g, vim.api, vim.cmd
local dirs = {
	org = "~/Library/Mobile Documents/com~apple~CloudDocs/org",
	dots = "~/.dotfiles",
}

do -- [ui/appearance] --
	-- fallback in the event our statusline plugins fail to load
	set.statusline = table.concat({
		"%2{mode()} | ",
		"f", -- relative path
		"m", -- modified flag
		"r",
		-- "%{FugitiveStatusline()}",
		"=",
		"{&spelllang}",
		"y", -- filetype
		"8(%l,%c%)", -- line, column
		"8p%% ", -- file percentage
	}, " %")
end

do -- [nvim options] --
	set.foldmethod = "expr"
	set.foldexpr = "nvim_treesitter#foldexpr()"
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
	g.loaded_python_provider = 1
	g.loaded_ruby_provider = 1
	g.loaded_perl_provider = 1
end

do
	vim.g.startuptime_tries = 10
	-- vim.g.startuptime_exe_args = {"+let g:auto_session_enabled = 0"}
end

do
	vim.g.matchup_matchparen_offscreen = {
		method = "popup",
		fullwidth = true,
		highlight = "Normal",
	}
end

do -- [nvim-treesitter] --
	require("nvim-treesitter.configs").setup({
		ensure_installed = {
			"bash",
			"c",
			"cpp",
			"css",
			"elixir",
			"elm",
			"erlang",
			"fish",
			"graphql",
			"html",
			"javascript",
			-- "markdown",
			"jsdoc",
			"json",
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
			config = {
				css = "// %s",
				lua = "-- %s",
			},
		},
		matchup = { enable = true },
		rainbow = {
			enable = true,
			extended_mode = true, -- Highlight also non-parentheses delimiters, boolean or table: lang -> boolean
			max_file_lines = 1000, -- Do not enable for files with more than 1000 lines, int
		},
		textsubjects = {
			enable = true,
			keymaps = {
				["."] = "textsubjects-smart",
				[";"] = "textsubjects-container-outer",
			},
		},
		textobjects = {
			select = {
				enable = true,
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
	})
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

do -- [luasnip] --
	require("luasnip").config.set_config({
		history = true,
		updateevents = "TextChanged,TextChangedI",
	})
	require("luasnip/loaders/from_vscode").load({
		paths = { vim.fn.stdpath("config") .. "/vsnips" },
	})
end

do -- [indent-blankline] --
	g.indent_blankline_buftype_exclude = { "terminal", "nofile" }
	g.indent_blankline_filetype_exclude = {
		"help",
		"startify",
		"dashboard",
		"packer",
		"neogitstatus",
		"NvimTree",
		"Trouble",
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

do -- [neoscroll] --
	require("neoscroll").setup({
		mappings = { "<C-u>", "<C-d>", "<C-b>", "<C-f>", "<C-y>", "zt", "zz", "zb" },
		stop_eof = false,
		hide_cursor = false,
		easing_function = "circular",
	})
end

-- [devicons] --
require("nvim-web-devicons").setup({ default = false })

do -- [orgmode] --
	-- REF: https://github.com/akinsho/dotfiles/blob/main/.config/nvim/lua/as/plugins/orgmode.lua
	-- CHEAT: https://github.com/akinsho/dotfiles/blob/main/.config/nvim/after/ftplugin/org.lua
	--        https://github.com/huynle/nvim/blob/master/lua/configs/orgmode.lua
	--        https://github.com/tkmpypy/dotfiles/blob/master/.config/nvim/lua/plugins.lua#L358-L470
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

do -- [zk] --
	-- REF:
	-- https://github.com/mhanberg/.dotfiles/blob/main/config/nvim/lua/plugin/zk.lua
	require("zk").setup({ debug = true })
end

do -- [trouble] --
	require("trouble").setup({ auto_close = true })
end

do -- [bullets] --
	g.bullets_enabled_file_types = {
		"markdown",
		"text",
		"gitcommit",
		"scratch",
	}
	g.bullets_checkbox_markers = " ○◐✗"
	-- g.bullets_set_mappings = 0
end

-- do
--   require("gitsigns").setup(
--     {
--       signs = {
--         add = {hl = "GitSignsAdd", text = "│", numhl = "GitSignsAddNr", linehl = "GitSignsAddLn"},
--         change = {hl = "GitSignsChange", text = "│", numhl = "GitSignsChangeNr", linehl = "GitSignsChangeLn"},
--         delete = {hl = "GitSignsDelete", text = "_", numhl = "GitSignsDeleteNr", linehl = "GitSignsDeleteLn"},
--         topdelete = {hl = "GitSignsDelete", text = "‾", numhl = "GitSignsDeleteNr", linehl = "GitSignsDeleteLn"},
--         changedelete = {hl = "GitSignsChange", text = "~", numhl = "GitSignsChangeNr", linehl = "GitSignsChangeLn"}
--       }
--     }
--   )
-- end

do -- [fixcursorhold] --
	g.cursorhold_updatetime = 100
end

-- do -- [lspsaga] --
--   require("lspsaga").init_lsp_saga {
--     use_saga_diagnostic_sign = false,
--     border_style = 2,
--     finder_action_keys = {
--       open = "<CR>",
--       vsplit = "v",
--       split = "s",
--       quit = {"<ESC>", "q"},
--       scroll_down = "<C-n>",
--       scroll_up = "<C-p>"
--     },
--     code_action_keys = {quit = "<ESC>", exec = "<CR>"},
--     code_action_prompt = {
--       enable = true,
--       sign = false,
--       virtual_text = true
--     },
--     finder_definition_icon = "•d",
--     finder_reference_icon = "•r"
--   }
-- end

do -- [beacon] --
	g.beacon_size = 90
	g.beacon_minimal_jump = 25
	-- g.beacon_shrink = 0
	-- g.beacon_fade = 0
	g.beacon_ignore_filetypes = { "fzf" }
end

do -- [nvim-comment] --
	require("nvim_comment").setup({
		hook = function()
			require("ts_context_commentstring.internal").update_commentstring()
		end,
	})
end

-- do -- [kommentary] --
-- 	local kommentary_config = require("kommentary.config")
-- 	kommentary_config.configure_language("default", {
-- 		single_line_comment_string = "auto",
-- 		prefer_single_line_comments = true,
-- 		multi_line_comment_strings = false,
-- 	})
-- 	kommentary_config.configure_language("typescriptreact", {
-- 		single_line_comment_string = "auto",
-- 		prefer_single_line_comments = true,
-- 	})
-- 	kommentary_config.configure_language("vue", {
-- 		single_line_comment_string = "auto",
-- 		prefer_single_line_comments = true,
-- 	})
-- 	kommentary_config.configure_language("css", {
-- 		single_line_comment_string = "auto",
-- 		prefer_single_line_comments = true,
-- 	})
-- end

do -- [conflict-marker] --
	-- disable the default highlight group
	g.conflict_marker_highlight_group = ""
	-- Include text after begin and end markers
	g.conflict_marker_begin = "^<<<<<<< .*$"
	g.conflict_marker_end = "^>>>>>>> .*$"
end

do -- [colorizer] --
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
		"sh",
		"conf",
		"lua",
		html = {
			mode = "foreground",
		},
	})
end

do -- [golden-size] --
	local golden_size_installed, golden_size = pcall(require, "golden_size")
	if golden_size_installed then
		local function ignore_by_buftype(types)
			local buftype = api.nvim_buf_get_option(api.nvim_get_current_buf(), "buftype")
			for _, type in pairs(types) do
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
				},
			},
			{ golden_size.ignore_float_windows }, -- default one, ignore float windows
			{ golden_size.ignore_by_window_flag }, -- default one, ignore windows with w:ignore_gold_size=1
		})
	end
end

do -- [autopairs] --
	local npairs = require("nvim-autopairs")
	npairs.setup({
		check_ts = true,
		ts_config = {
			lua = { "string" },
			-- it will not add pair on that treesitter node
			javascript = { "template_string" },
			java = false,
			-- don't check treesitter on java
		},
	})
	require("nvim-autopairs.completion.compe").setup({
		map_cr = true, --  map <CR> on insert mode
		map_complete = true, -- it will auto insert `(` after select function or method item
	})

	npairs.add_rules(require("nvim-autopairs.rules.endwise-ruby"))
	-- npairs.add_rules(require("nvim-autopairs.rules.endwise-lua"))
	local endwise = require("nvim-autopairs.ts-rule").endwise
	npairs.add_rules({
		endwise("then$", "end", "lua", nil),
		endwise("do$", "end", "lua", nil),
		endwise(" do$", "end", "elixir", nil),
	})
end

do -- [polyglot] --
	g.polyglot_disabled = {}
end

do -- [lightspeed] --
	require("lightspeed").setup({
		jump_to_first_match = false,
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

-- do -- [quickscope] --
--   g.qs_enable = 1
--   g.qs_highlight_on_keys = {"f", "F", "t", "T"}
--   g.qs_buftype_blacklist = {"terminal", "nofile"}
--   g.qs_lazy_highlight = 1
-- end

-- do -- [diffview] --
--   local cb = require("diffview.config").diffview_callback

--   require("diffview").setup(
--     {
--       diff_binaries = false, -- Show diffs for binaries
--       file_panel = {
--         width = 50,
--         use_icons = true -- Requires nvim-web-devicons
--       },
--       key_bindings = {
--         disable_defaults = false, -- Disable the default key bindings
--         -- The `view` bindings are active in the diff buffers, only when the current
--         -- tabpage is a Diffview.
--         view = {
--           ["<tab>"] = cb("select_next_entry"), -- Open the diff for the next file
--           ["<s-tab>"] = cb("select_prev_entry"), -- Open the diff for the previous file
--           ["<leader>e"] = cb("focus_files"), -- Bring focus to the files panel
--           ["<leader>b"] = cb("toggle_files") -- Toggle the files panel.
--         },
--         file_panel = {
--           ["j"] = cb("next_entry"), -- Bring the cursor to the next file entry
--           ["<down>"] = cb("next_entry"),
--           ["k"] = cb("prev_entry"), -- Bring the cursor to the previous file entry.
--           ["<up>"] = cb("prev_entry"),
--           ["<cr>"] = cb("select_entry"), -- Open the diff for the selected entry.
--           ["o"] = cb("select_entry"),
--           ["<2-LeftMouse>"] = cb("select_entry"),
--           ["-"] = cb("toggle_stage_entry"), -- Stage / unstage the selected entry.
--           ["S"] = cb("stage_all"), -- Stage all entries.
--           ["U"] = cb("unstage_all"), -- Unstage all entries.
--           ["R"] = cb("refresh_files"), -- Update stats and entries in the file list.
--           ["<tab>"] = cb("select_next_entry"),
--           ["<s-tab>"] = cb("select_prev_entry"),
--           ["<leader>e"] = cb("focus_files"),
--           ["<leader>b"] = cb("toggle_files")
--         }
--       }
--     }
--   )
-- end

do -- [git-messenger] --
	g.git_messenger_floating_win_opts = { border = g.floating_window_border_dark }
	g.git_messenger_no_default_mappings = true
	g.git_messenger_max_popup_width = 100
	g.git_messenger_max_popup_height = 100
end

do -- [vim-test] --
	api.nvim_exec(
		[[
    function! TerminalSplit(cmd)
    vert new | set filetype=test | call termopen(['/usr/local/bin/zsh', '-c', a:cmd], {'curwin':1})
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

do -- [projectionist] --
	g.projectionist_heuristics = {
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

do
	require("numb").setup()
end

do -- [fzf] --
	local actions = require("fzf-lua.actions")
	require("fzf-lua").setup({
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
			prompt = "FILES  ",
			cmd = "fd --type f --follow --hidden --color=always -E '.git' -E 'node_modules' -E '*.png' -E '*.jpg' -E '**/Spoons' --ignore-file '~/.gitignore_global'",
			git_icons = true, -- failing if ths is `true`; see failing line: https://github.com/ibhagwan/fzf-lua/blob/main/lua/fzf-lua/core.lua#L53
			git_diff_cmd = "git diff --name-status --relative HEAD",
			actions = {
				["default"] = actions.file_vsplit,
				["ctrl-t"] = actions.file_tabedit,
			},
		},
		grep = {
			prompt = "GREP  ",
			actions = {
				["default"] = actions.file_vsplit,
				["ctrl-t"] = actions.file_tabedit,
			},
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

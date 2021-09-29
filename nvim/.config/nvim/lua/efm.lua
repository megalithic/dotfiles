-- local prettierd = function()
-- 	return {
-- 		exe = "prettierd",
-- 		args = { vim.api.nvim_buf_get_name(0) },
-- 		stdin = true,
-- 	}
-- end
local prettier_format_options = {
	tabWidth = 4,
	singleQuote = true,
	trailingComma = "all",
	configPrecedence = "prefer-file",
}
local prettier = {
	formatCommand = ([[
  $([ -n "$(command -v node_modules/.bin/prettier)" ] && echo "node_modules/.bin/prettier" || echo "prettier")
  ${--config-precedence:prettier_format_options.configPrecedence}
  ${--tab-width:prettier_format_options.tabWidth}
  ${--single-quote:prettier_format_options.singleQuote}
  ${--trailing-comma:prettier_format_options.trailingComma}
  ]]):gsub("\n", ""),
}
local vint = {
	lintCommand = "vint -",
	lintStdin = true,
	lintFormats = { "%f:%l:%c: %m" },
}
local mix_credo = {
	lintCommand = "mix credo suggest --format=flycheck --read-from-stdin ${INPUT}",
	lintStdin = true,
	lintIgnoreExitCode = true,
	lintFormats = {
		"%f:%l:%c: %t: %m",
		"%f:%l: %t: %m",
	},
	rootMarkers = { "mix.lock", "mix.exs" }, -- for some reason, only mix.lock works in vpp
}
local stylua = { formatCommand = "stylua -", formatStdin = true }
local selene = {
	lintCommand = "selene --display-style quiet -",
	lintIgnoreExitCode = true,
	lintStdin = true,
	lintFormats = { "%f:%l:%c: %tarning%m", "%f:%l:%c: %tarning%m" },
}
local eslint = {
	lintCommand = "eslint_d -f visualstudio --stdin --stdin-filename ${INPUT}",
	lintIgnoreExitCode = true,
	lintStdin = true,
	lintFormats = { "%f(%l,%c): %tarning %m", "%f(%l,%c): %trror %m" },
}
local shellcheck = {
	lintCommand = "shellcheck -f gcc -x -",
	lintStdin = true,
	lintFormats = { "%f=%l:%c: %trror: %m", "%f=%l:%c: %tarning: %m", "%f=%l:%c: %tote: %m" },
}
local markdownlint = {
	lintCommand = "markdownlint -s",
	lintStdin = true,
	lintFormats = { "%f:%l:%c %m" },
}
local fish = { formatCommand = "fish_indent", formatStdin = true }
local misspell = {
	lintCommand = "misspell",
	lintIgnoreExitCode = true,
	lintStdin = true,
	lintFormats = { "%f:%l:%c: %m" },
}
local shfmt = {
	formatCommand = "shfmt -ci -s -bn",
	formatStdin = true,
}
local eslintPrettier = { prettier, eslint }
return {
	-- ["="] = {misspell},
	vim = { vint },
	lua = { stylua },
	-- elixir = { mix_credo },
	-- eelixir = { mix_credo },
	fish = { fish },
	typescript = eslintPrettier,
	javascript = eslintPrettier,
	tsx = eslintPrettier,
	typescriptreact = eslintPrettier,
	javascriptreact = eslintPrettier,
	yaml = eslintPrettier,
	json = eslintPrettier,
	html = eslintPrettier,
	scss = eslintPrettier,
	css = eslintPrettier,
	-- markdown = eslintPrettier,
	sh = { shellcheck, shfmt },
	zsh = { shellcheck, shfmt },
}

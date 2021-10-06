local prettier = {
	formatCommand = ([[
  $([ -n "$(command -v node_modules/.bin/prettier)" ] && echo "node_modules/.bin/prettier" || echo "prettier")
  ${--config-precedence:configPrecedence}
  ${--tab-width:tabWidth}
  ${--single-quote:singleQuote}
  ${--trailing-comma:trailingComma}
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
local stylua = {
	formatCommand = "stylua -",
	-- formatCommand = "stylua -s --stdin-filepath ${INPUT} -",
	formatStdin = true,
}
local selene = {
	lintCommand = "selene --display-style quiet -",
	lintIgnoreExitCode = true,
	lintStdin = true,
	lintFormats = { "%f:%l:%c: %tarning%m", "%f:%l:%c: %tarning%m" },
	lintSource = "selene",
}
local eslint = {
	lintCommand = "eslint_d -f visualstudio --stdin --stdin-filename ${INPUT}",
	lintIgnoreExitCode = true,
	lintStdin = true,
	-- lintFormats = { "%f(%l,%c): %tarning %m", "%f(%l,%c): %trror %m" },
	lintFormats = {
		"%f(%l,%c): %tarning %m",
		"%f(%l,%c): %rror %m",
	},
	lintSource = "eslint",
}
local shellcheck = {
	lintCommand = "shellcheck -f gcc -x -",
	lintStdin = true,
	lintFormats = { "%f=%l:%c: %trror: %m", "%f=%l:%c: %tarning: %m", "%f=%l:%c: %tote: %m" },
	lintSource = "shellcheck",
}
local fish = { formatCommand = "fish_indent", formatStdin = true }
local misspell = {
	lintCommand = "misspell",
	lintIgnoreExitCode = true,
	lintStdin = true,
	lintFormats = { "%f:%l:%c: %m" },
	lintSource = "misspell",
}
local shfmt = {
	formatCommand = "shfmt -ci -s -bn",
	-- formatCommand = "shfmt ${-i:tabWidth}",
	formatStdin = true,
}
return {
	["="] = { misspell },
	bash = { shellcheck, shfmt },
	css = { prettier, eslint },
	-- eelixir = { mix_credo },
	-- elixir = { mix_credo },
	fish = { fish },
	html = { prettier, eslint },
	-- javascript = { prettier, eslint },
	-- javascriptreact = { prettier, eslint },
	json = { prettier, eslint },
	lua = { stylua },
	scss = { prettier, eslint },
	sh = { shellcheck, shfmt },
	-- typescript = { prettier, eslint },
	-- typescriptreact = { prettier, eslint },
	vim = { vint },
	-- yaml = { prettier, eslint },
	zsh = { shellcheck, shfmt },
}

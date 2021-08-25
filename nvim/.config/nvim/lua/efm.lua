local vint = {
	lintCommand = "vint -",
	lintStdin = true,
	lintFormats = { "%f:%l:%c: %m" },
}
local luafmt = {
	formatCommand = "luafmt --indent-count 2 --stdin",
	-- formatCommand = "luafmt ${-i:tabWidth} --stdin",
	formatStdin = true,
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
-- local golint = require "mega.lc.efm.golint"
-- local goimports = require "mega.lc.efm.goimports"
-- local black = require "mega.lc.efm.black"
-- local isort = require "mega.lc.efm.isort"
-- local flake8 = require "mega.lc.efm.flake8"
-- local mypy = require "mega.lc.efm.mypy"
local stylua = { formatCommand = "stylua -", formatStdin = true }
local selene = {
	lintCommand = "selene --display-style quiet -",
	lintIgnoreExitCode = true,
	lintStdin = true,
	lintFormats = { "%f:%l:%c: %tarning%m", "%f:%l:%c: %tarning%m" },
}
local prettierLocal = {
	formatCommand = "./node_modules/.bin/prettier --stdin --stdin-filepath ${INPUT}",
	formatStdin = true,
}
local prettierGlobal = {
	formatCommand = "prettier --stdin --stdin-filepath ${INPUT}",
	formatStdin = true,
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
local eslintPrettier = { prettierGlobal, eslint }

return {
	-- ["="] = {misspell},
	vim = { vint },
	lua = { stylua },
	-- elixir = { mix_credo },
	-- eelixir = { mix_credo },
	-- go = {golint, goimports},
	-- python = {black, isort, flake8, mypy},
	fish = {fish},
	typescript = eslintPrettier,
	javascript = eslintPrettier,
	typescriptreact = eslintPrettier,
	javascriptreact = eslintPrettier,
	yaml = eslintPrettier,
	json = eslintPrettier,
	html = eslintPrettier,
	scss = eslintPrettier,
	css = eslintPrettier,
	-- markdown = eslintPrettier,
	sh = { shellcheck, shfmt },
	zsh = { shfmt },
	-- tf = {terraform},
}

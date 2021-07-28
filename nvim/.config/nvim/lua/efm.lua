local vint = {
  lintCommand = "vint -",
  lintStdin = true,
  lintFormats = {"%f:%l:%c: %m"}
}
local luafmt = {
  formatCommand = "luafmt --indent-count 2 --stdin",
  -- formatCommand = "luafmt ${-i:tabWidth} --stdin",
  formatStdin = true
}
local mix_credo = {
  lintCommand = "mix credo suggest --format=flycheck --read-from-stdin ${INPUT}",
  lintStdin = true,
  lintIgnoreExitCode = true,
  lintFormats = {"%f:%l:%c: %m"},
  rootMarkers = {"mix.lock"} -- for some reason, only mix.lock works in vpp
}
-- local golint = require "mega.lc.efm.golint"
-- local goimports = require "mega.lc.efm.goimports"
-- local black = require "mega.lc.efm.black"
-- local isort = require "mega.lc.efm.isort"
-- local flake8 = require "mega.lc.efm.flake8"
-- local mypy = require "mega.lc.efm.mypy"
local prettier = {
  formatCommand = ([[
        ./node_modules/.bin/prettier
        ${--config-precedence:configPrecedence}
        ${--tab-width:tabWidth}
        ${--single-quote:singleQuote}
        ${--trailing-comma:trailingComma}
    ]]):gsub(
    "\n",
    ""
  )
}
local eslint = {
  lintCommand = "./node_modules/.bin/eslint -f unix --stdin",
  lintIgnoreExitCode = true,
  lintStdin = true
}
local shellcheck = {
  lintCommand = "shellcheck -f gcc -x -",
  lintStdin = true,
  lintFormats = {"%f:%l:%c: %trror: %m", "%f:%l:%c: %tarning: %m", "%f:%l:%c: %tote: %m"}
}
local misspell = {
  lintCommand = "misspell",
  lintIgnoreExitCode = true,
  lintStdin = true,
  lintFormats = {"%f:%l:%c: %m"}
}
local shfmt = {
  formatCommand = "shfmt -i 2"
}

return {
  -- ["="] = {misspell},
  vim = {vint},
  lua = {luafmt},
  elixir = {mix_credo},
  eelixir = {mix_credo},
  -- go = {golint, goimports},
  -- python = {black, isort, flake8, mypy},
  typescript = {prettier, eslint},
  javascript = {prettier, eslint},
  typescriptreact = {prettier, eslint},
  javascriptreact = {prettier, eslint},
  yaml = {prettier},
  json = {prettier},
  html = {prettier},
  scss = {prettier},
  css = {prettier},
  markdown = {prettier},
  sh = {shellcheck, shfmt},
  zsh = {shellcheck, shfmt}
  -- tf = {terraform},
}

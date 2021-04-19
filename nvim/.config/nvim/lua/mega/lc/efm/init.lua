local vint = require "mega.lc.efm.vint"
local luafmt = require "mega.lc.efm.luafmt"
local mix_credo = require "mega.lc.efm.mix_credo"
local golint = require "mega.lc.efm.golint"
local goimports = require "mega.lc.efm.goimports"
local black = require "mega.lc.efm.black"
local isort = require "mega.lc.efm.isort"
local flake8 = require "mega.lc.efm.flake8"
local mypy = require "mega.lc.efm.mypy"
local prettier = require "mega.lc.efm.prettier"
local eslint = require "mega.lc.efm.eslint"
local shellcheck = require "mega.lc.efm.shellcheck"
-- local misspell = require "mega.lc.efm.misspell"
-- local terraform = require "mega.lc.efm.terraform"

return {
  -- ["="] = {misspell},
  vim = {vint},
  lua = {luafmt},
  elixir = {mix_credo},
  eelixir = {mix_credo},
  go = {golint, goimports},
  python = {black, isort, flake8, mypy},
  typescript = {prettier, eslint},
  javascript = {prettier, eslint},
  typescriptreact = {prettier, eslint},
  javascriptreact = {prettier, eslint},
  yaml = {prettier},
  json = {prettier},
  html = {prettier},
  scss = {prettier},
  css = {prettier},
  -- markdown = {prettier},
  sh = {shellcheck}
  -- tf = {terraform},
}

M = {
  stylua = {
    formatCommand = "stylua -s --stdin-filepath ${INPUT} -",
    formatStdin = true,
  },
  eslint = {
    lintCommand = "eslint_d -f visualstudio --stdin --stdin-filename ${INPUT}",
    lintIgnoreExitCode = true,
    lintStdin = true,
    lintFormats = {
      "%f(%l,%c): %tarning %m",
      "%f(%l,%c): %rror %m",
    },
    lintSource = "eslint",
  },
  misspell = {
    lintCommand = "misspell",
    lintIgnoreExitCode = true,
    lintStdin = true,
    lintFormats = { "%f:%l:%c: %m" },
    lintSource = "misspell",
  },
  prettier = {
    formatCommand = [[$([ -n "$(command -v node_modules/.bin/prettier)" ] && echo "node_modules/.bin/prettier" || echo "prettier") --stdin-filepath ${INPUT} ${--config-precedence:configPrecedence} ${--tab-width:tabWidth} ${--single-quote:singleQuote} ${--trailing-comma:trailingComma}]],
    formatStdin = true,
  },
  shellcheck = {
    lintCommand = "shellcheck -f gcc -x -",
    lintStdin = true,
    lintFormats = { "%f:%l:%c: %trror: %m", "%f:%l:%c: %tarning: %m", "%f:%l:%c: %tote: %m" },
    lintSource = "shellcheck",
  },
  shfmt = {
    formatCommand = "shfmt ${-i:tabWidth}",
  },
  mix_credo = {
    lintCommand = "mix credo suggest --format=flycheck --read-from-stdin ${INPUT}",
    lintStdin = true,
    lintFormats = { "%f:%l:%c: %t: %m", "%f:%l: %t: %m" },
  },
  mix_format = {
    formatCommand = "mix format ${INPUT}",
  },
  vint = {
    lintCommand = "vint -",
    lintStdin = true,
    lintFormats = { "%f:%l:%c: %m" },
    lintSource = "vint",
  },
}

function M.languages()
  return {
    ["="] = { M.misspell },
    vim = { M.vint },
    lua = { M.stylua },
    typescript = { M.prettier, M.eslint },
    javascript = { M.prettier, M.eslint },
    typescriptreact = { M.prettier, M.eslint },
    javascriptreact = { M.prettier, M.eslint },
    elixir = { M.mix_credo },
    heex = { M.mix_format },
    yaml = { M.prettier },
    json = { M.prettier },
    html = { M.prettier },
    scss = { M.prettier },
    css = { M.prettier },
    markdown = { M.prettier },
    sh = { M.shellcheck, M.shfmt },
  }
end

return M

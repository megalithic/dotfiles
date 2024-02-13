local eslint = { "eslint_d" } -- alts: biome, eslint, eslint_d
local uv = vim.uv or vim.loop
return {
  "mfussenegger/nvim-lint",
  cond = not vim.g.disable_autolint,
  ft = {
    "bash",
    "css",
    "javascript",
    "javascript.jsx",
    "javascriptreact",
    -- "lua",
    "elixir",
    "python",
    "ruby",
    "rst",
    "scss",
    "sh",
    "typescript",
    "typescript.tsx",
    "typescriptreact",
    "vim",
    "yaml",
    -- "zsh",
  },
  opts = {
    linters_by_ft = {
      ["javascript.jsx"] = eslint,
      ["typescript.tsx"] = eslint,
      bash = { "shellcheck" },
      css = { "stylelint" },
      elixir = { "credo" },
      javascript = eslint,
      javascriptreact = eslint,
      json = eslint,
      jsonc = eslint,
      lua = { "selene", "luacheck" },
      markdown = { "markdownlint" },
      python = { "mypy", "pylint" },
      rst = { "rstlint" },
      ruby = { "ruby", "rubocop" },
      scss = { "stylelint" },
      sh = { "shellcheck" },
      typescript = eslint,
      typescriptreact = eslint,
      vim = { "vint" },
      yaml = { "yamllint" },
      zsh = { "shellcheck" },
    },
    linters = {
      selene = {
        condition = function(ctx) return vim.fs.find({ "selene.toml" }, { path = ctx.filename, upward = true })[1] end,
      },
      luacheck = {
        condition = function(ctx) return vim.fs.find({ ".luacheckrc" }, { path = ctx.filename, upward = true })[1] end,
      },
      markdownlint = {
        args = {
          -- "--config",
          -- "~/dotfiles/linter_configs/markdownlint.json",
          "--disable",
          "MD013", -- disable line length limit
          "MD024", -- allow multiple headings with the same comment
          "MD030", -- allow spaces after list markers
          "MD033", -- allow inline HTML
          "MD036", -- allow emphasis blocks
          "MD040", -- allow code blocks without language specification
          "MD041", -- allow non-headers on the first line, e.g. meta section
          "MD046", -- allow mixed code-block styles
          "--",
        },
      },
    },
  },
  config = function(_, opts)
    local lint = require("lint")
    lint.linters_by_ft = opts.linters_by_ft
    for k, v in pairs(opts.linters) do
      lint.linters[k] = v
    end
    local timer = assert(uv.new_timer())
    local DEBOUNCE_MS = 500

    local do_lint = function() lint.try_lint(nil, { ignore_errors = true }) end

    mega.augroup("Lint", {
      {
        event = { "BufEnter", "BufWritePre", "BufWritePost", "TextChanged", "InsertLeave" },
        command = function()
          local bufnr = vim.api.nvim_get_current_buf()
          timer:stop()
          timer:start(
            DEBOUNCE_MS,
            0,
            vim.schedule_wrap(function()
              if vim.api.nvim_buf_is_valid(bufnr) then vim.api.nvim_buf_call(bufnr, do_lint) end
            end)
          )
        end,
      },
    })

    mega.command("ToggleAutoLint", function()
      vim.g.disable_autolint = not vim.g.disable_autolint
      if vim.g.disable_autolint then
        vim.notify("Disabled auto-linting.", L.WARN)
      else
        vim.notify("Enabled auto-linting.", L.INFO)
        do_lint()
      end
    end)

    do_lint()
  end,
}

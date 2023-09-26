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
      bash = { "shellcheck" },
      css = { "styleint" },
      javascript = { "eslint_d" },
      javascriptreact = { "eslint_d" },
      ["javascript.jsx"] = { "eslint_d" },
      -- lua = { "luacheck" },
      python = { "mypy", "pylint" },
      rst = { "rstlint" },
      ruby = { "ruby", "rubocop" },
      scss = { "styleint" },
      sh = { "shellcheck" },
      typescript = { "eslint_d" },
      typescriptreact = { "eslint_d" },
      ["typescript.tsx"] = { "eslint_d" },
      vim = { "vint" },
      yaml = { "yamllint" },
      -- zsh = { "shellcheck" },
    },
    linters = {},
  },
  config = function(_, opts)
    local lint = require("lint")
    lint.linters_by_ft = opts.linters_by_ft
    for k, v in pairs(opts.linters) do
      lint.linters[k] = v
    end
    local timer = assert(uv.new_timer())
    local DEBOUNCE_MS = 500

    mega.augroup("Lint", {
      {
        event = { "BufWritePost", "TextChanged", "InsertLeave" },
        command = function()
          local bufnr = vim.api.nvim_get_current_buf()
          timer:stop()
          timer:start(
            DEBOUNCE_MS,
            0,
            vim.schedule_wrap(function()
              if vim.api.nvim_buf_is_valid(bufnr) then
                vim.api.nvim_buf_call(bufnr, function() lint.try_lint(nil, { ignore_errors = true }) end)
              end
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
        lint.try_lint(nil, { ignore_errors = true })
      end
    end)

    lint.try_lint(nil, { ignore_errors = true })
  end,
}

return function()
  local formatter = require("formatter")

  local fn = vim.fn
  local api = vim.api

  local prettierConfig = function()
    return {
      exe = "prettier",
      args = { "--stdin-filepath", fn.shellescape(api.nvim_buf_get_name(0)), "--single-quote" },
      stdin = true,
    }
  end

  local formatterConfig = {
    lua = {
      function()
        return {
          -- exe = "stylua -s --stdin-filepath ${INPUT} -",
          exe = "stylua",
          args = { "-" },
          stdin = true,
        }
      end,
    },
    vue = {
      function()
        return {
          exe = "prettier",
          args = {
            "--stdin-filepath",
            fn.fnameescape(api.nvim_buf_get_name(0)),
            "--single-quote",
            "--parser",
            "vue",
          },
          stdin = true,
        }
      end,
    },
    rust = {
      -- Rustfmt
      function()
        return {
          exe = "rustfmt",
          args = { "--emit=stdout" },
          stdin = true,
        }
      end,
    },
    swift = {
      -- Swiftlint
      function()
        return {
          exe = "swift-format",
          args = { api.nvim_buf_get_name(0) },
          stdin = true,
        }
      end,
    },
    sh = {
      -- Shell Script Formatter
      function()
        return {
          exe = "shfmt",
          args = { "-i", 2 },
          stdin = true,
        }
      end,
    },
    heex = {
      function()
        return {
          exe = "mix",
          args = { "format", api.nvim_buf_get_name(0) },
          stdin = true,
        }
      end,
    },
    elixir = {
      function()
        return {
          exe = "mix",
          args = { "format", "-" },
          stdin = true,
        }
      end,
    },
    ["*"] = {
      function()
        return {
          -- remove trailing whitespace
          exe = "sed",
          args = { "-i", "'s/[ \t]*$//'" },
          stdin = false,
        }
      end,
    },
  }
  local commonFT = {
    "css",
    "scss",
    "html",
    "java",
    "javascript",
    "javascriptreact",
    "typescript",
    "typescriptreact",
    "markdown",
    "markdown.mdx",
    "json",
    "yaml",
    "xml",
    "svg",
  }
  for _, ft in ipairs(commonFT) do
    formatterConfig[ft] = { prettierConfig }
  end
  -- Setup functions
  formatter.setup({
    logging = true,
    filetype = formatterConfig,
  })
end

return function()
  local formatter = require("formatter")

  local fn = vim.fn
  local api = vim.api

  -- local prettierConfig = function()
  --   return {
  --     exe = "prettier",
  --     args = { "--stdin-filepath", fn.shellescape(api.nvim_buf_get_name(0)), "--single-quote" },
  --     stdin = true,
  --   }
  -- end

  local function prettier()
    P("attempting prettier")
    return {
      exe = "prettier",
      args = {
        "--stdin-filepath",
        vim.fn.shellescape(vim.api.nvim_buf_get_name(0)),
      },
      stdin = true,
    }
  end

  -- local function eslint()
  --   P("attempting eslint")
  --   return {
  --     exe = "eslint",
  --     args = {
  --       "--fix-dry-run",
  --       "--stdin",
  --       "--stdin-filename",
  --       vim.fn.shellescape(vim.api.nvim_buf_get_name(0)),
  --     },
  --     stdin = true,
  --   }
  -- end

  local function prettier_d()
    P("attempting prettier_d")
    return {
      exe = "prettierd",
      args = { vim.fn.shellescape(vim.api.nvim_buf_get_name(0)) },
      stdin = true,
    }
  end

  -- local function eslint_d()
  --   P("attempting eslint_d")
  --   return {
  --     exe = "eslint_d",
  --     args = {
  --       "--fix-to-stdout",
  --       "--stdin",
  --       "--stdin-filename",
  --       vim.fn.shellescape(vim.api.nvim_buf_get_name(0)),
  --     },
  --     stdin = true,
  --   }
  -- end

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
    formatterConfig[ft] = { prettier_d }
  end
  -- Setup functions
  formatter.setup({
    logging = true,
    log_level = vim.log.levels.DEBUG,
    filetype = formatterConfig,
  })
end

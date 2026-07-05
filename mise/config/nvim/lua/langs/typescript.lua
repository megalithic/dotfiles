-- lua/langs/typescript.lua
-- TypeScript/JavaScript language support

return {
  filetypes = {
    "javascript",
    "javascriptreact",
    "javascript.jsx",
    "typescript",
    "typescriptreact",
    "typescript.tsx",
  },

  servers = {
    vtsls = {
      cmd = { "vtsls", "--stdio" },
      root_markers = { "tsconfig.json", "package.json", "jsconfig.json", ".git" },
      filetypes = {
        "javascript",
        "javascriptreact",
        "javascript.jsx",
        "typescript",
        "typescriptreact",
        "typescript.tsx",
      },
      settings = {
        complete_function_calls = true,
        vtsls = {
          enableMoveToFileCodeAction = true,
          autoUseWorkspaceTsdk = true,
          experimental = {
            completion = {
              enableServerSideFuzzyMatch = true,
            },
          },
        },
        typescript = {
          updateImportsOnFileMove = { enabled = "always" },
          suggest = { completeFunctionCalls = true },
          inlayHints = {
            enumMemberValues = { enabled = true },
            functionLikeReturnTypes = { enabled = true },
            parameterNames = { enabled = "literals" },
            parameterTypes = { enabled = true },
            propertyDeclarationTypes = { enabled = true },
            variableTypes = { enabled = false },
          },
        },
        javascript = {
          updateImportsOnFileMove = { enabled = "always" },
          inlayHints = {
            parameterNames = { enabled = "literals" },
            parameterTypes = { enabled = true },
            variableTypes = { enabled = false },
            propertyDeclarationTypes = { enabled = true },
            functionLikeReturnTypes = { enabled = true },
            enumMemberValues = { enabled = true },
          },
        },
      },
      keys = {
        {
          "gD",
          function()
            local params = vim.lsp.util.make_position_params()
            vim.lsp.buf_request(0, "workspace/executeCommand", {
              command = "typescript.goToSourceDefinition",
              arguments = { params.textDocument.uri, params.position },
            })
          end,
          mode = "n",
          desc = "Goto source definition",
        },
        {
          "<leader>lo",
          function()
            vim.lsp.buf.code_action({
              apply = true,
              context = { only = { "source.organizeImports" }, diagnostics = {} },
            })
          end,
          mode = "n",
          desc = "Organize imports",
        },
        {
          "<leader>lM",
          function()
            vim.lsp.buf.code_action({
              apply = true,
              context = { only = { "source.addMissingImports.ts" }, diagnostics = {} },
            })
          end,
          mode = "n",
          desc = "Add missing imports",
        },
        {
          "<leader>lR",
          function()
            vim.lsp.buf.code_action({
              apply = true,
              context = { only = { "source.removeUnused.ts" }, diagnostics = {} },
            })
          end,
          mode = "n",
          desc = "Remove unused imports",
        },
      },
    },
    biome = {
      cmd = { "biome", "lsp-proxy" },
      filetypes = {
        "astro",
        "css",
        "graphql",
        "html",
        "javascript",
        "javascriptreact",
        "json",
        "jsonc",
        "svelte",
        "typescript",
        "typescript.tsx",
        "typescriptreact",
        "heex",
        "vue",
      },
      workspace_required = true,
      single_file_support = false,
      root_dir = function(bufnr, cb)
        local configs = { "biome.json", "biome.jsonc" }
        local fname = vim.uri_to_fname(vim.uri_from_bufnr(bufnr))
        local match = vim.fs.find(configs, { upward = true, path = fname })[1]

        if match then cb(vim.fn.fnamemodify(match, ":h")) end
      end,
    },
  },

  formatters = {
    javascript = { "biome", "prettierd", "prettier", stop_after_first = true },
    javascriptreact = { "biome", "prettierd", "prettier", stop_after_first = true },
    typescript = { "biome", "prettierd", "prettier", stop_after_first = true },
    typescriptreact = { "biome", "prettierd", "prettier", stop_after_first = true },
  },

  repl = {
    cmd = "node",
    position = "right",
  },
}

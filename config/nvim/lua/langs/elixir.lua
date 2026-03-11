-- lua/langs/elixir.lua
-- Elixir/HEEx language support

-- Helper: find ancestor node of given types
local function find_node_ancestor(types, node)
  if not node then return nil end
  if type(types) == "string" then types = { types } end

  while node do
    if vim.list_contains(types, node:type()) then return node end
    node = node:parent()
  end
  return nil
end

-- Smart = in HEEx/EEx: inside attribute -> ={""} with cursor inside quotes
local function setup_smart_equals(bufnr)
  vim.keymap.set("i", "=", function()
    local cursor = vim.api.nvim_win_get_cursor(0)
    local left_of_cursor_range = { cursor[1] - 1, cursor[2] - 1 }
    local node = vim.treesitter.get_node({ ignore_injections = false, pos = left_of_cursor_range })
    local attr_node = find_node_ancestor({ "attribute_name", "directive_argument", "directive_name" }, node)
    return attr_node and '={""}<left><left>' or "="
  end, { expr = true, buffer = bufnr, desc = "Smart = in attributes" })
end

-- Shared elixir ftplugin settings
local elixir_ftplugin = {
  opt = {
    shiftwidth = 2,
    tabstop = 2,
    expandtab = true,
    commentstring = "# %s",
  },
  abbr = {
    ep = "|>",
    epry = "require IEx; IEx.pry",
    -- Cursor positioning: <Esc>hi = escape, left, insert (cursor inside parens)
    ei = "IO.inspect()<Esc>hi",
    eputs = "IO.puts()<Esc>hi",
    edb = "dbg()<Esc>hi",
    -- ~H sigil with cursor inside: escape, 2 left, newline, up, delete indent
    ["~H"] = '~H""""""<Esc>2hi<CR><Esc>O',
    ["~h"] = '~H""""""<Esc>2hi<CR><Esc>O',
    [":skip:"] = "@tag :skip",
    tskip = "@tag :skip",
  },
  keys = {
    -- Pipe helpers (new line variants)
    { "n", "<localleader>ep", "o|><Esc>a", desc = "Pipe (new line)" },
    { "n", "<localleader>ed", "o|> dbg()<Esc>", desc = "dbg (new line)" },
    { "n", "<localleader>ei", "o|> IO.inspect()<Esc>i", desc = "IO.inspect (new line)" },
    { "n", "<localleader>eil", 'o|> IO.inspect(label: "")<Esc>hi', desc = "IO.inspect with label" },

    -- To/From pipe macros (via LSP)
    {
      "n",
      "<localleader>eP",
      function()
        local params = vim.lsp.util.make_position_params(0, "utf-16")
        vim.lsp.buf_request(0, "workspace/executeCommand", {
          command = "manipulatePipes:serverid",
          arguments = { "toPipe", params.textDocument.uri, params.position.line, params.position.character },
        })
      end,
      desc = "To pipe",
    },
    {
      "n",
      "<localleader>eF",
      function()
        local params = vim.lsp.util.make_position_params(0, "utf-16")
        vim.lsp.buf_request(0, "workspace/executeCommand", {
          command = "manipulatePipes:serverid",
          arguments = { "fromPipe", params.textDocument.uri, params.position.line, params.position.character },
        })
      end,
      desc = "From pipe",
    },
  },
  callback = function(bufnr)
    -- Extend iskeyword for Elixir identifiers (!, ?, etc.)
    vim.cmd.setlocal("iskeyword+=!,?")
    -- Adjust indentation for `end` keyword
    vim.cmd.setlocal("indentkeys-=0{")
    vim.cmd.setlocal("indentkeys+=0=end")

    -- Smart = in attributes
    setup_smart_equals(bufnr)

    -- Mini.clue hints
    if pcall(require, "mini.clue") then
      vim.b[bufnr].miniclue_config = {
        clues = {
          { mode = "n", keys = "<localleader>e", desc = "+elixir" },
          { mode = "n", keys = "<localleader>r", desc = "+repl" },
          { mode = "v", keys = "<localleader>r", desc = "+repl" },
        },
      }
    end
  end,
}

return {
  filetypes = { "elixir", "eelixir", "heex" },

  servers = {
    -- Expert: Official Elixir LSP (https://github.com/elixir-lang/expert)
    expert = {
      cmd = { "expert", "--stdio" },
      root_markers = { "mix.exs", ".git" },
    },

    -- Tailwind CSS for HEEx templates
    tailwindcss = {
      cmd = { "tailwindcss-language-server", "--stdio" },
      root_markers = { "tailwind.config.js", "tailwind.config.ts", ".git" },
      filetypes = { "html", "heex", "elixir", "eelixir", "css", "scss" },
      init_options = {
        userLanguages = {
          elixir = "html-eex",
          eelixir = "html-eex",
          heex = "html-eex",
        },
      },
      settings = {
        tailwindCSS = {
          experimental = {
            classRegex = {
              'class[:]\\s*"([^"]*)"',
              "class[:]\\s*'([^']*)'",
              '~H""".*class="([^"]*)".*"""',
            },
          },
        },
      },
    },
  },

  formatters = {
    elixir = { lsp_format = "prefer" },
    eelixir = { lsp_format = "prefer" },
    heex = { lsp_format = "prefer" },
  },

  repl = {
    cmd = "iex -S mix",
    position = "right",
    reload_cmd = "recompile()",
  },

  ftplugin = {
    elixir = elixir_ftplugin,
    eelixir = elixir_ftplugin,
    heex = {
      opt = {
        shiftwidth = 2,
        tabstop = 2,
        expandtab = true,
        commentstring = "<%!-- %s --%>",
      },
      callback = setup_smart_equals,
    },
  },

  plugins = {
    {
      "jesseleite/iex.nvim",
      ft = { "elixir", "eelixir", "heex" },
      opts = {},
    },
    -- {
    --   "elixir-tools/elixir-tools.nvim",
    --   version = "*",
    --   -- dev = true,
    --   event = { "BufReadPre", "BufNewFile" },
    --   config = function()
    --     local elixir = require("elixir")
    --     local use_expert = true
    --     local nextls_opts = {
    --       enable = not use_expert,
    --       spitfire = false,
    --       -- cmd = "/home/mitchell/src/next-ls/burrito_out/next_ls_linux_amd64",
    --       init_options = {
    --         experimental = {
    --           completions = {
    --             enable = true,
    --           },
    --         },
    --       },
    --     }
    --
    --     if use_expert then vim.lsp.enable("expert") end
    --
    --     elixir.setup({
    --       nextls = nextls_opts,
    --       credo = { enable = false },
    --       elixirls = { enable = false },
    --     })
    --   end,
    --   dependencies = {
    --     "nvim-lua/plenary.nvim",
    --     "mhanberg/workspace-folders.nvim",
    --   },
    -- },
  },
}

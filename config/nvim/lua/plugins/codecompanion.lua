return {
  "olimorris/codecompanion.nvim",
  dependencies = {
    { "nvim-treesitter/nvim-treesitter", build = ":TSUpdate" },
    { "nvim-lua/plenary.nvim" },
    { "saghen/blink.cmp" },
  },
  -- opts = {
  --   --Refer to: https://github.com/olimorris/codecompanion.nvim/blob/main/lua/codecompanion/config.lua
  --   strategies = {
  --     --NOTE: Change the adapter as required
  --     -- chat = { adapter = "copilot" },
  --     -- inline = { adapter = "copilot" },
  --     chat = {
  --       adapter = "anthropic",
  --       keymaps = {
  --         close = { modes = { n = "<C-q>", i = "<C-q>" }, opts = {} },
  --         options = { modes = { n = "<leader>h" }, opts = {} },
  --       },
  --     },
  --     inline = { adapter = "anthropic" },
  --   },
  --   adapters = {
  --     acp = {
  --       claude_code = function()
  --         return require("codecompanion.adapters").extend("claude_code", {
  --           env = {
  --             -- CLAUDE_CODE_OAUTH_TOKEN = vim.env.CLAUDE_CODE_OAUTH_TOKEN,
  --             CLAUDE_CODE_OAUTH_TOKEN = "cmd:op read op://shared/megaenv/CLAUDE_CODE_OAUTH_TOKEN --no-newline",
  --           },
  --         })
  --       end,
  --     },
  --   },
  --   -- extensions = {
  --   --   history = { enabled = true },
  --   -- },
  --   opts = {
  --     log_level = "DEBUG",
  --   },
  -- },
  config = function(_, opts)
    -- require("codecompanion").setup(opts)
    --
    -- vim.keymap.set(
    --   { "n", "v" },
    --   "<localleader>A",
    --   "<cmd>CodeCompanionActions<cr>",
    --   { noremap = true, silent = true, desc = "✨ Actions" }
    -- )
    -- vim.keymap.set(
    --   { "n", "v" },
    --   "<localleader>a",
    --   "<cmd>CodeCompanionChat Toggle<cr>",
    --   { noremap = true, silent = true, desc = "✨ Toggle Chat" }
    -- )
    -- vim.keymap.set(
    --   "v",
    --   "<localleader>c",
    --   "<cmd>CodeCompanionChat Add<cr>",
    --   { noremap = true, silent = true, desc = "✨ Add to Chat" }
    -- )
    --
    -- vim.cmd([[cab cc CodeCompanion]])

    -- required for githubmodels token via gh
    vim.env["CODECOMPANION_TOKEN_PATH"] = vim.fn.expand("~/.config")
    local ai_strategy = os.getenv("AI_STRATEGY") or "anthropic"

    require("codecompanion").setup({
      strategies = {
        chat = {
          adapter = ai_strategy,
          keymaps = {
            close = { modes = { n = "<C-q>", i = "<C-q>" }, opts = {} },
            options = { modes = { n = "<leader>h" }, opts = {} },
          },
        },
        inline = { adapter = ai_strategy },
      },
      adapters = {
        acp = {
          cspire_claude_code = function()
            return require("codecompanion.adapters").extend("claude_code", {
              env = {
                ANTHROPIC_API_KEY = nil,
                CLAUDE_CODE_OAUTH_TOKEN = nil,
                -- ANTHROPIC_API_KEY = "cmd:op read op://Private/yy6goxmme5pm5jkhsmspolopme/credential --no-newline",
              },
              commands = {
                default = {
                  "claude-code",
                },
              },
            })
          end,
          devclarity_claude_code = function()
            return require("codecompanion.adapters").extend("claude_code", {
              env = {
                ANTHROPIC_API_KEY = "cmd:op read op://shared/megaenv/ANTHROPIC_API_KEY --no-newline",
                -- ANTHROPIC_API_KEY = "cmd:op read op://Private/yy6goxmme5pm5jkhsmspolopme/credential --no-newline",
              },
              commands = {
                default = {
                  "claude-code-acp",
                },
              },
            })
          end,
          opencode = function()
            return require("codecompanion.adapters").extend("claude_code", {
              name = "opencode",
              formatted_name = "OpenCode",
              commands = {
                default = { "opencode", "acp" },
              },
            })
          end,
        },
        http = {
          -- hide adapters that I haven't explicitly configured
          opts = { show_defaults = false },
          anthropic = function()
            return require("codecompanion.adapters").extend("anthropic", {
              env = {
                api_key = "cmd:op read op://shared/megaenv/CLAUDE_CODE_OAUTH_TOKEN --no-newline",
                -- api_key = "cmd:op read op://Private/Claude/credential --no-newline",
              },
            })
          end,
          githubmodels = function()
            return require("codecompanion.adapters").extend("githubmodels", {
              schema = {
                model = {
                  default = "gpt-4.1",
                },
              },
            })
          end,
        },
      },
      -- extensions = {
      --   history = {
      --     enabled = true,
      --     opts = {
      --       title_generation_opts = nil,
      --       -- title_generation_opts = {
      --       --   adapter = 'copilot',
      --       --   model = 'gpt-4.1'
      --       -- },
      --     },
      --   },
      -- },
    })

    vim.keymap.set(
      { "n", "v" },
      "<localleader>A",
      "<cmd>CodeCompanionActions<cr>",
      { noremap = true, silent = true, desc = "✨ Actions" }
    )
    vim.keymap.set(
      { "n", "v" },
      "<localleader>a",
      "<cmd>CodeCompanionChat Toggle<cr>",
      { noremap = true, silent = true, desc = "✨ Toggle Chat" }
    )
    vim.keymap.set(
      "v",
      "<localleader>c",
      "<cmd>CodeCompanionChat Add<cr>",
      { noremap = true, silent = true, desc = "✨ Add to Chat" }
    )

    -- Expand 'cc' into 'CodeCompanion' in the command line
    vim.cmd([[cab cc CodeCompanion]])
  end,
}

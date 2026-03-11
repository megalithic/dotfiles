if true then return {} end

-- REF:
--
-- ollama-copilot??
-- https://github.com/ViViDboarder/vim-settings/blob/master/neovim/lua/plugins/ollama_copilot.lua
local key = function(mode, lhs, rhs, opts)
  local defaults = { silent = true, noremap = true }
  if type(opts) == "string" then defaults.desc = opts end
  opts = type(opts) == "table" and opts or {}
  vim.keymap.set(mode, lhs, rhs, vim.tbl_extend("force", defaults, opts))
end

return {
  {
    cond = vim.g.ai == "claudecode",
    "coder/claudecode.nvim",
    dependencies = { "folke/snacks.nvim" },
    opts = {
      -- Server Configuration
      port_range = { min = 10000, max = 65535 },
      auto_start = true,
      log_level = "info", -- "trace", "debug", "info", "warn", "error"
      terminal_cmd = nil, -- Custom terminal command (default: "claude")

      -- Selection Tracking
      track_selection = true,
      visual_demotion_delay_ms = 50,

      -- Terminal Configuration
      terminal = {
        split_side = "right", -- "left" or "right"
        split_width_percentage = 0.30,
        provider = "native", -- "auto", "snacks", or "native"
        auto_close = true,
      },

      -- Diff Integration
      diff_opts = {
        auto_close_on_accept = true,
        vertical_split = true,
        open_in_current_tab = true,
      },
    },
    keys = {
      { "<leader>cc", "<cmd>ClaudeCode<cr>", desc = "Toggle Claude" },
      { "<leader>cs", "<cmd>ClaudeCodeSend<cr>", mode = "v", desc = "Send to Claude" },
      { "<leader>c", nil, desc = "AI/Claude Code" },
      { "<leader>cc", "<cmd>ClaudeCode<cr>", desc = "Toggle Claude" },
      { "<leader>cf", "<cmd>ClaudeCodeFocus<cr>", desc = "Focus Claude" },
      { "<leader>cr", "<cmd>ClaudeCode --resume<cr>", desc = "Resume Claude" },
      { "<leader>cC", "<cmd>ClaudeCode --continue<cr>", desc = "Continue Claude" },
      { "<leader>cb", "<cmd>ClaudeCodeAdd %<cr>", desc = "Add current buffer" },
      { "<leader>cs", "<cmd>ClaudeCodeSend<cr>", mode = "v", desc = "Send to Claude" },
      {
        "<leader>cs",
        "<cmd>ClaudeCodeTreeAdd<cr>",
        desc = "Add file",
        ft = { "NvimTree", "neo-tree", "oil" },
      },
      -- Diff management
      { "<leader>ca", "<cmd>ClaudeCodeDiffAccept<cr>", desc = "Accept diff" },
      { "<leader>cd", "<cmd>ClaudeCodeDiffDeny<cr>", desc = "Deny diff" },
    },
  },
  {
    "olimorris/codecompanion.nvim",
    cond = vim.g.ai == "codecompanion",
    dependencies = {
      "nvim-lua/plenary.nvim",
      "nvim-treesitter/nvim-treesitter",
      "ravitemer/mcphub.nvim",
    },

    config = function()
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
            devclarity_claude_code = function()
              return require("codecompanion.adapters").extend("claude_code", {
                env = {
                  ANTHROPIC_API_KEY = "cmd:op read op://Private/yy6goxmme5pm5jkhsmspolopme/credential --no-newline",
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
                  api_key = "cmd:op read op://Private/Claude/credential --no-newline",
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
        extensions = {
          history = {
            enabled = true,
            opts = {
              title_generation_opts = nil,
              -- title_generation_opts = {
              --   adapter = 'copilot',
              --   model = 'gpt-4.1'
              -- },
            },
          },
        },
      })

      vim.keymap.set(
        { "n", "v" },
        "<LocalLeader>A",
        "<cmd>CodeCompanionActions<cr>",
        { noremap = true, silent = true, desc = "✨ Actions" }
      )
      vim.keymap.set(
        { "n", "v" },
        "<LocalLeader>a",
        "<cmd>CodeCompanionChat Toggle<cr>",
        { noremap = true, silent = true, desc = "✨ Toggle Chat" }
      )
      vim.keymap.set(
        "v",
        "<LocalLeader>c",
        "<cmd>CodeCompanionChat Add<cr>",
        { noremap = true, silent = true, desc = "✨ Add to Chat" }
      )

      -- Expand 'cc' into 'CodeCompanion' in the command line
      vim.cmd([[cab cc CodeCompanion]])

      -- local plugin = require("codecompanion")
      --
      -- local toggle_chat_buffer = function()
      --   plugin.toggle()
      -- end
      --
      -- local ask_inline = function()
      --   plugin.prompt("inline")
      -- end
      --
      -- local ask_lsp_diagnostics = function()
      --   plugin.prompt("lsp")
      -- end
      --
      -- local ask_explain_snippet = function()
      --   plugin.prompt("explain")
      -- end
      --
      -- local ask_fix_snippet = function()
      --   plugin.prompt("fix")
      -- end
      --
      -- key({ "n", "v" }, "<localleader>aa", toggle_chat_buffer, "AI: Toggle chat buffer")
      -- key({ "n", "v" }, "<localleader>al", ask_lsp_diagnostics, "AI: Explain LSP diagnostics")
      -- key({ "n", "v" }, "<localleader>ai", ask_inline, "AI: Inline")
      -- key({ "v" }, "<localleader>ae", ask_explain_snippet, "AI: Explain snippet")
      -- key({ "v" }, "<localleader>af", ask_fix_snippet, "AI: Fix snippet")
      --
      -- plugin.setup({
      --   prompt_library = {
      --     ["Custom Prompt"] = {
      --       opts = {
      --         short_name = "inline",
      --       },
      --     },
      --   },
      --   extensions = {
      --     mcphub = {
      --       callback = "mcphub.extensions.codecompanion",
      --       opts = {
      --         make_vars = true,
      --         make_slash_commands = true,
      --         show_result_in_chat = true,
      --       },
      --     },
      --   },
      --   strategies = {
      --     -- chat = {
      --     --   adapter = "anthropic",
      --     --   keymaps = {
      --     --     hide = {
      --     --       modes = {
      --     --         n = "q",
      --     --       },
      --     --       callback = function(chat) chat.ui:hide() end,
      --     --       description = "AI: Hide the chat buffer",
      --     --     },
      --     --   },
      --     -- },
      --     -- inline = {
      --     --   adapter = "anthropic",
      --     -- },
      --
      --     chat = {
      --       adapter = "copilot",
      --       keymaps = {
      --         hide = {
      --           modes = {
      --             n = "q",
      --           },
      --           callback = function(chat)
      --             chat.ui:hide()
      --           end,
      --           description = "AI: Hide the chat buffer",
      --         },
      --       },
      --     },
      --     inline = {
      --       adapter = "copilot",
      --     },
      --     agent = {
      --       adapter = "copilot",
      --     },
      --   },
      --   -- adapters = {
      --   --   copilot = function()
      --   --     return require("codecompanion.adapters").extend("anthropic", {
      --   --       schema = {
      --   --         model = {
      --   --           default = "claude-3.5-sonnet",
      --   --         },
      --   --       },
      --   --     })
      --   --   end,
      --   --   anthropic = function()
      --   --     return require("codecompanion.adapters").extend("anthropic", {
      --   --       env = {
      --   --         api_key = vim.env.ANTHROPIC_API_KEY,
      --   --       },
      --   --     })
      --   --   end,
      --   -- },
      --   display = {
      --     chat = {
      --       intro_message = "Press ? for options",
      --       show_setting = true,
      --     },
      --   },
      -- })
    end,
  },

  { -- lua alternative to the official codeium.vim plugin https://github.com/Exafunction/codeium.vim
    "monkoose/neocodeium",
    cond = vim.g.ai == "neocodeium",
    event = "InsertEnter",
    cmd = "NeoCodeium",
    opts = {
      filetypes = {
        oil = false,
        gitcommit = false,
        NeogitCommit = false,
        NeogitCommitMessage = false,
        markdown = false,
        DressingInput = false,
        TelescopePrompt = false,
        noice = false, -- sometimes triggered in error-buffers
        text = false, -- `pass` passwords editing filetype is plaintext
        ["rip-substitute"] = true,
      },
      silent = true,
      show_label = false, -- signcolumn label for number of suggestions
    },
    init = function()
      -- disable while recording
      vim.api.nvim_create_autocmd("RecordingEnter", { command = "NeoCodeium disable" })
      vim.api.nvim_create_autocmd("RecordingLeave", { command = "NeoCodeium enable" })
    end,
    keys = {
      {
        "<C-y>",
        function() require("neocodeium").accept() end,
        mode = "i",
        desc = "󰚩 Accept full suggestion",
      },
      {
        "<C-t>",
        function() require("neocodeium").accept_line() end,
        mode = "i",
        desc = "󰚩 Accept line",
      },
      {
        "<C-c>",
        function() require("neocodeium").clear() end,
        mode = "i",
        desc = "󰚩 Clear suggestion",
      },
      -- { "<C-w>", function() require("neocodeium").accept_word() end, mode = "i", desc = "󰚩 Accept word" },
      {
        "<A-n>",
        function() require("neocodeium").cycle(1) end,
        mode = "i",
        desc = "󰚩 Next suggestion",
      },
      {
        "<A-p>",
        function() require("neocodeium").cycle(-1) end,
        mode = "i",
        desc = "󰚩 Prev suggestion",
      },
      {
        "<leader>oa",
        function()
          vim.cmd.NeoCodeium("toggle")
          -- local on = require("neocodeium.options").options.enabled
          -- require("config.utils").notify("NeoCodeium", on and "enabled" or "disabled", "info")
        end,
        desc = "󰚩 NeoCodeium Suggestions",
      },
    },
  },
}

return {
  { -- lua alternative to the official codeium.vim plugin https://github.com/Exafunction/codeium.vim
    "monkoose/neocodeium",
    cond = function() return vim.g.ai == "neocodeium" end,
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
      { "<C-y>", function() require("neocodeium").accept() end, mode = "i", desc = "󰚩 Accept full suggestion" },
      { "<C-t>", function() require("neocodeium").accept_line() end, mode = "i", desc = "󰚩 Accept line" },
      {
        "<C-c>",
        function() require("neocodeium").clear() end,
        mode = "i",
        desc = "󰚩 Clear suggestion",
      },
      -- { "<C-w>", function() require("neocodeium").accept_word() end, mode = "i", desc = "󰚩 Accept word" },
      { "<A-n>", function() require("neocodeium").cycle(1) end, mode = "i", desc = "󰚩 Next suggestion" },
      { "<A-p>", function() require("neocodeium").cycle(-1) end, mode = "i", desc = "󰚩 Prev suggestion" },
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
  -- {
  --   "milanglacier/minuet-ai.nvim",
  --   dependencies = { { "nvim-lua/plenary.nvim" }, { "hrsh7th/nvim-cmp" } },
  --   config = function()
  --     require("minuet").setup({
  --       provider = "openai", -- openai, codestral, gemini
  --       request_timeout = 4,
  --       throttle = 2000,
  --       notify = "verbose",
  --       provider_options = {
  --         codestral = {
  --           optional = {
  --             stop = { "\n\n" },
  --             max_tokens = 256,
  --           },
  --         },
  --         gemini = {
  --           optional = {
  --             generationConfig = {
  --               maxOutputTokens = 256,
  --               topP = 0.9,
  --             },
  --             safetySettings = {
  --               {
  --                 category = "HARM_CATEGORY_DANGEROUS_CONTENT",
  --                 threshold = "BLOCK_NONE",
  --               },
  --               {
  --                 category = "HARM_CATEGORY_HATE_SPEECH",
  --                 threshold = "BLOCK_NONE",
  --               },
  --               {
  --                 category = "HARM_CATEGORY_HARASSMENT",
  --                 threshold = "BLOCK_NONE",
  --               },
  --               {
  --                 category = "HARM_CATEGORY_SEXUALLY_EXPLICIT",
  --                 threshold = "BLOCK_NONE",
  --               },
  --             },
  --           },
  --         },
  --         openai = {
  --           optional = {
  --             max_tokens = 256,
  --             top_p = 0.9,
  --           },
  --         },
  --         openai_compatible = {
  --           optional = {
  --             max_tokens = 256,
  --             top_p = 0.9,
  --           },
  --         },
  --       },
  --     })
  --   end,
  --   cond = function() return vim.g.ai == "minuet" end,
  -- },
  -- {
  --   "olimorris/codecompanion.nvim",
  --   cmd = { "CodeCompanion", "CodeCompanionActions" },
  --   cond = function() return vim.g.ai == "codecompanion" end,
  --   dependencies = {
  --     "nvim-lua/plenary.nvim",
  --     "nvim-treesitter/nvim-treesitter",
  --     -- "stevearc/dressing.nvim", -- Optional: Improves the default Neovim UI
  --   },
  --   config = function()
  --     local code_companion = require("codecompanion")
  --     local adapters = require("codecompanion.adapters")
  --
  --     code_companion.setup({
  --       adapters = {
  --         ollama = adapters.use("ollama", {
  --           schema = {
  --             model = {
  --               default = get_preferred_model(),
  --             },
  --           },
  --         }),
  --       },
  --       strategies = {
  --         chat = { adapter = "ollama" },
  --         inline = { adapter = "ollama" },
  --         agent = { adapter = "ollama" },
  --       },
  --     })
  --   end,
  -- },
}

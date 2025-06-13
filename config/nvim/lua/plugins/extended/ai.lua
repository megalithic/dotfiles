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
    "zbirenbaum/copilot.lua",
    cond = vim.g.ai == "copilot",
    event = "VeryLazy",
    config = function()
      require("copilot").setup({
        suggestion = {
          enabled = true,
          auto_trigger = true,
          keymap = {
            accept = "<C-g>",
          },
        },
        panel = { enabled = true },
        filetypes = {
          sh = function()
            local filename = vim.fs.basename(vim.api.nvim_buf_get_name(0))
            if string.match(filename, "^%.env.*") or string.match(filename, "^%.secret.*") or string.match(filename, "^%id_rsa.*") then return false end

            return true
          end,
          ["copilot-chat"] = true,
          ["*"] = true,
          ["."] = true,
          markdown = true,
        },
      })
    end,
  },
  {
    "CopilotC-Nvim/CopilotChat.nvim",
    cond = vim.g.ai == "copilot",
    branch = "main",
    dependencies = {
      "zbirenbaum/copilot.lua",
      -- "github/copilot.vim",
      "nvim-lua/plenary.nvim", -- for curl, log wrapper
    },
    keys = {
      {
        "<leader>cc",
        mode = { "n", "v" },
        "<cmd>CopilotChat<CR>",
        desc = "CopilotChat - Help actions",
      },
      {
        "<leader>ch",
        mode = { "n", "v" },
        function()
          local actions = require("CopilotChat.actions")
          -- require("CopilotChat.integrations.telescope").pick(actions.help_actions())
          require("CopilotChat.integrations.telescope").pick(actions.help_actions())
        end,
        desc = "CopilotChat - Help actions",
      },
      -- Show prompts actions with telescope
      {
        "<leader>cp",
        function()
          local actions = require("CopilotChat.actions")
          -- require("CopilotChat.integrations.telescope").pick(actions.prompt_actions({
          -- 	selection = require("CopilotChat.select").visual,
          -- }))
          require("CopilotChat.integrations.telescope").pick(actions.prompt_actions({
            selection = require("CopilotChat.select").visual,
          }))
        end,
        mode = { "n", "x", "v" },
        desc = "CopilotChat - Prompt actions",
      },
      -- {
      --     "<leader>cp",
      --     function()
      --         require("utils").copy_visual_selection()
      --         local actions = require("CopilotChat.actions")
      --         require("CopilotChat.integrations.telescope").pick(actions.prompt_actions())
      --     end,
      --     mode = { "x", "v" },
      --     desc = "CopilotChat - Prompt actions",
      -- },
      {
        "<leader>cq",
        function()
          local input = vim.fn.input("Quick Chat: ")
          if input ~= "" then require("CopilotChat").ask(input, { selection = require("CopilotChat.select").buffer }) end
        end,
        desc = "CopilotChat - Quick chat",
      },
      {
        "<leader>cdf",
        function()
          local ft = vim.bo.filetype

          vim.cmd("normal vaf")

          require("CopilotChat").ask([[
	As an expert ]] .. ft .. [[ developer, generate comprehensive and precise documentation for the following function/method. Adhere strictly to ]] .. ft .. [['s official documentation standards and best practices.
	Do not include implementation details, nor should you describe how the function works.
	Do not include any code snippets or examples.
	Do not include any information that is not directly related to the function's purpose and behavior.
	Do not describe the function's behavior in terms of the implementation.
	Do not assume any prior knowledge of the function's purpose or behavior.
	The length of a good documentation is between 50 and 100 words.
	The length of a line should not exceed 80 characters.

	Do include the following:

	1. A concise yet informative description of the function's purpose and behavior.
	2. Detailed parameter information:
	   - Name
	   - Type (be specific, e.g., 'List[int]' instead of just 'List')
	   - Description, including any constraints or expected formats
	   - Whether the parameter is optional, and if so, its default value
	3. Return value:
	   - Type (be as specific as possible)
	   - Detailed description of what is returned
	   - Any special cases or conditions that affect the return value
	4. Exceptions or errors:
	   - Specific exceptions that may be raised/thrown
	   - Conditions under which each exception occurs

	Use appropriate ]] .. ft .. [[ specific documentation syntax and formatting.

	Others conditions:
	 - If the language is lua, use the 3 dashes comment format.

	Function signature:
	                    ]], {
            selection = require("CopilotChat.select").visual,
            callback = function(response) vim.cmd("normal <C-y>") end,
          })
        end,
      },
      {
        "<leader>c",
        mode = { "n", "v" },
        function()
          local ft = vim.bo.filetype
          local prompt = [[
	                    /COPILOT_GENERATE
	As an expert ]] .. ft .. [[ developer, respond concisely and accurately based only on the provided code selection. Do not provide too much detail or discuss unrelated topics. Follows this rules:
	 	1. If you find a mistake in the code, please correct it.
	    2. If you think an information can be interesting, please provide it.
	    3. If you think the code can be improved, please provide a better version.
	    4. Do only respond to the request, do not provide additional information.
	Question or request: ]]

          local mode = vim.api.nvim_get_mode().mode
          local header = "Request"
          local is_visual = mode == "v" or mode == "V" or mode == ""

          if is_visual then header = header .. " (visual)" end

          local question = vim.fn.input(header)
          if question == "" then return end

          if is_visual then
            require("CopilotChat").ask(prompt .. question, { selection = require("CopilotChat.select").visual })
          else
            require("CopilotChat").ask(prompt .. question)
          end
        end,
      },
    },
    opts = function()
      local user = vim.env.USER or "User"
      -- user = user:sub(1, 1):upper() .. user:sub(2)

      return {
        question_header = "  " .. user .. " ",
        answer_header = "  Copilot ",
        error_header = "  Error ",
        separator = "───",
        show_folds = false,
        auto_follow_cursor = false,
        debug = false,
        log_level = "error",
        -- context = "buffer",

        selection = function(source) return require("CopilotChat.select").visual(source) or "" end,

        prompts = {
          BetterNamings = {
            prompt = "/COPILOT_GENERATE Provide better names for the following variables and/or functions.",
          },
          TestsxUnit = {
            prompt = "/COPILOT_GENERATE Write a set of detailed unit test functions for the following code with the xUnit framework.",
          },
          AddPEP = {
            prompt = [[
/COPILOT_GENERATE Analyze the selected code and add useful, related Python Enhancement Proposals (PEPs). The PEPs should be directly relevant to the concepts, functions, or constructs used in the code. Ensure the references are accurate and avoid including unrelated PEPs.

Example input:

### Classes in Python
class MyClass:
    def __init__(self, value: int):
        self.value = value

    def increment(self):
        self.value += 1

Output:
:::info
Useful PEPs for this section (not exhaustive):
- [PEP 253 (Subtyping Built-in Types)](https://www.python.org/dev/peps/pep-0253/)
- [PEP 257 (Docstring Conventions)](https://www.python.org/dev/peps/pep-0257/)
- [PEP 526 (Syntax for Variable Annotations)](https://www.python.org/dev/peps/pep-0526/)
- [PEP 3107 (Function Annotations)](https://www.python.org/dev/peps/pep-3107/)
- [PEP 3119 (Introducing Abstract Base Classes)](https://www.python.org/dev/peps/pep-3119/)
:::
                        ]],
          },
        },
        mappings = {
          show_diff = {
            normal = "cd",
          },
          complete = {
            insert = "",
          },
        },
      }
    end,
    config = function(_, opts)
      local chat = require("CopilotChat")

      -- require("CopilotChat.integrations.cmp").setup()
      chat.setup(opts)

      vim.keymap.set("n", "<leader>cy", function()
        local buf = vim.api.nvim_get_current_buf()
        local lines = vim.api.nvim_buf_get_lines(buf, 0, -1, false)

        local start_line = nil
        for i = #lines, 1, -1 do
          if lines[i]:find("Copilot") then
            start_line = i
            break
          end
        end

        if not start_line then
          print("Copilot header not found")
          return
        end

        local code_block = {}
        local in_code_block = false
        for i = start_line, #lines do
          local line = lines[i]
          if line:find("^```") then
            if in_code_block then
              break
            else
              in_code_block = true
            end
          elseif in_code_block then
            table.insert(code_block, line)
          end
        end

        local code_str = table.concat(code_block, "\n")

        if #code_str > 0 then
          vim.fn.setreg("*", code_str)
          vim.fn.setreg("+", code_str)
          print("Code copied to system clipboard.")
        else
          print("No code found.")
        end
      end, { noremap = true, silent = true })

      -- Custom buffer for CopilotChat
      -- vim.api.nvim_create_autocmd("BufEnter", {
      -- 	pattern = "copilot-*",
      -- 	callback = function()
      -- 		vim.opt_local.relativenumber = false
      -- 		vim.opt_local.number = false
      --
      -- 		local ft = vim.bo.filetype
      -- 		if ft == "copilot-chat" then
      -- 			vim.bo.filetype = "markdown"
      -- 		end
      -- 	end,
      -- })
      -- Custom buffer for CopilotChat

      utils.on_event("BufEnter", function()
        vim.opt_local.relativenumber = false
        vim.opt_local.number = false
        vim.opt_local.statuscolumn = " "
        -- 			vim.bo.filetype = "markdown"
        -- require("cmp").setup.buffer({ enabled = false })
      end, {
        target = "copilot-*",
        desc = "Disable relative number and cmp for CopilotChat",
      })
    end,
  },
  {
    "supermaven-inc/supermaven-nvim",
    event = "VeryLazy",
    cond = vim.g.ai == "supermaven",
    opts = {
      keymaps = {
        accept_suggestion = nil, -- handled by nvim-cmp / blink.cmp
        clear_suggestion = "<C-c>",
      },
      disable_inline_completion = true,
      ignore_filetypes = { "bigfile", "snacks_input", "snacks_notif" },
    },
    config = function(_, opts)
      local plugin = require("supermaven-nvim")
      local api = require("supermaven-nvim.api")
      local utils = require("config.utils")

      local function toggle()
        local is_on = api.is_running()

        api.toggle()

        vim.api.nvim_set_hl(0, "T", { fg = is_on and "#ff0000" or "#00ff00" })

        utils.echo(utils.strings.truncateChunks({
          { is_on and "[OFF]" or "[ON]", "T" },
          { " " },
          { "AI suggestions" },
        }))
      end

      utils.command("ToggleAISuggestions", toggle, {})
      key("n", "<localleader>at", toggle, "AI: Toggle inline suggestions")

      -- plugin.setup({
      --   keymaps = {
      --     clear_suggestion = "<C-c>",
      --   },
      --   log_level = "off",
      -- })
      plugin.setup(opts)
    end,
  },
  {
    -- ✨ AI-powered coding, seamlessly in Neovim. Supports Anthropic, Copilot, Gemini, Ollama, OpenAI and xAI LLMs.
    -- SEE: https://github.com/olimorris/codecompanion.nvim
    "olimorris/codecompanion.nvim",
    cond = vim.g.ai == "codecompanion",
    dependencies = {
      "nvim-lua/plenary.nvim",
      "nvim-treesitter/nvim-treesitter",
      "saghen/blink.cmp",
    },

    config = function()
      local plugin = require("codecompanion")

      local toggle_chat_buffer = function() plugin.toggle() end

      local ask_inline = function() plugin.prompt("inline") end

      local ask_lsp_diagnostics = function() plugin.prompt("lsp") end

      local ask_explain_snippet = function() plugin.prompt("explain") end

      local ask_fix_snippet = function() plugin.prompt("fix") end

      key({ "n", "v" }, "<localleader>aa", toggle_chat_buffer, "AI: Toggle chat buffer")
      key({ "n", "v" }, "<localleader>al", ask_lsp_diagnostics, "AI: Explain LSP diagnostics")
      key({ "n", "v" }, "<localleader>ai", ask_inline, "AI: Inline")
      key({ "v" }, "<localleader>ae", ask_explain_snippet, "AI: Explain snippet")
      key({ "v" }, "<localleader>af", ask_fix_snippet, "AI: Fix snippet")

      plugin.setup({
        prompt_library = {
          ["Custom Prompt"] = {
            opts = {
              short_name = "inline",
            },
          },
        },
        strategies = {
          -- chat = {
          --   adapter = "anthropic",
          --   keymaps = {
          --     hide = {
          --       modes = {
          --         n = "q",
          --       },
          --       callback = function(chat) chat.ui:hide() end,
          --       description = "AI: Hide the chat buffer",
          --     },
          --   },
          -- },
          -- inline = {
          --   adapter = "anthropic",
          -- },

          chat = {
            adapter = "copilot",
            keymaps = {
              hide = {
                modes = {
                  n = "q",
                },
                callback = function(chat) chat.ui:hide() end,
                description = "AI: Hide the chat buffer",
              },
            },
          },
          inline = {
            adapter = "copilot",
          },
          agent = {
            adapter = "copilot",
          },
        },
        -- adapters = {
        --   copilot = function()
        --     return require("codecompanion.adapters").extend("anthropic", {
        --       schema = {
        --         model = {
        --           default = "claude-3.5-sonnet",
        --         },
        --       },
        --     })
        --   end,
        --   anthropic = function()
        --     return require("codecompanion.adapters").extend("anthropic", {
        --       env = {
        --         api_key = vim.env.ANTHROPIC_API_KEY,
        --       },
        --     })
        --   end,
        -- },
        display = {
          chat = {
            intro_message = "Press ? for options",
            show_setting = true,
          },
        },
      })
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

  {
    "yetone/avante.nvim",
    cond = vim.g.ai == "avante",
    event = "VeryLazy",
    lazy = false,
    version = "*", -- set this if you want to always pull the latest change
    opts = {
      behaviour = {
        auto_set_keymaps = false,
        support_paste_from_clipboard = true,
        auto_suggestions = false,
      },
      provider = "copilot",
      auto_suggestions_provider = "copilot",
      hints = { enabled = true },
    },
    -- if you want to build from source then do `make BUILD_FROM_SOURCE=true`
    build = "make",
    -- build = "powershell -ExecutionPolicy Bypass -File Build.ps1 -BuildFromSource false" -- for windows
    dependencies = {
      "stevearc/dressing.nvim",
      "nvim-lua/plenary.nvim",
      "MunifTanjim/nui.nvim",
      --- The below dependencies are optional,
      "hrsh7th/nvim-cmp", -- autocompletion for avante commands and mentions
      "saghen/blink.cmp",
      "nvim-tree/nvim-web-devicons", -- or echasnovski/mini.icons
      "zbirenbaum/copilot.lua", -- for providers='copilot'
      {
        -- support for image pasting
        "HakonHarnes/img-clip.nvim",
        event = "VeryLazy",
        opts = {
          -- recommended settings
          default = {
            embed_image_as_base64 = false,
            prompt_for_file_name = false,
            drag_and_drop = {
              insert_mode = true,
            },
            -- required for Windows users
            use_absolute_path = true,
          },
        },
      },
      {
        -- Make sure to set this up properly if you have lazy=true
        "MeanderingProgrammer/render-markdown.nvim",
        opts = {
          file_types = { "markdown", "Avante" },
        },
        ft = { "markdown", "Avante" },
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

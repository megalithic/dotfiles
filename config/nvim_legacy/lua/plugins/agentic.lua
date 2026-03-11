return {
  "carlos-algms/agentic.nvim",
  enabled = false,
  dependencies = {
    { "hakonharnes/img-clip.nvim", opts = {} },
  },
  opts = {
    -- Available by default: "claude-acp" | "gemini-acp" | "codex-acp" | "opencode-acp" | "cursor-acp"
    provider = "claude-acp", -- setting the name here is all you need to get started
    acp_providers = {
      ["claude-acp"] = {
        -- Automatically switch to this mode when a new session starts
        default_mode = "bypassPermissions",
      },
    },
    -- Keybindings for the prompt buffer only
    prompt = {
      submit = {
        "<CR>", -- Normal mode, just Enter
        {
          "<C-CR>",
          mode = { "n", "v", "i" },
        },
      },

      paste_image = {
        {
          "<localleader>p",
          mode = { "n" }, -- I like normal and insert modes for this, but feel free to customize
        },
      },
    },
  },

  -- these are just suggested keymaps; customize as desired
  keys = {
    {
      "<C-,>",
      function() require("agentic").toggle() end,
      mode = { "n", "v", "i" },
      desc = "Toggle Agentic Chat",
    },
    {
      "<C-'>",
      function() require("agentic").add_selection_or_file_to_context() end,
      mode = { "n", "v" },
      desc = "Add file or selection to Agentic to Context",
    },
    -- {
    --   "<C-,>",
    --   function() require("agentic").new_session() end,
    --   mode = { "n", "v", "i" },
    --   desc = "New Agentic Session",
    -- },
  },
}

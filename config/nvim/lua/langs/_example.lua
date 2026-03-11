-- lua/langs/_example.lua
-- Documented example of a lang config file
-- Files starting with _ are not loaded automatically
--
-- This file shows all available options and their expected formats.
-- Copy this to create a new lang config (e.g., lua/langs/python.lua)

---@class LangConfig
---@field extends? string Inherit from another lang config
---@field filetypes? string[] Filetypes this lang applies to (metadata)
---@field servers? table<string, ServerConfig|false> LSP server configurations
---@field formatters? table<string, FormatterConfig> Formatter configs per filetype
---@field ftplugin? table<string, FtpluginConfig> ftplugin settings per filetype
---@field repl? ReplConfig REPL configuration (auto-creates keymaps)
---@field plugins? LazySpec[] Additional lazy.nvim plugin specs

---@class ReplConfig
---@field cmd string|string[] Command to start the REPL
---@field position? "bottom"|"right"|"float" Terminal position (default: "right")
---@field reload_cmd? string Command to reload/recompile in REPL

---@class ServerConfig
---@field cmd? string[] Command to start the server
---@field filetypes? string[] Filetypes to attach to
---@field root_markers? string[] Files/dirs to find project root (converted to root_dir)
---@field root_dir? function Root directory detection (alternative to root_markers)
---@field settings? table Server-specific settings
---@field keys? KeymapDef[] Per-server keymaps (applied on LspAttach)

---@class FormatterConfig
---@field [1]? string First formatter to try
---@field [2]? string Second formatter to try
---@field lsp_format? "prefer"|"fallback"|"never" Use LSP formatting
---@field stop_after_first? boolean Stop after first successful formatter

---@class FtpluginConfig
---@field opt? table<string, any> Buffer/window options
---@field keys? KeymapDef[] Buffer-local keymaps
---@field abbr? table<string, string> Insert-mode abbreviations
---@field bufvar? table<string, any> Buffer variables
---@field callback? fun(bufnr: integer) Custom setup function

---@class KeymapDef
---@field [1] string Mode(s): "n", "i", "v", "x", etc. (for ftplugin) or lhs (for servers)
---@field [2] string|function Lhs (for ftplugin) or rhs (for servers)
---@field [3]? string|function Rhs (for ftplugin only)
---@field mode? string Mode (for server keys)
---@field desc? string Description
---@field silent? boolean Silent mapping
---@field nowait? boolean No wait
---@field remap? boolean Allow remapping

---@type LangConfig
return {
  -- ===========================================================================
  -- extends (optional)
  -- ===========================================================================
  -- Inherit all config from another lang file.
  -- Child values override parent values according to merge semantics:
  --   filetypes: replace
  --   servers: deep merge (use `server = false` to disable)
  --   formatters: merge
  --   ftplugin: merge
  --   plugins: extend (concatenate)
  --
  -- Example: eelixir extending elixir
  -- extends = "elixir",

  -- ===========================================================================
  -- filetypes (optional)
  -- ===========================================================================
  -- Declares which filetypes this config applies to.
  -- Used for documentation and can be used by LSP servers.
  filetypes = { "example", "example2" },

  -- ===========================================================================
  -- servers (optional)
  -- ===========================================================================
  -- LSP server configurations. Uses native vim.lsp.config API (nvim 0.11+).
  -- Keys are server names, values are server configs.
  servers = {
    -- Basic server with settings
    example_ls = {
      -- Command to start the server (optional, has defaults for known servers)
      cmd = { "example-language-server", "--stdio" },

      -- Root markers: files/dirs that indicate project root
      -- Gets converted to a root_dir function automatically
      root_markers = { "example.config.json", "package.json", ".git" },

      -- Filetypes to attach to (optional, uses lang filetypes by default)
      filetypes = { "example" },

      -- Server-specific settings
      settings = {
        example = {
          formatting = { enabled = true },
          diagnostics = { enabled = true },
        },
      },

      -- Per-server keymaps (applied when this server attaches)
      -- Format: { lhs, rhs, mode = "n", desc = "..." }
      keys = {
        {
          "<leader>le",
          function() vim.lsp.buf.execute_command({ command = "example.doThing" }) end,
          mode = "n",
          desc = "Example: do thing",
        },
      },
    },

    -- Disable an inherited server
    -- some_server = false,
  },

  -- ===========================================================================
  -- formatters (optional)
  -- ===========================================================================
  -- Formatter configurations for conform.nvim.
  -- Keys are filetypes, values are formatter configs.
  formatters = {
    -- List of formatters (tries in order, stops after first success)
    example = { "example_fmt", "prettier", stop_after_first = true },

    -- Use LSP formatting
    example2 = { lsp_format = "prefer" },
  },

  -- ===========================================================================
  -- ftplugin (optional)
  -- ===========================================================================
  -- Settings applied when a buffer of this filetype is opened.
  -- Replaces traditional ftplugin/*.lua files.
  ftplugin = {
    example = {
      -- Buffer/window options
      opt = {
        shiftwidth = 2,
        expandtab = true,
        commentstring = "// %s",
      },

      -- Buffer-local keymaps
      -- Format: { mode, lhs, rhs, desc = "..." }
      keys = {
        { "n", "<localleader>r", ":ExampleRun<CR>", desc = "Run example" },
        { "n", "<localleader>t", ":ExampleTest<CR>", desc = "Test example" },
        { "v", "<localleader>e", ":ExampleEval<CR>", desc = "Eval selection" },
      },

      -- Insert-mode abbreviations
      abbr = {
        funciton = "function",  -- fix common typo
        teh = "the",
      },

      -- Buffer variables
      bufvar = {
        example_enabled = true,
      },

      -- Custom callback (runs after other settings applied)
      callback = function(bufnr)
        -- Custom setup for this filetype
        -- e.g., set up buffer-local commands
        vim.api.nvim_buf_create_user_command(bufnr, "ExampleCmd", function()
          print("Example command!")
        end, {})
      end,
    },
  },

  -- ===========================================================================
  -- repl (optional)
  -- ===========================================================================
  -- REPL configuration. When defined, automatically sets up keymaps:
  --   <localleader>rs - Start REPL
  --   <localleader>rr - Send line (normal) / selection (visual) to REPL
  --   <localleader>rc - Reload/recompile (if reload_cmd defined)
  repl = {
    cmd = "example-repl",           -- Command to start REPL
    position = "right",             -- Terminal position (default: "right")
    reload_cmd = "reload()",        -- Optional: command to reload in REPL
  },

  -- ===========================================================================
  -- plugins (optional)
  -- ===========================================================================
  -- Additional lazy.nvim plugin specs for this language.
  -- These are collected and returned by require("langs").lazy_specs()
  plugins = {
    {
      "someone/example.nvim",
      ft = "example",  -- lazy load on filetype
      opts = {
        -- plugin options
      },
    },
    {
      "someone/example-tools.nvim",
      cmd = { "ExampleRun", "ExampleTest" },  -- lazy load on command
    },
  },
}

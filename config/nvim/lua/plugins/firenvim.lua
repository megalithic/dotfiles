-- lua/plugins/firenvim.lua
-- Firenvim: embed neovim in browser textareas
-- Ref: https://github.com/glacambre/firenvim

-- Only define the plugin spec if we're in firenvim OR in terminal (for build/install)
-- The `cond` field handles conditional loading

local is_firenvim = vim.g.started_by_firenvim == true

return {
  {
    "glacambre/firenvim",
    lazy = false,
    cond = is_firenvim,
    build = function()
      require("lazy").load({ plugins = "firenvim", wait = true })
      vim.fn["firenvim#install"](0)
    end,
    init = function()
      -- firenvim_config must be set before the plugin loads
      vim.g.firenvim_config = {
        globalSettings = {
          alt = "all",
          cmdlineTimeout = 3000,
          -- Keys to pass through to browser (firenvim won't capture these)
          ignoreKeys = {
            all = {
              "<C-t>", -- new tab
              "<C-z>", -- hide frame / background
              "<C-c>", -- focus page
            },
            insert = {
              "<C-r>", -- browser refresh
            },
          },
        },
        localSettings = {
          -- Default: take over textareas on all sites
          [".*"] = {
            cmdline = "neovim",
            content = "text",
            priority = 0,
            selector = 'textarea:not([readonly], [aria-readonly]), div[role="textbox"]',
            takeover = "always",
          },
          -- Never take over on these sites (too complex / not useful)
          ["https?://docs\\.google\\.com/.*"] = { takeover = "never", priority = 1 },
          ["https?://mail\\.google\\.com/.*"] = { takeover = "never", priority = 1 },
          ["https?://.*\\.slack\\.com/.*"] = { takeover = "never", priority = 1 },
          ["https?://discord\\.com/.*"] = { takeover = "never", priority = 1 },
          ["https?://.*\\.notion\\.so/.*"] = { takeover = "never", priority = 1 },
          ["https?://.*\\.figma\\.com/.*"] = { takeover = "never", priority = 1 },
          -- GitHub: use markdown filetype
          ["https?://github\\.com/.*"] = {
            priority = 1,
            takeover = "always",
          },
        },
      }
    end,
    config = function()
      if not is_firenvim then return end

      local group = vim.api.nvim_create_augroup("mega.firenvim", { clear = true })

      -- ── UI setup on firenvim connect ──────────────────────────────
      vim.api.nvim_create_autocmd("UIEnter", {
        group = group,
        callback = function()
          local client = vim.api.nvim_get_chan_info(vim.v.event.chan).client
          if not client or client.name ~= "Firenvim" then return end

          -- Font: JetBrainsMono Nerd Font Mono at size 22
          vim.o.guifont = "JetBrainsMono Nerd Font Mono:h22"

          -- Minimal UI
          vim.o.laststatus = 0
          vim.o.showtabline = 0
          vim.o.number = true
          vim.o.relativenumber = true
          vim.o.signcolumn = "no"
          vim.o.cmdheight = 1

          -- Minimal statuscolumn: just line numbers
          vim.o.statuscolumn = "%l "

          -- Disable autoformat in firenvim
          vim.g.disable_autoformat = true

          -- Initial resize
          vim.defer_fn(function()
            local lines = vim.api.nvim_buf_line_count(0)
            vim.o.lines = math.max(lines + 5, 10)
          end, 100)
        end,
      })

      -- ── Filetype detection from buffer name ──────────────────────
      vim.api.nvim_create_autocmd("BufEnter", {
        group = group,
        pattern = "github.com_*.txt",
        callback = function() vim.bo.filetype = "markdown" end,
      })

      -- ── Auto-sync buffer to page on InsertLeave ──────────────────
      vim.api.nvim_create_autocmd("InsertLeave", {
        group = group,
        callback = function()
          if vim.bo.buftype ~= "" then return end
          vim.cmd("silent! write")
        end,
      })

      -- ── Auto-resize to fit content ───────────────────────────────
      vim.api.nvim_create_autocmd({ "TextChanged", "TextChangedI" }, {
        group = group,
        callback = function()
          local lines = vim.api.nvim_buf_line_count(0)
          local target = math.max(lines + 5, 10)
          if vim.o.lines ~= target then vim.o.lines = target end
        end,
      })

      -- ── Insert mode if buffer is empty ───────────────────────────
      vim.api.nvim_create_autocmd("BufEnter", {
        group = group,
        callback = function()
          vim.defer_fn(function()
            local lines = vim.api.nvim_buf_get_lines(0, 0, -1, false)
            if #lines <= 1 and (lines[1] or "") == "" then vim.cmd("startinsert") end
          end, 50)
        end,
      })

      -- ── Keymaps ──────────────────────────────────────────────────
      -- Ctrl-z: hide firenvim frame, focus the html element
      vim.keymap.set(
        { "n", "i", "v" },
        "<C-z>",
        function() vim.fn["firenvim#hide_frame"]() end,
        { desc = "Hide firenvim, focus input" }
      )

      -- Ctrl-c: focus the page (not the input)
      vim.keymap.set(
        { "n", "i", "v" },
        "<C-c>",
        function() vim.fn["firenvim#focus_page"]() end,
        { desc = "Focus page" }
      )
    end,
  },

  -- ── Grammar/spelling: harper-ls ────────────────────────────────────
  -- Only enable harper-ls in firenvim for prose-heavy contexts
  {
    "neovim/nvim-lspconfig",
    optional = true,
    opts = function(_, opts)
      if not is_firenvim then return end
      opts.servers = opts.servers or {}
      opts.servers.harper_ls = {
        filetypes = { "markdown", "text", "gitcommit" },
        settings = {
          ["harper-ls"] = {
            linters = {
              spell_check = true,
              sentence_capitalization = false,
              long_sentences = true,
              repeated_words = true,
              unclosed_quotes = true,
              wrong_quotes = false,
              linking_verbs = false,
              avoid_curses = false,
            },
          },
        },
      }
    end,
  },

  -- ── GitHub completion via blink-cmp-git ────────────────────────────
  -- Issues (#), PRs (#), users (@), commits (:) when on GitHub
  {
    "Kaiser-Yang/blink-cmp-git",
    cond = is_firenvim,
    dependencies = { "saghen/blink.cmp" },
    opts = {
      before_reload_cache = function() end, -- silence cache-reload notification
      commit = { enable = false },
      git_centers = {
        github = {
          pull_request = { enable = true },
          mention = { enable = true },
          issue = { get_documentation = function() return "" end }, -- disable doc window
        },
      },
    },
  },

  -- Wire blink-cmp-git into blink.cmp sources
  {
    "saghen/blink.cmp",
    optional = true,
    opts = function(_, opts)
      if not is_firenvim then return end
      opts.sources = opts.sources or {}
      opts.sources.default = opts.sources.default or {}

      -- Add git source
      if not vim.list_contains(opts.sources.default, "git") then table.insert(opts.sources.default, "git") end

      opts.sources.providers = opts.sources.providers or {}
      opts.sources.providers.git = {
        module = "blink-cmp-git",
        name = "Git",
        enabled = function()
          -- Only on github-related buffers
          local bufname = vim.api.nvim_buf_get_name(0)
          return bufname:match("github%.com") ~= nil or vim.bo.filetype == "gitcommit" or vim.bo.filetype == "markdown"
        end,
        opts = {},
      }
    end,
  },
}

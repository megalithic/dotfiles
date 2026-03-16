-- lua/plugins/blink.lua
-- Completion engine with fuzzy matching and colorful menu

return {
  {
    "saghen/blink.cmp",
    version = "*",
    event = { "InsertEnter", "CmdlineEnter" },
    dependencies = {
      { "xzbdmw/colorful-menu.nvim", opts = {} },
      { "Kaiser-Yang/blink-cmp-git", config = false }, -- configured as source below
    },
    opts = {
      keymap = {
        preset = "none",
        ["<C-e>"] = { "hide", "fallback" },
        ["<C-c>"] = { "cancel" },
        ["<C-y>"] = { "select_and_accept", "fallback" },
        ["<CR>"] = { "accept", "fallback" },
        ["<Tab>"] = { "snippet_forward", "select_next", "fallback" },
        ["<S-Tab>"] = { "snippet_backward", "select_prev", "fallback" },
        ["<C-n>"] = { "select_next", "fallback" },
        ["<C-p>"] = { "select_prev", "fallback" },
        ["<C-u>"] = { "scroll_documentation_up", "fallback" },
        ["<C-d>"] = { "scroll_documentation_down", "fallback" },
      },

      appearance = {
        use_nvim_cmp_as_default = false, -- Native BlinkCmp* highlights in megaforest.lua
        nerd_font_variant = "mono",
        kind_icons = {
          Text = "󰉿",
          Snippet = "󰞘",
          File = "",
          Module = "",
        },
      },

      signature = { enabled = true },
      fuzzy = { implementation = "prefer_rust_with_warning" },

      sources = {
        default = { "git", "lsp", "path", "snippets", "buffer" },
        providers = {
          git = {
            module = "blink-cmp-git",
            name = "[git]",
            enabled = function()
              if vim.bo.filetype == "gitcommit" then return true end
              return vim.g.started_by_firenvim and vim.api.nvim_buf_get_name(0):match("github%.com") ~= nil
            end,
            opts = (function()
              -- Fix ssh:// URL parsing (upstream doesn't handle this format)
              -- e.g. ssh://git@github.com/owner/repo -> owner/repo
              local function get_owner_repo()
                local utils = require("blink-cmp-git.utils")
                local url = utils.get_repo_remote_url()
                url = url:gsub("%.git$", ""):gsub("^ssh://", ""):gsub("^git@", ""):gsub("^https?://", ""):gsub("/$", "")
                local owner, repo = url:match("[/:]([^/]+)/([^/]+)$")
                return (owner and repo) and (owner .. "/" .. repo) or utils.get_repo_owner_and_repo()
              end

              local function make_args(feature, endpoint)
                return function(command, token)
                  local args = require("blink-cmp-git.default.github")[feature].get_command_args(command, token)
                  args[#args] = (command == "curl" and "https://api.github.com/" or "") .. "repos/" .. get_owner_repo() .. "/" .. endpoint
                  return args
                end
              end

              return {
                commit = { enable = false },
                git_centers = {
                  github = {
                    issue = { enable = true, get_command_args = make_args("issue", "issues") },
                    pull_request = { enable = true, get_command_args = make_args("pull_request", "pulls") },
                    mention = { enable = true, get_command_args = make_args("mention", "contributors") },
                  },
                },
              }
            end)(),
          },
          path = { name = "[path]" },
          snippets = { name = "[snip]", score_offset = 3 },
          buffer = {
            name = "[buf]",
            max_items = 4,
            min_keyword_length = 4,
            score_offset = -7,
          },
          lsp = {
            name = "[lsp]",
            fallbacks = {},
          },
        },
      },

      completion = {
        keyword = { range = "full" },
        ghost_text = { enabled = true },
        list = {
          cycle = { from_top = false },
          selection = { preselect = false, auto_insert = true },
        },
        accept = {
          auto_brackets = { enabled = true },
        },
        documentation = {
          auto_show = true,
          auto_show_delay_ms = 250,
          window = { max_width = 50, max_height = 30 },
        },
        menu = {
          max_height = 12,
          scrolloff = 0, -- Don't add extra padding for single items
          draw = {
            align_to = "none",
            treesitter = { "lsp" },
            columns = {
              { "label", gap = 1 },
              { "kind_icon", "kind", gap = 1 },
              { "source_name" },
            },
            components = {
              label = {
                width = { max = 50, fill = true },
                -- Use colorful-menu for syntax-highlighted labels
                text = function(ctx)
                  local highlights_info = require("colorful-menu").blink_highlights(ctx)
                  if highlights_info ~= nil then return highlights_info.label end
                  return ctx.label
                end,
                highlight = function(ctx)
                  local highlights = {}
                  local highlights_info = require("colorful-menu").blink_highlights(ctx)
                  if highlights_info ~= nil then highlights = highlights_info.highlights end
                  -- Add fuzzy match highlights
                  for _, idx in ipairs(ctx.label_matched_indices) do
                    table.insert(highlights, { idx, idx + 1, group = "BlinkCmpLabelMatch" })
                  end
                  return highlights
                end,
              },
              kind_icon = {
                text = function(ctx)
                  local icons = { snippets = "󰩫", buffer = "﬘", path = "", cmdline = "" }
                  return icons[ctx.item.source_id] or ctx.kind_icon
                end,
              },
              source_name = {
                width = { max = 30, fill = true },
                text = function(ctx)
                  if ctx.item.source_id == "lsp" then
                    local client = vim.lsp.get_client_by_id(ctx.item.client_id)
                    if client then return string.format("[%s]", client.name) end
                  end
                  return ctx.source_name
                end,
                highlight = "BlinkCmpSource",
              },
            },
          },
        },
      },
    },
    opts_extend = { "sources.default" },
  },
  {
    -- "saghen/blink.pairs",
    "madmaxieee/blink.pairs", -- for my abbr expand patch
    event = { "InsertEnter", "CmdlineEnter" },
    enabled = false,
    build = "cargo build --release",
    --- @module 'blink.pairs'
    --- @type blink.pairs.Config
    opts = {
      mappings = {
        enabled = true,
        cmdline = true,
        pairs = {
          ["!"] = {
            {
              "<!--",
              "-->",
              languages = { "html", "markdown", "markdown_inline" },
            },
          },
          ["("] = ")",
          ["["] = "]",
          ["{"] = "}",
          ["'"] = {
            {
              "''",
              "''",
              when = function(ctx) return ctx:text_before_cursor(1) == "'" end,
              languages = { "nix" },
            },
            {
              "'''",
              when = function(ctx) return ctx:text_before_cursor(2) == "''" end,
              languages = {
                "python",
                "toml",
              },
            },
            {
              "'",
              enter = false,
              space = false,
              when = function(ctx)
                return ctx.ft ~= "plaintext"
                  and not ctx.char_under_cursor:match("%w")
                  and ctx.ts:blacklist("singlequote").matches
              end,
            },
          },
          ['"'] = {
            {
              'r#"',
              '"#',
              languages = { "rust" },
              priority = 100,
            },
            {
              '"""',
              when = function(ctx) return ctx:text_before_cursor(2) == '""' end,
              languages = {
                "python",
                "elixir",
                "julia",
                "kotlin",
                "scala",
                "toml",
              },
            },
            { '"', enter = false, space = false },
          },
          ["`"] = {
            {
              "```",
              when = function(ctx) return ctx:text_before_cursor(2) == "``" end,
              languages = {
                "markdown",
                "markdown_inline",
                "typst",
                "vimwiki",
                "rmarkdown",
                "rmd",
                "quarto",
              },
            },
            {
              "`",
              "'",
              languages = { "bibtex", "latex", "plaintex" },
            },
            { "`", enter = false, space = false },
          },
          ["_"] = {
            {
              "_",
              when = function(ctx)
                return not ctx.char_under_cursor:match("%w") and ctx.ts:blacklist("underscore").matches
              end,
              languages = { "typst" },
            },
          },
          ["*"] = {
            {
              "*",
              when = function(ctx) return ctx.ts:blacklist("asterisk").matches end,
              languages = { "typst" },
            },
          },
          ["<"] = {
            {
              "<",
              ">",
              when = function(ctx) return ctx.ts:whitelist("angle").matches end,
              languages = { "rust" },
            },
          },
          ["$"] = {
            {
              "$",
              languages = {
                "markdown",
                "markdown_inline",
                "typst",
                "latex",
                "plaintex",
              },
            },
          },
        },
      },
      highlights = { enabled = false },
    },
  },
}

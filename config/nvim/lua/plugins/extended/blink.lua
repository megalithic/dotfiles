local SETTINGS = require("mega.settings")
local icons = SETTINGS.icons
local U = require("mega.utils")

local in_jsx = U.in_jsx_tags
local keep_text_entries = { "emmet_language_server", "marksman" }
local text = vim.lsp.protocol.CompletionItemKind.Text

local function esc(cmd) return vim.api.nvim_replace_termcodes(cmd, true, false, true) end

local function feedkeys(key, mode) vim.fn.feedkeys(esc(key), mode or "") end

local function has_words_before()
  local line, col = unpack(vim.api.nvim_win_get_cursor(0))
  return col ~= 0 and vim.api.nvim_buf_get_lines(0, line - 1, line, true)[1]:sub(col, col):match("%s") == nil
end

local function expand_snippet()
  local filetype_map = {
    typescriptreact = "javascript",
    typescript = "javascript",
    javascriptreact = "javascript",
  }
  local line_to_cursor = vim.fn.getline("."):sub(1, vim.fn.col(".") - 1)
  local keyword = vim.fn.matchstr(line_to_cursor, [[\k\+$]])
  local filetype = filetype_map[vim.bo.filetype] or vim.bo.filetype
  local path = vim.fn.stdpath("config") .. "/snippets/" .. filetype .. ".json"
  local fs_stat = vim.uv.fs_stat(path)
  if not fs_stat or fs_stat.type ~= "file" then return end
  ---@type { prefix: string[], body: string[] }[]
  local data = vim.json.decode(table.concat(vim.fn.readfile(path), "\n"))

  for _, snippet in pairs(data) do
    if snippet.prefix[1] == keyword then
      vim.fn.feedkeys(esc("<C-w>"), "n")
      vim.schedule(function() vim.snippet.expand(table.concat(snippet.body, "\n")) end)
      return true
    end
  end
end

-- -- DOCS https://github.com/saghen/blink.cmp#configuration
-- --------------------------------------------------------------------------------
-- ---@diagnostic disable: missing-fields -- pending https://github.com/Saghen/blink.cmp/issues/427
-- --------------------------------------------------------------------------------
return {
  {
    "saghen/blink.cmp",
    dependencies = {
      "ribru17/blink-cmp-spell",
      "rafamadriz/friendly-snippets",
      "MeanderingProgrammer/render-markdown.nvim",
      { "saghen/blink.compat", version = "*", opts = { impersonate_nvim_cmp = true } },
      { "chrisgrieser/cmp-nerdfont", lazy = true },
      { "MattiasMTS/cmp-dbee", ft = { "sql", "psql", "mysql", "plsql", "dbee" }, opts = {}, lazy = true },
      { "hrsh7th/cmp-emoji", lazy = true },
      { "xzbdmw/colorful-menu.nvim", lazy = true, opts = {} },
      "mikavilpas/blink-ripgrep.nvim",
    },
    event = { "InsertEnter", "CmdlineEnter" },
    version = "*",
    cond = vim.g.completer == "blink",
    config = function()
      local blink = require("blink.cmp")
      local sort_text = require("blink.cmp.fuzzy.sort").sort_text
      blink.setup({
        -- keymap = {
        --   ["<C-e>"] = { "hide", "fallback" },
        --   ["<CR>"] = { "accept", "fallback" },

        --   ["<Tab>"] = {
        --     function(cmp) return cmp.select_next() end,
        --     "snippet_forward",
        --     "fallback",
        --   },
        --   ["<S-Tab>"] = {
        --     function(cmp) return cmp.select_prev() end,
        --     "snippet_backward",
        --     "fallback",
        --   },

        --   ["<Up>"] = { "select_prev", "fallback" },
        --   ["<Down>"] = { "select_next", "fallback" },
        --   ["<C-p>"] = { "select_prev", "fallback" },
        --   ["<C-n>"] = { "select_next", "fallback" },
        --   ["<C-up>"] = { "scroll_documentation_up", "fallback" },
        --   ["<C-down>"] = { "scroll_documentation_down", "fallback" },
        -- },
        keymap = {
          preset = "none", -- default?
          ["<C-e>"] = { "hide", "fallback" },
          ["<C-c>"] = { "cancel" },
          ["<C-y>"] = { "select_and_accept", "fallback" },
          -- ["<CR>"] = { "accept", "fallback" },
          ["<CR>"] = { "accept", "fallback" },
          ["<S-CR>"] = { "hide" },
          ["<C-n>"] = { "select_next", "fallback" },
          ["<C-p>"] = { "select_prev", "fallback" },
          ["<Down>"] = { "select_next", "fallback" },
          ["<Up>"] = { "select_prev", "fallback" },
          ["<C-u>"] = { "scroll_documentation_up", "fallback" },
          ["<C-d>"] = { "scroll_documentation_down", "fallback" },
          ["<Tab>"] = { "snippet_forward", "select_next", "fallback" },
          ["<S-Tab>"] = { "snippet_backward", "select_prev", "fallback" },

          -- ["<Tab>"] = {
          --   function()
          --     if blink.is_visible() then
          --       blink.select_next({ auto_insert = true })
          --     elseif vim.fn.mode() == "c" then
          --       vim.api.nvim_feedkeys(vim.api.nvim_replace_termcodes("<Down>", true, true, true), "n", true)
          --     end
          --   end,
          -- },
          -- ["<S-Tab>"] = {
          --   function()
          --     if blink.is_visible() then
          --       blink.select_prev({ auto_insert = true })
          --     elseif vim.fn.mode() == "c" then
          --       vim.api.nvim_feedkeys(vim.api.nvim_replace_termcodes("<Up>", true, true, true), "n", true)
          --     end
          --   end,
          -- },
        },
        signature = { enabled = true },

        appearance = {
          use_nvim_cmp_as_default = true,
          nerd_font_variant = "mono",
          kind_icons = {
            -- different icons of the corresponding source
            Text = "󰦨", -- `buffer`
            Snippet = "󰞘", -- `snippets`
            File = "", -- `path`
            Folder = "󰉋",
            Method = "󰊕",
            Function = "󰡱",
            Constructor = "",
            Field = "󰇽",
            Variable = "󰀫",
            Class = "󰜁",
            Interface = "",
            Module = "",
            Property = "󰜢",
            Unit = "",
            Value = "󰎠",
            Enum = "",
            Keyword = "󰌋",
            Color = "󰏘",
            Reference = "",
            EnumMember = "",
            Constant = "󰏿",
            Struct = "󰙅",
            Event = "",
            Operator = "󰆕",
            TypeParameter = "󰅲",
          },
        },
        cmdline = {
          completion = {
            menu = {
              auto_show = function()
                local ctype = vim.fn.getcmdtype()
                return ctype == ":"
                  or ctype == "/"
                  or ctype == "?"
                  -- enable for inputs as well, with:
                  or ctype == "@"
              end,
            },
          },
          sources = function()
            local type = vim.fn.getcmdtype()
            -- Search forward and backward
            if type == "/" or type == "?" then return { "buffer" } end
            -- Commands
            if type == ":" then return { "cmdline" } end
            return {}
          end,
        },
        fuzzy = {
          implementation = "prefer_rust_with_warning",
          sorts = {
            function(a, b)
              if (a.client_name == nil or b.client_name == nil) or (a.client_name == b.client_name) then return end
              return b.client_name == "emmet_ls"
            end,
            -- default sorts
            "score",
            "sort_text",
          },
        },
        sources = {
          default = { "lsp", "path", "snippets", "spell", "buffer" },
          per_filetype = {
            sql = { "lsp", "dadbod", "dbee", "buffer" }, -- Add any other source to include here
          },
          providers = {
            path = { name = "[path]", opts = { get_cwd = vim.uv.cwd } },
            spell = {
              name = "[spl]",
              module = "blink-cmp-spell",
              opts = {
                -- Only enable source in `@spell` captures, and disable it in
                -- `@nospell` captures
                enable_in_context = function()
                  local curpos = vim.api.nvim_win_get_cursor(0)
                  local captures = vim.treesitter.get_captures_at_pos(0, curpos[1] - 1, curpos[2] - 1)
                  local in_spell_capture = false
                  for _, cap in ipairs(captures) do
                    if cap.capture == "spell" then
                      in_spell_capture = true
                    elseif cap.capture == "nospell" then
                      return false
                    end
                  end
                  return in_spell_capture
                end,
              },
            },
            dadbod = { name = "Dadbod", module = "vim_dadbod_completion.blink" },
            dbee = { name = "cmp-dbee", module = "blink.compat.source" },

            ripgrep = {
              name = "[rg]",
              module = "blink-ripgrep",
              score_offset = -10,
              opts = {
                prefix_min_len = 4,
                project_root_marker = { "package.json", ".git", "mix.exs" },
                future_features = {
                  backend = {
                    use = "gitgrep-or-ripgrep",
                  },
                },
              },
            },
            snippets = {
              name = "[snip]",
              min_keyword_length = 1,
              score_offset = -1,
              opts = {
                clipboard_register = "+", -- register to use for `$CLIPBOARD`
                show_autosnippets = false,
              },
            },
            buffer = {
              name = "[buf]",
              max_items = 4,
              min_keyword_length = 4,
              -- with `-7`, typing `then` in lua prioritize the `then .. end`
              -- snippet, effectively acting as `nvim-endwise`
              score_offset = -7,
              opts = {
                -- show completions from all buffers used within the last x minutes
                get_bufnrs = function()
                  local mins = 15
                  local allOpenBuffers = vim.fn.getbufinfo({ buflisted = 1, bufloaded = 1 })
                  local recentBufs = vim
                    .iter(allOpenBuffers)
                    :filter(function(buf)
                      local recentlyUsed = os.time() - buf.lastused < (60 * mins)
                      local nonSpecial = vim.bo[buf.bufnr].buftype == ""
                      return recentlyUsed and nonSpecial
                    end)
                    :map(function(buf) return buf.bufnr end)
                    :totable()
                  return recentBufs
                end,
              },
            },
            lsp = {
              name = "[lsp]",
              async = true,
              fallbacks = {}, -- do not use `buffer` as fallback
              enabled = function()
                if vim.bo.ft ~= "lua" then return true end

                -- prevent useless suggestions when typing `--` in lua, but
                -- keep the useful `---@param;@return` suggestion
                local col = vim.api.nvim_win_get_cursor(0)[2]
                local charsBefore = vim.api.nvim_get_current_line():sub(col - 2, col)
                local luadocButNotComment = not charsBefore:find("^%-%-?$") and not charsBefore:find("%s%-%-?")
                return luadocButNotComment
              end,
              transform_items = function(ctx, items)
                -- Remove the "Text" source from lsp autocomplete
                local ft = vim.bo[ctx.bufnr].filetype
                return vim.tbl_filter(function(item)
                  local client = vim.lsp.get_client_by_id(item.client_id)
                  local client_name = client and client.name or ""
                  if client_name == "emmet_language_server" and (ft == "javascriptreact" or ft == "typescriptreact") then return in_jsx(true) end
                  return item.kind ~= text or vim.tbl_contains(keep_text_entries, client_name)
                end, items)
              end,
            },
          },
        },

        snippets = {
          preset = "default",
        },

        completion = {
          -- ghost_text = {
          --   enabled = true,
          -- },
          list = {
            cycle = { from_top = false }, -- cycle at bottom, but not at the top
            selection = {
              preselect = false,
              auto_insert = true,
            },
          },
          accept = {
            auto_brackets = {
              -- Whether to auto-insert brackets for functions
              enabled = true,
              -- Default brackets to use for unknown languages
              default_brackets = { "(", ")" },
              -- Overrides the default blocked filetypes
              override_brackets_for_filetypes = { "rust", "elixir", "heex", "lua" },
              -- Synchronously use the kind of the item to determine if brackets should be added
              kind_resolution = {
                enabled = true,
                blocked_filetypes = { "typescriptreact", "javascriptreact", "vue" },
              },
              -- Asynchronously use semantic token to determine if brackets should be added
              semantic_token_resolution = {
                enabled = true,
                blocked_filetypes = {},
                -- How long to wait for semantic tokens to return before assuming no brackets should be added
                timeout_ms = 400,
              },
            },
          },
          documentation = {
            auto_show = true,
            auto_show_delay_ms = 250,
            window = {
              border = SETTINGS.borders.blink_empty,
              max_width = 50,
              max_height = 15,
            },
          },
          menu = {
            border = SETTINGS.borders.blink_empty,
            draw = {
              align_to = "none", -- keep in place
              treesitter = { "lsp" },
              columns = {
                { "label", gap = 1 },
                -- { "label", "label_description", gap = 1 },
                { "kind_icon", "kind", gap = 1 },
                { "source_name" },
              },
              components = {
                label = {
                  width = { max = 30, fill = true },
                  -- defaults:
                  -- text = function(ctx) return require("colorful-menu").blink_components_text(ctx) end,
                  -- highlight = function(ctx) return require("colorful-menu").blink_components_highlight(ctx) end,
                  --
                  -- customs:
                  text = function(ctx)
                    local highlights_info = require("colorful-menu").blink_highlights(ctx)
                    if highlights_info ~= nil then
                      -- Or you want to add more item to label
                      return highlights_info.label
                    else
                      return ctx.label
                    end
                  end,
                  highlight = function(ctx)
                    local highlights = {}
                    local highlights_info = require("colorful-menu").blink_highlights(ctx)
                    if highlights_info ~= nil then highlights = highlights_info.highlights end
                    for _, idx in ipairs(ctx.label_matched_indices) do
                      table.insert(highlights, { idx, idx + 1, group = "BlinkCmpLabelMatch" })
                    end
                    -- Do something else
                    return highlights
                  end,
                },
                label_description = { width = { max = 20 } },
                kind_icon = {
                  text = function(ctx)
                    -- detect emmet-ls
                    local source, client = ctx.item.source_id, ctx.item.client_id
                    local lspName = client and vim.lsp.get_client_by_id(client).name
                    if lspName == "emmet_language_server" then source = "emmet" end

                    -- use source-specific icons, and `kind_icon` only for items from LSPs
                    local sourceIcons = { snippets = "󰩫", buffer = "󰦨", emmet = "", path = "" }
                    return sourceIcons[source] or ctx.kind_icon
                  end,
                },
                source_name = {
                  width = { max = 30, fill = true },
                  text = function(ctx)
                    if ctx.item.source_id == "lsp" then
                      local client = vim.lsp.get_client_by_id(ctx.item.client_id)
                      if client ~= nil then return string.format("[%s]", client.name) end
                      return ctx.source_name
                    end

                    return ctx.source_name
                  end,
                  highlight = "BlinkCmpSource",
                },
              },
            },
          },
        },
      })
    end,

    -- allows extending the providers array elsewhere in your config
    -- without having to redefine it
    opts_extend = { "sources.default" },
  },
}

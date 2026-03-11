-- lua/langs/markdown.lua
-- Markdown language support

return {
  filetypes = { "markdown" },

  servers = {
    marksman = {
      cmd = { "marksman", "server" },
    },
    -- markdown-oxide: PKM LSP for wiki links, tags, backlinks
    -- Works on any markdown file, not just Obsidian vaults
    markdown_oxide = {
      cmd = { "markdown-oxide" },
      root_markers = { ".obsidian", ".moxide.toml", ".git" },
      capabilities = {
        workspace = {
          didChangeWatchedFiles = { dynamicRegistration = true },
        },
      },
    },
    -- Note: obsidian-ls is provided by obsidian.nvim itself
    -- It auto-attaches when in an Obsidian vault
  },

  formatters = {
    markdown = { "prettier" },
  },

  ftplugin = {
    markdown = {
      opt = {
        wrap = true,
        linebreak = true,
        spell = true,
        conceallevel = 2,
      },
      abbr = {
        ["mtg:"] = "### Meeting 󱛡 ->",
        ["pr:"] = "### Pull Request  ->",
        ["act:"] = "_Action item:_ ",
        ["call:"] = " (call) ",
        ["email:"] = " (email) ",
      },
    },
  },

  -- Plugin specs (collected by langs.lazy_specs())
  plugins = {
    -- render-markdown.nvim: Visual rendering of markdown
    {
      "MeanderingProgrammer/render-markdown.nvim",
      cond = not vim.g.started_by_firenvim,
      dependencies = "echasnovski/mini.icons",
      ft = { "markdown", "codecompanion" },
      opts = {
        sign = { enabled = false },
        latex = { enabled = false },
        render_modes = { "n", "c", "i", "v", "V" },
        html = {
          comment = { text = "󰆈" },
        },
        heading = {
          position = "inline",
          icons = { "󰉫 ", "󰉬 ", "󰉭 ", "󰉮 ", "󰉯 ", "󰉰 " },
        },
        bullet = {
          icons = { "•", "∘", "▪", "▫", "" },
          ordered_icons = "",
        },
        dash = { icon = "┈" },
        code = { border = "thick", position = "left" },
        link = {
          image = "󰥶 ",
          email = "󰀓 ",
          hyperlink = "󰌹 ",
          custom = {
            web = { pattern = "^http[s]?://", icon = "󰖟 ", highlight = "RenderMarkdownLink" },
            mastodon = { pattern = "%.social/@", icon = " " },
            linkedin = { pattern = "linkedin%.com", icon = "󰌻 " },
          },
        },
        checkbox = {
          custom = {
            todo = { raw = "[-]", rendered = "󱗽 ", highlight = "RenderMarkdownListTodo" },
            event = { raw = "[|]", rendered = "󰀠 ", highlight = "RenderMarkdownListEvent" },
            wip = { raw = "[.]", rendered = "󰡖 ", highlight = "RenderMarkdownListWip" },
            skip = { raw = "[/]", rendered = " ", highlight = "RenderMarkdownListTrash" },
            fire = { raw = "[f]", rendered = "󰈸 ", highlight = "RenderMarkdownListFire" },
            star = { raw = "[s]", rendered = " ", highlight = "RenderMarkdownListStar" },
            idea = { raw = "[*]", rendered = "󰌵 ", highlight = "RenderMarkdownListIdea" },
            yes = { raw = "[y]", rendered = "󰔓 ", highlight = "RenderMarkdownListYes" },
            no = { raw = "[n]", rendered = "󰔑 ", highlight = "RenderMarkdownListNo" },
            question = { raw = "[?]", rendered = " ", highlight = "RenderMarkdownListQuestion" },
            info = { raw = "[i]", rendered = " ", highlight = "RenderMarkdownListInfo" },
            important = { raw = "[!]", rendered = "󱅶 ", highlight = "RenderMarkdownListImportant" },
          },
        },
        win_options = {
          conceallevel = { default = 0, rendered = 2 },
        },
      },
    },

    -- markdown.nvim: List continuation, inline surround, navigation
    -- Replaces unmaintained autolist.nvim (last commit Dec 2023)
    {
      "tadmccorkle/markdown.nvim",
      ft = "markdown",
      opts = {
        mappings = {
          inline_surround_toggle = "gs",
          inline_surround_toggle_line = "gss",
          inline_surround_delete = "ds",
          inline_surround_change = "cs",
          link_add = "gl",
          link_follow = "gx",
          go_curr_heading = "]c",
          go_parent_heading = "]p",
          go_next_heading = "]]",
          go_prev_heading = "[[",
        },
        on_attach = function(bufnr)
          local map = vim.keymap.set
          local opts = { buffer = bufnr }

          -- List item insertion (Alt+Enter)
          map({ "n", "i" }, "<M-CR>", "<Cmd>MDListItemBelow<CR>", opts)
          map({ "n", "i" }, "<M-S-CR>", "<Cmd>MDListItemAbove<CR>", opts)

          -- Insert mode: Enter continues lists
          map("i", "<CR>", function()
            local line = vim.api.nvim_get_current_line()
            -- If in a list (bullet or numbered), create new item
            if line:match("^%s*[-*+]%s") or line:match("^%s*%d+[.)]%s") then
              return "<Cmd>MDListItemBelow<CR>"
            end
            return "<CR>"
          end, { buffer = bufnr, expr = true })

          -- Normal mode: o continues lists
          map("n", "o", function()
            local line = vim.api.nvim_get_current_line()
            if line:match("^%s*[-*+]%s") or line:match("^%s*%d+[.)]%s") then
              return "<Cmd>MDListItemBelow<CR>"
            end
            return "o"
          end, { buffer = bufnr, expr = true })

          map("n", "O", function()
            local line = vim.api.nvim_get_current_line()
            if line:match("^%s*[-*+]%s") or line:match("^%s*%d+[.)]%s") then
              return "<Cmd>MDListItemAbove<CR>"
            end
            return "O"
          end, { buffer = bufnr, expr = true })
        end,
      },
    },
  },
}

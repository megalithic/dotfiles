if true then return {} end

-- REF: reawlllly good keymaps for markdown and image things:
-- https://github.com/linkarzu/dotfiles-latest/blob/main/neovim/neobean/lua/config/keymaps.lua
return {
  -- {
  --   "ribru17/markdown-preview.nvim",
  --   -- anchor links have an issue, see
  --   -- https://github.com/iamcco/markdown-preview.nvim/pull/575
  --   cmd = { "MarkdownPreviewToggle", "MarkdownPreview", "MarkdownPreviewStop" },
  --   ft = "markdown",
  --   build = "cd app && npx --yes yarn install",
  -- },
  -- {
  --   "dkarter/bullets.vim",
  --   ft = { "markdown", "text", "gitcommit" },
  --   cmd = { "InsertNewBullet" },
  -- },
  -- {
  --   "iamcco/markdown-preview.nvim",
  --   cmd = { "MarkdownPreviewToggle", "MarkdownPreview", "MarkdownPreviewStop" },
  --   ft = { "markdown" },
  --   build = function(plugin)
  --     if vim.fn.executable("npx") then
  --       vim.cmd("!cd " .. plugin.dir .. " && cd app && npx --yes yarn install")
  --     else
  --       vim.cmd([[Lazy load markdown-preview.nvim]])
  --       vim.fn["mkdp#util#install"]()
  --     end
  --   end,
  --   init = function()
  --     if vim.fn.executable("npx") then vim.g.mkdp_filetypes = { "markdown" } end
  --   end,
  -- },
  {
    "jannis-baum/vivify.vim", -- Preview markdown files in the browser using `vivify`
    file_types = {
      "markdown",
    },
    init = function()
      -- Refresh page contents on CursorHold and CursorHoldI
      vim.g.vivify_instant_refresh = 1
      -- additional filetypes to recognize as markdown
      vim.g.vivify_filetypes = { "vimwiki" }
    end,
    keys = {
      { "<localleader>mp", "<cmd>Vivify<cr>", desc = "Preview using vivify", ft = "markdown" },
    },
  },
  -- {
  --   "toppair/peek.nvim",
  --   event = { "VeryLazy" },
  --   build = "deno task --quiet build:fast",
  --   config = function()
  --     require("peek").setup()
  --     vim.api.nvim_create_user_command("PeekOpen", require("peek").open, {})
  --     vim.api.nvim_create_user_command("PeekClose", require("peek").close, {})
  --   end,
  -- },
  {
    "ray-x/yamlmatter.nvim",
    lazy = false,
    cond = false,
    -- event = "VeryLazy",
    -- ft = { "markdown" },
    config = function()
      require("yamlmatter").setup({
        key_value_padding = 4, -- Default padding between key and value
        icon_mappings = {
          -- Default icon mappings
          title = "",
          author = "",
          date = "",
          id = "",
          tags = "",
          category = "",
          type = "",
          default = "󰦨",
        },
        highlight_groups = {
          -- icon = 'YamlFrontmatterIcon',
          -- key = 'YamlFrontmatterKey',
          -- value = 'YamlFrontmatterValue',
          icon = "Identifier",
          key = "Function",
          value = "Type",
        },
      })
    end,
  },
  {
    "MeanderingProgrammer/markdown.nvim",
    cond = not vim.g.started_by_firenvim,
    name = "render-markdown", -- Only needed if you have another plugin named markdown.nvim
    dependencies = { "nvim-treesitter/nvim-treesitter", "echasnovski/mini.nvim", "echasnovski/mini.icons" }, -- if you use the mini.nvim suite
    ft = { "markdown", "codecompanion", "vimwiki", "gitcommit" },
    config = function()
      require("render-markdown").setup({
        heading = {
          -- Turn on / off heading icon & background rendering
          enabled = true,
          -- Turn on / off any sign column related rendering
          sign = false,
          -- Replaces '#+' of 'atx_h._marker'
          -- The number of '#' in the heading determines the 'level'
          -- The 'level' is used to index into the array using a cycle
          -- The result is left padded with spaces to hide any additional '#'
          icons = { "󰉫 ", "󰉬 ", "󰉭 ", "󰉮 ", "󰉯 ", "󰉰 " },
          -- icons = { "󰉫 ", "󰉬 ", "󰉭 ", "󰉮 ", "󰉯 ", "󰉰 " },
          -- icons = { "󰼏 ", "󰎨 " },
          -- icons = { "󰲡 ", "󰲣 ", "󰲥 ", "󰲧 ", "󰲩 ", "󰲫 " },
          -- Added to the sign column if enabled
          -- The 'level' is used to index into the array using a cycle
          signs = { "󰫎 " },
          -- The 'level' is used to index into the array using a clamp
          -- Highlight for the heading icon and extends through the entire line
          -- backgrounds = {
          --   "RenderMarkdownH1Bg",
          --   "RenderMarkdownH2Bg",
          --   "RenderMarkdownH3Bg",
          --   "RenderMarkdownH4Bg",
          --   "RenderMarkdownH5Bg",
          --   "RenderMarkdownH6Bg",
          -- },
          -- The 'level' is used to index into the array using a clamp
          -- Highlight for the heading and sign icons
          foregrounds = {
            "RenderMarkdownH1",
            "RenderMarkdownH2",
            "RenderMarkdownH3",
            "RenderMarkdownH4",
            "RenderMarkdownH5",
            "RenderMarkdownH6",
          },
          -- Used above heading for border
          -- above = "▄",
          -- Used below heading for border
          -- below = "▀",
          -- border = true,
          -- width = { "full", "full", "block", "block", "block" },
          -- width = { "full", "full", "block" },
          -- left_pad = 1,
          -- right_pad = 2,
          -- min_width = 20,
        },
        code = {
          -- Turn on / off code block & inline code rendering
          enabled = true,
          -- Turn on / off any sign column related rendering
          sign = false,
          -- Determines how code blocks & inline code are rendered:
          --  none: disables all rendering
          --  normal: adds highlight group to code blocks & inline code, adds padding to code blocks
          --  language: adds language icon to sign column if enabled and icon + name above code blocks
          --  full: normal + language
          style = "full",
          -- Amount of padding to add to the left of code blocks
          left_pad = 2,
          right_pad = 4,
          width = "block",
          -- Determins how the top / bottom of code block are rendered:
          --  thick: use the same highlight as the code body
          --  thin: when lines are empty overlay the above & below icons
          border = "thin",
          -- Used above code blocks for thin border
          above = "", -- alts: ┄
          -- above = "▄",
          -- Used below code blocks for thin border
          below = "▀", -- alts: ─
          -- below = "▀",
          -- Highlight for code blocks & inline code
          highlight = "RenderMarkdownCode",
        },
        dash = {
          -- Turn on / off thematic break rendering
          enabled = true,
          -- Replaces '---'|'***'|'___'|'* * *' of 'thematic_break'
          -- The icon gets repeated across the window's width
          -- icon = "─",
          icon = "┈",
          -- icon = "░",
          -- Highlight for the whole line generated from the icon
          highlight = "RenderMarkdownDash",
        },
        bullet = {
          -- Turn on / off list bullet rendering
          enabled = true,
          -- Replaces '-'|'+'|'*' of 'list_item'
          -- How deeply nested the list is determines the 'level'
          -- The 'level' is used to index into the array using a cycle
          -- If the item is a 'checkbox' a conceal is used to hide the bullet instead
          icons = { "•", "∘", "▪", "▫", "" }, -- alts: ◦
          -- Highlight for the bullet icon
          highlight = "RenderMarkdownBullet",
        },
        checkbox = {
          -- Turn on / off checkbox state rendering
          enabled = true,
          unchecked = {
            -- Replaces '[ ]' of 'task_list_marker_unchecked'
            icon = " ", -- alts: 󰄱
            -- Highlight for the unchecked icon
            highlight = "RenderMarkdownUnchecked",
          },
          checked = {
            -- Replaces '[x]' of 'task_list_marker_checked'
            icon = " ", -- alts: 󰱒   
            -- Highligh for the checked icon
            highlight = "RenderMarkdownChecked",
          },
          -- Define custom checkbox states, more involved as they are not part of the markdown grammar
          -- As a result this requires neovim >= 0.10.0 since it relies on 'inline' extmarks
          -- Can specify as many additional states as you like following the 'todo' pattern below
          --   The key in this case 'todo' is for healthcheck and to allow users to change its values
          --   'raw': Matched against the raw text of a 'shortcut_link'
          --   'rendered': Replaces the 'raw' value when rendering
          --   'highlight': Highlight for the 'rendered' icon
          -- custom = {
          --   todo = { raw = "[-]", rendered = "󰥔 ", highlight = "RenderMarkdownTodo" },
          -- },
          custom = {
            -- todo = { raw = "[-]", rendered = " 󰥔 ", highlight = "RenderMarkdownTodo" },
            todo = { raw = "[-]", rendered = "󱗽 ", highlight = "RenderMarkdownListTodo" },
            event = { raw = "[|]", rendered = "󰀠 ", highlight = "RenderMarkdownListEvent" },
            wip = { raw = "[.]", rendered = "󰡖 ", highlight = "RenderMarkdownListWip" },
            -- trash = { raw = "[/]", rendered = " ", highlight = "RenderMarkdownListSkipped" },
            skip = { raw = "[/]", rendered = " ", highlight = "RenderMarkdownListTrash" },

            fire = { raw = "[f]", rendered = "󰈸 ", highlight = "RenderMarkdownListFire" },
            star = { raw = "[s]", rendered = " ", highlight = "RenderMarkdownListStar" },
            idea = { raw = "[*]", rendered = "󰌵 ", highlight = "RenderMarkdownListIdea" },
            yes = { raw = "[y]", rendered = "󰔓 ", highlight = "RenderMarkdownListYes" },
            no = { raw = "[n]", rendered = "󰔑 ", highlight = "RenderMarkdownListNo" },
            question = { raw = "[?]", rendered = " ", highlight = "RenderMarkdownListQuestion" },
            info = { raw = "[i]", rendered = " ", highlight = "RenderMarkdownListInfo" },
            important = { raw = "[!]", rendered = "󱅶 ", highlight = "RenderMarkdownListImportant" },
          },
        },
        quote = {
          -- Turn on / off block quote & callout rendering
          enabled = true,
          -- Replaces '>' of 'block_quote'
          icon = "▐",
          -- Highlight for the quote icon
          highlight = "RenderMarkdownQuote",
        },
        pipe_table = {
          -- Turn on / off pipe table rendering
          enabled = true,
          -- Determines how the table as a whole is rendered:
          --  none: disables all rendering
          --  normal: applies the 'cell' style rendering to each row of the table
          --  full: normal + a top & bottom line that fill out the table when lengths match
          style = "full",
          -- Determines how individual cells of a table are rendered:
          --  overlay: writes completely over the table, removing conceal behavior and highlights
          --  raw: replaces only the '|' characters in each row, leaving the cells unmodified
          --  padded: raw + cells are padded with inline extmarks to make up for any concealed text
          cell = "padded",
        -- Characters used to replace table border
        -- Correspond to top(3), delimiter(3), bottom(3), vertical, & horizontal
        -- stylua: ignore
        border = {
            '┌', '┬', '┐',
            '├', '┼', '┤',
            '└', '┴', '┘',
            '│', '─',
        },
          -- Highlight for table heading, delimiter, and the line above
          head = "RenderMarkdownTableHead",
          -- Highlight for everything else, main table rows and the line below
          row = "RenderMarkdownTableRow",
          -- Highlight for inline padding used to add back concealed space
          filler = "RenderMarkdownTableFill",
        },
        -- Callouts are a special instance of a 'block_quote' that start with a 'shortcut_link'
        -- Can specify as many additional values as you like following the pattern from any below, such as 'note'
        --   The key in this case 'note' is for healthcheck and to allow users to change its values
        --   'raw': Matched against the raw text of a 'shortcut_link', case insensitive
        --   'rendered': Replaces the 'raw' value when rendering
        --   'highlight': Highlight for the 'rendered' text and quote markers
        callout = {
          note = { raw = "[!NOTE]", rendered = "󰋽 Note", highlight = "RenderMarkdownInfo" },
          tip = { raw = "[!TIP]", rendered = "󰌶 Tip", highlight = "RenderMarkdownSuccess" },
          important = { raw = "[!IMPORTANT]", rendered = "󰅾 Important", highlight = "RenderMarkdownHint" },
          warning = { raw = "[!WARNING]", rendered = "󰀪 Warning", highlight = "RenderMarkdownWarn" },
          caution = { raw = "[!CAUTION]", rendered = "󰳦 Caution", highlight = "RenderMarkdownError" },
          -- Obsidian: https://help.a.md/Editing+and+formatting/Callouts
          abstract = { raw = "[!ABSTRACT]", rendered = "󰨸 Abstract", highlight = "RenderMarkdownInfo" },
          todo = { raw = "[!TODO]", rendered = "󰗡 Todo", highlight = "RenderMarkdownInfo" },
          success = { raw = "[!SUCCESS]", rendered = "󰄬 Success", highlight = "RenderMarkdownSuccess" },
          question = { raw = "[!QUESTION]", rendered = "󰘥 Question", highlight = "RenderMarkdownWarn" },
          failure = { raw = "[!FAILURE]", rendered = "󰅖 Failure", highlight = "RenderMarkdownError" },
          danger = { raw = "[!DANGER]", rendered = "󱐌 Danger", highlight = "RenderMarkdownError" },
          bug = { raw = "[!BUG]", rendered = "󰨰 Bug", highlight = "RenderMarkdownError" },
          example = { raw = "[!EXAMPLE]", rendered = "󰉹 Example", highlight = "RenderMarkdownHint" },
          quote = { raw = "[!QUOTE]", rendered = "󱆨 Quote", highlight = "RenderMarkdownQuote" },
        },
        -- link = {
        --   -- Turn on / off inline link icon rendering
        --   enabled = true,
        --   -- Inlined with 'image' elements
        --   image = "󰥶 ",
        --   -- Inlined with 'inline_link' elements
        --   hyperlink = "󰌹 ",
        --   -- Applies to the inlined icon
        --   highlight = "RenderMarkdownLink",
        -- },
        --
        link = {
          enabled = true,
          image = "󰥶 ",
          email = "󰀓 ",
          hyperlink = "󰌹 ",
          highlight = "RenderMarkdownLink",
          custom = {
            web = { pattern = "^http[s]?://", icon = "󰖟 ", highlight = "RenderMarkdownLink" },
          },
        },
        sign = {
          -- Turn on / off sign rendering
          enabled = true,
          -- More granular mechanism, disable signs within specific buftypes
          exclude = {
            buftypes = { "nofile" },
          },
          -- Applies to background of sign text
          highlight = "RenderMarkdownSign",
        },
      })
    end,
  },
  {
    -- this hates me; with bullets enabled markdown/elixir/heex.vim syntax errors occur
    "dkarter/bullets.vim",
    -- ft = { "markdown", "text", "gitcommit" },
    event = {
      -- "BufRead **.md,**.neorg,**.org",
      -- "BufNewFile **.md,**.neorg,**.org",
      "FileType gitcommit,NeogitCommitMessage,.git/COMMIT_EDITMSG",
      -- "FileType gitcommit,NeogitCommitMessage,.git/COMMIT_EDITMSG,markdown,text,plaintext",
    },
    cmd = { "InsertNewBullet" },
  },
  {
    "gaoDean/autolist.nvim",
    event = {
      "BufRead **.md,**.neorg,**.org",
      "BufNewFile **.md,**.neorg,**.org",
      "FileType gitcommit,NeogitCommitMessage,.git/COMMIT_EDITMSG,markdown",
    },
    -- cond = false,
    version = "2.3.0",
    config = function()
      local al = require("autolist")
      al.setup()
      al.create_mapping_hook("i", "<CR>", al.new)
      al.create_mapping_hook("i", "<Tab>", al.indent, "<C-t>")
      al.create_mapping_hook("i", "<S-Tab>", al.indent, "<C-d>")
      al.create_mapping_hook("n", "o", al.new)
      -- al.create_mapping_hook("n", "<C-c>", al.invert_entry)
      -- al.create_mapping_hook("n", "<C-x>", al.invert_entry)
      al.create_mapping_hook("n", "O", al.new_before)
    end,
  },
  -- {
  --   "lukas-reineke/headlines.nvim",
  --   event = {
  --     "BufRead **.md,**.yaml,**.neorg,**.org",
  --     "BufNewFile **.md,**.yaml,**.neorg,**.org",
  --     -- "FileType gitcommit,NeogitCommitMessage,.git/COMMIT_EDITMSG",
  --   },
  --   dependencies = "nvim-treesitter",
  --   config = function()
  --     require("headlines").setup({
  --       markdown = {
  --         source_pattern_start = "^```",
  --         source_pattern_end = "^```$",
  --         dash_pattern = "-",
  --         dash_highlight = "Dash",
  --         dash_string = "󰇜",
  --         quote_highlight = "Quote",
  --         quote_string = "┃",
  --         headline_pattern = "^#+",
  --         headline_highlights = { "Headline1", "Headline2", "Headline3", "Headline4", "Headline5", "Headline6" },
  --         fat_headlines = true,
  --         fat_headline_upper_string = "▃",
  --         fat_headline_lower_string = "🬂",
  --         codeblock_highlight = "CodeBlock",
  --         bullets = {},
  --         bullet_highlights = {},
  --         -- bullets = { "◉", "○", "✸", "✿" },
  --         -- bullet_highlights = {
  --         --   "@text.title.1.marker.markdown",
  --         --   "@text.title.2.marker.markdown",
  --         --   "@text.title.3.marker.markdown",
  --         --   "@text.title.4.marker.markdown",
  --         --   "@text.title.5.marker.markdown",
  --         --   "@text.title.6.marker.markdown",
  --         -- },
  --       },
  --       yaml = {
  --         dash_pattern = "^---+$",
  --         dash_highlight = "Dash",
  --       },
  --     })
  --   end,
  -- },
  {
    -- Still having issues with magick luarock not installing
    enabled = false,
    "3rd/image.nvim",
    dependencies = {
      { "leafo/magick" },
      -- {
      --   -- luarocks.nvim is a Neovim plugin designed to streamline the installation
      --   -- of luarocks packages directly within Neovim. It simplifies the process
      --   -- of managing Lua dependencies, ensuring a hassle-free experience for
      --   -- Neovim users.
      --   -- https://github.com/vhyrro/luarocks.nvim
      --   "vhyrro/luarocks.nvim",
      --   -- this plugin needs to run before anything else
      --   priority = 1001,
      --   opts = {
      --     rocks = { "magick" },
      --   },
      -- },
    },
    opts = {
      backend = "kitty",
      kitty_method = "normal",
      integrations = {
        markdown = {
          enabled = true,
          clear_in_insert_mode = false,
          download_remote_images = true,
          only_render_image_at_cursor = true,
          filetypes = { "markdown", "vimwiki" }, -- markdown extensions (ie. quarto) can go here
        },
        html = {
          enabled = true,
        },
        css = {
          enabled = true,
        },
      },
      max_width = nil,
      max_height = nil,
      max_width_window_percentage = nil,
      max_height_window_percentage = 40,
      window_overlap_clear_enabled = false, -- toggles images when windows are overlapped
      window_overlap_clear_ft_ignore = { "cmp_menu", "cmp_docs", "" },
      editor_only_render_when_focused = true, -- auto show/hide images when the editor gains/looses focus
      tmux_show_only_in_active_window = true, -- auto show/hide images in the correct Tmux window (needs visual-activity off)
      hijack_file_patterns = { "*.png", "*.jpg", "*.jpeg", "*.gif", "*.webp", "*.avif" }, -- render image files as images when opened
    },
    config = function(_, opts) require("image").setup(opts) end,
  },
  -- {
  --   cond = false,
  --   "epwalsh/obsidian.nvim",
  --   version = "*", -- recommended, use latest release instead of latest commit
  --   lazy = true,
  --   ft = "markdown",
  --   dependencies = {
  --     "nvim-lua/plenary.nvim",
  --   },
  --   config = function()
  --     require("obsidian").setup({
  --       workspaces = {
  --         {
  --           name = "notes",
  --           path = vim.env.OBSIDIAN_VAULT_DIR,
  --         },
  --       },
  --     })
  --   end,
  -- },
}

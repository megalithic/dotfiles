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
  --   build = function() vim.fn["mkdp#util#install"]() end,
  -- },
  {
    "toppair/peek.nvim",
    event = { "VeryLazy" },
    build = "deno task --quiet build:fast",
    config = function()
      require("peek").setup()
      vim.api.nvim_create_user_command("PeekOpen", require("peek").open, {})
      vim.api.nvim_create_user_command("PeekClose", require("peek").close, {})
    end,
  },
  {
    "gaoDean/autolist.nvim",
    event = {
      "BufRead **.md,**.neorg,**.org",
      "BufNewFile **.md,**.neorg,**.org",
      "FileType gitcommit,NeogitCommitMessage,.git/COMMIT_EDITMSG",
    },
    -- enabled = false,
    version = "2.3.0",
    config = function()
      local al = require("autolist")
      al.setup()
      al.create_mapping_hook("i", "<CR>", al.new)
      al.create_mapping_hook("i", "<Tab>", al.indent)
      al.create_mapping_hook("i", "<S-Tab>", al.indent, "<C-d>")
      al.create_mapping_hook("n", "o", al.new)
      al.create_mapping_hook("n", "<C-c>", al.invert_entry)
      al.create_mapping_hook("n", "<C-x>", al.invert_entry)
      al.create_mapping_hook("n", "O", al.new_before)
    end,
  },
  {
    "lukas-reineke/headlines.nvim",
    event = {
      "BufRead **.md,**.yaml,**.neorg,**.org",
      "BufNewFile **.md,**.yaml,**.neorg,**.org",
      -- "FileType gitcommit,NeogitCommitMessage,.git/COMMIT_EDITMSG",
    },
    dependencies = "nvim-treesitter",
    config = function()
      require("headlines").setup({
        markdown = {
          source_pattern_start = "^```",
          source_pattern_end = "^```$",
          dash_pattern = "-",
          dash_highlight = "Dash",
          dash_string = "󰇜",
          quote_highlight = "Quote",
          quote_string = "┃",
          headline_pattern = "^#+",
          headline_highlights = { "Headline1", "Headline2", "Headline3", "Headline4", "Headline5", "Headline6" },
          fat_headlines = true,
          fat_headline_upper_string = "▃",
          fat_headline_lower_string = "🬂",
          codeblock_highlight = "CodeBlock",
          bullets = {},
          bullet_highlights = {},
          -- bullets = { "◉", "○", "✸", "✿" },
          -- bullet_highlights = {
          --   "@text.title.1.marker.markdown",
          --   "@text.title.2.marker.markdown",
          --   "@text.title.3.marker.markdown",
          --   "@text.title.4.marker.markdown",
          --   "@text.title.5.marker.markdown",
          --   "@text.title.6.marker.markdown",
          -- },
        },
        yaml = {
          dash_pattern = "^---+$",
          dash_highlight = "Dash",
        },
      })
    end,
  },
}

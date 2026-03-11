-- REF: reawlllly good keymaps for markdown and image things:
-- https://github.com/linkarzu/dotfiles-latest/blob/main/neovim/neobean/lua/config/keymaps.lua
return {
  {
    "MeanderingProgrammer/render-markdown.nvim",
    cond = not vim.g.started_by_firenvim,
    dependencies = "echasnovski/mini.icons",
    ft = { "markdown", "codecompanion", "vimwiki", "gitcommit", "obsidian" },
    opts = {
      restart_highlighter = true, -- nvim core bug fix https://github.com/MeanderingProgrammer/render-markdown.nvim/issues/488#issuecomment-3154937211

      sign = { enabled = false },
      latex = { enabled = false },
      render_modes = { "n", "c", "i", "v", "V" },
      html = {
        comment = { text = "󰆈" },
      },
      heading = {
        position = "inline", -- remove indentation of headings
        icons = { "󰉫 ", "󰉬 ", "󰉭 ", "󰉮 ", "󰉯 ", "󰉰 " },
      },
      bullet = {
        icons = { "•", "∘", "▪", "▫", "" }, -- alts: ◦
        ordered_icons = "", -- empty string = disable
      },
      dash = {
        icon = "┈",
      },
      code = {
        border = "thick",
        position = "left",
      },
      link = {
        image = "󰥶 ",
        email = "󰀓 ",
        hyperlink = "󰌹 ",
        custom = {
          web = { pattern = "^http[s]?://", icon = "󰖟 ", highlight = "RenderMarkdownLink" },
          -- myWebsite = { pattern = "https://chris%-grieser.de", icon = " " },
          mastodon = { pattern = "%.social/@", icon = " " },
          linkedin = { pattern = "linkedin%.com", icon = "󰌻 " },
          -- researchgate = { pattern = "researchgate%.net", icon = "󰙨 " },
        },
      },
      checkbox = {
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
      -- makes toggling this plugin also toggle conceallevel
      win_options = {
        conceallevel = { default = 0, rendered = 2 },
      },
    },
  },
  {
    "gaoDean/autolist.nvim",
    event = {
      "BufRead **.md,**.neorg,**.org",
      "BufNewFile **.md,**.neorg,**.org",
      "FileType gitcommit,NeogitCommitMessage,.git/COMMIT_EDITMSG,markdown",
    },
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
}

local SETTINGS = mega.req("mega.settings")
return {
  {
    "echasnovski/mini.indentscope",
    config = function()
      mega.req("mini.indentscope").setup({
        symbol = SETTINGS.indent_scope_char,
        -- mappings = {
        --   goto_top = "<leader>k",
        --   goto_bottom = "<leader>j",
        -- },
        draw = {
          delay = 10,
          animation = function() return 0 end,
        },
        options = { try_as_border = true, border = "both", indent_at_cursor = true },
      })

      mega.req("mega.autocmds").augroup("mini.indentscope", {
        {
          event = "FileType",
          pattern = {
            "help",
            "alpha",
            "dashboard",
            "neo-tree",
            "Trouble",
            "lazy",
            "mason",
            "fzf",
            "dirbuf",
            "terminal",
            "fzf-lua",
            "fzflua",
            "megaterm",
            "nofile",
            "terminal",
            "megaterm",
            "lsp-installer",
            "SidebarNvim",
            "lspinfo",
            "markdown",
            "help",
            "startify",
            "packer",
            "NeogitStatus",
            "oil",
            "DirBuf",
            "markdown",
          },
          command = function() vim.b.miniindentscope_disable = true end,
        },
      })
    end,
  },

  {
    "echasnovski/mini.surround",
    keys = {
      { "S", mode = { "x" } },
      "ys",
      "ds",
      "cs",
    },
    config = function()
      require("mini.surround").setup({
        mappings = {
          add = "ys",
          delete = "ds",
          replace = "cs",
          find = "",
          find_left = "",
          highlight = "",
          update_n_lines = "",
        },
      })

      vim.keymap.set("x", "S", [[:<C-u>lua MiniSurround.add('visual')<CR>]])
    end,
  },
  {
    "echasnovski/mini.hipatterns",
    opts = {
      -- Highlight standalone "FIXME", "ERROR", "HACK", "TODO", "NOTE", "WARN", "REF"
      highlighters = {
        fixme = { pattern = "%f[%w]()FIXME()%f[%W]", group = "MiniHipatternsFixme" },
        error = { pattern = "%f[%w]()ERROR()%f[%W]", group = "MiniHipatternsError" },
        hack = { pattern = "%f[%w]()HACK()%f[%W]", group = "MiniHipatternsHack" },
        warn = { pattern = "%f[%w]()WARN()%f[%W]", group = "MiniHipatternsWarn" },
        todo = { pattern = "%f[%w]()TODO()%f[%W]", group = "MiniHipatternsTodo" },
        note = { pattern = "%f[%w]()NOTE()%f[%W]", group = "MiniHipatternsNote" },
        ref = { pattern = "%f[%w]()REF()%f[%W]", group = "MiniHipatternsRef" },
        refs = { pattern = "%f[%w]()REFS()%f[%W]", group = "MiniHipatternsRef" },

        -- Highlight hex color strings (`#rrggbb`) using that color
        -- hex_color = hipatterns.gen_highlighter.hex_color(),
      },
      -- vim.b.minihipatterns_disable = not context.in_treesitter_capture("comment") or not context.in_syntax_group("Comment")
    },
  },
  {
    "echasnovski/mini.ai",
    keys = {
      { "a", mode = { "o", "x" } },
      { "i", mode = { "o", "x" } },
    },
    config = function()
      local ai = require("mini.ai")
      local gen_spec = ai.gen_spec
      ai.setup({
        n_lines = 500,
        search_method = "cover_or_next",
        custom_textobjects = {
          o = gen_spec.treesitter({
            a = { "@block.outer", "@conditional.outer", "@loop.outer" },
            i = { "@block.inner", "@conditional.inner", "@loop.inner" },
          }, {}),
          f = gen_spec.treesitter({ a = "@function.outer", i = "@function.inner" }, {}),
          c = gen_spec.treesitter({ a = "@class.outer", i = "@class.inner" }, {}),
          -- t = { "<(%w-)%f[^<%w][^<>]->.-</%1>", "^<.->%s*().*()%s*</[^/]->$" }, -- deal with selection without the carriage return
          t = { "<([%p%w]-)%f[^<%p%w][^<>]->.-</%1>", "^<.->().*()</[^/]->$" },

          -- scope
          s = gen_spec.treesitter({
            a = { "@function.outer", "@class.outer", "@testitem.outer" },
            i = { "@function.inner", "@class.inner", "@testitem.inner" },
          }),
          S = gen_spec.treesitter({
            a = { "@function.name", "@class.name", "@testitem.name" },
            i = { "@function.name", "@class.name", "@testitem.name" },
          }),
        },
        mappings = {
          around = "a",
          inside = "i",

          around_next = "an",
          inside_next = "in",
          around_last = "al",
          inside_last = "il",

          goto_left = "",
          goto_right = "",
        },
      })
    end,
  },
  {
    "echasnovski/mini.pairs",
    opts = {},
  },
}

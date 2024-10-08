local SETTINGS = mega.req("mega.settings")
return {
  { "echasnovski/mini.icons", version = false },
  {
    "echasnovski/mini.comment",
    version = false,
    opts = {
      -- Options which control module behavior
      options = {
        -- Function to compute custom 'commentstring' (optional)
        custom_commentstring = nil,

        -- Whether to ignore blank lines when commenting
        ignore_blank_line = true,

        -- Whether to recognize as comment only lines without indent
        start_of_line = false,

        -- Whether to force single space inner padding for comment parts
        pad_comment_parts = true,
      },

      -- Module mappings. Use `''` (empty string) to disable one.
      mappings = {
        -- Toggle comment (like `gcip` - comment inner paragraph) for both
        -- Normal and Visual modes
        comment = "gc",

        -- Toggle comment on current line
        comment_line = "gcc",

        -- Toggle comment on visual selection
        comment_visual = "gc",

        -- Define 'comment' textobject (like `dgc` - delete whole comment block)
        -- Works also in Visual mode if mapping differs from `comment_visual`
        textobject = "gc",
      },

      -- Hook functions to be executed at certain stage of commenting
      hooks = {
        -- Before successful commenting. Does nothing by default.
        pre = function() end,
        -- After successful commenting. Does nothing by default.
        post = function() end,
      },
    },
  },
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
          delay = 0,
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
    enabled = false,
    "echasnovski/mini.pairs",
    opts = {},
  },
  {
    "echasnovski/mini.clue",
    event = "VeryLazy",
    opts = function()
      local clue = require("mini.clue")
      -- REF: https://github.com/ahmedelgabri/dotfiles/blob/main/config/nvim/lua/plugins/mini.lua#L314
      -- Clues for a-z/A-Z marks.
      local function mark_clues()
        local marks = {}
        vim.list_extend(marks, vim.fn.getmarklist(vim.api.nvim_get_current_buf()))
        vim.list_extend(marks, vim.fn.getmarklist())

        return vim
          .iter(marks)
          :map(function(mark)
            local key = mark.mark:sub(2, 2)

            -- Just look at letter marks.
            if not string.match(key, "^%a") then return nil end

            -- For global marks, use the file as a description.
            -- For local marks, use the line number and content.
            local desc
            if mark.file then
              desc = vim.fn.fnamemodify(mark.file, ":p:~:.")
            elseif mark.pos[1] and mark.pos[1] ~= 0 then
              local line_num = mark.pos[2]
              local lines = vim.fn.getbufline(mark.pos[1], line_num)
              if lines and lines[1] then desc = string.format("%d: %s", line_num, lines[1]:gsub("^%s*", "")) end
            end

            if desc then return {
              mode = "n",
              keys = string.format("`%s", key),
              desc = desc,
            } end
          end)
          :totable()
      end

      -- Clues for recorded macros.
      local function macro_clues()
        local res = {}
        for _, register in ipairs(vim.split("abcdefghijklmnopqrstuvwxyz", "")) do
          local keys = string.format("\"%s", register)
          local ok, desc = pcall(vim.fn.getreg, register, 1)
          if ok and desc ~= "" then
            table.insert(res, { mode = "n", keys = keys, desc = desc })
            table.insert(res, { mode = "v", keys = keys, desc = desc })
          end
        end

        return res
      end

      return {
        triggers = {
          -- Leader triggers
          { mode = "n", keys = "<leader>" },
          { mode = "x", keys = "<leader>" },

          { mode = "n", keys = "<localleader>" },
          { mode = "x", keys = "<localleader>" },

          -- Built-in completion
          { mode = "i", keys = "<C-x>" },

          -- `g` key
          { mode = "n", keys = "g", desc = "+go[to]" },
          { mode = "x", keys = "g", desc = "+go[to]" },

          -- Marks
          { mode = "n", keys = "'" },
          { mode = "n", keys = "`" },
          { mode = "x", keys = "'" },
          { mode = "x", keys = "`" },

          -- Registers
          { mode = "n", keys = "\"" },
          { mode = "x", keys = "\"" },
          { mode = "i", keys = "<C-r>" },
          { mode = "c", keys = "<C-r>" },

          -- Window commands
          { mode = "n", keys = "<C-w>" },

          -- `z` key
          { mode = "n", keys = "z" },
          { mode = "x", keys = "z" },

          -- Moving between stuff.
          { mode = "n", keys = "[" },
          { mode = "n", keys = "]" },
        },

        clues = {
          { mode = "n", keys = "<leader>e", desc = "+explore/edit files" },
          { mode = "n", keys = "<leader>f", desc = "+find (" .. vim.g.picker .. ")" },
          { mode = "n", keys = "<leader>t", desc = "+terminal" },
          { mode = "n", keys = "<leader>r", desc = "+repl" },
          { mode = "n", keys = "<leader>l", desc = "+lsp" },
          { mode = "n", keys = "<leader>n", desc = "+notes" },
          { mode = "n", keys = "<leader>g", desc = "+git" },
          { mode = "n", keys = "<leader>p", desc = "+plugins" },
          { mode = "n", keys = "<leader>z", desc = "+zk" },
          { mode = "n", keys = "<localleader>g", desc = "+git" },
          { mode = "n", keys = "<localleader>h", desc = "+git hunk" },
          { mode = "n", keys = "<localleader>t", desc = "+test" },
          { mode = "n", keys = "<localleader>s", desc = "+spell" },
          { mode = "n", keys = "<localleader>d", desc = "+debug" },
          { mode = "n", keys = "<localleader>y", desc = "+yank" },

          { mode = "n", keys = "[", desc = "+prev" },
          { mode = "n", keys = "]", desc = "+next" },

          clue.gen_clues.builtin_completion(),
          clue.gen_clues.g(),
          clue.gen_clues.marks(),
          clue.gen_clues.registers(),
          clue.gen_clues.windows(),
          clue.gen_clues.z(),

          mark_clues,
          macro_clues,
        },
        window = {
          -- Floating window config
          config = function(bufnr)
            local max_width = 0
            for _, line in ipairs(vim.api.nvim_buf_get_lines(bufnr, 0, -1, false)) do
              max_width = math.max(max_width, vim.fn.strchars(line))
            end

            -- Keep some right padding.
            max_width = max_width + 2

            return {
              border = "rounded",
              -- Dynamic width capped at 45.
              width = math.min(45, max_width),
            }
          end,

          -- Delay before showing clue window
          delay = 300,

          -- Keys to scroll inside the clue window
          scroll_down = "<C-d>",
          scroll_up = "<C-u>",
        },
      }
    end,
  },
}

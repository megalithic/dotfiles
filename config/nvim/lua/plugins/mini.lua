return {
  -- {
  --   "nvim-mini/mini.jump",
  --   enabled = true,
  --   version = false,
  --   opts = {
  --     view = { dim = true },
  --     mappings = {
  --       start_jumping = "",
  --     },
  --   },
  -- },

  { "nvim-mini/mini.icons", version = false, opts = {} },
  {
    "nvim-mini/mini.indentscope",
    config = function()
      require("mini.indentscope").setup({
        symbol = vim.g.indent_scope_char,
        mappings = {
          goto_top = "[[",
          goto_bottom = "]]",
        },
        draw = {
          delay = 0,
          animation = function() return 0 end,
        },
        options = { try_as_border = true, border = "both", indent_at_cursor = true },
      })

      if Augroup ~= nil then
        Augroup("mini.indentscope", {
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
      end
    end,
  },
  { "nvim-mini/mini.extra", version = false, opts = {} },
  {
    enabled = true,
    "nvim-mini/mini.pick",
    main = "mini.pick",
    version = false,
    cmd = { "Pick", "MiniPick" },
    lazy = true,
    dependencies = {
      { "echasnovski/mini.extra", config = true },
      { "echasnovski/mini.fuzzy", config = true },
      { "echasnovski/mini.visits", config = true, event = "LazyFile" },
      { "echasnovski/mini.align", config = true },
      -- {
      --   -- "diego-velez/fff.nvim",
      --   "dmtrKovalenko/fff.nvim",
      --   build = "cargo build --release",
      --   -- build = {
      --   --   function(args)
      --   --     local cmd = { "rustup", "run", "nightly", "cargo", "build", "--release" }
      --   --     ---@type vim.SystemOpts
      --   --     local opts = { cwd = args.dir, text = true }
      --   --
      --   --     vim.notify("Building " .. args.name, vim.log.levels.INFO)
      --   --     local output = vim.system(cmd, opts):wait()
      --   --     if output.code ~= 0 then
      --   --       vim.notify("Failed to build " .. args.name .. "\n" .. output.stderr, vim.log.levels.ERROR)
      --   --     else
      --   --       vim.notify("Built " .. args.name, vim.log.levels.INFO)
      --   --     end
      --   --   end,
      --   -- },
      -- },
    },
    init = function() require("plugins.mini-pick") end,
  },
  {
    "nvim-mini/mini.surround",
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
          update_n_lines = 500,
        },
        custom_surroundings = {
          tag_name_only = {
            input = { "<(%w-)%f[^<%w][^<>]->.-</%1>", "^<()%w+().*</()%w+()>$" },
            output = function()
              local tag_name = require("mini.surround").user_input("Tag name (excluding attributes)")
              if tag_name == nil then return nil end
              return { left = tag_name, right = tag_name }
            end,
          },
        },
      })

      Keymap("x", "S", [[:<C-u>lua MiniSurround.add('visual')<CR>]])
      Keymap("n", "yss", "ys_", { noremap = false })
    end,
  },
  {
    "nvim-mini/mini.hipatterns",
    opts = function()
      local hi = require("mini.hipatterns")
      return {

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
          due = { pattern = "%f[%w]()@@%f![%W]", group = "MiniHipatternsDue" },

          hex_color = hi.gen_highlighter.hex_color({ priority = 2000 }),
          shorthand = {
            pattern = "()#%x%x%x()%f[^%x%w]",
            group = function(_, _, data)
              ---@type string
              local match = data.full_match
              local r, g, b = match:sub(2, 2), match:sub(3, 3), match:sub(4, 4)
              local hex_color = "#" .. r .. r .. g .. g .. b .. b

              return MiniHipatterns.compute_hex_color_group(hex_color, "bg")
            end,
            extmark_opts = { priority = 2000 },
          },
        },

        tailwind = {
          enabled = true,
          ft = {
            "astro",
            "css",
            "heex",
            "html",
            "html-eex",
            "javascript",
            "javascriptreact",
            "rust",
            "svelte",
            "typescript",
            "typescriptreact",
            "vue",
            "elixir",
            "phoenix-html",
            "heex",
          },
          -- full: the whole css class will be highlighted
          -- compact: only the color will be highlighted
          style = "full",
        },
      }
    end,
    config = function(_, opts) require("mini.hipatterns").setup(opts) end,
  },
  {
    "nvim-mini/mini.ai",
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
          -- ["?"] = false,
          -- 				["/"] = ai.gen_spec.user_prompt(),
          -- 				["%"] = function() -- Entire file
          -- 					local from = { line = 1, col = 1 }
          -- 					local to = {
          -- 						line = vim.fn.line("$"),
          -- 						col = math.max(vim.fn.getline("$"):len(), 1),
          -- 					}
          -- 					return { from = from, to = to }
          -- 				end,
          -- 				a = ai.gen_spec.treesitter({ a = "@parameter.outer", i = "@parameter.inner" }),
          -- 				c = ai.gen_spec.treesitter({ a = "@comment.outer", i = "@comment.inner" }),
          -- 				f = ai.gen_spec.treesitter({ a = "@function.outer", i = "@function.inner" }),
          -- 				s = { -- Single words in different cases (camelCase, snake_case, etc.)
          -- 					{
          -- 						"%u[%l%d]+%f[^%l%d]",
          -- 						"%f[^%s%p][%l%d]+%f[^%l%d]",
          -- 						"^[%l%d]+%f[^%l%d]",
          -- 						"%f[^%s%p][%a%d]+%f[^%a%d]",
          -- 						"^[%a%d]+%f[^%a%d]",
          -- 					},
          -- 					"^().*()$",
          -- 				},
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
    "nvim-mini/mini.pairs",
    enabled = false,
    opts = {
      modes = { insert = true, command = false, terminal = false },
      -- skip autopair when next character is one of these
      skip_next = [=[[%w%%%'%[%"%.%`%$]]=],
      -- skip autopair when the cursor is inside these treesitter nodes
      skip_ts = { "string" },
      -- skip autopair when next character is closing pair
      -- and there are more closing pairs than opening pairs
      skip_unbalanced = true,
      -- better deal with markdown code blocks
      markdown = true,
      mappings = {
        ["`"] = { neigh_pattern = "[^\\`]." }, -- Prevent 4th backtick (https://github.com/echasnovski/mini.nvim/issues/31#issuecomment-2151599842)
      },
    },
  },
  {
    "nvim-mini/mini.clue",
    event = "VeryLazy",
    opts = function()
      local ok, clue = pcall(require, "mini.clue")
      if not ok then return end
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

            if desc then
              return {
                mode = "n",
                keys = string.format("`%s", key),
                desc = desc,
              }
            end
          end)
          :totable()
      end

      -- Clues for recorded macros.
      local function macro_clues()
        local res = {}
        for _, register in ipairs(vim.split("abcdefghijklmnopqrstuvwxyz", "")) do
          local keys = string.format('"%s', register)
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

          { mode = "n", keys = "<C-x>", desc = "+task toggling" },
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
          { mode = "n", keys = '"' },
          { mode = "x", keys = '"' },
          { mode = "i", keys = "<C-r>" },
          { mode = "c", keys = "<C-r>" },

          -- Window commands
          { mode = "n", keys = "<C-w>" },

          -- `z` key
          { mode = "n", keys = "z" },
          { mode = "x", keys = "z" },

          -- mini.surround
          { mode = "n", keys = "S", desc = "+treesitter" },

          -- Operator-pending mode key
          { mode = "o", keys = "a" },
          { mode = "o", keys = "i" },

          -- Moving between stuff.
          { mode = "n", keys = "[" },
          { mode = "n", keys = "]" },
        },

        clues = {
          { mode = "n", keys = "<leader>e", desc = "+explore/edit files" },
          { mode = "n", keys = "<leader>f", desc = "+find (" .. "default" .. ")" },
          { mode = "n", keys = "<leader>s", desc = "+search" },
          { mode = "n", keys = "<leader>t", desc = "+terminal" },
          { mode = "n", keys = "<leader>r", desc = "+repl" },
          { mode = "n", keys = "<leader>l", desc = "+lsp" },
          { mode = "n", keys = "<leader>n", desc = "+notes" },
          { mode = "n", keys = "<leader>g", desc = "+git" },
          { mode = "n", keys = "<leader>p", desc = "+plugins" },
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

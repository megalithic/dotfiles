local function mini_surround()
  require("mini.surround").setup({
    mappings = {
      add = "ys",
      delete = "ds",
      find = "yf",
      find_left = "yF",
      highlight = "vs",
      replace = "cs",
      update_n_lines = "",
      -- Add this only if you don't want to use extended mappings
      -- suffix_last = "",
      -- suffix_next = "",
    },
    custom_surroundings = {
      ["("] = { output = { left = "( ", right = " )" } },
      ["["] = { output = { left = "[ ", right = " ]" } },
      ["{"] = { output = { left = "{ ", right = " }" } },
      ["<"] = { output = { left = "<", right = ">" } },
      ["|"] = { output = { left = "|", right = "|" } },
      ["%"] = { output = { left = "<% ", right = " %>" } },
      ["="] = { output = { left = "<%= ", right = " %>" } },
    },
    n_lines = 500,
    search_method = "cover_or_next", -- alts: cover_or_nearest
  })

  mega.xnoremap("S", [[:<C-u>lua MiniSurround.add('visual')<CR>]])
end

local function mini_jump()
  require("mini.jump").setup()
  local mj = require("mini.jump2d")

  do
    if true then
      local m = {
        jump2d = require("mini.jump2d"),
        jump2d_char = function() return mj.start(mj.builtin_opts.single_character) end,
        jump2d_start = function() return mj.start(mj.builtin_opts.default) end,
        jump2d_query = function() return mj.start(mj.builtin_opts.query) end,
        jump2d_line = function() return mj.start(mj.builtin_opts.line_start) end,
        jump2d_word = function() return mj.start(mj.builtin_opts.word_start) end,
        jump2d_twochar = function()
          local safe_getcharstr = function(msg)
            vim.cmd("echon " .. vim.inspect(msg))
            local char1_ok, char1 = pcall(vim.fn.getcharstr) -- Allow `<C-c>` to end input
            local char2_ok, char2 = pcall(vim.fn.getcharstr) -- Allow `<C-c>` to end input
            vim.cmd([[echo '' | redraw]]) -- Clean command line

            -- Treat `<Esc>` or `<CR>` as cancel
            if not char1_ok or (char1 == "\27" or char1 == "\r") then
              vim.notify("no char1 given", L.ERROR)
              return ""
            end
            if not char2_ok or (char2 == "\27" or char2 == "\r") then
              vim.notify("no char2 given", L.ERROR)
              return ""
            end

            return char1 .. char2
          end

          local gettwocharstr = function()
            local _, char0 = pcall(vim.fn.getcharstr)
            local _, char1 = pcall(vim.fn.getcharstr)

            return char0 .. char1
          end

          -- local pattern = vim.pesc(gettwocharstr())
          local pattern = vim.pesc(safe_getcharstr("(mini.jump2d) Enter two chars: "))

          return mj.start({
            spotter = mj.gen_pattern_spotter(pattern),
            allowed_lines = {
              cursor_before = true,
              cursor_after = true,
              blank = false,
              fold = false,
            },
            allowed_windows = {
              not_current = false,
            },
            labels = "etovxqpdygfblzhckisuran",
          })
        end,
      }

      local opt = { noremap = true, silent = true }
      nnoremap("s", m.jump2d_char, opt)
      nnoremap("S", m.jump2d_twochar, opt)

      -- vim.keymap.set({ "n", "v" }, "S", m.jump2d_char, opt)
      -- vim.keymap.set({ "n", "v" }, "S", m.jump2d_start, opt)
      -- vim.keymap.set({ "n", "v" }, "S", m.jump2d_line, opt)
      -- vim.keymap.set({ "n", "v" }, "S", m.jump2d_word, opt)

      require("mini.jump2d").setup({
        -- spotter = dummy_spotter,
        -- allowed_lines = { blank = false, fold = false },
        -- hooks = {
        --   before_start = function()
        --     local first = safe_getcharstr("(mini.jump2d) Enter first character: ")
        --     if first == nil then
        --       jump2d.config.spotter = dummy_spotter
        --       return
        --     end
        --
        --     local second = safe_getcharstr("(mini.jump2d) Enter second character: ")
        --     if second == nil then
        --       jump2d.config.spotter = dummy_spotter
        --       return
        --     end
        --
        --     local pattern = make_ignorecase_pattern(first .. second)
        --     jump2d.config.spotter = jump2d.gen_pattern_spotter(pattern)
        --   end,
        -- },
        mappings = { start_jumping = "" },
        labels = "etovxqpdygfblzhckisuran",
      })
    else
      local status, jump2d = pcall(require, "mini.jump2d")
      if not status then
        print("mini.jump2d error")
        return
      end

      local safe_getcharstr = function(msg)
        vim.cmd("echon " .. vim.inspect(msg))
        local ok, res = pcall(vim.fn.getcharstr) -- Allow `<C-c>` to end input
        vim.cmd([[echo '' | redraw]]) -- Clean command line

        -- Treat `<Esc>` or `<CR>` as cancel
        if not ok or (res == "\27" or res == "\r") then return nil end

        return res
      end

      local make_ignorecase_pattern = function(word)
        local parts = {}
        for i = 1, word:len() do
          local char = word:sub(i, i)

          if char:find("^%a$") then
            -- Convert letter to a match both lower and upper case
            char = "[" .. char:lower() .. char:upper() .. "]"
          else
            char = vim.pesc(char) -- Escape non-letter characters
          end

          table.insert(parts, char)
        end

        return table.concat(parts)
      end

      local dummy_spotter = function() return {} end

      jump2d.setup({
        spotter = dummy_spotter,
        allowed_lines = { blank = false, fold = false },
        hooks = {
          before_start = function()
            local first = safe_getcharstr("(mini.jump2d) Enter first character: ")
            if first == nil then
              jump2d.config.spotter = dummy_spotter
              return
            end

            local second = safe_getcharstr("(mini.jump2d) Enter second character: ")
            if second == nil then
              jump2d.config.spotter = dummy_spotter
              return
            end

            local pattern = make_ignorecase_pattern(first .. second)
            jump2d.config.spotter = jump2d.gen_pattern_spotter(pattern)
          end,
        },
        mappings = { start_jumping = "s" },
        labels = "etovxqpdygfblzhckisuran",
      })
    end
  end
end

local function mini_pairs(opts)
  opts = opts or {}
  require("mini.pairs").setup(opts)
end

local function mini_comment()
  require("mini.comment").setup({
    hooks = {
      pre = function() require("ts_context_commentstring.internal").update_commentstring({}) end,
    },
  })
end

local function mini_ai()
  local ai = require("mini.ai")
  local gen_spec = ai.gen_spec
  ai.setup({
    n_lines = 500,
    -- search_method = "cover_or_next",
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

  local ai_map = function(text_obj, desc)
    for _, side in ipairs({ "left", "right" }) do
      for dir, d in mini_pairs({ prev = "[", next = "]" }) do
        local lhs = d .. (side == "right" and text_obj:upper() or text_obj:lower())
        for _, mode in ipairs({ "n", "x", "o" }) do
          vim.keymap.set(mode, lhs, function() ai.move_cursor(side, "a", text_obj, { search_method = dir }) end, {
            desc = dir .. " " .. desc,
          })
        end
      end
    end
  end

  ai_map("f", "function")
  ai_map("c", "class")
  ai_map("o", "block")
end

local function mini_align()
  require("mini.align").setup({
    mappings = {
      start = "ga",
      start_with_preview = "gA",
    },
  })
end

local function mini_indentscope()
  require("mini.indentscope").setup({
    symbol = "┊", -- alts: ┊│┆ ┊  ▎││ ▏▏
    draw = {
      delay = 10,
      -- animation = require("mini.indentscope").gen_animation.none(),
      animation = function() return 10 end,
    },
    options = { try_as_border = true },
  })

  vim.api.nvim_create_autocmd("FileType", {
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
      "neogitstatus",
      "DirBuf",
      "markdown",
    },
    callback = function() vim.b.miniindentscope_disable = true end,
  })
end

local function mini_hipatterns()
  -- Highlight standalone "FIXME", "HACK", "TODO", "NOTE", "WARN", "REF"
  local hipatterns = require("mini.hipatterns")
  hipatterns.setup({
    highlighters = {
      fixme = { pattern = "%f[%w]()FIXME()%f[%W]", group = "MiniHipatternsFixme" },
      hack = { pattern = "%f[%w]()HACK()%f[%W]", group = "MiniHipatternsHack" },
      warn = { pattern = "%f[%w]()WARN()%f[%W]", group = "MiniHipatternsWarn" },
      todo = { pattern = "%f[%w]()TODO()%f[%W]", group = "MiniHipatternsTodo" },
      note = { pattern = "%f[%w]()NOTE()%f[%W]", group = "MiniHipatternsNote" },
      ref = { pattern = "%f[%w]()REF()%f[%W]", group = "MiniHipatternsRef" },

      -- Highlight hex color strings (`#rrggbb`) using that color
      -- hex_color = hipatterns.gen_highlighter.hex_color(),
    },
  })
end

local function mini_clue()
  local miniclue = require("mini.clue")
  miniclue.setup({
    triggers = {
      -- Leader triggers
      { mode = "n", keys = "<Leader>" },
      { mode = "x", keys = "<Leader>" },

      -- Built-in completion
      { mode = "i", keys = "<C-x>" },

      -- `g` key
      { mode = "n", keys = "g" },
      { mode = "x", keys = "g" },

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
    },

    clues = {
      -- Enhance this by adding descriptions for <Leader> mapping groups
      miniclue.gen_clues.builtin_completion(),
      miniclue.gen_clues.g(),
      miniclue.gen_clues.marks(),
      miniclue.gen_clues.registers(),
      miniclue.gen_clues.windows(),
      miniclue.gen_clues.z(),
    },
  })
end

return {
  "echasnovski/mini.nvim",

  init = function()
    mega.nmap("<leader>bd", function() require("mini.bufremove").delete(0, false) end)
    mega.nmap("<leader>bD", function() require("mini.bufremove").delete(0, true) end)
  end,
  event = { "BufReadPost", "BufNewFile" },
  config = function()
    mini_surround()
    mini_pairs()
    mini_comment()
    mini_align()
    mini_indentscope()
    -- mini_jump()
    mini_hipatterns()
    -- mini_clue()
    -- mini_ai()
  end,
}

local mini = {
  "echasnovski/mini.nvim",
  event = "VeryLazy",
}

local specs = { mini, "JoosepAlviste/nvim-ts-context-commentstring" }

function mini.surround()
  -- require("mini.surround").setup({
  --   mappings = {
  --     add = "gza", -- Add surrounding in Normal and Visual modes
  --     delete = "gzd", -- Delete surrounding
  --     find = "gzf", -- Find surrounding (to the right)
  --     find_left = "gzF", -- Find surrounding (to the left)
  --     highlight = "gzh", -- Highlight surrounding
  --     replace = "gzr", -- Replace surrounding
  --     update_n_lines = "gzn", -- Update `n_lines`
  --   },
  -- })

  require("mini.surround").setup({
    mappings = {
      add = "ys",
      delete = "ds",
      -- find = "",
      -- find_left = "",
      -- highlight = "",
      replace = "cs",
      -- add = "yp",
      -- visual_add = "P",
      -- delete = "dp",
      -- find = "gp",
      -- find_left = "gP",
      -- replace = "cp",
      -- update_n_lines = "",
    },
    -- n_lines = 200,
    -- search_method = "cover_or_nearest", -- alts: cover_or_next
  })

  mega.xnoremap("S", [[:<C-u>lua MiniSurround.add('visual')<CR>]])
end

function mini.jump() require("mini.jump").setup({}) end

function mini.pairs() require("mini.pairs").setup({}) end

function mini.comment()
  require("mini.comment").setup({
    hooks = {
      pre = function() require("ts_context_commentstring.internal").update_commentstring({}) end,
    },
  })
end

function mini.ai()
  local ai = require("mini.ai")
  require("mini.ai").setup({
    n_lines = 500,
    -- search_method = "cover_or_next",
    custom_textobjects = {
      o = ai.gen_spec.treesitter({
        a = { "@block.outer", "@conditional.outer", "@loop.outer" },
        i = { "@block.inner", "@conditional.inner", "@loop.inner" },
      }, {}),
      f = ai.gen_spec.treesitter({ a = "@function.outer", i = "@function.inner" }, {}),
      c = ai.gen_spec.treesitter({ a = "@class.outer", i = "@class.inner" }, {}),
    },
  })

  local map = function(text_obj, desc)
    for _, side in ipairs({ "left", "right" }) do
      for dir, d in pairs({ prev = "[", next = "]" }) do
        local lhs = d .. (side == "right" and text_obj:upper() or text_obj:lower())
        for _, mode in ipairs({ "n", "x", "o" }) do
          vim.keymap.set(mode, lhs, function() ai.move_cursor(side, "a", text_obj, { search_method = dir }) end, {
            desc = dir .. " " .. desc,
          })
        end
      end
    end
  end

  map("f", "function")
  map("c", "class")
  map("o", "block")
end

function mini.config()
  mini.jump()
  mini.surround()
  mini.ai()
  mini.pairs()
  mini.comment()
  -- mini.animate()
end

function mini.animate()
  local mouse_scrolled = false
  for _, scroll in ipairs({ "Up", "Down" }) do
    local key = "<ScrollWheel" .. scroll .. ">"
    vim.keymap.set("", key, function()
      mouse_scrolled = true
      return key
    end, { remap = true, expr = true })
  end

  local animate = require("mini.animate")
  vim.go.winwidth = 20
  vim.go.winminwidth = 5

  animate.setup({
    resize = {
      timing = animate.gen_timing.linear({ duration = 100, unit = "total" }),
    },
    scroll = {
      timing = animate.gen_timing.linear({ duration = 150, unit = "total" }),
      subscroll = animate.gen_subscroll.equal({
        predicate = function(total_scroll)
          if mouse_scrolled then
            mouse_scrolled = false
            return false
          end
          return total_scroll > 1
        end,
      }),
    },
  })
end

function mini.init()
  vim.keymap.set("n", "<leader>bd", function() require("mini.bufremove").delete(0, false) end)
  vim.keymap.set("n", "<leader>bD", function() require("mini.bufremove").delete(0, true) end)
end

return specs
-- local M = { "echasnovski/mini.nvim", dependencies = "nvim-treesitter" }

-- M.config = function()
--   -- if true then return end

--     -- local miniAiDiagnostics = function()
--     --   local diagnostics = vim.diagnostic.get(0)
--     --   diagnostics = vim.tbl_map(function(diagnostic)
--     --     local from_line = diagnostic.lnum + 1
--     --     local from_col = diagnostic.col + 1
--     --     local to_line = diagnostic.end_lnum + 1
--     --     local to_col = diagnostic.end_col + 1
--     --     return {
--     --       from = { line = from_line, col = from_col },
--     --       to = { line = to_line, col = to_col },
--     --     }
--     --   end, diagnostics)

--     --   return diagnostics
--     -- end

--     -- local miniAiGitsigns = function()
--     --   local bufnr = vim.api.nvim_get_current_buf()
--     --   local hunks = require("gitsigns.cache").cache[bufnr].hunks
--     --   hunks = vim.tbl_map(function(hunk)
--     --     local from_line = hunk.added.start
--     --     local from_col = 1
--     --     local to_line = hunk.vend
--     --     local to_col = #vim.api.nvim_buf_get_lines(0, to_line - 1, to_line, false)[1] + 1
--     --     return {
--     --       from = { line = from_line, col = from_col },
--     --       to = { line = to_line, col = to_col },
--     --     }
--     --   end, hunks)

--     --   return hunks
--     -- end

--     -- REF: blatantly thieved from @Oliver-Leete
--     -- https://github.com/Oliver-Leete/Configs/blob/master/nvim/lua/mini_config.lua
--     -- https://github.com/oncomouse/dotfiles/blob/master/conf/vim/after/plugin/mini-nvim.lua
--     local gen_spec = require("mini.ai").gen_spec
--     require("mini.ai").setup({
--       custom_textobjects = {
--         -- argument
--         a = gen_spec.argument({ separators = { ",", ";" } }),
--         -- digits
--         d = { "%f[%d]%d+" },
--         -- grammer (sentence)
--         g = {
--           {
--             "\n%s*\n()().-()\n%s*\n[%s]*()", -- normal paragraphs
--             "^()().-()\n%s*\n[%s]*()", -- paragraph at start of file
--             "\n%s*\n()().-()()$", -- paragraph at end of file
--           },
--           {
--             "[%.?!][%s]+()().-[^%s].-()[%.?!]()[%s]", -- normal sentence
--             "^[%s]*()().-[^%s].-()[%.?!]()[%s]", -- sentence at start of paragraph
--             "[%.?!][%s]+()().-[^%s].-()()[\n]*$", -- sentence at end of paragraph
--             "^[%s]*()().-[^%s].-()()[%s]+$", -- sentence at end of paragraph (no final punctuation)
--           },
--         },
--         -- function
--         f = gen_spec.treesitter({
--           a = "@function.outer",
--           i = "@function.inner",
--         }),
--         F = gen_spec.treesitter({
--           a = "@function.name",
--           i = "@function.name",
--         }),
--         -- blOck
--         o = gen_spec.treesitter({
--           a = { "@block.outer", "@conditional.outer", "@loop.outer" },
--           i = { "@block.inner", "@conditional.inner", "@loop.inner" },
--         }),
--         -- paragraph
--         p = {
--           {
--             "\n%s*\n()().-()\n%s*\n[%s]*()", -- normal paragraphs
--             "^()().-()\n%s*\n[%s]*()", -- paragraph at start of file
--             "\n%s*\n()().-()()$", -- paragraph at end of file
--           },
--         },
--         -- sub-word (below w on my keyboard)
--         r = {
--           {
--             "%u[%l%d]+%f[^%l%d]",
--             "%f[%S][%l%d]+%f[^%l%d]",
--             "%f[%P][%l%d]+%f[^%l%d]",
--             "^[%l%d]+%f[^%l%d]",
--           },
--           "^().*()$",
--         },
--         -- scope
--         s = gen_spec.treesitter({
--           a = { "@function.outer", "@class.outer", "@testitem.outer" },
--           i = { "@function.inner", "@class.inner", "@testitem.inner" },
--         }),
--         S = gen_spec.treesitter({
--           a = { "@function.name", "@class.name", "@testitem.name" },
--           i = { "@function.name", "@class.name", "@testitem.name" },
--         }),
--         -- line (same key as visual line in my mappings)
--         x = { {
--           "\n()%s*().-()\n()",
--           "^()%s*().-()\n()",
--         } },
--         -- WORD
--         W = { {
--           "()()%f[%w%p][%w%p]+()[ \t]*()",
--         } },
--         -- word
--         w = { "()()%f[%w_][%w_]+()[ \t]*()" },
--       },

--       mappings = {
--         around = "a",
--         inside = "i",

--         around_next = "an",
--         inside_next = "in",
--         around_last = "al",
--         inside_last = "il",

--         goto_left = "",
--         goto_right = "",
--       },

--       n_lines = 500,

--       search_method = "cover_or_nearest",
--     })

--     require("mini.surround").setup({
--       mappings = {
--         add = "ys",
--         delete = "ds",
--         -- find = "",
--         -- find_left = "",
--         -- highlight = "",
--         replace = "cs",
--         -- add = "yp",
--         -- visual_add = "P",
--         -- delete = "dp",
--         -- find = "gp",
--         -- find_left = "gP",
--         -- replace = "cp",
--         -- update_n_lines = "",
--       },
--       n_lines = 200,
--       search_method = "cover_or_nearest", -- alts: cover_or_next
--     })

--     -- vim.api.nvim_del_keymap("x", "ys")
--     mega.xnoremap("S", [[:<C-u>lua MiniSurround.add('visual')<CR>]])
--     -- vim.keymap.del("x", "yp")

--     -- removes the difference between inner and outer treesitter
--     -- not using mini, but related to surround
--     -- nmap("dpS", "misy<c-o>Ras")
--     -- nmap("dpO", "mioy<c-o>Rao")

--     require("mini.align").setup({
--       mappings = {
--         start = "ga",
--         start_with_preview = "gA",
--       },
--     })

--     -- require("mini.indentscope").setup({
--     --   symbol = "▏", -- │ ▏
--     --   draw = {
--     --     delay = 50,
--     --     animation = require("mini.indentscope").gen_animation("none"),
--     --   },
--     -- })

--     -- require("mini.jump").setup({
--     --   -- Module mappings. Use `''` (empty string) to disable one.
--     --   mappings = {
--     --     forward = "f",
--     --     backward = "F",
--     --     forward_till = "t",
--     --     backward_till = "T",
--     --     repeat_jump = ";",
--     --   },

--     --   -- Delay values (in ms) for different functionalities. Set any of them to
--     --   -- a very big number (like 10^7) to virtually disable.
--     --   delay = {
--     --     -- Delay between jump and highlighting all possible jumps
--     --     highlight = 100,

--     --     -- Delay between jump and automatic stop if idle (no jump is done)
--     --     idle_stop = 10000000,
--     --   },
--     -- })
--     require("mini.pairs").setup({})
-- end

-- return M

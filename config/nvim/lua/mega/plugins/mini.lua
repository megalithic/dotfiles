return function()
  -- if true then return end

  vim.defer_fn(function()
    -- local miniAiDiagnostics = function()
    --   local diagnostics = vim.diagnostic.get(0)
    --   diagnostics = vim.tbl_map(function(diagnostic)
    --     local from_line = diagnostic.lnum + 1
    --     local from_col = diagnostic.col + 1
    --     local to_line = diagnostic.end_lnum + 1
    --     local to_col = diagnostic.end_col + 1
    --     return {
    --       from = { line = from_line, col = from_col },
    --       to = { line = to_line, col = to_col },
    --     }
    --   end, diagnostics)

    --   return diagnostics
    -- end

    -- local miniAiGitsigns = function()
    --   local bufnr = vim.api.nvim_get_current_buf()
    --   local hunks = require("gitsigns.cache").cache[bufnr].hunks
    --   hunks = vim.tbl_map(function(hunk)
    --     local from_line = hunk.added.start
    --     local from_col = 1
    --     local to_line = hunk.vend
    --     local to_col = #vim.api.nvim_buf_get_lines(0, to_line - 1, to_line, false)[1] + 1
    --     return {
    --       from = { line = from_line, col = from_col },
    --       to = { line = to_line, col = to_col },
    --     }
    --   end, hunks)

    --   return hunks
    -- end

    -- local gen_spec = require("mini.ai").gen_spec
    -- -- REF: blatantly thieved from @Oliver-Leete
    -- -- https://github.com/Oliver-Leete/Configs/blob/master/nvim/lua/mini_config.lua
    -- require("mini.ai").setup({
    --   custom_textobjects = {
    --     -- argument
    --     a = gen_spec.argument({ separators = { ",", ";" } }),
    --     -- digits
    --     d = { "%f[%d]%d+" },
    --     -- diagnostics (errors)
    --     -- e = miniAiDiagnostics,
    --     -- grammer (sentence)
    --     g = {
    --       {
    --         "\n%s*\n()().-()\n%s*\n[%s]*()", -- normal paragraphs
    --         "^()().-()\n%s*\n[%s]*()", -- paragraph at start of file
    --         "\n%s*\n()().-()()$", -- paragraph at end of file
    --       },
    --       {
    --         "[%.?!][%s]+()().-[^%s].-()[%.?!]()[%s]", -- normal sentence
    --         "^[%s]*()().-[^%s].-()[%.?!]()[%s]", -- sentence at start of paragraph
    --         "[%.?!][%s]+()().-[^%s].-()()[\n]*$", -- sentence at end of paragraph
    --         "^[%s]*()().-[^%s].-()()[%s]+$", -- sentence at end of paragraph (no final punctuation)
    --       },
    --     },
    --     -- function
    --     F = gen_spec.treesitter({
    --       a = "@function.outer",
    --       i = "@function.inner",
    --     }),
    --     -- git hunks
    --     -- h = miniAiGitsigns,
    --     -- blOck
    --     o = gen_spec.treesitter({
    --       a = { "@block.outer", "@conditional.outer", "@loop.outer" },
    --       i = { "@block.inner", "@conditional.inner", "@loop.inner" },
    --     }),
    --     -- paragraph
    --     p = {
    --       {
    --         "\n%s*\n()().-()\n%s*\n[%s]*()", -- normal paragraphs
    --         "^()().-()\n%s*\n[%s]*()", -- paragraph at start of file
    --         "\n%s*\n()().-()()$", -- paragraph at end of file
    --       },
    --     },
    --     -- sub-word (below w on my keyboard)
    --     r = {
    --       {
    --         "%u[%l%d]+%f[^%l%d]",
    --         "%f[%S][%l%d]+%f[^%l%d]",
    --         "%f[%P][%l%d]+%f[^%l%d]",
    --         "^[%l%d]+%f[^%l%d]",
    --       },
    --       "^().*()$",
    --     },
    --     -- scope
    --     s = gen_spec.treesitter({
    --       a = { "@function.outer", "@class.outer" },
    --       i = { "@function.inner", "@class.inner" },
    --     }),
    --     -- line (same key as visual line in my mappings)
    --     x = { {
    --       "\n()%s*().-()\n()",
    --       "^()%s*().-()\n()",
    --     } },
    --     -- WORD
    --     W = { {
    --       "()()%f[%w%p][%w%p]+()[ \t]*()",
    --     } },
    --     -- word
    --     w = { "()()%f[%w_][%w_]+()[ \t]*()" },
    --     -- key or value (needs a lot of work)
    --     -- z = gen_spec.argument({ brackets = { '%b()'}, separators = {',', ';', '=>'}}),
    --     -- chunk (as in from vim-textobj-chunk)
    --     -- z = {
    --     --     '\n.-%b{}',
    --     --     '\n().-%{\n().*()\n.*%}()'
    --     -- },
    --   },

    --   mappings = {
    --     around = "a",
    --     inside = "i",

    --     around_next = "an",
    --     inside_next = "in",
    --     around_last = "al",
    --     inside_last = "il",

    --     goto_left = "",
    --     goto_right = "",
    --   },

    --   n_lines = 500,

    --   search_method = "cover_or_nearest",
    -- })

    -- require("mini.indentscope").setup({
    --   symbol = "▏", -- │ ▏
    --   draw = {
    --     delay = 50,
    --     animation = require("mini.indentscope").gen_animation("none"),
    --   },
    -- })

    require("mini.jump").setup({
      -- Module mappings. Use `''` (empty string) to disable one.
      mappings = {
        forward = "f",
        backward = "F",
        forward_till = "t",
        backward_till = "T",
        repeat_jump = ";",
      },

      -- Delay values (in ms) for different functionalities. Set any of them to
      -- a very big number (like 10^7) to virtually disable.
      delay = {
        -- Delay between jump and highlighting all possible jumps
        highlight = 100,

        -- Delay between jump and automatic stop if idle (no jump is done)
        idle_stop = 10000000,
      },
    })
  end, 0)
end

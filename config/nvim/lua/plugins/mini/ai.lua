-- lua/plugins/mini/ai.lua
-- Extended text objects (around/inside)
-- Reference: https://github.com/drowning-cat/nvim/blob/main/plugin/30_mini_ai%2Bsurround.lua

return {
  "echasnovski/mini.ai",
  event = "VeryLazy",
  opts = function()
    local ai = require("mini.ai")
    local gen_spec = ai.gen_spec

    return {
      n_lines = 500,
      search_method = "cover_or_next",
      custom_textobjects = {
        -- Treesitter-based
        f = gen_spec.treesitter({ a = "@function.outer", i = "@function.inner" }),
        c = gen_spec.treesitter({ a = "@class.outer", i = "@class.inner" }),
        o = gen_spec.treesitter({
          a = { "@block.outer", "@conditional.outer", "@loop.outer" },
          i = { "@block.inner", "@conditional.inner", "@loop.inner" },
        }),

        -- Argument with flexible separator
        a = gen_spec.argument({ separator = ",%s*" }),

        -- HTML/XML tags (improved pattern)
        t = { "<([%p%w]-)%f[^<%p%w][^<>]->.-</%1>", "^<.->().*()</[^/]->$" },

        -- Entire buffer
        g = function()
          local from = { line = 1, col = 1 }
          local to = {
            line = vim.fn.line("$"),
            col = math.max(vim.fn.getline("$"):len(), 1),
          }
          return { from = from, to = to }
        end,

        -- Subword (camelCase, snake_case, kebab-case parts)
        -- e.g., in "myVariableName": "my", "Variable", "Name"
        e = function(ai_type)
          local patterns = {
            -- camelCase: lowercase followed by uppercase
            "%u[%l%d]+",
            -- word at start or after separator
            "%f[%w][%l%d]+",
            -- ALLCAPS
            "%u%u+%f[^%u]",
          }

          local line = vim.fn.getline(".")
          local cursor_col = vim.fn.col(".")

          -- Find subword under/near cursor
          for _, pattern in ipairs(patterns) do
            local s, e = 1, 0
            while true do
              s, e = line:find(pattern, e + 1)
              if not s then break end
              if s <= cursor_col and cursor_col <= e then
                local from = { line = vim.fn.line("."), col = s }
                local to = { line = vim.fn.line("."), col = e }
                if ai_type == "i" then
                  return { from = from, to = to }
                else
                  -- "around" includes trailing separator if present
                  local after = line:sub(e + 1, e + 1)
                  if after:match("[_%-/\\]") then
                    to.col = e + 1
                  end
                  return { from = from, to = to }
                end
              end
            end
          end
          return nil
        end,
      },

      mappings = {
        around = "a",
        inside = "i",
        around_next = "an",
        inside_next = "in",
        around_last = "al",
        inside_last = "il",
        goto_left = "g[",
        goto_right = "g]",
      },
    }
  end,
}

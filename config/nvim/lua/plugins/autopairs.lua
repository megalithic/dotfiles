return {
  {
    -- NOTE: Maybe replace with ultimate-autopair after the following issue is
    -- fixed: https://github.com/altermo/ultimate-autopair.nvim/issues/5.
    "windwp/nvim-autopairs",
    event = { "InsertEnter" },
    opts = {
      check_ts = true,
      enable_moveright = true,
      -- fast_wrap = {
      --   map = "<c-e>",
      -- },
    },
    config = function(_, opts)
      local npairs = require("nvim-autopairs")
      npairs.setup(opts)

      local Rule = require("nvim-autopairs.rule")
      local cond = require("nvim-autopairs.conds")
      local ts_conds = require("nvim-autopairs.ts-conds")

      npairs.add_rules(require("nvim-autopairs.rules.endwise-elixir"))
      npairs.add_rules(require("nvim-autopairs.rules.endwise-lua"))
      npairs.add_rules(require("nvim-autopairs.rules.endwise-ruby"))

      -- rule for: `(|)` -> Space -> `( | )` and associated deletion options
      local brackets = { { "(", ")" }, { "[", "]" }, { "{", "}" } }
      local bracket_pairs = vim.tbl_map(function(pair)
        return pair[1] .. pair[2]
      end, brackets)
      npairs.add_rules({
        Rule(" ", " ", "-markdown")
          :with_pair(function(opts)
            local pair = opts.line:sub(opts.col - 1, opts.col)
            return vim.list_contains(bracket_pairs, pair)
          end)
          :with_move(cond.none())
          :with_cr(cond.none())
          :with_del(function(opts)
            -- We only want to delete the pair of spaces when the cursor is as such: ( | )
            local col = vim.api.nvim_win_get_cursor(0)[2]
            local context = opts.line:sub(col - 1, col + 2)
            return vim.list_contains({
              brackets[1][1] .. "  " .. brackets[1][2],
              brackets[2][1] .. "  " .. brackets[2][2],
              brackets[3][1] .. "  " .. brackets[3][2],
            }, context)
          end),
      })

      local function is_in_tasks_section()
        local cursor_line = vim.api.nvim_win_get_cursor(0)[1]
        local lines = vim.api.nvim_buf_get_lines(0, 0, cursor_line, false)

        local in_tasks = false
        for _, line in ipairs(lines) do
          local heading = line:match("^##%s+(.+)$")
          if heading then
            in_tasks = heading:lower():match("^tasks") ~= nil
          end
        end
        return in_tasks
      end

      local function is_typing_checkbox(rule_opts)
        local before = rule_opts.line:sub(1, rule_opts.col - 1)
        return before:match("%s*%-%s*$") ~= nil
      end

      local bracket_rules = npairs.get_rules("[")
      if bracket_rules and bracket_rules[1] then
        bracket_rules[1]:with_pair(function(rule_opts)
          if vim.bo.filetype ~= "markdown" then
            return nil
          end
          if is_in_tasks_section() or is_typing_checkbox(rule_opts) then
            return nil
          end
          return false
        end)
      end

      for _, bracket in pairs(brackets) do
        npairs.add_rules({
          -- add move for brackets with pair of spaces inside
          Rule(bracket[1] .. " ", " " .. bracket[2])
            :with_pair(function() return false end)
            :with_del(function() return false end)
            :with_move(function(opts) return opts.prev_char:match(".%" .. bracket[2]) ~= nil end)
            :use_key(bracket[2]),

          -- add closing brackets even if next char is '$'
          Rule(bracket[1], bracket[2]):with_pair(cond.after_text("$")),

          -- `()|` -> <BS> -> `|`
          Rule(bracket[1] .. bracket[2], "")
            :with_pair(function() return false end)
            :with_cr(function() return false end),
        })
      end

      -- add and delete pairs of dollar signs (if not escaped) in markdown
      npairs.add_rule(Rule("$", "$", "markdown")
        :with_move(
          function(opts)
            return opts.next_char == opts.char
              and ts_conds.is_ts_node({
                "inline_formula",
                "displayed_equation",
                "math_environment",
              })(opts)
          end
        )
        :with_pair(ts_conds.is_not_ts_node({
          "inline_formula",
          "displayed_equation",
          "math_environment",
        }))
        :with_pair(cond.not_before_text("\\")))

      npairs.add_rule(Rule("/**", "  */"):with_pair(cond.not_after_regex(
        --> INJECT: luap
        ".-%*/",
        -1
      )):set_end_pair_length(3))

      npairs.add_rule(
        Rule("**", "**", "markdown"):with_move(
          function(opts) return cond.after_text("*")(opts) and cond.not_before_text("\\")(opts) end
        )
      )
    end,
  },
  -- {
  --   "windwp/nvim-autopairs",
  --   event = "InsertEnter",
  --   opts = {
  --     check_ts = true,
  --     enable_moveright = true,
  --     -- fast_wrap = {
  --     --   map = "<c-e>",
  --     -- },
  --   },
  --   config = function(_, opts)
  --     local npairs = require("nvim-autopairs")
  --     local Rule = require("nvim-autopairs.rule")
  --     local cond = require("nvim-autopairs.conds")
  --     npairs.setup(opts)
  --
  --     npairs.add_rules(require("nvim-autopairs.rules.endwise-elixir"))
  --     npairs.add_rules(require("nvim-autopairs.rules.endwise-lua"))
  --     npairs.add_rules(require("nvim-autopairs.rules.endwise-ruby"))
  --
  --     -- Context-aware bracket pairing for markdown:
  --     -- In "Tasks" section: autopair [ -> [] (for checkboxes like `- [ ]`)
  --     -- In other sections (Notes, Links, etc.): don't autopair [ (for wiki links [[]])
  --     --
  --     -- Strategy: Modify the default [ rule to check markdown context
  --     local function is_in_tasks_section()
  --       local cursor_line = vim.api.nvim_win_get_cursor(0)[1]
  --       local lines = vim.api.nvim_buf_get_lines(0, 0, cursor_line, false)
  --
  --       local in_tasks = false
  --       for _, line in ipairs(lines) do
  --         -- Check for section headings (## Something)
  --         local heading = line:match("^##%s+(.+)$")
  --         if heading then
  --           -- Case-insensitive check for "Tasks" section
  --           in_tasks = heading:lower():match("^tasks") ~= nil
  --         end
  --       end
  --       return in_tasks
  --     end
  --
  --     -- Also check if we're at the start of a task line (- [ ] pattern)
  --     local function is_typing_checkbox(rule_opts)
  --       -- Check if line before cursor looks like start of a task: "- ["
  --       local before = rule_opts.line:sub(1, rule_opts.col - 1)
  --       return before:match("%s*%-%s*$") ~= nil
  --     end
  --
  --     -- Get the default [ rule and add our condition
  --     -- The condition returns: true = pair, false = don't pair, nil = check next condition
  --     local bracket_rules = npairs.get_rules("[")
  --     if bracket_rules and bracket_rules[1] then
  --       bracket_rules[1]:with_pair(function(rule_opts)
  --         -- Non-markdown: use default behavior (allow pairing)
  --         if vim.bo.filetype ~= "markdown" then
  --           return nil -- Pass to next condition (default behavior)
  --         end
  --         -- Markdown: only pair if in Tasks section OR typing a checkbox
  --         if is_in_tasks_section() or is_typing_checkbox(rule_opts) then
  --           return nil -- Allow pairing (pass to default conditions)
  --         end
  --         -- In Notes/Links/etc sections: don't pair (for wiki links)
  --         return false
  --       end)
  --     end
  --   end,
  -- },
}

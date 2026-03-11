return {
  {
    "windwp/nvim-autopairs",
    event = "InsertEnter",
    opts = {
      check_ts = true,
      enable_moveright = true,
      -- fast_wrap = {
      --   map = "<c-e>",
      -- },
    },
    config = function(_, opts)
      local npairs = require("nvim-autopairs")
      local Rule = require("nvim-autopairs.rule")
      local cond = require("nvim-autopairs.conds")
      npairs.setup(opts)

      npairs.add_rules(require("nvim-autopairs.rules.endwise-elixir"))
      npairs.add_rules(require("nvim-autopairs.rules.endwise-lua"))
      npairs.add_rules(require("nvim-autopairs.rules.endwise-ruby"))

      -- Context-aware bracket pairing for markdown:
      -- In "Tasks" section: autopair [ -> [] (for checkboxes like `- [ ]`)
      -- In other sections (Notes, Links, etc.): don't autopair [ (for wiki links [[]])
      --
      -- Strategy: Modify the default [ rule to check markdown context
      local function is_in_tasks_section()
        local cursor_line = vim.api.nvim_win_get_cursor(0)[1]
        local lines = vim.api.nvim_buf_get_lines(0, 0, cursor_line, false)

        local in_tasks = false
        for _, line in ipairs(lines) do
          -- Check for section headings (## Something)
          local heading = line:match("^##%s+(.+)$")
          if heading then
            -- Case-insensitive check for "Tasks" section
            in_tasks = heading:lower():match("^tasks") ~= nil
          end
        end
        return in_tasks
      end

      -- Also check if we're at the start of a task line (- [ ] pattern)
      local function is_typing_checkbox(rule_opts)
        -- Check if line before cursor looks like start of a task: "- ["
        local before = rule_opts.line:sub(1, rule_opts.col - 1)
        return before:match("%s*%-%s*$") ~= nil
      end

      -- Get the default [ rule and add our condition
      -- The condition returns: true = pair, false = don't pair, nil = check next condition
      local bracket_rules = npairs.get_rules("[")
      if bracket_rules and bracket_rules[1] then
        bracket_rules[1]:with_pair(function(rule_opts)
          -- Non-markdown: use default behavior (allow pairing)
          if vim.bo.filetype ~= "markdown" then
            return nil -- Pass to next condition (default behavior)
          end
          -- Markdown: only pair if in Tasks section OR typing a checkbox
          if is_in_tasks_section() or is_typing_checkbox(rule_opts) then
            return nil -- Allow pairing (pass to default conditions)
          end
          -- In Notes/Links/etc sections: don't pair (for wiki links)
          return false
        end)
      end
    end,
  },
}

return function()
  local system = vim.fn.system

  local function terminal_notifier(cmd, exit)
    -- local tmux_display_message = require("mega.utils").ext.tmux.display_message

    if exit == 0 then
      vim.notify("Test(s) passed.", vim.log.levels.INFO)
      -- tmux_display_message("Success!")
      system(string.format([[terminal-notifier -title "Neovim" -subtitle "%s" -message "Success\!"]], cmd))
    else
      vim.notify("Test(s) failed.", vim.log.levels.ERROR)
      -- tmux_display_message("Failure!")
      system(string.format([[terminal-notifier -title "Neovim" -subtitle "%s" -message "Failure\!"]], cmd))
    end
  end

  -- REF:
  -- neat ways to detect jest things
  -- https://github.com/weilbith/vim-blueplanet/blob/master/pack/plugins/start/test_/autoload/test/typescript/jest.vim
  -- https://github.com/roginfarrer/dotfiles/blob/main/nvim/.config/nvim/lua/rf/plugins/vim-test.lua#L19
  vim.g["test#strategy"] = "neovim"
  vim.g["test#javascript#jest#file_pattern"] = "\v(__tests__/.*|(spec|test)).(js|jsx|coffee|ts|tsx)$"
  vim.g["test#ruby#use_binstubs"] = 0
  vim.g["test#ruby#bundle_exec"] = 0
  vim.g["test#filename_modifier"] = ":."
  vim.g["test#preserve_screen"] = 0

  local term_opts = function(cmd, extra_opts)
    return vim.tbl_extend("force", {
      winnr = vim.fn.winnr(),
      cmd = cmd,
      pre_cmd = "eval $(desk load)",
      notifier = terminal_notifier,
      temp = true,
      start_insert = false,
      focus_on_open = false,
      move_on_direction_change = false,
      on_exit = function(job_id, exit_code, event, job_cmd, caller_winnr, term_buf_id)
        P(fmt("test run exited with: %s", I({ job_id, exit_code, event, job_cmd, caller_winnr, term_buf_id })))
      end,
    }, extra_opts or {})
  end

  vim.g["test#custom_strategies"] = {
    termsplit = function(cmd) mega.term.open(term_opts(cmd)) end,
    termvsplit = function(cmd) mega.term.open(term_opts(cmd, { direction = "vertical" })) end,
    termfloat = function(cmd) mega.term.open(term_opts(cmd, { direction = "float", focus_on_open = true })) end,
  }

  vim.g["test#strategy"] = {
    nearest = "termsplit",
    file = "termfloat",
    suite = "termfloat",
    last = "termsplit",
  }
end

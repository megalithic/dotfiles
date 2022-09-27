return function()
  local fmt = string.format
  local system = vim.fn.system

  local function terminal_notifier(cmd, exit)
    local tmux_display_message = require("mega.utils").ext.tmux.display_message

    if exit == 0 then
      vim.notify("Test(s) passed.", "info")
      tmux_display_message("Success!")
      system(string.format([[terminal-notifier -title "Neovim" -subtitle "%s" -message "Success\!"]], cmd))
    else
      vim.notify("Test(s) failed.", "error")
      tmux_display_message("Failure!")
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

  vim.g["test#custom_strategies"] = {
    termsplit = function(cmd)
      mega.term.open({
        winnr = vim.fn.winnr(),
        cmd = cmd,
        precmd = "eval $(desk load)",
        notifier = terminal_notifier,
        temp = true,
      })
    end,
    termfloat = function(cmd)
      mega.term.open({
        winnr = vim.fn.winnr(),
        cmd = cmd,
        direction = "float",
        precmd = "eval $(desk load)",
        notifier = terminal_notifier,
        temp = true,
      })
    end,
    termvsplit = function(cmd)
      mega.term.open({
        winnr = vim.fn.winnr(),
        cmd = cmd,
        precmd = "eval $(desk load)",
        direction = "vertical",
        notifier = terminal_notifier,
        temp = true,
      })
    end,
  }

  vim.g["test#strategy"] = {
    nearest = "termsplit",
    file = "termfloat",
    suite = "termfloat",
    last = "termsplit",
  }
end

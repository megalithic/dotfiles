return function()
  local fmt = string.format
  local system = vim.fn.system

  local function terminal_notifier(cmd, exit)
    local tmux_display_message = require("mega.utils").ext.tmux.display_message

    if exit == 0 then
      print("Success!")
      tmux_display_message("Success!")
      system(string.format([[terminal-notifier -title "Neovim" -subtitle "%s" -message "Success\!"]], cmd))
    else
      print("Failure!")
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

  local tt = require("toggleterm")
  local tterms = require("toggleterm.terminal")
  vim.g["test#custom_strategies"] = {
    toggleterm = function(cmd)
      -- P(fmt("cmd: %s", cmd))
      tt.exec(cmd, nil, nil, nil, "vertical")
      P(fmt("cmd: %s", cmd))
      -- tt.exec(cmd)
    end,
    toggleterm_f = function(cmd)
      P(fmt("f_cmd: %s", cmd))
      tt.exec(cmd, nil, nil, nil, "float")
    end,
    toggleterm_h = function(cmd)
      P(fmt("h_cmd: %s", cmd))
      tt.exec(cmd, nil, nil, nil, "horizontal")
    end,
    -- toggleterm_f = function(cmd)
    --   P(fmt("f_cmd: %s", cmd))
    --   tt.exec_command(fmt([[cmd="%s" direction=float]], cmd))
    -- end,
    -- toggleterm_h = function(cmd)
    --   P(fmt("h_cmd: %s", cmd))
    --   tt.exec_command(fmt([[cmd="%s" direction=horizontal]], cmd))
    -- end,
    toggleterm_close = function(cmd)
      local term_id = 0
      tt.exec(cmd, term_id)
      tterms.get_or_create_term(term_id):close()
    end,
    termsplit = function(cmd)
      mega.term_open({
        winnr = vim.fn.winnr(),
        cmd = cmd,
        precmd = "eval $(desk load)",
        notifier = terminal_notifier,
      })
    end,
    termvsplit = function(cmd)
      mega.term_open({
        winnr = vim.fn.winnr(),
        cmd = cmd,
        precmd = "eval $(desk load)",
        direction = "vertical",
        notifier = terminal_notifier,
      })
    end,
  }

  vim.g["test#strategy"] = {
    nearest = "termsplit",
    file = "toggleterm_f",
    suite = "toggleterm_f",
    last = "toggleterm_f",
  }
end

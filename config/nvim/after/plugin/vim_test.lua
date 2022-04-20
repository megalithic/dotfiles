local fmt = string.format

mega.conf("vim-test", function()
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
    vtermsplit = function(cmd)
      vim.cmd(
        fmt("vert new | set filetype=test | call termopen(['zsh', '-ci', 'eval $(desk load); %s'], {'curwin':1})", cmd)
      )
    end,
    toggleterm = function(cmd)
      P(fmt("cmd: %s", cmd))
      require("toggleterm").exec(cmd)
    end,
    toggleterm_f = function(cmd)
      P(fmt("f_cmd: %s", cmd))
      require("toggleterm").exec_command(fmt([[cmd="%s" direction=float]], cmd))
    end,
    toggleterm_h = function(cmd)
      P(fmt("h_cmd: %s", cmd))
      require("toggleterm").exec_command(fmt([[cmd="%s" direction=horizontal]], cmd))
    end,
    termsplit = function(cmd)
      --FIXME: should I get the bufnr instead??
      local winnr = vim.fn.winnr()
      mega.term_open({
        winnr = winnr,
        cmd = cmd,
        precmd = "eval $(desk load)",
      })
    end,
    termvsplit = function(cmd)
      --FIXME: should I get the bufnr instead??
      local winnr = vim.fn.winnr()
      mega.term_open({
        winnr = winnr,
        cmd = cmd,
        precmd = "eval $(desk load)",
        direction = "vert",
      })
    end,
  }

  vim.g["test#strategy"] = {
    nearest = "termsplit",
    file = "toggleterm_f",
    suite = "toggleterm_f",
    last = "toggleterm_f",
  }
end)

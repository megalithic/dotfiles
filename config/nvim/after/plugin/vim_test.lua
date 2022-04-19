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
    termsplit = function(cmd)
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
    trial = function(cmd)
      local system = vim.fn.system

      local terminal_notifier_notifier = function(c, exit)
        if exit == 0 then
          P("Success!")
          system(string.format([[terminal-notifier -title "Neovim" -subtitle "%s" -message "Success\!"]], c))
        else
          P("Failure!")
          system(string.format([[terminal-notifier -title "Neovim" -subtitle "%s" -message "Failure\!"]], c))
        end
      end

      local winnr = vim.fn.winnr()
      local nil_buf_id = 999999
      local term_buf_id = nil_buf_id

      local function open(c, w, n)
        -- delete the current buffer if it's still open
        if vim.api.nvim_buf_is_valid(term_buf_id) then
          vim.api.nvim_buf_delete(term_buf_id, { force = true })
          term_buf_id = nil_buf_id
        end

        vim.cmd("botright new | lua vim.api.nvim_win_set_height(0, 15)")
        term_buf_id = vim.api.nvim_get_current_buf()
        vim.opt_local.filetype = "terminal"
        vim.opt_local.number = false
        vim.opt_local.cursorline = false
        nmap("q", function()
          vim.api.nvim_buf_delete(term_buf_id, { force = true })
          term_buf_id = nil_buf_id
        end, { buffer = term_buf_id })

        vim.fn.termopen(c, {
          on_exit = function(_jobid, exit_code, _event)
            if n then
              n(c, exit_code)
            end

            if exit_code == 0 then
              vim.api.nvim_buf_delete(term_buf_id, { force = true })
              term_buf_id = nil_buf_id
            end
          end,
        })

        print(c)

        vim.cmd([[normal! G]])
        vim.cmd(w .. [[wincmd w]])
      end

      open(fmt("eval $(desk load); %s", cmd), winnr, terminal_notifier_notifier)
    end,
  }

  vim.g["test#strategy"] = {
    nearest = "trial",
    file = "toggleterm_f",
    suite = "toggleterm_f",
    last = "toggleterm_f",
  }
end)

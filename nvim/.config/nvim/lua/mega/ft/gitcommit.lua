return function(_) -- bufnr
  -- _G.gitcommit_exec = function()
    vim.cmd([[normal gg0]])

    vim.bo.textwidth = 72
    vim.wo.colorcolumn = "72"
    vim.wo.spell = true
    vim.bo.spelllang = "en_us"
    vim.wo.list = false
    vim.wo.number = false
    vim.wo.relativenumber = false
    vim.wo.wrap = true
    vim.wo.linebreak = true

    vim.cmd([[setlocal comments+=fb:*]])
    vim.cmd([[setlocal comments+=fb:-]])
    vim.cmd([[setlocal comments+=fb:+]])
    vim.cmd([[setlocal comments+=b:>]])

    vim.cmd([[setlocal formatoptions+=c]])
    vim.cmd([[setlocal formatoptions+=q]])
  -- end

  -- mega.augroup(
  --   "mega.git",
  --   function()
  --     au([[autocmd!]])
  --     au([[autocmd! BufEnter,WinEnter,FocusGained *COMMIT_EDITMSG,*PULLREQ_EDITMSG exe v:lua.gitcommit_exec()]])
  --     au([[autocmd! FileType gitcommit,gitrebase exe v:lua.gitcommit_exec()]])
  --   end
  -- )
end

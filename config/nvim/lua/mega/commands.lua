local command = vim.api.nvim_create_user_command

vim.cmd([[
  command! -nargs=1 Rg lua require("telescope.builtin").grep_string({ search = vim.api.nvim_eval('"<args>"') })
]])

command("Todo", [[noautocmd silent! grep! 'TODO\|FIXME\|BUG\|HACK' | copen]], {})
command("ReloadModule", function(tbl) require("plenary.reload").reload_module(tbl.args) end, {
  nargs = 1,
})
command(
  "DuplicateFile",
  [[noautocmd clear | silent! execute "!cp '%:p' '%:p:h/%:t:r-copy.%:e'"<bar>redraw<bar>echo "Copied " . expand('%:t') . ' to ' . expand('%:t:r') . '-copy.' . expand('%:e')]],
  {}
)
command("SaveAsFile", [[noautocmd clear | :execute "saveas %:p:h/" .input('save as -> ') | :e ]], {})
command("RenameFile", [[noautocmd clear | :execute "Rename " .input('rename to -> ') | :e ]], {})
-- command("Rename", [[RenameFile]])
--
command("Flash", function() mega.blink_cursorline() end, {})
command("P", function(opts)
  vim.g.debug_enabled = true
  vim.cmd(fmt("lua P(%s)", opts.args))
  vim.g.debug_enabled = false
end, { nargs = "*" })
command("D", function(opts)
  vim.g.debug_enabled = true
  vim.cmd(fmt("lua d(%s)", opts.args))
  vim.g.debug_enabled = false
end, { nargs = "*" })
-- command("Noti", [[Notifications]])
command("Noti", [[Messages | Notifications]], {})
command("noti", [[Messages | Notifications]], {})
command("Mess", [[messages]], {})
command("mess", [[messages]], {})

_G.fzf_enter = function()
  vim.o.ruler = false
  vim.o.number = false
  vim.o.relativenumber = false
  vim.o.signcolumn = "no"
end

_G.fzf_leave = function()
  vim.o.ruler = true
  vim.o.number = true
  vim.o.relativenumber = true
  vim.o.signcolumn = "yes:2"
end

_G.fzf_enter()

mega.augroup("mega.ftplugin.fzf", {
  {
    events = { "BufLeave", "TermClose" },
    targets = { [[\v[0-9]+;#FZF$]] },
    command = "lua fzf_leave()",
  },
})

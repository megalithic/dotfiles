-- loads a local .nvimrc for our current working directory
local local_vimrc = vim.fn.getcwd() .. "/.nvimrc"
if vim.loop.fs_stat(local_vimrc) then
  if vim.bo.filetype == "lua" then
    vim.cmd.luafile(local_vimrc)
  elseif vim.bo.filetype == "vim" then
    vim.cmd.source(local_vimrc)
  end

  vim.notify(fmt("Read **%s**", local_vimrc), vim.log.levels.INFO, {
    title = "Nvim (.nvimrc)",
  })
end

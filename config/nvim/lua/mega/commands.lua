local fmt = string.format
local Methods = vim.lsp.protocol.Methods
local command = function(lhs, rhs, opts)
  opts = vim.tbl_extend("force", opts, {})
  vim.api.nvim_create_user_command(lhs, rhs, opts)
end

-- command("Rg", function(opts) require("telescope.builtin").live_grep_string({ search = vim.api.nvim_eval(fmt("%s", opts.args)) }) end, { nargs = "*" })
-- vim.cmd([[
--   command! -nargs=1 Rg lua require("telescope.builtin").grep_string({ search = vim.api.nvim_eval('"<args>"') })
-- ]])

command("Todo", [[noautocmd silent! grep! 'TODO\|FIXME\|BUG\|HACK' | copen]], {})
command("ReloadModule", function(tbl) require("plenary.reload").reload_module(tbl.args) end, {
  nargs = 1,
})
command("Rg", function(opts) require("telescope.builtin").grep_string({ search = vim.api.nvim_eval("\"<args>\"") }) end, { nargs = "*" })
command(
  "DuplicateFile",
  [[noautocmd clear | silent! execute "!cp '%:p' '%:p:h/%:t:r-copy.%:e'"<bar>redraw<bar>echo "Copied " . expand('%:t') . ' to ' . expand('%:t:r') . '-copy.' . expand('%:e')]],
  {}
)
command("SaveAsFile", [[noautocmd clear | :execute "saveas %:p:h/" .input('save as -> ') | :e ]], {})
command("RenameFile", [[noautocmd clear | :execute "Rename " .input('rename to -> ') | :e ]], {})
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
vim.cmd.cnoreabbrev("noti Noti")
command("Mess", [[messages]], {})
vim.cmd.cnoreabbrev("mess Mess")
command("LogRead", function(_opts) vim.cmd.vnew("/tmp/nlog") end, {})
command("Capture", function(opts)
  vim.fn.writefile(vim.split(vim.api.nvim_exec2(opts.args, { output = true }).output, "\n"), "/tmp/nvim_out.capture")
  vim.cmd.split("/tmp/nvim_out.capture")
end, { nargs = "*", complete = "command" })

command("Delete", function()
  local fp = vim.api.nvim_buf_get_name(0)
  local ok, err = vim.uv.fs_unlink(fp)
  if not ok then
    vim.notify(table.concat({ fp, err }, "\n"), vim.log.levels.ERROR, { title = ":Delete failed" })
    vim.cmd.bwipeout()
  else
    require("mega.utils").buf_close()
    vim.notify(fp, vim.log.levels.INFO, { title = ":Delete succeeded" })
  end
end, { desc = "Delete current file" })

command("Rename", function(opts)
  local prevpath = vim.fn.expand("%:p")
  local prevname = vim.fn.expand("%:t")
  local prevdir = vim.fn.expand("%:p:h")
  vim.ui.input({
    prompt = "New file name: ",
    default = opts.fargs[1] or prevname,
    completion = "file",
  }, function(next)
    if not next or next == "" or next == prevname then return end
    local nextpath = ("%s/%s"):format(prevdir, next)

    local changes, clients
    if type(prevpath) == "string" then
      clients = vim.lsp.get_clients()
      changes = {
        files = {
          {
            oldUri = vim.uri_from_fname(prevpath),
            newUri = vim.uri_from_fname(nextpath),
          },
        },
      }

      for _, client in ipairs(clients) do
        if client:supports_method(Methods.workspace_willRenameFiles) then
          local resp = client.request_sync(Methods.workspace_willRenameFiles, changes, 1000, 0)
          if resp and resp.result ~= nil then vim.lsp.util.apply_workspace_edit(resp.result, client.offset_encoding) end
        end
      end
    end

    vim.cmd.file(nextpath) -- rename buffer, preserving undo
    vim.cmd("noautocmd write") -- save
    vim.cmd("edit") -- update file syntax if you changed extension

    if changes ~= nil and #clients and type(prevpath) == "string" then
      for _, client in ipairs(clients) do
        if client:supports_method(Methods.workspace_didRenameFiles) then client:notify(Methods.workspace_didRenameFiles, changes) end
      end
    else
      return
    end

    local ok, err = vim.uv.fs_unlink(prevpath)
    if not ok then vim.notify(table.concat({ prevpath, err }, "\n"), vim.log.levels.ERROR, { title = ":Rename failed to delete orig" }) end
  end)
end, {
  desc = "Rename current file",
  nargs = "?",
  complete = function() return { vim.fn.expand("%") } end,
})

-- run :AICommitMsg from a commit buffer to get an AI generated commit message
command("AICommitMsg", function()
  local text = vim.fn.system("$DOTS/bin/ai_commit_msg.sh")
  vim.api.nvim_put(vim.split(text, "\n", {}), "", false, true)
end, {})

-- stage everything, then open a commit buffer with an AI generated commit message
command("AICommit", function()
  vim.fn.system("git add .")
  vim.cmd("Git commit")
  vim.cmd("AICommitMsg")
end, {})

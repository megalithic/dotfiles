local fmt = string.format
local Methods = vim.lsp.protocol.Methods
local U = require("config.utils")

local M = {}

-- Create user command
function M.command(cmd, func, opts)
  opts = opts or {}

  local bufnr = nil
  if opts.buffer == true then
    bufnr = 0
  elseif type(opts.buffer) == "number" then
    bufnr = opts.buffer
  end
  opts.buffer = nil

  if bufnr then
    vim.api.nvim_buf_create_user_command(bufnr, cmd, func, opts)
  else
    vim.api.nvim_create_user_command(cmd, func, opts)
  end
end

local command = M.command

command("Todo", [[noautocmd silent! grep! 'TODO\|FIXME\|BUG\|HACK' | copen]], {})

-- command("Rg", function(opts) require("telescope.builtin").live_grep_string({ search = vim.api.nvim_eval(fmt("%s", opts.args)) }) end, { nargs = "*" })
-- vim.cmd([[
--   command! -nargs=1 Rg lua require("telescope.builtin").grep_string({ search = vim.api.nvim_eval('"<args>"') })
-- ]])
-- Command("Rg", function(opts)
--   require("telescope.builtin").grep_string({ search = vim.api.nvim_eval('"<args>"') })
-- end, { nargs = "*" })
command(
  "DuplicateFile",
  [[noautocmd clear | silent! execute "!cp '%:p' '%:p:h/%:t:r-copy.%:e'"<bar>redraw<bar>echo "Copied " . expand('%:t') . ' to ' . expand('%:t:r') . '-copy.' . expand('%:e')]],
  {}
)
command("SaveAsFile", [[noautocmd clear | :execute "saveas %:p:h/" .input('save as -> ') | :e ]], {})
command("RenameFile", [[noautocmd clear | :execute "Rename " .input('rename to -> ') | :e ]], {})
command("Flash", function()
  mega.blink_cursorline()
end, {})
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
-- command("Noti", [[Messages | Notifications]], {})
vim.cmd.cnoreabbrev("noti Notifications")
-- command("Mess", [[messages]], {})
-- open messages in a new buffer (by EstudiandoAjedrez)
-- command("Messages", function()
--   -- scratch_buffer = vim.api.nvim_create_buf(false, true)
--   -- vim.bo[scratch_buffer].filetype = "vim"
--   local messages = vim.split(vim.fn.execute("messages", "silent"), "\n")
--   local qf_list = {}
--
--   for _, msg in ipairs(messages) do
--     table.insert(qf_list, {
--       text = msg,
--       -- bufnr = vim.api.nvim_get_current_buf(),
--       -- lnum = start_row + 1,
--       -- col = start_col + 1,
--       -- end_col = start_col + line:len(),
--     })
--   end
--
--   U.setqflist(messages, { scroll_to_end = true, title = "messages", simple_list = true })
--   -- vim.api.nvim_buf_set_text(scratch_buffer, 0, 0, 0, 0, messages)
--   -- vim.cmd("sbuffer " .. scratch_buffer)
--   -- vim.opt_local.wrap = true
--   -- vim.bo.buflisted = false
--   -- vim.bo.bufhidden = "wipe"
--   --
--   -- vim.cmd(fmt("let &winheight=%d", 20))
--   -- vim.opt_local.winfixheight = true
--   -- vim.opt_local.winminheight = 20 / 2
--   -- vim.api.nvim_win_set_height(0, 20)
-- end, {})
vim.cmd.cnoreabbrev("mess messages")
vim.cmd.cnoreabbrev("Mess messages")
vim.cmd.cnoreabbrev("Messages messages")

command("LogRead", function(_opts)
  vim.cmd.vnew("/tmp/nlog")
end, {})

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
    require("config.utils").buf_close()
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
    if not next or next == "" or next == prevname then
      return
    end
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
          if resp and resp.result ~= nil then
            vim.lsp.util.apply_workspace_edit(resp.result, client.offset_encoding)
          end
        end
      end
    end

    vim.cmd.file(nextpath) -- rename buffer, preserving undo
    vim.cmd("noautocmd write") -- save
    vim.cmd("edit") -- update file syntax if you changed extension

    if changes ~= nil and #clients and type(prevpath) == "string" then
      for _, client in ipairs(clients) do
        if client:supports_method(Methods.workspace_didRenameFiles) then
          client:notify(Methods.workspace_didRenameFiles, changes)
        end
      end
    else
      return
    end

    local ok, err = vim.uv.fs_unlink(prevpath)
    if not ok then
      vim.notify(
        table.concat({ prevpath, err }, "\n"),
        vim.log.levels.ERROR,
        { title = ":Rename failed to delete orig" }
      )
    end
  end)
end, {
  desc = "Rename current file",
  nargs = "?",
  complete = function()
    return { vim.fn.expand("%") }
  end,
})

Load_macros(M)

return M

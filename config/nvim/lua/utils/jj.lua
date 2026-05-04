-- Jujutsu utilities: config, commands, root detection.
-- Adapted from: https://github.com/madmaxieee/nvim-config/blob/main/lua/utils/jj.lua

local M = {}

M.config = {
  base_rev = "@-",
}

--- Gets the jj root directory for a buffer or path.
--- Delegates to utils.vcs.get_jj_root.
---@param path? number|string buffer or path
---@return string?
function M.find_root(path) return require("utils.vcs").get_jj_root(path) end

-- ── Commands ──────────────────────────────────────────────────────────────

vim.api.nvim_create_user_command("JJDiff", function(opts)
  local rev = opts.args
  local path = vim.api.nvim_buf_get_name(0)
  local dir = vim.fs.dirname(path)
  vim.system(
    { "jj", "--no-pager", "--color=never", "log", "-r", rev, "--no-graph", "-T", "" },
    { cwd = dir },
    function(res)
      if res.code ~= 0 then
        vim.schedule(function()
          vim.notify(("jj: '%s' is not a valid rev"):format(rev))
        end)
        return
      end
      M.config.base_rev = rev
      local ok, make_source = pcall(require, "plugins.mini.diff.make-source")
      if ok then make_source.reload_all("jj") end
      vim.schedule(function()
        vim.notify(("jj: reference rev is set to '%s'"):format(rev))
      end)
    end
  )
end, { nargs = 1 })

vim.api.nvim_create_user_command("JJPDiff", function()
  if M.config.base_rev == "@-" then
    vim.cmd([[JJDiff @--]])
  else
    vim.cmd([[JJDiff @-]])
  end
end, { nargs = 0 })

return M

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

-- ── Diffedit ──────────────────────────────────────────────────────────────

--- Launch `jj diffedit --tool difftool`.
--- End-to-end flow requires the jj merge-tools.difftool config (Step 7 / dot-j34v).
---@param opts? {args: string}
function M.diffedit(opts)
  opts = opts or { args = "" }
  vim.fn.jobstart("jj diffedit --tool difftool " .. opts.args)
end

--- Check whether a difftool session is active (qflist populated with user_data.diff).
--- If not, force-delete any stale /tmp/jj-diff* buffers.
---@return 0|1
function M.is_jj_diffedit_open()
  local entry = vim.fn.getqflist({ all = true }).items[1]
  if not entry or not entry.user_data or not entry.user_data.diff then
    for _, buf in ipairs(vim.api.nvim_list_bufs()) do
      if vim.fn.fnamemodify(vim.api.nvim_buf_get_name(buf), ":p"):match("/tmp/jj%-diff.*") then
        vim.api.nvim_buf_delete(buf, { force = true })
      end
    end
    return 0
  else
    return 1
  end
end

vim.api.nvim_create_user_command("Diffedit", function(opts)
  M.diffedit({ args = opts.args or "" })
end, { nargs = "*" })

return M

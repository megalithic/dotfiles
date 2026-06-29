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

-- ── Toggle vdiff ─────────────────────────────────────────────────────────

--- Close any jj:// revision buffer visible in the current tabpage.
--- Returns true if a diff was closed (i.e. we toggled off).
---@return boolean
function M.close_vdiff()
  for _, win in ipairs(vim.api.nvim_tabpage_list_wins(0)) do
    if vim.api.nvim_win_is_valid(win) then
      local buf = vim.api.nvim_win_get_buf(win)
      local name = vim.api.nvim_buf_get_name(buf)
      if name:match("^jj://") then
        -- Closing this buffer triggers the native backend's cleanup autocmd,
        -- which restores the original window and exits diff mode.
        vim.api.nvim_buf_delete(buf, { force = true })
        return true
      end
    end
  end
  return false
end

--- Toggle jj.nvim's vertical diff split.
--- If a jj:// buffer is visible, close it. Otherwise, open a new vdiff.
---@param rev? string revision to diff against (default: "trunk()")
function M.toggle_vdiff(rev)
  rev = rev or "trunk()"
  if M.close_vdiff() then return end
  require("jj.diff").open_vdiff({ rev = rev })
end

-- ── Unified JJDiff command ────────────────────────────────────────────────
-- :JJDiff <rev>        — set base rev for mini.diff signs + overlay
-- :JJDiff overlay      — toggle mini.diff overlay
-- :JJDiff vdiff [rev]  — toggle jj.nvim vertical diff split

local subcommands = { overlay = true, vdiff = true }

vim.api.nvim_create_user_command("JJDiff", function(opts)
  local args = vim.split(opts.args, "%s+")
  local first = args[1]

  -- Subcommand: overlay
  if first == "overlay" then
    require("mini.diff").toggle_overlay(0)
    return
  end

  -- Subcommand: vdiff [rev]
  if first == "vdiff" then
    M.toggle_vdiff(args[2])
    return
  end

  -- Default: set base rev for mini.diff
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
end, {
  nargs = "?",
  complete = function(_, line)
    local prefix = line:match("JJDiff%s+(.*)") or ""
    if prefix == "" then
      return vim.tbl_keys(subcommands)
    end
    local first = vim.split(prefix, "%s+")[1]
    if subcommands[first] and first == "vdiff" then
      -- Could complete revs here; for now just return empty
      return {}
    end
    return vim.tbl_keys(subcommands)
  end,
})

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

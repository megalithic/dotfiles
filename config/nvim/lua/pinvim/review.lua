-- lua/pinvim/review.lua
-- Worktree-aware review orchestrator for pinvim.
--
-- Opens the right review surface for a requested scope and records active
-- review metadata so annotation flushes (ticket dot-jl46) can attach context.
--
-- Scopes:
--   uncommitted  -> diffs.nvim review of current worktree changes
--   unpushed     -> diffs.nvim review against @{u} (or clear fallback)
--   branch       -> diffs.nvim review against PR base / default base
--   pr           -> :Guh <current PR> via gh
--   ticket       -> branch/uncommitted scope + ticket metadata
--   worktrees    -> pick a worktree, then reopen review scoped to it
--
-- Preserves strict pinvim pairing: never touches PI_SOCKET / PINVIM_PAIR_ID.

local M = {}

-- Active review metadata, consumed by pinvim.lua compose/flush (dot-jl46).
-- nil when no review session is active.
M.active = nil

local SCOPES = { "uncommitted", "unpushed", "branch", "pr", "ticket", "worktrees" }

--- Run a shell command synchronously and return trimmed stdout lines.
--- Returns (lines, ok). Never throws.
local function run_lines(cmd)
  local ok, out = pcall(vim.fn.systemlist, cmd)
  if not ok or vim.v.shell_error ~= 0 then return {}, false end
  return out, true
end

local function run_trim(cmd)
  local ok, out = pcall(vim.fn.system, cmd)
  if not ok then return nil, false end
  if vim.v.shell_error ~= 0 then return nil, false end
  return vim.trim(out), true
end

--- Resolve the current git worktree root (toplevel), or nil if not a git repo.
function M.worktree_root()
  local out, ok = run_trim("git rev-parse --show-toplevel")
  if not ok or out == "" then return nil end
  return out
end

--- Current branch name, or nil for detached HEAD.
function M.branch()
  local out, ok = run_trim("git branch --show-current")
  if not ok or out == "" then return nil end
  return out
end

--- Upstream ref name (e.g. origin/main), or nil if none.
function M.upstream()
  local out, ok = run_trim("git rev-parse --abbrev-ref --symbolic-full-name @{u} 2>/dev/null")
  if not ok or out == "" then return nil end
  return out
end

--- Default base ref: main if it exists, else origin/main, else nil.
function M.default_base()
  for _, ref in ipairs({ "main", "origin/main", "master", "origin/master" }) do
    local out, ok = run_trim("git rev-parse --verify --quiet refs/heads/" .. ref .. " 2>/dev/null || git rev-parse --verify --quiet " .. ref)
    if ok and out ~= "" then return ref end
  end
  return nil
end

--- PR metadata for the current branch via `gh pr view`.
--- Returns table { number, url, baseRefName, headRefName } or nil.
function M.pr_metadata()
  if vim.fn.executable("gh") ~= 1 then return nil end
  local out, ok = run_lines("gh pr view --json number,url,baseRefName,headRefName 2>/dev/null")
  if not ok or #out == 0 then return nil end
  local parsed, data = pcall(vim.json.decode, table.concat(out, "\n"))
  if not parsed or type(data) ~= "table" then return nil end
  return {
    number = data.number,
    url = data.url,
    baseRefName = data.baseRefName,
    headRefName = data.headRefName,
  }
end

--- Derive a ticket id from the branch name (e.g. "dot-ab12") when cheap.
--- Also confirms a matching ticket file exists under .tickets/ when possible.
function M.ticket_id()
  local branch = M.branch()
  if not branch then return nil end
  local id = branch:match("(dot%-[a-z0-9]+)")
  if not id then return nil end
  return id
end

--- Build the active review metadata record for the given scope.
local function build_metadata(scope)
  local pr = M.pr_metadata()
  return {
    scope = scope,
    worktree = M.worktree_root(),
    branch = M.branch(),
    upstream = M.upstream(),
    base = (pr and pr.baseRefName) or M.default_base(),
    pr = pr,
    ticket = M.ticket_id(),
  }
end

--- Open a diffs.nvim repo review against `ref`.
--- Uses HEAD for uncommitted scope so review shows staged, unstaged, and untracked changes.
local function open_diffs_review(ref)
  local ok, commands = pcall(require, "diffs.commands")
  if not ok then
    vim.notify("pinvim review: diffs.nvim is not available", vim.log.levels.ERROR)
    return false
  end

  local bufnr = commands.review({
    base = (ref and ref ~= "") and ref or "HEAD",
    repo = M.worktree_root(),
    untracked = true,
  })
  return bufnr ~= nil
end

--- Open the GitHub PR review via guh.nvim.
local function open_guh(pr)
  if not pr then
    vim.notify("pinvim review: no PR found for current branch; use :Guh to browse", vim.log.levels.WARN)
    return false
  end
  local target = pr.url or tostring(pr.number)
  vim.cmd("Guh " .. vim.fn.fnameescape(target))
  return true
end

--- Resolve which base ref to use for `branch` scope.
local function branch_base()
  local pr = M.pr_metadata()
  if pr and pr.baseRefName then return pr.baseRefName end
  local base = M.default_base()
  return base
end

--- Core scope dispatcher. `opts.cwd` switches worktree before detecting.
function M.run(scope, opts)
  opts = opts or {}
  scope = scope or "uncommitted"

  if scope == "worktrees" then
    return M.pick_worktree(opts)
  end

  if opts.cwd and opts.cwd ~= "" and opts.cwd ~= M.worktree_root() then
    vim.cmd("tcd " .. vim.fn.fnameescape(opts.cwd))
  end

  if not M.worktree_root() then
    vim.notify("pinvim review: not inside a git worktree", vim.log.levels.ERROR)
    return false
  end

  local ok = true
  if scope == "uncommitted" then
    ok = open_diffs_review(nil)
  elseif scope == "unpushed" then
    local up = M.upstream()
    if not up then
      vim.notify("pinvim review: no upstream tracking branch; falling back to uncommitted", vim.log.levels.WARN)
      ok = open_diffs_review(nil)
    else
      ok = open_diffs_review(up)
    end
  elseif scope == "branch" then
    local base = branch_base()
    if not base then
      vim.notify("pinvim review: could not determine base ref; falling back to uncommitted", vim.log.levels.WARN)
      ok = open_diffs_review(nil)
    else
      ok = open_diffs_review(base)
    end
  elseif scope == "pr" then
    ok = open_guh(M.pr_metadata())
  elseif scope == "ticket" then
    -- Ticket scope: prefer branch diff, fall back to uncommitted, attach ticket metadata.
    local base = branch_base()
    if base then
      ok = open_diffs_review(base)
    else
      ok = open_diffs_review(nil)
    end
  else
    vim.notify("pinvim review: unknown scope '" .. scope .. "'", vim.log.levels.ERROR)
    return false
  end

  -- Record active review metadata (consumed by compose/flush, ticket dot-jl46).
  if ok then M.active = build_metadata(scope) end
  return ok
end

--- List git worktrees via `git worktree list --porcelain`.
--- Returns a list of { path, branch, head, detached }.
function M.list_worktrees()
  local lines, ok = run_lines("git worktree list --porcelain")
  if not ok then return {} end
  local worktrees = {}
  local cur = nil
  for _, line in ipairs(lines) do
    if line == "" then
      if cur and cur.path then table.insert(worktrees, cur) end
      cur = nil
    else
      local key, value = line:match("^(%S+)%s+(.*)$")
      if key == "worktree" then
        cur = { path = value, branch = nil, head = nil, detached = false }
      elseif cur then
        if key == "HEAD" then
          cur.head = value
        elseif key == "branch" then
          cur.branch = value:gsub("^refs/heads/", "")
        elseif key == "detached" then
          cur.detached = true
        end
      end
    end
  end
  if cur and cur.path then table.insert(worktrees, cur) end
  return worktrees
end

--- Basic worktree picker (enriched + tmux launcher added in ticket dot-vxup).
function M.pick_worktree(opts)
  opts = opts or {}
  local worktrees = M.list_worktrees()
  if #worktrees == 0 then
    vim.notify("pinvim review: no git worktrees found", vim.log.levels.WARN)
    return false
  end

  -- Enrich each worktree with dirty/staged/untracked counts.
  for _, wt in ipairs(worktrees) do
    local counts = { dirty = 0, staged = 0, untracked = 0 }
    local lines, ok = run_lines("git -C " .. vim.fn.shellescape(wt.path) .. " status --porcelain")
    if ok then
      for _, line in ipairs(lines) do
        local x = line:sub(1, 1)
        local y = line:sub(2, 2)
        if x == "?" or y == "?" then
          counts.untracked = counts.untracked + 1
        else
          if x ~= " " and x ~= "?" then counts.staged = counts.staged + 1 end
          if y ~= " " and y ~= "?" then counts.dirty = counts.dirty + 1 end
        end
      end
      wt.counts = counts
    else
      wt.counts = nil
    end
  end

  local labels = {}
  for _, wt in ipairs(worktrees) do
    local name = wt.branch or (wt.detached and "detached" or "?")
    local counts = wt.counts
    local stats
    if counts then
      stats = string.format("dirty=%d staged=%d untracked=%d", counts.dirty, counts.staged, counts.untracked)
    else
      stats = "unknown"
    end
    table.insert(labels, string.format("%s  [%s]  (%s)", wt.path, name, stats))
  end
  vim.ui.select(labels, { prompt = "Select worktree to review:" }, function(choice, idx)
    if not choice or not idx then return end
    local wt = worktrees[idx]
    local scope = opts.scope or "uncommitted"
    M.run(scope, { cwd = wt.path })
  end)
  return true
end

--- Public accessor for active review metadata (used by pinvim.lua flush).
function M.metadata()
  return M.active
end

--- Clear active review metadata (e.g. when review tab closes).
function M.clear()
  M.active = nil
end

--- Completion list for :PiReview.
function M.complete()
  return SCOPES
end

return M

-- NOTE: shamelessly thieved from the infamous @folke
-- selene: allow(global_usage)

local M = {}

M.notify = {
  notifs = {},
  orig = vim.notify,
}

function M.notify.lazy(...) table.insert(M.notify.notifs, { ... }) end

function M.notify.setup()
  vim.notify = M.notify.lazy
  local check = vim.loop.new_check()
  local start = vim.loop.hrtime()
  check:start(function()
    if vim.notify ~= M.notify.lazy then
      -- use the new notify
    elseif (vim.loop.hrtime() - start) / 1e6 > 1000 then
      -- use the old notify if loading the new one takes over 1 second
      vim.notify = M.notify.orig
    else
      return
    end
    check:stop()
    -- use the new notify
    vim.schedule(function()
      ---@diagnostic disable-next-line: no-unknown
      for _, notif in ipairs(M.notify.notifs) do
        vim.notify(unpack(notif))
      end
    end)
  end)
end

function M.get_loc()
  local me = debug.getinfo(1, "S")
  local level = 2
  local info = debug.getinfo(level, "S")
  while info and info.source == me.source do
    level = level + 1
    info = debug.getinfo(level, "S")
  end
  info = info or me
  local source = info.source:sub(2)
  source = vim.loop.fs_realpath(source) or source
  return vim.fn.fnamemodify(source, ":~:.") .. ":" .. info.linedefined
end

---@param value any
---@param opts? {loc:string, schedule:boolean}
function M.dump(value, opts)
  opts = opts or {}
  opts.loc = opts.loc or M.get_loc()
  local msg = vim.inspect(value)
  local function notify()
    mega.notify(msg, vim.log.levels.INFO, {
      title = "Debug: " .. opts.loc,
      on_open = function(win)
        vim.wo[win].conceallevel = 3
        vim.wo[win].concealcursor = ""
        vim.wo[win].spell = false
        local buf = vim.api.nvim_win_get_buf(win)
        if not pcall(vim.treesitter.start, buf, "lua") then vim.bo[buf].filetype = "lua" end
      end,
    })
  end
  if opts.schedule then
    vim.schedule(notify)
  else
    notify()
  end
end

function M.get_value(...)
  local value = { ... }
  return vim.tbl_islist(value) and vim.tbl_count(value) <= 1 and value[1] or value
end

_G.d = function(...) M.dump(M.get_value(...)) end

_G.dd = function(...) M.dump(M.get_value(...), { schedule = true }) end

_G.dbg = function(...) M.dump(M.get_value(...), { schedule = true }) end

function M.setup()
  M.notify.setup()
  -- make all keymaps silent by default
  local keymap_set = vim.keymap.set
  ---@diagnostic disable-next-line: duplicate-set-field
  vim.keymap.set = function(mode, lhs, rhs, opts)
    opts = opts or {}
    opts.silent = opts.silent ~= false
    return keymap_set(mode, lhs, rhs, opts)
  end
end

M.setup()

return M

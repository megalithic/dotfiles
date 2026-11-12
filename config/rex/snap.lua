-- Copy and hints modes over a pane. Captures the pane and
-- opens Neovim (snap/view.lua) in a floating layer exactly over it.
-- Capture and layer code adapted from CJNE/rex-copy-mode (MIT, see snap/LICENSE).
local common = require("snap.common")

local M = {}
local TERMINAL = "com.superlogical.terminal"
local CHUNK = 983040
local root = debug.getinfo(1, "S").source:gsub("^@", ""):match("^(.*/)") .. "snap/"

local function checked(result, err)
  if not result then error(err or "Rex call failed", 0) end
  return result
end

local function exec(argv)
  local result = checked(rex.exec(argv, { timeout = 5 }))
  if not result.ok then error("snap: " .. argv[1] .. " failed: " .. result.stderr, 0) end
  return result.stdout
end

local function block_call(ctx, method, args)
  return checked(rex.block.call(TERMINAL, method, {
    session_id = ctx.session_id, block_id = ctx.block_id, args = args or {},
  }))
end

-- Write the pane's screen and scrollback to path, reading it in chunks. With
-- tail, skip to the last tail bytes after the first chunk; the viewer keeps
-- only the last lines, so the seam is never shown.
local function write_capture(ctx, path, args, tail)
  args.max_bytes = CHUNK
  local part = block_call(ctx, "format", args)
  local file = assert(io.open(path, "wb"))
  local ok, err = pcall(function()
    local offset, content = 0, part.content
    while true do
      assert(file:write(content))
      offset = offset + #content
      if offset > 128 * 1024 * 1024 then error("capture exceeds 128 MiB", 0) end
      if not part.id or part.eof == true or (part.total and offset >= part.total) then break end
      if tail and part.total then offset = math.max(offset, part.total - tail) end
      part = block_call(ctx, "blob_read", { id = part.id, offset = offset, max_bytes = CHUNK })
      content = part.data
      if #content == 0 then error("incomplete capture", 0) end
    end
  end)
  file:close()
  if not ok then error(err, 0) end
end

-- The app's config loader has a narrower PATH than a shell, so fall back to
-- mise and to the Rex Server bundle.
local function which(name)
  local home = os.getenv("HOME")
  for _, argv in ipairs({
    { "which", name },
    { home .. "/.local/bin/mise", "which", name },
    { "test", "-x", home .. "/Library/Application Support/com.superlogical.rex/RexServer/Versions/Current/Rex Server.app/Contents/MacOS/" .. name },
  }) do
    local result = rex.exec(argv, { timeout = 5 })
    if result and result.ok then
      return argv[1] == "test" and argv[3] or result.stdout:match("[^\r\n]+")
    end
  end
  error("snap: cannot find " .. name, 0)
end

local function open(ctx, mode, jump)
  local hints = mode == "hints"
  if not ctx.session_id or not ctx.block_id then error("snap needs a focused pane", 0) end
  -- Resolved on first use, not at config load, so a missing binary can only
  -- break this action, never the whole config. The layer's launcher has a
  -- narrower PATH still, so it gets absolute paths.
  M.nvim = M.nvim or which("nvim")
  M.rex = M.rex or which("rex")
  local source = checked(rex.session.describe_block{ session_id = ctx.session_id, block_id = ctx.block_id })
  if source.block.creator_name ~= TERMINAL then error("snap needs a terminal pane", 0) end
  local window_id = assert(source.block.window_id, "pane is not in a window")
  local view = checked(rex.session.view{ session_id = ctx.session_id })
  local bounds, zoomed = common.pane_bounds(view, window_id, ctx.block_id)
  local size = block_call(ctx, "size")
  -- A float is one row (its title bar) and one column smaller than the pane.
  -- Grow it by a cell each way and lift the title bar above the pane, so the
  -- overlay's cells sit on the pane's cells.
  local cw, ch = bounds[3] / size.columns, bounds[4] / size.rows
  local y = math.max(0, bounds[2] - ch)
  bounds = { bounds[1], y, math.min(bounds[3] + cw, 1 - bounds[1]), math.min(bounds[4] + (bounds[2] - y), 1 - y) }

  local tmp = (os.getenv("TMPDIR") or "/tmp"):gsub("/+$", "")
  local dir = exec({ "mktemp", "-d", tmp .. "/rex-snap-XXXXXXXX" }):gsub("%s+$", "")
  local opened = false
  local ok, err = pcall(function()
    -- Hints work on the visible screen only: the last rows lines, unwrapped
    -- as text too to find soft-wrapped rows. 64 bytes per cell covers SGR.
    local tail = hints and (size.rows + 1) * (size.columns + 1) * 64 or nil
    write_capture(ctx, dir .. "/capture.vt", { format = "vt", trim = true }, tail)
    local cwd
    if hints then
      write_capture(ctx, dir .. "/unwrap.txt", { format = "text", trim = true, unwrap = true }, tail)
      local process = block_call(ctx, "process")
      cwd = process.foreground and process.foreground.cwd
    end
    local meta = checked(rex.json.encode({
      mode = mode, jump = jump, rex = M.rex,
      session = ctx.session_id, source_block = ctx.block_id, source_window = window_id,
      source_zoomed = zoomed, lifted = y < bounds[2],
      rows = size.rows, cols = size.columns, cwd = cwd,
    }))
    local file = assert(io.open(dir .. "/meta.json", "wb"))
    assert(file:write(meta))
    file:close()
    exec({ "chmod", "600", dir .. "/capture.vt", dir .. "/meta.json", hints and dir .. "/unwrap.txt" or nil })
    checked(rex.session.new_layer{
      session_id = ctx.session_id, window_id = window_id, bounds = bounds, focus = true,
      layout = rex.layout.block{
        flavor = "com.superlogical.terminal.shell", label = "snap " .. mode,
        options = {
          shell = "none",
          command = {
            "/usr/bin/env", "NVIM_APPNAME=rex-snap", M.nvim, "-u", "NONE", "-i", "NONE", "-n",
            "--cmd", "set nomodeline",
            "--cmd", "lua vim.g.rex_snap_dir = " .. string.format("%q", dir),
            "-c", "lua dofile(" .. string.format("%q", root .. "view.lua") .. ")",
          },
          exit = { on_completion = true, quick_exit_threshold_ms = 0 },
        },
      },
    })
    opened = true -- The viewer owns cleanup from here, including on startup errors.
  end)
  if not opened then
    os.remove(dir .. "/capture.vt")
    os.remove(dir .. "/unwrap.txt")
    os.remove(dir .. "/meta.json")
    pcall(rex.exec, { "rmdir", dir }, { timeout = 2 })
  end
  if not ok then error(err, 0) end
end

function M.setup()
  rex.action{
    name = "snap_copy",
    title = "Copy Mode",
    description = "Vim motions, flash jump and yank over the pane's scrollback",
    category = "Pane",
    keywords = "copy mode scrollback vim flash yank",
    run = function(ctx) open(ctx, "copy") end,
  }
  rex.action{
    name = "snap_jump",
    title = "Copy Mode Jump",
    description = "Copy mode with a flash jump already started",
    category = "Pane",
    keywords = "copy mode flash jump",
    run = function(ctx) open(ctx, "copy", true) end,
  }
  rex.action{
    name = "snap_hints",
    title = "Hints",
    description = "Label URLs, paths, SHAs, code and IDs on screen; type a label to copy, Shift to open",
    category = "Pane",
    keywords = "hints fingers thumbs copy open url path",
    run = function(ctx) open(ctx, "hints") end,
  }
end

return M

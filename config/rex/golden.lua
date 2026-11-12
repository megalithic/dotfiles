-- golden.lua: golden-ratio pane sizing. The focused pane gets 61.8% of every
-- split it sits in, so it grows and its neighbours shrink as focus moves.
-- golden-watch.lua runs apply() on each layout change (launchd agent
-- com.megadots.rex-golden); init.lua binds the toggle.
local M = {}

local RATIO = 0.618
local STATE_DIR = (os.getenv("XDG_STATE_HOME") or (os.getenv("HOME") .. "/.local/state")) .. "/rex"
-- A file rather than a variable, because the toggle runs in the server's config
-- and apply() runs in the watcher script.
local OFF_FILE = STATE_DIR .. "/golden-off"

function M.enabled()
  local f = io.open(OFF_FILE)
  if f then
    f:close()
    return false
  end
  return true
end

-- Also sets Rex's "Autobalance splits" to the opposite. The app reads that
-- setting at launch, so it applies from the next launch; until then golden
-- sizing overrides the balancing anyway.
function M.set_enabled(on)
  if on then
    os.remove(OFF_FILE)
  else
    rex.exec({ "/bin/mkdir", "-p", STATE_DIR }, { timeout = 2 })
    local f = assert(io.open(OFF_FILE, "w"))
    f:close()
  end
  local balance = on and "false" or "true"
  rex.exec(
    { "/usr/bin/defaults", "write", "com.superlogical.rex", "Workspace.balancesSplitsOnCreation", "-bool", balance },
    { timeout = 2 }
  )
end

local function contains(node, block_id)
  if node.block_id then
    return node.block_id == block_id
  end
  return node.split ~= nil and (contains(node.split.before, block_id) or contains(node.split.after, block_id))
end

local function first_block(node)
  return node.block_id or first_block(node.split.before)
end

-- Walks from the outer split to the focused pane and gives the focused side
-- RATIO of each split. Idempotent, so the layout change its own resizes cause
-- leads to no further calls.
function M.apply(session_id)
  local view = rex.session.view({ session_id = session_id })
  for _, win in ipairs(view and view.windows or {}) do
    local focused = win.focused_block_id
    if focused and not win.zoomed_block_id then
      for _, layer in ipairs(win.layers or {}) do
        local node = layer.kind == "tiled" and layer.layout
        while node and node.split do
          local s = node.split
          local in_before = contains(s.before, focused)
          if not in_before and not contains(s.after, focused) then
            break -- focus is in a floating layer
          end
          local want = in_before and RATIO or 1 - RATIO
          if math.abs(s.ratio - want) > 0.01 then
            rex.session.resize_pane({
              session_id = session_id,
              direction = s.direction,
              before_block_id = first_block(s.before),
              after_block_id = first_block(s.after),
              ratio = want,
            })
          end
          node = in_before and s.before or s.after
        end
      end
    end
  end
end

return M

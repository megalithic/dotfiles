-- Pure Lua 5.1 helpers shared by Rex (snap.lua) and the Neovim viewer.
-- sanitize_vt, find_rect and pane_bounds are adapted from CJNE/rex-copy-mode
-- (MIT, Copyright (c) 2026 Johan Isacsson). See snap/LICENSE.
local M = {}
local ESC = string.char(27)

-- Keep printable text and SGR styling. Drop OSC/DCS, cursor controls and
-- device queries, so a capture can't make the viewer do anything.
function M.sanitize_vt(text)
  local c1 = { [144] = "P", [152] = "X", [155] = "[", [156] = "\\", [157] = "]", [158] = "^", [159] = "_" }
  text = text:gsub("\194[\128-\159]", function(pair)
    local suffix = c1[pair:byte(2)]
    return suffix and ESC .. suffix or ""
  end)
  local output, i = {}, 1
  while i <= #text do
    local first, last = text:find("[^%z\1-\8\11\12\14-\31\127]+", i)
    if first == i then
      output[#output + 1] = text:sub(first, last)
      i = last + 1
    elseif text:byte(i) == 27 then
      local start, kind = i, text:sub(i + 1, i + 1)
      i = i + 2
      if kind == "[" then
        local final = text:find("[@-~]", i)
        if not final then break end
        local params, cmd = text:sub(i, final - 1), text:sub(final, final)
        if cmd == "m" and params:match("^[0-9;:]*$") then
          output[#output + 1] = text:sub(start, final)
        elseif cmd == "C" and params:match("^%d*$") then
          -- Cursor forward (e.g. a right prompt) as spaces keeps columns.
          output[#output + 1] = string.rep(" ", math.min(math.max(tonumber(params) or 1, 1), 1000))
        end
        i = final + 1
      elseif kind ~= "" and ("]PX^_"):find(kind, 1, true) then
        local stop = text:find(ESC .. "\\", i, true)
        local bell = kind == "]" and text:find("\7", i, true) or nil
        if bell and (not stop or bell < stop) then i = bell + 1
        elseif stop then i = stop + 2
        else break end
      elseif kind >= " " and kind <= "/" then
        while i <= #text and text:byte(i) >= 32 and text:byte(i) <= 47 do i = i + 1 end
        i = i + 1
      end
    else
      i = i + 1
    end
  end
  return (table.concat(output):gsub("\r\n", "\n"):gsub("\r", "\n"))
end

function M.find_rect(node, block_id)
  if not node then return nil end
  if node.block_id == block_id then return node.rect end
  if node.split then
    return M.find_rect(node.split.before, block_id) or M.find_rect(node.split.after, block_id)
  end
end

-- The pane's rectangle as window fractions {x, y, w, h}, and whether it is zoomed.
function M.pane_bounds(view, window_id, block_id)
  for _, window in ipairs(view.windows or {}) do
    if window.window_id == window_id then
      if window.zoomed_block_id == block_id then return { 0, 0, 1, 1 }, true end
      for _, layer in ipairs(window.layers or {}) do
        local rect = M.find_rect(layer.layout, block_id)
        if rect then
          local x, y = math.max(0, rect[1]), math.max(0, rect[2])
          return { x, y, math.min(rect[3], 1 - x), math.min(rect[4], 1 - y) }, false
        end
      end
    end
  end
  error("Cannot find the pane in the current layout", 0)
end

return M

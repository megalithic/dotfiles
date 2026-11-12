-- Hints mode: labels URLs, paths, SHAs, code and IDs on the visible screen.
-- Type a label to copy its match and close; type it in uppercase to open the
-- match. Esc or q closes. User patterns and open handlers live in config.lua.
-- The soft-wrap join follows xeind/rex-fingers (MIT).
local M = {}
local root = debug.getinfo(1, "S").source:gsub("^@", ""):match("^(.*/)")
local ALPHABET = "asdfghjklwertyuiopzxcvbnm" -- no q, it closes
local ns = vim.api.nvim_create_namespace("snap_hints")

local function system_open(target)
  vim.system({ "/usr/bin/open", target }, { detach = true })
end

-- Built-in patterns, Vim very magic. On a tie (same start and length) the
-- earlier one wins; user patterns go first.
local NAME = [=[[[:alnum:]_.@+-]]=]
local EXT = [[%(lua|md|txt|log|json|toml|ya?ml|ex|exs|heex|eex|leex|js|mjs|cjs|ts|tsx|jsx|css|scss|html|sh|bash|zsh|fish|py|rb|go|rs|swift|c|h|cpp|java|kt|nix|sql|pkl|xml|csv|lock|conf|env|vim|pdf|png|jpe?g|gif|svg)]]
local PATH = [[%(%(\~|\.\.?)?/|]] .. NAME .. [[+/)%(]] .. NAME .. [[+/?)*]]

local function trim_punct(text)
  return (text:gsub("[.,;:!?'\"]+$", ""))
end

local function has_alpha(text)
  text = trim_punct(text)
  return text:find("%a") and text or nil
end

local function trim_url(text)
  while true do
    local last = text:sub(-1)
    if last:match("[.,;:!?'\"%]}]") or (last == ")" and not text:find("(", 1, true)) then
      text = text:sub(1, -2)
    else
      return text
    end
  end
end

-- NPIs carry a Luhn check digit over the number prefixed with 80840.
local function luhn_npi(text)
  local sum, digits = 0, "80840" .. text
  for i = #digits, 1, -1 do
    local d = tonumber(digits:sub(i, i))
    if (#digits - i) % 2 == 1 then
      d = d * 2
      if d > 9 then d = d - 9 end
    end
    sum = sum + d
  end
  return sum % 10 == 0 and text or nil
end

local BUILTIN = {
  { name = "code", pattern = [[\v```([^`]+)```]], group = 1, open = false },
  { name = "code", pattern = [[\v`([^`]+)`]], group = 1, open = false },
  { name = "url", pattern = [[\v<%(https?|ftp|file|ssh)://[^[:space:]<>"'`]+]], clean = trim_url },
  { name = "email", pattern = [=[\v<[[:alnum:]._%+-]+\@[[:alnum:].-]+\.\a{2,}>]=],
    open = function(match) system_open("mailto:" .. match) end },
  { name = "fileline", pattern = [[\v%(]] .. PATH .. [[|<]] .. NAME .. [[+\.]] .. EXT .. [[):\d+%(:\d+)?>]], path = true,
    open = function(match) system_open((match:gsub(":%d+:?%d*$", ""))) end },
  { name = "path", pattern = [[\v]] .. PATH, clean = has_alpha, path = true },
  { name = "filename", pattern = [[\v<]] .. NAME .. [[+\.]] .. EXT .. [[>]], path = true },
  { name = "uuid", pattern = [[\v<\x{8}-\x{4}-\x{4}-\x{4}-\x{12}>]], open = false },
  { name = "sha", pattern = [[\v<[0-9a-f]{7,40}>]], open = false,
    clean = function(text) return text:find("%d") and text:find("%a") and text or nil end },
  { name = "npi", pattern = [[\v<\d{10}>]], clean = luhn_npi, open = false },
  { name = "phone", pattern = [[\v%(\+?<1[ .-]?)?%(\(\d{3}\) ?|<\d{3}[.-])\d{3}[.-]\d{4}>]], open = false },
}

local function patterns()
  return vim.list_extend(dofile(root .. "config.lua").patterns or {}, BUILTIN)
end

-- One logical line per line the program wrote: a row exactly cols wide joins
-- the next when the unwrapped capture holds both together. segs map byte
-- offsets back to buffer rows. Box drawing (U+2500-U+257F) becomes spaces of
-- the same byte length, so gutters never join or break a match.
local function logical_lines(src, out)
  local prev
  for i, row in ipairs(src.rows) do
    local r = src.first + i - 1
    local line = out[#out]
    if prev and row ~= "" and vim.fn.strdisplaywidth(prev) >= src.cols
      and src.unwrapped:find(prev .. row, 1, true) then
      line.segs[#line.segs + 1] = { row = r, from = #line.text, len = #row }
      line.text = line.text .. row
    else
      out[#out + 1] = { src = src, text = row, segs = { { row = r, from = 0, len = #row } } }
    end
    prev = row
  end
end

-- Fenced code blocks: the fence line copies the body without the fences or
-- the common indent, each body line copies itself. A fence with a language
-- always opens, so a closing fence whose block began above the screen is
-- dropped once the next block opens.
local CODE = { name = "code", open = false }
local function fences(lines, found, skip)
  local open
  local function close(stop)
    local body, indent = {}, math.huge
    for i = open.line + 1, stop - 1 do
      local text = lines[i].text
      skip[i] = true
      local s, e = #text:match("^%s*"), #text:gsub("%s+$", "")
      if e > s then
        indent = math.min(indent, s)
        found[#found + 1] = { line = i, s = s, e = e, text = text:sub(s + 1, e), def = CODE }
      end
      body[#body + 1] = text
    end
    for i, text in ipairs(body) do body[i] = text:sub(indent + 1):gsub("%s+$", "") end
    skip[open.line] = true
    if indent < math.huge then
      found[#found + 1] = { line = open.line, s = open.s, e = open.e, text = table.concat(body, "\n"), def = CODE }
    end
    open = nil
  end
  for i, line in ipairs(lines) do
    local indent, lang = line.text:match("^(%s*)```(%S*)%s*$")
    if indent then
      if open and lang == "" then
        close(i)
        skip[i] = true
      else
        open = { line = i, s = #indent, e = #line.text:gsub("%s+$", ""), lang = lang }
      end
    end
  end
  if open and open.lang ~= "" then close(#lines + 1) end
end

-- Leftmost-longest across all patterns, per logical line.
local function find_matches(lines, defs)
  local found, skip = {}, {}
  fences(lines, found, skip)
  local scratch = vim.api.nvim_create_buf(false, true)
  vim.api.nvim_buf_set_lines(scratch, 0, -1, false, vim.tbl_map(function(line) return line.text end, lines))
  for prio, def in ipairs(defs) do
    for _, m in ipairs(vim.fn.matchbufline(scratch, def.pattern, 1, "$", { submatches = def.group ~= nil })) do
      if not skip[m.lnum] then
        local text = def.group and m.submatches[def.group] or m.text
        if def.clean and not def.group then text = def.clean(text) end
        if text and text ~= "" then
          found[#found + 1] = {
            line = m.lnum, s = m.byteidx, e = m.byteidx + (def.group and #m.text or #text),
            text = text, def = def, prio = prio,
          }
        end
      end
    end
  end
  vim.api.nvim_buf_delete(scratch, { force = true })
  table.sort(found, function(a, b)
    if a.line ~= b.line then return a.line < b.line end
    if a.s ~= b.s then return a.s < b.s end
    if a.e ~= b.e then return a.e > b.e end
    return (a.prio or 0) < (b.prio or 0)
  end)
  local chosen, line, stop = {}, nil, 0
  for _, m in ipairs(found) do
    if m.line ~= line then line, stop = m.line, 0 end
    if m.s >= stop then
      chosen[#chosen + 1] = m
      stop = m.e
    end
  end
  return chosen
end

-- Fixed-length labels, so none is a prefix of another. The same text gets the
-- same label, and the matches nearest the bottom get the first letters.
local function assign_labels(matches)
  local order, seen = {}, {}
  for i = #matches, 1, -1 do
    local text = matches[i].text
    if not seen[text] then
      seen[text] = true
      order[#order + 1] = text
    end
  end
  local k, len = #ALPHABET, 1
  while k ^ len < #order do len = len + 1 end
  local labels = {}
  for i, text in ipairs(order) do
    local n, label = i - 1, ""
    for _ = 1, len do
      label = ALPHABET:sub(n % k + 1, n % k + 1) .. label
      n = math.floor(n / k)
    end
    labels[text] = label
  end
  local targets = {}
  for _, m in ipairs(matches) do
    m.label = labels[m.text]
    targets[m.label] = targets[m.label] or m
  end
  return targets
end

local function position(line, offset)
  for i, seg in ipairs(line.segs) do
    if offset < seg.from + seg.len or i == #line.segs then return seg.row, offset - seg.from end
  end
end

local function render(sources, lines, matches, typed)
  for _, src in ipairs(sources) do
    vim.api.nvim_buf_clear_namespace(src.buf, ns, 0, -1)
    local last = vim.api.nvim_buf_get_lines(src.buf, src.last, src.last + 1, false)[1]
    vim.api.nvim_buf_set_extmark(src.buf, ns, src.first, 0,
      { end_row = src.last, end_col = #last, hl_group = "SnapHintsDim", priority = 100 })
  end
  for _, m in ipairs(matches) do
    if vim.startswith(m.label, typed) then
      local line = lines[m.line]
      local buf = line.src.buf
      for _, seg in ipairs(line.segs) do
        local s, e = math.max(m.s, seg.from), math.min(m.e, seg.from + seg.len)
        if s < e then
          vim.api.nvim_buf_set_extmark(buf, ns, seg.row, s - seg.from,
            { end_col = e - seg.from, hl_group = "SnapHintsMatch", priority = 200, strict = false })
        end
      end
      local row, col = position(line, m.s)
      vim.api.nvim_buf_set_extmark(buf, ns, row, col, {
        virt_text = { { m.label:sub(#typed + 1), "SnapHintsLabel" } },
        virt_text_pos = "overlay", priority = 300, strict = false,
      })
    end
  end
end

local function resolve(path, cwd)
  if path:sub(1, 2) == "~/" then return vim.env.HOME .. path:sub(2) end
  if path:sub(1, 1) == "/" or not cwd then return path end
  return vim.fs.normalize(cwd .. "/" .. path)
end

-- Open runs the type's handler: a script path (the match as its argument), a
-- function(match, ctx), or /usr/bin/open. Types with open = false copy.
local function act(m, open, meta)
  local def, src = m.def, m.src
  if open and def.open ~= false then
    local value = def.path and resolve(m.text, src.cwd) or m.text
    if type(def.open) == "function" then
      def.open(value, { name = def.name, cwd = src.cwd, session = meta.session, block = src.block })
    elseif type(def.open) == "string" then
      vim.system({ vim.fs.normalize(def.open), value }, { detach = true })
    else
      system_open(value)
    end
  else
    vim.fn.setreg("+", m.text)
  end
end

function M.start(buf, meta)
  vim.api.nvim_set_hl(0, "SnapHintsDim", { fg = "#5c6370" })
  vim.api.nvim_set_hl(0, "SnapHintsMatch", { fg = "#d9bb80" })
  vim.api.nvim_set_hl(0, "SnapHintsLabel", { fg = "#272b30", bg = "#e67e80", bold = true })
  vim.api.nvim_set_hl(0, "SnapHintsCursor", { blend = 100, nocombine = true })
  vim.o.guicursor = "a:SnapHintsCursor"

  local file = assert(io.open(vim.g.rex_snap_dir .. "/unwrap.txt", "rb"))
  local sources = { {
    buf = buf, rows = meta.screen, first = 1, last = meta.rows, cols = meta.cols, cwd = meta.cwd,
    block = meta.source_block, unwrapped = file:read("*a"),
  } }
  file:close()

  local lines = {}
  for _, src in ipairs(sources) do logical_lines(src, lines) end
  local matches = find_matches(lines, patterns())
  if #matches == 0 then return vim.cmd("qa!") end
  for _, m in ipairs(matches) do m.src = lines[m.line].src end
  local targets = assign_labels(matches)

  local typed, open = "", false
  while true do
    render(sources, lines, matches, typed)
    vim.cmd.redraw()
    local ok, key = pcall(vim.fn.getcharstr)
    if not ok or key == "\27" or key == "q" then break end
    if key == vim.keycode("<BS>") or key == "\8" then
      typed = typed:sub(1, -2)
      if typed == "" then open = false end
    elseif #key == 1 and ALPHABET:find(key:lower(), 1, true) then
      local next = typed .. key:lower()
      if targets[next] then
        act(targets[next], open or key ~= key:lower(), meta)
        break
      end
      for label in pairs(targets) do
        if vim.startswith(label, next) then
          typed, open = next, open or key ~= key:lower()
          break
        end
      end
    end
  end
  vim.cmd("qa!")
end

return M

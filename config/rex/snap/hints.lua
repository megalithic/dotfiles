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

-- Foreground after an SGR sequence: "#rrggbb" for true colour, "@n" for a
-- palette colour, nil for the default.
local function sgr_fg(fg, params)
  local p = vim.split(params, ";", { plain = true })
  local i = 1
  while i <= #p do
    local n = tonumber(p[i]) or 0
    if n == 0 or n == 39 then
      fg = nil
    elseif n == 38 or n == 48 then
      local color
      if p[i + 1] == "2" then
        color = ("#%02x%02x%02x"):format(tonumber(p[i + 2]) or 0, tonumber(p[i + 3]) or 0, tonumber(p[i + 4]) or 0)
        i = i + 4
      elseif p[i + 1] == "5" then
        color = "@" .. (p[i + 2] or "0")
        i = i + 2
      end
      if n == 38 then fg = color end
    elseif n >= 30 and n <= 37 then
      fg = "@" .. (n - 30)
    elseif n >= 90 and n <= 97 then
      fg = "@" .. (n - 82)
    end
    i = i + 1
  end
  return fg
end

local BOX = "\226[\148\149][\128-\191]" -- U+2500-U+257F

-- A captured row as plain text, as text with box drawing (U+2500-U+257F)
-- masked to spaces of the same byte length so gutters never join or break a
-- match, and as foreground runs over byte ranges.
local function parse_row(raw)
  local parts, runs, fg, pos, i = {}, {}, nil, 0, 1
  while true do
    local s, e, params = raw:find("\27%[([0-9;:]*)m", i)
    local chunk = raw:sub(i, (s or 0) - 1)
    if chunk ~= "" then
      local last = runs[#runs]
      if last and last.fg == fg and last.e == pos then
        last.e = pos + #chunk
      else
        runs[#runs + 1] = { s = pos, e = pos + #chunk, fg = fg }
      end
      parts[#parts + 1] = chunk
      pos = pos + #chunk
    end
    if not s then break end
    fg = sgr_fg(fg, params)
    i = e + 1
  end
  local plain = table.concat(parts)
  return plain, (plain:gsub(BOX, "   ")), runs
end

-- Agent TUIs (Pi, Claude Code) wrap long URLs and paths themselves: the row
-- runs to the right edge on a token with a slash, and the next row goes on
-- at the same indent. Returns that indent.
local function hard_wrap(prev, text, cols)
  local body = prev.text:gsub("%s+$", "")
  local indent = #body:match("^%s*")
  -- Width from the unmasked row: a masked box character is three spaces.
  local width = vim.fn.strdisplaywidth((prev.plain:gsub(BOX, " "):gsub("%s+$", "")))
  if width >= cols - 4 and body:find("%S*/%S*$")
    and not text:sub(1, indent):find("%S") and text:sub(indent + 1, indent + 1):find("%S") then
    return indent
  end
end

-- One logical line per line the program wrote. A row exactly cols wide joins
-- the next when the unwrapped capture holds both together, as rex-fingers
-- does; in agent TUIs a hard-wrapped row joins too. segs map byte offsets
-- back to buffer rows: seg.from is the offset in the line, seg.col the
-- row's first byte used.
local function logical_lines(src, out)
  local prev
  for i, raw in ipairs(src.rows) do
    local plain, text, runs = parse_row(raw)
    local line, indent = out[#out], nil
    if prev and plain ~= "" and vim.fn.strdisplaywidth(prev.plain) >= src.cols
      and src.unwrapped:find(prev.plain .. plain, 1, true) then
      indent = 0
    elseif prev and src.alt then
      indent = hard_wrap(prev, text, src.cols)
      if indent then -- drop the right padding or gutter before the join
        local trimmed = line.text:gsub("%s+$", "")
        prev.len = prev.len - (#line.text - #trimmed)
        line.text = trimmed
      end
    end
    local seg = { row = src.first + i - 1, col = indent or 0, len = #text - (indent or 0), text = text, plain = plain, runs = runs }
    if indent then
      seg.from = #line.text
      line.segs[#line.segs + 1] = seg
      line.text = line.text .. text:sub(indent + 1)
    else
      seg.from = 0
      out[#out + 1] = { src = src, text = text, segs = { seg } }
    end
    prev = seg
  end
end

-- Lines first to last as a code block: at, a { line, s, e } spot, copies the
-- body without its common indent, and each body line copies itself.
local CODE = { name = "code", open = false }
local function code_block(lines, first, last, at, found, skip)
  local body, indent = {}, math.huge
  for i = first, last do
    local text = lines[i].text
    skip[i] = true
    local s, e = #text:match("^%s*"), #text:gsub("%s+$", "")
    if e > s then
      indent = math.min(indent, s)
      found[#found + 1] = { line = i, s = s, e = e, text = text:sub(s + 1, e), def = CODE }
    end
    body[#body + 1] = text
  end
  if at and indent < math.huge then
    for i, text in ipairs(body) do body[i] = text:sub(indent + 1):gsub("%s+$", "") end
    skip[at.line] = true
    found[#found + 1] = { line = at.line, s = at.s, e = at.e, text = table.concat(body, "\n"), def = CODE }
  end
end

-- Fenced code blocks, labelled on the opening fence. A fence with a language
-- always opens, so a closing fence whose block began above the screen is
-- dropped once the next block opens.
local function fences(lines, found, skip)
  local open
  for i, line in ipairs(lines) do
    local indent, lang = line.text:match("^(%s*)```(%S*)%s*$")
    if indent then
      if open and lang == "" then
        code_block(lines, open.line + 1, i - 1, open, found, skip)
        skip[i], open = true, nil
      else
        open = { line = i, s = #indent, e = #line.text:gsub("%s+$", ""), lang = lang }
      end
    end
  end
  if open and open.lang ~= "" then code_block(lines, open.line + 1, #lines, open, found, skip) end
end

-- Claude Code draws code without fences but syntax-highlights it in palette
-- colours, where prose uses default or true colours. An indented paragraph
-- with palette coloured text is a code block, labelled on the blank line
-- above it; the indent rules out status lines such as a prompt. Only
-- in the alternate screen, where agent TUIs run, so colourful shell output
-- isn't taken for code.
local function painted(line)
  for _, seg in ipairs(line.segs) do
    for _, run in ipairs(seg.runs) do
      if run.fg and run.fg:sub(1, 1) == "@" and seg.text:sub(run.s + 1, run.e):find("%S") then return true end
    end
  end
end

local function paragraphs(lines, found, skip)
  local first
  for i = 1, #lines + 1 do
    local blank = not lines[i] or skip[i] or not lines[i].src.alt or not lines[i].text:find("%S")
    if blank and first then
      local any, indented = false, true
      for j = first, i - 1 do
        any = any or painted(lines[j])
        indented = indented and lines[j].text:find("^%s") ~= nil
      end
      if any and indented then
        local above = lines[first - 1]
        above = above and above.src == lines[first].src and not above.text:find("%S")
        code_block(lines, first, i - 1, above and { line = first - 1, s = 0, e = 0 } or nil, found, skip)
      end
      first = nil
    elseif not blank and not first then
      first = i
    end
  end
end

-- Inline code without backticks: runs in one of the inline_code colours, on
-- a row that also has default-colour text, so status bars don't count. Loses
-- ties to the patterns, so a path in code colour still opens.
local function inline_code(lines, colors, found, skip)
  for i, line in ipairs(lines) do
    for _, seg in ipairs(skip[i] and {} or line.segs) do
      local prose = false
      for _, run in ipairs(seg.runs) do
        if not run.fg and seg.text:sub(run.s + 1, run.e):find("%S") then prose = true end
      end
      for _, run in ipairs(prose and seg.runs or {}) do
        local lead, body = seg.text:sub(run.s + 1, run.e):match("^(%s*)(.-)%s*$")
        if colors[run.fg] and run.s >= seg.col and body:find("%w") then
          local s = seg.from + run.s - seg.col + #lead
          found[#found + 1] = { line = i, s = s, e = s + #body, text = body, def = CODE, prio = math.huge }
        end
      end
    end
  end
end

-- Leftmost-longest across all patterns, per logical line.
local function find_matches(lines, config)
  local found, skip, colors = {}, {}, {}
  for _, color in ipairs(config.inline_code or {}) do colors[color:lower()] = true end
  fences(lines, found, skip)
  paragraphs(lines, found, skip)
  inline_code(lines, colors, found, skip)
  local defs = vim.list_extend(config.patterns or {}, BUILTIN)
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
    if offset < seg.from + seg.len or i == #line.segs then return seg.row, offset - seg.from + seg.col end
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
          vim.api.nvim_buf_set_extmark(buf, ns, seg.row, s - seg.from + seg.col,
            { end_col = e - seg.from + seg.col, hl_group = "SnapHintsMatch", priority = 200, strict = false })
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
    block = meta.source_block, alt = meta.alt, unwrapped = file:read("*a"),
  } }
  file:close()

  local lines = {}
  for _, src in ipairs(sources) do logical_lines(src, lines) end
  local matches = find_matches(lines, dofile(root .. "config.lua"))
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

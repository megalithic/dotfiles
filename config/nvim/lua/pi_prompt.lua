-- lua/pi_prompt.lua
-- Tidewave-style editor context for pi.
--   prompt(): popup for notes + context preview, then sends to the cwd-matching pi
--             over its bridge socket (pi.control.v1 message.send).
--   yank():   copies the same context to the + register.

local M = {}

local SURROUND_LINES = 15
local MAX_SCOPE_LINES = 60
local MIN_SCOPE_LINES = 5
local MAX_NODE_LINES = 40
local MAX_SELECTION_LINES = 200
local MAX_HOVER_LINES = 20
local MAX_DEFINITIONS = 5
local MAX_LABEL_WIDTH = 120
local MAX_NESTED_SCOPES = 8
local SYNTAX_PATH_DEPTH = 8
local LSP_TIMEOUT_MS = 600
local SEND_TIMEOUT_MS = 2000

local function rel(path, cwd) return vim.fs.relpath(cwd, path) or vim.fn.fnamemodify(path, ":~") end

local function line_text(buf, row) return vim.api.nvim_buf_get_lines(buf, row, row + 1, false)[1] or "" end

local function truncate_lines(text, max)
  local lines = vim.split(text, "\n", { plain = true })
  if #lines <= max then return text end
  return table.concat(vim.list_slice(lines, 1, max), "\n") .. string.format("\n... [%d more lines]", #lines - max)
end

local function node_rows(node)
  local sr, _, er, ec = node:range()
  if ec == 0 and er > sr then er = er - 1 end
  return sr, er
end

local function node_text(node, buf) return vim.treesitter.get_node_text(node, buf) end

local function line_range(first, last)
  return first == last and string.format("line %d", first) or string.format("lines %d-%d", first, last)
end

local function path_range(path, first, last)
  return first == last and string.format("%s:%d", path, first) or string.format("%s:%d-%d", path, first, last)
end

local function article(word) return word:match("^[aeiouAEIOU]") and "an" or "a" end

--------------------------------------------------------------------------------
-- Capture
--------------------------------------------------------------------------------

local function capture()
  local win = vim.api.nvim_get_current_win()
  local buf = vim.api.nvim_win_get_buf(win)
  local cursor = vim.api.nvim_win_get_cursor(win)
  local name = vim.api.nvim_buf_get_name(buf)
  local cwd = vim.fn.getcwd(win)

  local ctx = {
    win = win,
    buf = buf,
    row = cursor[1] - 1,
    col = cursor[2],
    cwd = cwd,
    path = name ~= "" and rel(name, cwd) or "[No Name]",
    filetype = vim.bo[buf].filetype,
    modified = vim.bo[buf].modified,
    word = vim.fn.expand("<cword>"),
    WORD = vim.fn.expand("<cWORD>"),
  }

  local mode = vim.fn.mode()
  if mode == "v" or mode == "V" or mode == "\22" then
    local from, to = vim.fn.getpos("v"), vim.fn.getpos(".")
    ctx.selection = {
      first = math.min(from[2], to[2]) - 1,
      last = math.max(from[2], to[2]) - 1,
      text = table.concat(vim.fn.getregion(from, to, { type = mode }), "\n"),
    }
    vim.api.nvim_feedkeys(vim.keycode("<Esc>"), "nx", false)
  end

  return ctx
end

local function focus_range(ctx)
  if not ctx.selection then return { ctx.row, ctx.col, ctx.row, ctx.col } end
  local first_line = line_text(ctx.buf, ctx.selection.first)
  local last_line = line_text(ctx.buf, ctx.selection.last)
  return { ctx.selection.first, math.max(0, (first_line:find("%S") or 1) - 1), ctx.selection.last, #last_line }
end

--------------------------------------------------------------------------------
-- Treesitter
--------------------------------------------------------------------------------

local function scope_capture_ids(lang, root, buf, row)
  local ok, query = pcall(vim.treesitter.query.get, lang, "textobjects")
  if not ok or not query then return nil end

  local wanted = {}
  for id, name in ipairs(query.captures) do
    if name == "function.outer" or name == "class.outer" then wanted[id] = true end
  end
  if vim.tbl_isempty(wanted) then return nil end

  local ids = {}
  local iter_ok = pcall(function()
    for id, node in query:iter_captures(root, buf, row, row + 1) do
      if wanted[id] then ids[node:id()] = true end
    end
  end)
  return iter_ok and ids or nil
end

local function scopes_in_tree(ltree, buf, range)
  local tree = ltree:tree_for_range(range, { ignore_injections = true })
  if not tree then return {} end

  local root = tree:root()
  local ids = scope_capture_ids(ltree:lang(), root, buf, range[1])
  local scopes, last_start, nested = {}, nil, 0
  local node = root:named_descendant_for_range(unpack(range))

  while node and not node:equal(root) do
    local sr, er = node_rows(node)
    local textobject = ids and ids[node:id()]
    local container = node:type():find("block") or node:type():find("body")
    local multiline = er > sr and not container and nested < MAX_NESTED_SCOPES
    if sr ~= last_start and (textobject or multiline) then
      table.insert(scopes, { first = sr, last = er })
      last_start = sr
      if not textobject then nested = nested + 1 end
    end
    node = node:parent()
  end

  return scopes
end

local function treesitter_info(ctx, range)
  local ok, parser = pcall(vim.treesitter.get_parser, ctx.buf)
  if not ok or not parser then return nil end
  parser:parse({ range[1], range[3] + 1 })

  local ltree = parser:language_for_range(range)
  local info = {
    parser = parser,
    host_lang = parser:lang(),
    lang = ltree:lang(),
    langs = {},
    node = parser:named_node_for_range(range, { ignore_injections = false }),
    scopes = {},
  }

  while ltree do
    table.insert(info.langs, ltree:lang())
    vim.list_extend(info.scopes, scopes_in_tree(ltree, ctx.buf, range))
    ltree = ltree:parent()
  end

  return info
end

local function syntax_path(node)
  local types = {}
  while node and #types < SYNTAX_PATH_DEPTH do
    table.insert(types, node:type())
    node = node:parent()
  end
  return table.concat(types, " < ")
end

--------------------------------------------------------------------------------
-- Language support (keyed by the host treesitter language)
--------------------------------------------------------------------------------

local ELIXIR_FUNCTIONS = {
  def = true,
  defp = true,
  defmacro = true,
  defmacrop = true,
  defguard = true,
  defguardp = true,
  defdelegate = true,
  defn = true,
  defnp = true,
}
local ELIXIR_MODULES = { defmodule = true, defprotocol = true }

local function child_of_type(node, type)
  for child in node:iter_children() do
    if child:type() == type then return child end
  end
end

local function elixir_call_target(node, buf)
  if node:type() ~= "call" then return nil end
  local target = node:field("target")[1]
  return target and node_text(target, buf), child_of_type(node, "arguments")
end

local function elixir_arity(call, buf)
  local args = child_of_type(call, "arguments")
  local arity = args and args:named_child_count() or 0
  local parent = call:parent()
  if parent and parent:type() == "binary_operator" then
    local op, right = parent:field("operator")[1], parent:field("right")[1]
    if op and right and right:equal(call) and node_text(op, buf) == "|>" then arity = arity + 1 end
  end
  return arity
end

local function elixir_head(head, buf)
  if head:type() == "binary_operator" then head = head:field("left")[1] end
  if not head then return nil end
  if head:type() == "identifier" then return node_text(head, buf), 0 end
  local name, args = elixir_call_target(head, buf)
  if name then return name, args and args:named_child_count() or 0 end
end

local function elixir_details(parser, buf, range)
  local node = parser:named_node_for_range(range, { ignore_injections = true })
  local modules, fn = {}, nil

  while node do
    local target, args = elixir_call_target(node, buf)
    local first_arg = args and args:named_child(0)
    if target and first_arg then
      if not fn and ELIXIR_FUNCTIONS[target] then
        local name, arity = elixir_head(first_arg, buf)
        if name then fn = { kind = target, name = name, arity = arity } end
      elseif ELIXIR_MODULES[target] then
        table.insert(modules, 1, node_text(first_arg, buf))
      end
    end
    node = node:parent()
  end

  local details = {}
  local module = table.concat(modules, ".")
  if module ~= "" then table.insert(details, { "module", module }) end
  if fn then
    local prefix = module ~= "" and module .. "." or ""
    table.insert(details, { "function", string.format("%s%s/%d (%s)", prefix, fn.name, fn.arity, fn.kind) })
  end
  return details
end

local function elixir_symbol(parser, buf, range)
  local node = parser:named_node_for_range(range, { ignore_injections = true })
  if not node then return nil end

  local parent = node:parent()
  local dot = (node:type() == "dot" and node) or (parent and parent:type() == "dot" and parent) or nil
  local target = dot or node
  local call = target:parent()

  if call and call:type() == "call" and call:field("target")[1] and call:field("target")[1]:equal(target) then
    local name = node_text(target, buf)
    if ELIXIR_FUNCTIONS[name] or ELIXIR_MODULES[name] then return nil end
    return string.format("%s/%d", name, elixir_arity(call, buf))
  end
  if dot then return node_text(dot, buf) end
  if node:type() == "alias" then return node_text(node, buf) end
end

local languages = {
  elixir = { details = elixir_details, symbol = elixir_symbol },
}

--------------------------------------------------------------------------------
-- LSP
--------------------------------------------------------------------------------

local function lsp_results(ctx)
  local function position(client) return vim.lsp.util.make_position_params(ctx.win, client.offset_encoding) end
  local requests = {
    definition = { method = "textDocument/definition", params = position },
    hover = { method = "textDocument/hover", params = position },
    symbols = {
      method = "textDocument/documentSymbol",
      params = function() return { textDocument = vim.lsp.util.make_text_document_params(ctx.buf) } end,
    },
  }

  local results, pending = {}, 0
  for key, request in pairs(requests) do
    if #vim.lsp.get_clients({ bufnr = ctx.buf, method = request.method }) > 0 then
      pending = pending + 1
      vim.lsp.buf_request_all(ctx.buf, request.method, request.params, function(responses)
        for _, response in pairs(responses) do
          local result = response.result
          if not results[key] and type(result) == "table" and not vim.tbl_isempty(result) then results[key] = result end
        end
        pending = pending - 1
      end)
    end
  end

  if pending > 0 then vim.wait(LSP_TIMEOUT_MS, function() return pending == 0 end, 10) end
  return results
end

local function contains(range, row, col)
  local first, last = range.start, range["end"]
  local after_start = first.line < row or (first.line == row and first.character <= col)
  local before_end = last.line > row or (last.line == row and last.character >= col)
  return after_start and before_end
end

local function symbol_path(symbols, row, col)
  local hits = {}
  local function walk(list)
    for _, symbol in ipairs(list or {}) do
      local range = symbol.range or (symbol.location and symbol.location.range)
      if range and contains(range, row, col) then
        table.insert(hits, { symbol = symbol, first = range.start.line, last = range["end"].line })
        walk(symbol.children)
      end
    end
  end
  walk(symbols)

  table.sort(hits, function(a, b)
    if a.first ~= b.first then return a.first < b.first end
    return a.last > b.last
  end)

  return vim.tbl_map(
    function(hit)
      return string.format("%s (%s)", hit.symbol.name, vim.lsp.protocol.SymbolKind[hit.symbol.kind] or "Symbol")
    end,
    hits
  )
end

local function definition_locations(result, ctx)
  local locations = {}
  for _, loc in ipairs(vim.islist(result) and result or { result }) do
    local uri = loc.uri or loc.targetUri
    local range = loc.targetSelectionRange or loc.range or loc.targetRange
    if uri and range then
      local path = rel(vim.uri_to_fname(uri), ctx.cwd)
      local line = range.start.line
      if not (path == ctx.path and line == ctx.row) and #locations < MAX_DEFINITIONS then
        table.insert(locations, string.format("%s:%d", path, line + 1))
      end
    end
  end
  return locations
end

local function hover_text(result)
  if not result.contents then return nil end
  local text = vim.trim(table.concat(vim.lsp.util.convert_input_to_markdown_lines(result.contents), "\n"))
  if text == "" then return nil end
  return truncate_lines(text, MAX_HOVER_LINES)
end

--------------------------------------------------------------------------------
-- Context
--------------------------------------------------------------------------------

local function diagnostics_between(ctx, first, last)
  local items = vim.tbl_filter(function(d) return d.lnum >= first and d.lnum <= last end, vim.diagnostic.get(ctx.buf))
  table.sort(items, function(a, b) return a.lnum < b.lnum end)

  return vim.tbl_map(function(d)
    local message = d.message:gsub("%s*\n%s*", " ")
    local source = d.source and string.format(" (%s)", d.source) or ""
    return string.format(
      "%s:%d:%d [%s] %s%s",
      ctx.path,
      d.lnum + 1,
      d.col + 1,
      vim.diagnostic.severity[d.severity],
      message,
      source
    )
  end, items)
end

local function excerpt_rows(ctx, scopes)
  local first = ctx.selection and ctx.selection.first or ctx.row
  local last = ctx.selection and ctx.selection.last or ctx.row

  local best
  for _, scope in ipairs(scopes) do
    if scope.first <= first and scope.last >= last and scope.last - scope.first < MAX_SCOPE_LINES then best = scope end
  end
  if best and best.last - best.first + 1 >= MIN_SCOPE_LINES then return best.first, best.last end

  local count = vim.api.nvim_buf_line_count(ctx.buf)
  return math.max(0, first - SURROUND_LINES), math.min(count - 1, last + SURROUND_LINES)
end

local function numbered_lines(ctx, first, last)
  local focus_first = ctx.selection and ctx.selection.first or ctx.row
  local focus_last = ctx.selection and ctx.selection.last or ctx.row
  local lines = vim.api.nvim_buf_get_lines(ctx.buf, first, last + 1, false)
  local width = #tostring(last + 1)

  for i, line in ipairs(lines) do
    local row = first + i - 1
    local mark = (row >= focus_first and row <= focus_last) and ">" or " "
    lines[i] = string.format("%s %" .. width .. "d | %s", mark, row + 1, line)
  end
  return table.concat(lines, "\n")
end

local function scope_label(ctx, scope)
  local text = vim.trim(line_text(ctx.buf, scope.first))
  if #text > MAX_LABEL_WIDTH then text = text:sub(1, MAX_LABEL_WIDTH) .. "…" end
  return string.format("%s:%d: %s", ctx.path, scope.first + 1, text)
end

local function cursor_reference(ctx, symbol)
  if ctx.selection then
    local first, last = ctx.selection.first + 1, ctx.selection.last + 1
    return {
      type = "selection",
      description = string.format("The user has selected %s.", line_range(first, last)),
      sections = {
        { "source", path_range(ctx.path, first, last) },
        { "text", truncate_lines(ctx.selection.text, MAX_SELECTION_LINES) },
      },
    }
  end

  local location = string.format("%s:%d:%d", ctx.path, ctx.row + 1, ctx.col + 1)
  local sections = { { "source", location }, { "line", line_text(ctx.buf, ctx.row) } }
  local description = string.format("The cursor is on line %d, column %d.", ctx.row + 1, ctx.col + 1)

  if ctx.word ~= "" then
    description = string.format("The cursor is on line %d, column %d, on `%s`.", ctx.row + 1, ctx.col + 1, ctx.word)
    table.insert(sections, { "word", ctx.word })
    if ctx.WORD ~= ctx.word then table.insert(sections, { "WORD", ctx.WORD }) end
  end
  if symbol then table.insert(sections, { "symbol", symbol }) end

  return { type = "cursor", description = description, sections = sections }
end

local function syntax_reference(ctx, ts)
  local node = ts.node
  local focus = node
  if focus:named_child_count() == 0 and focus:parent() then focus = focus:parent() end
  local first, last = node_rows(focus)

  local details = { "The node source is at:", "", string.format("%s:%d", ctx.path, first + 1) }
  if #ts.scopes > 0 then
    vim.list_extend(details, { "", "Enclosing scopes (from innermost to outermost):", "" })
    for _, scope in ipairs(ts.scopes) do
      table.insert(details, scope_label(ctx, scope))
    end
  end

  return {
    type = "syntax_node",
    description = string.format(
      "The %s is inside %s `%s` node (%s), %s.",
      ctx.selection and "selection" or "cursor",
      article(focus:type()),
      focus:type(),
      ts.lang,
      line_range(first + 1, last + 1)
    ),
    sections = {
      { "syntax-path", syntax_path(node) },
      { "framework-details", table.concat(details, "\n") },
      { "text", truncate_lines(node_text(focus, ctx.buf), MAX_NODE_LINES) },
    },
  }
end

local function lsp_reference(ctx, lsp)
  local sections = {}
  local locations = lsp.definition and definition_locations(lsp.definition, ctx) or {}
  if #locations > 0 then table.insert(sections, { "definition", table.concat(locations, "\n") }) end
  local hover = lsp.hover and hover_text(lsp.hover)
  if hover then table.insert(sections, { "hover", hover }) end
  if #sections == 0 then return nil end

  local subject = ctx.word ~= "" and string.format(" for `%s`", ctx.word) or ""
  return {
    type = "lsp",
    description = string.format("Language server information%s.", subject),
    sections = sections,
  }
end

local function collect()
  local ctx = capture()
  local range = focus_range(ctx)
  local ts = treesitter_info(ctx, range)
  local lsp = lsp_results(ctx)
  local support = ts and languages[ts.host_lang]

  local details = {}
  if ts then
    local outer = vim.list_slice(ts.langs, 2)
    local embedded = #outer > 0 and string.format(" (embedded in %s)", table.concat(outer, " in ")) or ""
    table.insert(details, { "language", ts.lang .. embedded })
  end
  if ctx.filetype ~= "" and not (ts and ts.host_lang == ctx.filetype) then
    table.insert(details, { "filetype", ctx.filetype })
  end
  if support and support.details then vim.list_extend(details, support.details(ts.parser, ctx.buf, range)) end
  local symbols = lsp.symbols and symbol_path(lsp.symbols, ctx.row, ctx.col) or {}
  if #symbols > 0 then table.insert(details, { "symbols", table.concat(symbols, " › ") }) end
  if ctx.modified then table.insert(details, { "unsaved changes", "yes; the buffer differs from the file on disk" }) end

  local symbol = not ctx.selection and support and support.symbol and support.symbol(ts.parser, ctx.buf, range)
  local refs = { cursor_reference(ctx, symbol) }
  if ts and ts.node then table.insert(refs, syntax_reference(ctx, ts)) end
  local lsp_ref = lsp_reference(ctx, lsp)
  if lsp_ref then table.insert(refs, lsp_ref) end

  local first, last = excerpt_rows(ctx, ts and ts.scopes or {})
  local diagnostics = diagnostics_between(ctx, first, last)
  if #diagnostics > 0 then
    table.insert(refs, {
      type = "diagnostics",
      description = string.format("Diagnostics in %s.", line_range(first + 1, last + 1)),
      sections = { { "items", table.concat(diagnostics, "\n") } },
    })
  end

  table.insert(refs, {
    type = "surrounding_code",
    description = string.format(
      "%s of %s; `>` marks the %s.",
      line_range(first + 1, last + 1):gsub("^%l", string.upper),
      ctx.path,
      ctx.selection and "selected lines" or "cursor line"
    ),
    sections = {
      { "source", path_range(ctx.path, first + 1, last + 1) },
      { "code", numbered_lines(ctx, first, last) },
    },
  })

  return {
    ctx = ctx,
    location = string.format("%s:%d:%d", ctx.path, ctx.row + 1, ctx.col + 1),
    details = details,
    refs = refs,
  }
end

local function render(data, notes)
  local out = {}
  local function add(...) vim.list_extend(out, { ... }) end
  local function tag(name, body) add("<" .. name .. ">", body, "</" .. name .. ">") end

  if notes and notes ~= "" then
    tag("user_prompt", notes)
    add("")
  end

  add('<context name="current-file">', "The user is looking at a file in Neovim.")
  tag("file", data.location)
  if #data.details > 0 then
    tag("editor-details", table.concat(vim.tbl_map(function(kv) return kv[1] .. ": " .. kv[2] end, data.details), "\n"))
  end
  add("</context>", "", "<references>")

  for i, ref in ipairs(data.refs) do
    add("", string.format('<reference id="%d" type="%s">', i - 1, ref.type))
    tag("description", ref.description)
    for _, section in ipairs(ref.sections) do
      tag(section[1], section[2])
    end
    add("</reference>")
  end

  add("", "</references>")
  return table.concat(out, "\n")
end

--------------------------------------------------------------------------------
-- Pi targets (bridge manifests)
--------------------------------------------------------------------------------

local function state_dir()
  if vim.env.PI_STATE_DIR then return vim.env.PI_STATE_DIR end
  local xdg = vim.env.XDG_STATE_HOME or vim.fs.joinpath(vim.env.HOME, ".local", "state")
  return vim.fs.joinpath(xdg, "pi")
end

local function is_socket(path)
  local stat = type(path) == "string" and vim.uv.fs_stat(path) or nil
  return stat ~= nil and stat.type == "socket"
end

local function read_targets()
  local targets = {}
  for _, file in ipairs(vim.fn.glob(vim.fs.joinpath(state_dir(), "manifests", "*.info"), false, true)) do
    local ok, manifest = pcall(
      function() return vim.json.decode(table.concat(vim.fn.readfile(file), "\n"), { luanil = { object = true } }) end
    )
    if
      ok
      and type(manifest) == "table"
      and manifest.ephemeral ~= true
      and is_socket(manifest.socket)
      and type(manifest.pid) == "number"
      and vim.uv.kill(manifest.pid, 0) == 0
    then
      table.insert(targets, manifest)
    end
  end
  return targets
end

local function tmux_window()
  if not vim.env.TMUX_PANE then return nil end
  local result = vim
    .system({ "tmux", "display-message", "-p", "-t", vim.env.TMUX_PANE, "#{session_name}\t#{window_index}" }, { text = true })
    :wait(500)
  if result.code ~= 0 then return nil end
  local session, window = vim.trim(result.stdout or ""):match("^(.-)\t(.*)$")
  return session and { session = session, window = window } or nil
end

local function target_label(target)
  local where = target.session
      and string.format("%s:%s %s", target.session, target.windowIndex or target.window, target.pane)
    or ("pid " .. target.pid)
  local name = target.sessionName or vim.fs.basename(target.cwd or "")
  return string.format("%s · %s", where, name)
end

local function resolve_target(cwd, callback)
  local all = read_targets()
  if #all == 0 then return vim.notify("pi: no running pi found", vim.log.levels.ERROR) end

  local norm = vim.fs.normalize(cwd)
  local matches = vim.tbl_filter(function(t) return t.cwd and vim.fs.normalize(t.cwd) == norm end, all)

  local window = #matches > 1 and tmux_window()
  if window then
    local same_window = vim.tbl_filter(
      function(t) return t.session == window.session and (t.windowIndex or t.window) == window.window end,
      matches
    )
    if #same_window > 0 then matches = same_window end
  end

  if #matches == 1 then return callback(matches[1]) end

  vim.ui.select(#matches > 0 and matches or all, {
    prompt = #matches > 0 and "Send to which pi?"
      or string.format("No pi in %s; send to:", vim.fn.fnamemodify(cwd, ":~")),
    format_item = target_label,
  }, function(choice)
    if choice then callback(choice) end
  end)
end

local function send(target, text, mode, callback)
  local pipe = assert(vim.uv.new_pipe(false))
  local timer = assert(vim.uv.new_timer())
  local buffer, done = "", false

  local function finish(ok, detail)
    if done then return end
    done = true
    timer:stop()
    timer:close()
    if not pipe:is_closing() then pipe:close() end
    vim.schedule(function() callback(ok, detail) end)
  end

  local request = vim.json.encode({
    type = "control",
    protocol = "pi.control.v1",
    id = string.format("nvim-%x-%x", os.time(), math.random(0, 0xffffff)),
    operation = "message.send",
    params = { text = text, mode = mode, from = "nvim" },
  })

  timer:start(SEND_TIMEOUT_MS, 0, function() finish(false, "timed out") end)
  pipe:connect(target.socket, function(connect_err)
    if connect_err then return finish(false, connect_err) end
    pipe:write(request .. "\n")
    pipe:read_start(function(read_err, chunk)
      if read_err then return finish(false, read_err) end
      if not chunk then return finish(false, "bridge closed the connection") end
      buffer = buffer .. chunk
      local line = buffer:match("^([^\n]*)\n")
      if not line then return end
      local ok, response = pcall(vim.json.decode, line, { luanil = { object = true } })
      if not ok or type(response) ~= "table" then return finish(false, "unreadable bridge response") end
      if response.ok then return finish(true, response.data and response.data.deliveredAs) end
      finish(false, response.error or "bridge rejected the message")
    end)
  end)
end

--------------------------------------------------------------------------------
-- Popup
--------------------------------------------------------------------------------

local PLACEHOLDER = "Notes for pi (optional). The context below is sent either way."
local MODES = {
  follow_up = { label = "follow-up", hl = "DiagnosticInfo" },
  steer = { label = "steer", hl = "DiagnosticWarn" },
}

local function fit(text, max)
  if vim.fn.strchars(text) <= max then return text end
  return vim.fn.strcharpart(text, 0, max - 1) .. "…"
end

local function short_label(target)
  local name = (target.sessionName or ""):gsub("^%.%.%.", ""):gsub("^…", "")
  if name == "" then name = vim.fs.basename(target.cwd or "pi") end
  local window = target.windowIndex or target.window
  return window and string.format("%s · win %s", name, window) or name
end

local function open_popup(data, target)
  local mode = "follow_up"
  local context = vim.split(render(data), "\n", { plain = true })
  local ns = vim.api.nvim_create_namespace("pi_prompt")
  local group = vim.api.nvim_create_augroup("pi_prompt_popup", { clear = true })

  local width = math.min(120, vim.o.columns - 8)
  local input_height = 5
  local preview_height = math.min(#context, 30, math.max(5, vim.o.lines - input_height - 12))
  local row = math.max(0, math.floor((vim.o.lines - input_height - preview_height - 5) / 2))
  local col = math.floor((vim.o.columns - width) / 2)

  local input, preview
  local closed = false

  local function title()
    local m = MODES[mode]
    return {
      { " pi ", "FloatTitle" },
      { " " .. fit(short_label(target), width - #m.label - 16) .. " ", "SnacksInputTitle" },
      { " " .. m.label .. " ", m.hl },
    }
  end

  local function close()
    if closed then return end
    closed = true
    pcall(vim.api.nvim_del_augroup_by_id, group)
    for _, win in ipairs({ input, preview }) do
      if win:valid() then win:close() end
    end
    vim.cmd.stopinsert()
    if vim.api.nvim_win_is_valid(data.ctx.win) then vim.api.nvim_set_current_win(data.ctx.win) end
  end

  local function submit()
    local notes = vim.trim(table.concat(vim.api.nvim_buf_get_lines(input.buf, 0, -1, false), "\n"))
    local text = render(data, notes)
    close()
    send(target, text, mode, function(ok, detail)
      if ok then
        vim.notify(string.format("pi: sent to %s (%s)", short_label(target), detail or mode))
      else
        vim.fn.setreg("+", text)
        vim.notify(string.format("pi: send failed (%s); prompt copied to clipboard", detail), vim.log.levels.ERROR)
      end
    end)
  end

  local function toggle_mode()
    mode = mode == "follow_up" and "steer" or "follow_up"
    input:set_title(title(), "left")
  end

  local function placeholder()
    if not vim.api.nvim_buf_is_valid(input.buf) then return end
    vim.api.nvim_buf_clear_namespace(input.buf, ns, 0, -1)
    local lines = vim.api.nvim_buf_get_lines(input.buf, 0, -1, false)
    if #lines > 1 or lines[1] ~= "" then return end
    vim.api.nvim_buf_set_extmark(input.buf, ns, 0, 0, {
      virt_text = { { PLACEHOLDER, "Comment" } },
      virt_text_pos = "overlay",
    })
  end

  local keys = {
    send = { "<C-s>", submit, mode = { "n", "i" }, desc = "send" },
    toggle = { "<C-t>", toggle_mode, mode = { "n", "i" }, desc = "steer/follow-up" },
    q = { "q", close, desc = "cancel" },
    cancel = { "<Esc>", close, desc = "cancel" },
  }
  local base = {
    relative = "editor",
    position = "float",
    width = width,
    col = col,
    border = "rounded",
    title_pos = "left",
    zindex = 60,
  }

  preview = Snacks.win(vim.tbl_extend("force", base, {
    row = row + input_height + 3,
    height = preview_height,
    title = { { " context ", "FloatTitle" }, { string.format(" %d lines ", #context), "SnacksInputTitle" } },
    text = context,
    ft = "xml",
    backdrop = false,
    bo = { modifiable = false },
    wo = { wrap = false, cursorline = true },
    keys = vim.tbl_extend("force", keys, {
      focus = { "<Tab>", function() input:focus() end, desc = "notes" },
    }),
  }))

  input = Snacks.win(vim.tbl_extend("force", base, {
    row = row,
    height = input_height,
    title = title(),
    footer_keys = { "<C-s>", "<C-t>", "<Tab>", "q" },
    footer_pos = "right",
    backdrop = 60,
    enter = true,
    ft = "markdown",
    wo = { wrap = true, linebreak = true },
    keys = vim.tbl_extend("force", keys, {
      focus = { "<Tab>", function() preview:focus() end, desc = "preview" },
      submit = { "<CR>", submit, desc = "send" },
      down = { "<C-d>", function() preview:scroll() end, desc = "scroll preview" },
      up = { "<C-u>", function() preview:scroll(true) end, desc = "scroll preview up" },
    }),
  }))

  placeholder()
  vim.api.nvim_create_autocmd({ "TextChanged", "TextChangedI" }, {
    group = group,
    buffer = input.buf,
    callback = placeholder,
  })
  vim.api.nvim_create_autocmd("WinClosed", {
    group = group,
    pattern = { tostring(input.win), tostring(preview.win) },
    callback = function() vim.schedule(close) end,
  })
  vim.api.nvim_create_autocmd("WinEnter", {
    group = group,
    callback = function()
      local win = vim.api.nvim_get_current_win()
      if win ~= input.win and win ~= preview.win then vim.schedule(close) end
    end,
  })

  vim.cmd.startinsert()
end

--------------------------------------------------------------------------------
-- Public API
--------------------------------------------------------------------------------

function M.context(notes) return render(collect(), notes) end

function M.prompt()
  local data = collect()
  resolve_target(data.ctx.cwd, function(target) open_popup(data, target) end)
end

function M.yank()
  local text = M.context()
  vim.fn.setreg("+", text)
  vim.notify(string.format("pi: yanked context (%d lines)", select(2, text:gsub("\n", "")) + 1))
end

return M

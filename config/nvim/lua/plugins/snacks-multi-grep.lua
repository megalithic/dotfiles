local M = {}
M.cmd = ""

local shortcuts = {
  ["c"] = "*.{h,hpp,c,cc,cpp}",
  ["l"] = "*.lua",
  ["n"] = "*.nix",
  ["x"] = "*.{ex,exs}",
  ["e"] = "*.{ex,exs}",
  ["h"] = "*.html.heex",
  ["p"] = "*.py",
  ["v"] = "*.vue",
  ["j"] = "*.{js,ts,jsx,tsx}",
  ["t"] = "*.{js,ts,jsx,tsx}",
}

local uv = vim.uv or vim.loop

---@param opts snacks.picker.grep.Config
---@param filter snacks.picker.Filter
local function get_cmd(opts, filter)
  local cmd = "rg"
  local args = {
    "--color=never",
    "--no-heading",
    "--with-filename",
    "--line-number",
    "--column",
    "--smart-case",
    "--max-columns=500",
    "--max-columns-preview",
    "-g",
    "!.git",
  }

  args = vim.deepcopy(args)

  -- exclude
  for _, e in ipairs(opts.exclude or {}) do
    vim.list_extend(args, { "-g", "!" .. e })
  end

  -- hidden
  if opts.hidden then
    table.insert(args, "--hidden")
  else
    table.insert(args, "--no-hidden")
  end

  -- ignored
  if opts.ignored then args[#args + 1] = "--no-ignore" end

  -- follow
  if opts.follow then args[#args + 1] = "-L" end

  local types = type(opts.ft) == "table" and opts.ft or { opts.ft }
  ---@cast types string[]
  for _, t in ipairs(types) do
    args[#args + 1] = "-t"
    args[#args + 1] = t
  end

  if opts.regex == false then args[#args + 1] = "--fixed-strings" end

  local glob = type(opts.glob) == "table" and opts.glob or { opts.glob }
  ---@cast glob string[]
  for _, g in ipairs(glob) do
    args[#args + 1] = "-g"
    args[#args + 1] = g
  end

  -- extra args
  vim.list_extend(args, opts.args or {})

  -- search pattern
  -- string after two spaces is treated as file glob
  local pattern, file_pattern = unpack(vim.split(filter.search, "  "))
  if file_pattern then
    if shortcuts[file_pattern] then
      vim.list_extend(args, { "--glob", shortcuts[file_pattern] })
    elseif not file_pattern:find("[%*%?%[%{]") then
      vim.list_extend(args, { "--glob", "*" .. file_pattern .. "*" })
    else
      vim.list_extend(args, { "--glob", file_pattern })
    end
  end

  args[#args + 1] = "--"
  table.insert(args, pattern)

  local paths = {} ---@type string[]

  if opts.buffers then
    for _, buf in ipairs(vim.api.nvim_list_bufs()) do
      local name = vim.api.nvim_buf_get_name(buf)
      if name ~= "" and vim.bo[buf].buflisted and uv.fs_stat(name) then paths[#paths + 1] = name end
    end
  end
  vim.list_extend(paths, opts.dirs or {})
  if opts.rtp then vim.list_extend(paths, Snacks.picker.util.rtp()) end

  -- dirs
  if #paths > 0 then
    paths = vim.tbl_map(svim.fs.normalize, paths) ---@type string[]
    vim.list_extend(args, paths)
  end

  return cmd, args
end

---@param opts snacks.picker.grep.Config
---@type snacks.picker.finder
local function finder(opts, ctx)
  if opts.need_search ~= false and ctx.filter.search == "" then
    return function() end
  end
  local absolute = (opts.dirs and #opts.dirs > 0) or opts.buffers or opts.rtp
  local cwd = not absolute and svim.fs.normalize(opts and opts.cwd or uv.cwd() or ".") or nil
  local cmd, args = get_cmd(opts, ctx.filter)
  opts.cmd = cmd
  if opts.debug.grep then Snacks.notify.info("grep: " .. cmd .. " " .. table.concat(args, " ")) end
  return require("snacks.picker.source.proc").proc({
    opts,
    {
      notify = false,
      cmd = cmd,
      args = args,
      ---@param item snacks.picker.finder.Item
      transform = function(item)
        item.cwd = cwd
        local file, line, col, text = item.text:match("^(.+):(%d+):(%d+):(.*)$")
        if not file then
          if not item.text:match("WARNING") then Snacks.notify.error("invalid grep output:\n" .. item.text) end
          return false
        else
          item.line = text
          item.file = file
          item.pos = { tonumber(line), tonumber(col) - 1 }
        end
      end,
    },
  }, ctx)
end

function M.multi_grep()
  ---@type snacks.picker.Config
  require("snacks.picker").pick({
    title = "multi-grep",
    source = "grep",
    finder = finder,
  })
end

return {
  "folke/snacks.nvim",
  -- use patched fork for https://github.com/folke/snacks.nvim/pull/2012
  multi_grep = M.multi_grep,
}

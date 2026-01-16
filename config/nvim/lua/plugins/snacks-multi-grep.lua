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

local MATCH_SEP = "󰄊󱥳󱥰"

---@param opts snacks.picker.grep.Config
---@param filter snacks.picker.Filter
local function get_cmd(opts, filter)
  local cmd = "rg"
  local args = {
    "--color=never",
    "--no-heading",
    "--with-filename",
    "--line-number",
    "--replace",
    ("%s${0}%s"):format(MATCH_SEP, MATCH_SEP),
    "--column",
    "--smart-case",
    "--max-columns=500",
    "--max-columns-preview",
    "--glob=!.bare",
    "--glob=!.git",
    "-0",
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
  local pattern, pargs = Snacks.picker.util.parse(filter.search)
  vim.list_extend(args, pargs)

  -- NOTE: start customization

  -- string after two spaces is treated as file glob
  local file_glob
  pattern, file_glob = unpack(vim.split(filter.search, "  "))
  if file_glob then
    if shortcuts[file_glob] then
      vim.list_extend(args, { "--glob", shortcuts[file_glob] })
    elseif not file_glob:find("[%*%?%[%{]") then
      vim.list_extend(args, { "--glob", "*" .. file_glob .. "*" })
    else
      vim.list_extend(args, { "--glob", file_glob })
    end
  end

  -- NOTE: end customization

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
  if opts.debug.grep then Snacks.notify.info("grep: " .. cmd .. " " .. table.concat(args, " ")) end
  return require("snacks.picker.source.proc").proc(
    ctx:opts({
      notify = false, -- never notify on grep errors, since it's impossible to know if the error is due to the search pattern
      cmd = cmd,
      args = args,
      ---@param item snacks.picker.finder.Item
      transform = function(item)
        item.cwd = cwd
        -- Split on NUL byte (which comes from rg's -0 flag)
        local file_sep = item.text:find("\0")
        if not file_sep then
          if not item.text:match("WARNING") then Snacks.notify.error("invalid grep output:\n" .. item.text) end
          return false
        end
        local file = item.text:sub(1, file_sep - 1)
        local rest = item.text:sub(file_sep + 1)
        ---@type string?, string?, string?
        local line, col, text = rest:match("^(%d+):(%d+):(.*)$")
        if not (line and col and text) then
          if not item.text:match("WARNING") then Snacks.notify.error("invalid grep output:\n" .. item.text) end
          return false
        end
        item.text = file .. ":" .. rest:gsub(MATCH_SEP, "")

        -- indices of matches
        local from = tonumber(col)
        item.pos = { tonumber(line), from - 1 }

        item.resolve = function()
          local positions = {} ---@type number[]
          local offset = 0
          local in_match = false
          while from < #text do
            local idx = text:find(MATCH_SEP, from, true)
            if not idx then break end
            if in_match then
              for i = from, idx - 1 do
                positions[#positions + 1] = i - offset
              end
              item.end_pos = item.end_pos or { item.pos[1], idx - offset - 1 }
            end
            in_match = not in_match
            offset = offset + #MATCH_SEP
            from = idx + #MATCH_SEP
          end
          item.positions = #positions > 0 and positions or nil
          item.line = text:gsub(MATCH_SEP, "")
        end

        item.file = file
      end,
    }),
    ctx
  )
end

function M.multi_grep()
  local picker = require("snacks.picker")
  ---@type snacks.picker.Config
  picker.pick({
    title = "Multi Grep",
    source = "grep",
    finder = finder,
    actions = {
      -- Open all selected items in vertical splits
      -- Use <Tab> to select multiple items, then <CR> to open them all
      vsplit_all = function(picker_instance)
        local items = picker_instance:selected({ fallback = true })
        if #items == 0 then return end

        picker_instance:close()

        -- Open ALL selected items in vsplits (even the first one)
        for _, item in ipairs(items) do
          local path = Snacks.picker.util.path(item)
          if not path then
            Snacks.notify.error("No path found for item", { title = "Multi Grep" })
            return
          end

          vim.cmd("vsplit " .. vim.fn.fnameescape(path))

          -- Position cursor at match location
          if item.pos and item.pos[1] > 0 then
            vim.api.nvim_win_set_cursor(0, { item.pos[1], item.pos[2] })
            vim.cmd("norm! zzzv") -- Center and open folds
          end
        end
      end,
    },
    win = {
      input = {
        keys = {
          -- Override default confirm to open all selections in vsplits
          ["<CR>"] = { "vsplit_all", mode = { "i", "n" } },
        },
      },
    },
  })
end

-- return M

return {
  "folke/snacks.nvim",
  -- use patched fork for https://github.com/folke/snacks.nvim/pull/2012
  ---@module 'snacks'
  ---@type snacks.Config
  opts = {
    picker = {
      enabled = true,
      ui_select = true,
      formatters = {
        file = { filename_first = true },
      },
      previewers = {
        file = {
          max_size = 10 * 1024 * 1024, -- 10MB
        },
      },
      win = {
        preview = {
          wo = {
            wrap = false,
          },
        },
      },
    },
  },
  multi_grep = M.multi_grep,
}

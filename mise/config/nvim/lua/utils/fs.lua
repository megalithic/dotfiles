mega.u.fs = {}

local format = vim.fn.fnamemodify

---@param options {capitalize: boolean}
---@return string
function mega.u.fs.root(options)
  local opts = options or { capitalize = false }

  local cwd = vim.fn.getcwd()
  local root = format(cwd, ":t")

  if opts.capitalize then
    return root:upper()
  else
    return root
  end
end

---@param loc string
---@return string
function mega.u.fs.relative_path(loc)
  return format(loc, ":.")
end

---@param loc string
---@return string
function mega.u.fs.filename(loc)
  return format(loc, ":t")
end

---@param loc string
---@return string
function mega.u.fs.filestem(loc)
  return format(loc, ":t:r")
end

---@param loc string
---@param fmt "absolute" | "relative" | "filename" | "filestem"
---@return string | nil
function mega.u.fs.format(loc, fmt)
  if fmt == "absolute" then
    return loc
  elseif fmt == "relative" then
    return mega.u.fs.relative_path(loc)
  elseif fmt == "filename" then
    return mega.u.fs.filename(loc)
  elseif fmt == "filestem" then
    return mega.u.fs.filestem(loc)
  else
    log.error("Invalid path format: " .. fmt)
    return nil
  end
end

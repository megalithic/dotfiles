--- SF Symbol image generator with caching
--- Uses Swift script to generate SF Symbol images on-demand

---@class SFSymbolOpts
---@field color? string Hex color string (default: "FFFFFF")
---@field size? number Icon size in points (default: 32)

---@class SFSymbolModule
---@field image fun(name: string, opts?: SFSymbolOpts): hs.image|nil Generate or get cached SF Symbol
---@field clearCache fun() Clear memory cache
---@field clearAll fun() Clear memory and disk cache
---@field preload fun(symbols: table) Preload multiple symbols

local M = {}

-- Cache: key = "symbolName:color:size" -> hs.image
local cache = {}

-- Path to Swift script
local scriptPath = hs.configdir .. "/scripts/sfsymbol.swift"

-- Cache directory for generated images
local cacheDir = os.getenv("TMPDIR") .. "hammerspoon-sfsymbols/"

-- Ensure cache directory exists
os.execute("mkdir -p " .. cacheDir)

--- Generate or retrieve cached SF Symbol image
---@param name string SF Symbol name (e.g., "checkmark", "gearshape")
---@param opts? table Options: color (hex string), size (number)
---@return hs.image|nil
function M.image(name, opts)
  opts = opts or {}
  local color = opts.color or "FFFFFF"
  local size = opts.size or 32
  
  -- Normalize color (remove # if present)
  color = color:gsub("^#", ""):upper()
  
  -- Cache key
  local key = string.format("%s:%s:%d", name, color, size)
  
  -- Return cached if available
  if cache[key] then
    return cache[key]
  end
  
  -- Generate filename
  local filename = string.format("%s_%s_%d.png", name, color, size)
  local filepath = cacheDir .. filename
  
  -- Check if file already exists on disk
  local file = io.open(filepath, "r")
  if file then
    file:close()
    local img = hs.image.imageFromPath(filepath)
    if img then
      cache[key] = img
      return img
    end
  end
  
  -- Generate via Swift script
  local cmd = string.format(
    '/usr/bin/swift "%s" "%s" %d "%s" "%s" 2>&1',
    scriptPath, name, size, filepath, color
  )
  
  local output, status = hs.execute(cmd)
  
  if not status then
    print("[sfsymbol] Error generating symbol:", output)
    return nil
  end
  
  -- Load the generated image
  local img = hs.image.imageFromPath(filepath)
  if img then
    cache[key] = img
    return img
  end
  
  print("[sfsymbol] Failed to load generated image:", filepath)
  return nil
end

--- Clear the cache (memory only, keeps disk files)
function M.clearCache()
  cache = {}
end

--- Clear everything (memory + disk)
function M.clearAll()
  cache = {}
  os.execute("rm -rf " .. cacheDir)
  os.execute("mkdir -p " .. cacheDir)
end

--- Preload common symbols
---@param symbols table Array of {name, color, size} tables
function M.preload(symbols)
  for _, s in ipairs(symbols) do
    M.image(s.name or s[1], {
      color = s.color or s[2],
      size = s.size or s[3] or 32,
    })
  end
end

return M

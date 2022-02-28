-- setup vim's various config directories
--
-- # cache_dirs
local data_dir = {
  mega.cache_dir .. "backup",
  mega.cache_dir .. "session",
  mega.cache_dir .. "swap",
  mega.cache_dir .. "tags",
  mega.cache_dir .. "undo",
}
if not mega.is_dir(mega.cache_dir) then
  os.execute("mkdir -p " .. mega.cache_dir)
end
for _, v in pairs(data_dir) do
  if not mega.is_dir(v) then
    os.execute("mkdir -p " .. v)
  end
end

-- # local_share_dirs
local local_share_dir = {
  mega.local_share_dir .. "shada",
}
if not mega.is_dir(mega.local_share_dir) then
  os.execute("mkdir -p " .. mega.local_share_dir)
end
for _, v in pairs(local_share_dir) do
  if not mega.is_dir(v) then
    os.execute("mkdir -p " .. v)
  end
end

--
-- ensure our runtime path has our local pack paths added; so we can just put
-- "dev" packages into that folder and they just load and work..
-- local local_packs = string.format("%s/site/pack/local", vim.fn.stdpath("data"))
-- vim.o.runtimepath = vim.o.runtimepath .. "," .. local_packs
-- resolved to -> ~/.local/share/nvim/site/pack/local/*
--

-- [ speed ] --------------------------------------------------------------- {{{
local impatient_ok, impatient = mega.load("impatient", { safe = true })
if impatient_ok then
  impatient.enable_profile()
end
-- }}}

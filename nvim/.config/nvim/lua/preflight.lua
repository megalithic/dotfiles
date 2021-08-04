-- REF: https://github.com/savq/dotfiles/blob/master/install.sh#L12-L14
local exists = pcall(vim.cmd, [[packadd paq-nvim]])
local repo_url = "https://github.com/savq/paq-nvim"
local install_path = string.format("%s/site/pack/paqs/start/", vim.fn.stdpath("data"))
-- resolved to -> ~/.local/share/nvim/site/pack/paqs/start/paq-nvim

--
-- clone paq-nvim and install if it doesn't exist..
if not exists or vim.fn.empty(vim.fn.glob(install_path)) > 0 then
  print "should be installing things"
  if vim.fn.input("-> [?] download paq-nvim? [yn] -> ") ~= "y" then
    print "-> skipping paq-nvim install."
    return
  end

  vim.fn.mkdir(install_path, "p")

  print("-> downloading paq-nvim...")
  vim.fn.system(string.format("git clone --depth 1 %s %s/%s", repo_url, install_path, "paq-nvim"))

  vim.cmd([[packadd paq-nvim]])

  print("-> paq-nvim downloaded.")

  -- install plugins
  mega.plugins()
  vim.cmd("bufdo e")

  return
end
--
-- setup vim's various config directories
local data_dir = {
  mega.cache_dir .. "backup",
  mega.cache_dir .. "session",
  mega.cache_dir .. "swap",
  mega.cache_dir .. "tags",
  mega.cache_dir .. "undo"
}
-- Only check once that If cache_dir exists
-- Then I don't want to check subs dir exists
if not mega.isdir(mega.cache_dir) then
  os.execute("mkdir -p " .. mega.cache_dir)

  for _, v in pairs(data_dir) do
    if not mega.isdir(v) then
      os.execute("mkdir -p " .. v)
    end
  end
end
--
-- ensure our runtime path has our local pack paths added; so we can just put
-- "dev" packages into that folder and they just load and work..
-- local local_packs = string.format("%s/site/pack/local", vim.fn.stdpath("data"))
-- vim.o.runtimepath = vim.o.runtimepath .. "," .. local_packs
-- resolved to -> ~/.local/share/nvim/site/pack/local/*

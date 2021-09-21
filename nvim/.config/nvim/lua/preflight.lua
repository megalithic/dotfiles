-- REF: https://github.com/savq/dotfiles/blob/master/install.sh#L12-L14
local exists = pcall(vim.cmd, [[packadd paq-nvim]])
local repo_url = "https://github.com/savq/paq-nvim"
local install_path = string.format("%s/site/pack/paqs/start/", vim.fn.stdpath("data"))
-- resolved to -> ~/.local/share/nvim/site/pack/paqs/start/paq-nvim

--
-- clone paq-nvim and install if it doesn't exist..
if not exists or vim.fn.empty(vim.fn.glob(install_path)) > 0 then
	print("should be installing things")
	if vim.fn.input("-> [?] download paq-nvim? [yn] -> ") ~= "y" then
		print("-> skipping paq-nvim install.")
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
if not mega.isdir(mega.cache_dir) then
	os.execute("mkdir -p " .. mega.cache_dir)
end
for _, v in pairs(data_dir) do
	if not mega.isdir(v) then
		os.execute("mkdir -p " .. v)
	end
end

-- # local_share_dirs
local local_share_dir = {
	mega.local_share_dir .. "shada",
}
if not mega.isdir(mega.local_share_dir) then
	os.execute("mkdir -p " .. mega.local_share_dir)
end
for _, v in pairs(local_share_dir) do
	if not mega.isdir(v) then
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

do
	-- handle caching for SPEED #gainz
	-- https://github.com/lewis6991/impatient.nvim
	--
	-- ****
	-- FIXME: presently (2021-09-21) crashing due to:
	-- ...pack/paqs/start/impatient.nvim/lua/impatient/profile.lua:142: attempt to perform arithmetic on field 'exec' (a nil value)
	-- presumably from this commit: https://github.com/lewis6991/impatient.nvim/commit/165a28c1097923c88022bb9e494430a096ca1b95
	-- ****
	--
	-- local ok, impatient = mega.load("impatient", { safe = true })
	-- if ok then
	-- 	impatient.enable_profile()
	-- end
end

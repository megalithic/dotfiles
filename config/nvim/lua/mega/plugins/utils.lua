-- @HT tiagovla/.dotfiles for this packer boilerplate

local fn = vim.fn
local fmt = string.format

-- ---A thin wrapper around vim.notify to add packer details to the message
-- ---@param msg string
local function packer_notify(msg, level) vim.notify(msg, level, { title = "Packer" }) end

local function bootstrap_packer(rtp_method, compiled_path)
  rtp_method = rtp_method or "start"
  local PACKER_INSTALL_PATH = fmt("%s/site/pack/packer/%s/packer.nvim", fn.stdpath("data"), rtp_method)

  if fn.empty(fn.glob(PACKER_INSTALL_PATH)) > 0 then
    packer_notify("Downloading packer.nvim...")
    packer_notify(
      fn.system({ "git", "clone", "--depth", "1", "https://github.com/wbthomason/packer.nvim", PACKER_INSTALL_PATH })
    )
    vim.fn.delete(compiled_path)
    vim.cmd.packadd({ "packer.nvim", bang = true })
    -- require("packer").sync()
    return true
    -- else
    --   vim.cmd.packadd({ "packer.nvim", bang = true })
  end
  return false
end

-- function _G.packer_upgrade()
--   vim.fn.delete(PACKER_INSTALL_PATH, "rf")
--   bootstrap_packer("start", PACKER_COMPILED_PATH)
-- end
--
-- vim.cmd.command({ "PackerUpgrade", ":call v:lua.packer_upgrade()", bang = true })

local function load(path)
  require("mega.plugins." .. path)
  local ok_conf, res = pcall(require, "mega.plugins." .. path)
  if ok_conf then
    return res
  else
    packer_notify(fmt("Could not load %s", path))
    return {}
  end
end

local function use(spec)
  if spec.ext then
    local config_ext = load(spec.ext)
    spec = vim.tbl_deep_extend("force", spec, config_ext)
    spec.ext = nil
  end

  require("packer").use(spec)
end

-- hard coded local plugins path
local function use_local(spec)
  local sp = vim.split(spec[1], "/")
  local repo_path = vim.fn.expand(fmt("%s/%s", vim.env.CODE, sp[#sp]), nil, nil)
  if vim.fn.isdirectory(repo_path) == 1 then
    spec[1] = repo_path
  else
    packer_notify(fmt("Could not load local %s, using online instead.", repo_path))
  end

  use(spec)
end

local function conf(name) return require(fmt("mega.plugins.%s", name)) end

return { use, use_local, bootstrap_packer, packer_notify, conf }

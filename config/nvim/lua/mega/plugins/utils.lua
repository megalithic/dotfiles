-- @HTfunction  tiagovla/.dotfiles for this packer boilerplate

local fn = vim.fn
local fmt = string.format
local M = { local_plugins = {} }

-- ---A thin wrapper around vim.notify to add packer details to the message
-- ---@param msg string
function M.notify(msg, level) vim.notify(msg, level, { title = "packer" }) end

function M.conf(name) return require(fmt("mega.plugins.%s", name)) end

local function setup_autocmds()
  mega.augroup("PackerSetupInit", {
    {
      event = { "BufWritePost" },
      pattern = { "*/mega/plugins/*.lua", "*/mega/lsp/servers.lua" },
      desc = "setup and reloaded",
      command = mega.reload,
    },
    {
      event = { "User" },
      pattern = { "VimrcReloaded" },
      desc = "setup and reloaded",
      command = mega.reload,
    },
    {
      event = { "User" },
      pattern = { "PackerCompileDone" },
      command = function() M.notify("compilation finished") end,
    },
    {
      event = { "User" },
      pattern = { "PackerComplete" },
      command = function()
        M.notify("updates finished")
        vim.defer_fn(function()
          -- if vim.env.PACKER_NON_INTERACTIVE then vim.cmd("quitall!") end
        end, 100)
      end,
    },
  })
end

function M.bootstrap()
  if fn.empty(fn.glob(vim.g.packer_install_path)) > 0 then
    M.notify("Downloading packer.nvim...")
    M.notify(fn.system({
      "git",
      "clone",
      "--depth",
      "1",
      "https://github.com/wbthomason/packer.nvim",
      vim.g.packer_install_path,
    }))
    vim.fn.delete(vim.g.packer_compiled_path)
    vim.cmd.packadd({ "packer.nvim", bang = true })
    return true
  end

  vim.cmd.packadd({ "packer.nvim", bang = true })
  setup_autocmds()
  return false
end

function M.get_name(pkg)
  local parts = vim.split(pkg, "/")
  return parts[#parts], parts[1]
end

function M.has_local(name) return vim.loop.fs_stat(vim.fn.expand(fmt("%s/%s", vim.env.CODE, name))) ~= nil end

-- This method replaces any plugins with the local clone under vim.env.CODE
function M.process_local_plugins(spec)
  if type(spec) == "string" then
    local name, owner = M.get_name(spec)
    local local_pkg = fmt("%s/%s", vim.env.CODE, name)

    if M.local_plugins[name] or M.local_plugins[owner] or M.local_plugins[owner .. "/" .. name] then
      if M.has_local(name) then
        return local_pkg
      else
        M.notify("Local package " .. name .. " not found", vim.log.levels.ERROR)
      end
    end
    return spec
  else
    for i, s in ipairs(spec) do
      spec[i] = M.process_local_plugins(s)
    end
  end
  if spec.requires then spec.requires = M.process_local_plugins(spec.requires) end
  return spec
end

-- processes external config strings
function M.process_ext_configs(spec)
  if spec.ext then spec.config = M.conf(spec.ext) end
  return spec
end

function M.wrap(use)
  return function(spec)
    if vim.g.is_local_dev then spec = M.process_local_plugins(spec) end
    spec = M.process_ext_configs(spec)
    use(spec)
  end
end

function M.sync(config, plugins)
  -- HACK: see https://github.com/wbthomason/packer.nvim/issues/180
  vim.fn.setenv("MACOSX_DEPLOYMENT_TARGET", "10.15")

  vim.cmd.packadd({ "packer.nvim", bang = true })
  setup_autocmds()

  local packer = require("packer")
  if config and plugins then
    packer.sync(config, plugins)
  else
    packer.sync()
  end
end

function M.setup(config, plugins_fn)
  -- HACK: see https://github.com/wbthomason/packer.nvim/issues/180
  vim.fn.setenv("MACOSX_DEPLOYMENT_TARGET", "10.15")

  local bootstrapped = M.bootstrap(config.compile_path)
  local packer = require("packer")
  packer.init(config)
  M.local_plugins = config.local_plugins or {}
  packer.startup({
    function(use)
      use = M.wrap(use)
      plugins_fn(use)
    end,
  })
  if bootstrapped then require("packer").sync() end
end

return M

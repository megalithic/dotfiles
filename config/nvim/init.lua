-- [ speed ] -------------------------------------------------------------------

vim.api.nvim_create_augroup("vimrc", {})
local ok, impatient = pcall(require, "impatient")
if ok then impatient.enable_profile() end

-- [ loaders ] -----------------------------------------------------------------

local ok, reload = pcall(require, "plenary.reload")
RELOAD = ok and reload.reload_module or function(...) return ... end
function R(name)
  RELOAD(name)
  return require(name)
end

R("mega.globals")
R("mega.options")
R("mega.plugins").config()

mega.u.clipboard = {}

---@param text string
function mega.u.clipboard.yank(text) vim.fn.setreg("+", text) end

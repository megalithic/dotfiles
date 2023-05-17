-- REF:
-- running tests in iex:
-- https://curiosum.com/til/run-tests-in-elixir-iex-shell?utm_medium=email&utm_source=elixir-radar

vim.cmd([[setlocal iskeyword+=!,?,-]])

-- nnoremap("<leader>ed", [[orequire IEx; IEx.pry; #respawn() to leave pry<ESC>:w<CR>]])
nnoremap("<localleader>ep", [[o|><ESC>a]])
nnoremap("<localleader>ed", [[o|> dbg()<ESC>a]])
nnoremap("<localleader>ei", [[o|> IO.inspect()<ESC>i]])
nnoremap("<localleader>eil", [[o|> IO.inspect(label: "")<ESC>hi]])

local has_wk, wk = mega.require("which-key")
if has_wk then wk.register({
  ["<localleader>e"] = { name = "+elixir" },
}) end

vim.cmd.iabbrev([[ep      |>]])
vim.cmd.iabbrev([[epry    require IEx; IEx.pry]])
vim.cmd.iabbrev([[ei      IO.inspect()<ESC>i]])
vim.cmd.iabbrev([[eputs   IO.puts()<ESC>i]])
vim.cmd.iabbrev([[edb      dbg()<ESC>i]])
vim.cmd.iabbrev([[~H      ~H""""""<ESC>2hi<CR><ESC>O<BS> ]])
vim.cmd.iabbrev([[~h      ~H""""""<ESC>2hi<CR><ESC>O<BS> ]])
vim.cmd.iabbrev([[:skip:  @tag :skip]])
vim.cmd.iabbrev([[tskip   @tag :skip]])

local function desk_cmd()
  local deskfile_cmd = ""
  local deskfile_path = require("mega.utils").root_has_file("Deskfile")
  if deskfile_path then deskfile_cmd = "eval $(desk load); " end
  return deskfile_cmd
end

-- local ms_ok, ms = mega.require("mini.surround")
-- if ms_ok then
--   vim.b.minisurround_config = {
--     custom_surroundings = {
--       ["%"] = {
--         output = function()
--           local clipboard = vim.fn.getreg("+"):gsub("\n", "")
--           return { left = "[", right = "](" .. clipboard .. ")" }
--         end,
--       },
--       L = {
--         output = function()
--           local link_name = ms.user_input("Enter the link name: ")
--           return {
--             left = "[" .. link_name .. "](",
--             right = ")",
--           }
--         end,
--       },
--       ["b"] = { -- Surround for bold
--         input = { "%*%*().-()%*%*" },
--         output = { left = "**", right = "**" },
--       },
--       ["i"] = { -- Surround for italics
--         input = { "%*().-()%*" },
--         output = { left = "*", right = "*" },
--       },
--     },
--   }
-- end

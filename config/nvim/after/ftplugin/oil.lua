-- easy quit
vim.cmd([[nnoremap <buffer> q :q<CR>]])
-- go-to parent dir
-- vim.cmd([[nmap <buffer> - <Plug>(dirbuf_up)]])
-- go-to parent dirup a dir
-- vim.cmd([[nmap <buffer> <BS> <Plug>(dirbuf_up)]])
nnoremap("<BS>", function() require("oil").open() end, { desc = "oil: goto parent dir" })
-- acts like toggle-off
vim.cmd([[nmap <buffer> <leader>ed :q<CR>]])

-- nnoremap("gp", function()
--   local oil = require("oil")
--   local entry = oil.get_cursor_entry()
--   if entry["type"] == "file" then
--     local dir = oil.get_current_dir()
--     local fileName = entry["name"]
--     local fullName = dir .. fileName
--
--     require("mega.utils").preview_image(fullName)
--   else
--     return ""
--   end
-- end, { desc = "oil: preview image" })

-- nnoremap("<C-v>", function() require("dirbuf").enter("vsplit") end, "dirbuf: open in vsplit")
-- nnoremap("<C-s>", function() require("dirbuf").enter("vsplit") end, "dirbuf: open in split")
-- nnoremap("<C-t>", function() require("dirbuf").enter("tabedit") end, "dirbuf: open in tab")

-- vim.api.nvim_win_set_width(0, 60)

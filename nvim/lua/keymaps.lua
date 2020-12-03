-- [ keymaps.. ] ---------------------------------------------------------------

local utils = require "utils"

-- local g = vim.g
-- local go = vim.o
-- local bo = vim.bo
-- local wo = vim.wo
-- local cmd = vim.cmd
-- local exec = vim.api.nvim_exec

-- ( fun ) --

local vis_selection =
  vim.api.nvim_exec(
  [[
    function! GetVisualSelection(mode)
        " call with visualmode() as the argument
        let [line_start, column_start] = getpos("'<")[1:2]
        let [line_end, column_end]     = getpos("'>")[1:2]
        let lines = getline(line_start, line_end)
        if a:mode ==# 'v'
            " Must trim the end before the start, the beginning will shift left.
            let lines[-1] = lines[-1][: column_end - (&selection == 'inclusive' ? 1 : 2)]
            let lines[0] = lines[0][column_start - 1:]
        elseif  a:mode ==# 'V'
            " Line mode no need to trim start or end
        elseif  a:mode == "\<c-v>"
            " Block mode, trim every line
            let new_lines = []
            let i = 0
            for line in lines
                let lines[i] = line[column_start - 1: column_end - (&selection == 'inclusive' ? 1 : 2)]
                let i = i + 1
            endfor
        else
            return ''
        endif
        for line in lines
            echom line
        endfor
        return join(lines, "\n")
    endfunction

    call GetVisualSelection(visualmode())
  ]],
  true
)

-- ( things3 ) -----------------------------------------------------------------

-- utils.bmap("x", "<Leader>T", "<cmd>lua print(" .. vis_selection .. ")<CR>")
utils.bmap(
  "x",
  "<Leader>T",
  '<cmd>!open "things:///add?show-quick-entry=true&title=%:t&notes=' .. vis_selection .. '<CR>"'
)

-- utils.bmap("x", "<Leader>T", os.execute("open things:///add?show-quick-entry=true&title=%:t&notes=" .. vim.api.nvim_eval(call GetVisualSelection)))
-- utils.bmap("v", "<Leader>T", '<cmd>!open things:///add?show-quick-entry=true&title=%:t&notes=%:l' .. vim.api.nvim_eval() .. '<CR>')
-- utils.bmap("v", "<Leader>T", '<cmd>lua require("telescope.builtin").fd()<CR>')

-- ( telescope.nvim ) ----------------------------------------------------------

-- utils.bmap("n", "<Leader>m", '<cmd>lua require("telescope.builtin").fd()<CR>')
-- utils.bmap("n", "<Leader>f", '<cmd>lua require("telescope.builtin").git_files()<CR>')
-- utils.bmap("n", "<Leader>a", '<cmd>lua require("telescope.builtin").live_grep()<CR>')
utils.bmap("c", "<c-r><c-r>", "<Plug>(TelescopeFuzzyCommandSearch)", {noremap = false, nowait = true})
utils.bmap("c", "<c-n>", "<Up>", {noremap = false, nowait = true})
utils.bmap("c", "<c-p>", "<Down>", {noremap = false, nowait = true})

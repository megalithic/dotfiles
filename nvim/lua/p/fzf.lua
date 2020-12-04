print "p.fzf loaded.."

local utils = require "utils"

--vim.g.fzf_layout = { 'down': '~15%' }
--vim.g.fzf_layout = { 'window': { 'width': 0.6, 'height': 0.5 } }
--vim.g.fzf_action = {
--\ 'ctrl-s': 'split',
--\ 'ctrl-v': 'vsplit',
--\ 'enter': 'vsplit'
--\ }
--vim.g.fzf_preview_window = {'right:50%:hidden', 'alt-p'}

utils.gmap("n", "<Leader>m", '<cmd>Files<CR>')

--return {
--  config = function()
--    vim.g.fzf_layout = { 'down': '~15%' }
--    vim.g.fzf_layout = { 'window': { 'width': 0.6, 'height': 0.5 } }
--    vim.g.fzf_action = {
--      \ 'ctrl-s': 'split',
--      \ 'ctrl-v': 'vsplit',
--      \ 'enter': 'vsplit'
--    \ }
--    vim.g.fzf_preview_window = {'right:50%:hidden', 'alt-p'}
--  end,
--  maps = function()
--    utils.gmap("n", "<Leader>m", '<cmd>Files<CR>')

--    -- wr.map('n', '<leader>fm', ':Marks<CR>')
--    -- wr.map('n', '<leader>ff', '<cmd>lua wr.fzfwrap.files()<cr>')
--    -- wr.map('n', '<leader>fb', '<cmd>lua wr.fzfwrap.buffers()<cr>')
--    -- wr.map('n', '<leader>fw', ':Windows<CR>')
--    -- wr.map('n', '<leader>fc', ':Commands<CR>')
--    -- wr.map('n', '<leader>f/', ':History/<CR>')
--    -- wr.map('n', '<leader>f;', ':History:<CR>')
--    -- wr.map('n', '<leader>fr', ':History<CR>')
--    -- wr.map('n', '<leader>fl', ':BLines<CR>')
--  end,
--}

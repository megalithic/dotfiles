local M = {}


M.on_attach = function(client)
  require'lsp_status'.on_attach(client)
  require'diagnostic'.on_attach()
  require'completion'.on_attach({
      sorter = 'alphabet',
      matcher = {'exact', 'fuzzy'}
    })
end

return M

let g:lsc_server_commands = {
      \  'ruby': {
      \    'command': 'solargraph stdio',
      \    'log_level': -1,
      \    'suppress_stderr': v:true,
      \  },
      \  'javascript': {
      \    'command': 'typescript-language-server --stdio',
      \    'log_level': -1,
      \    'suppress_stderr': v:true,
      \  },
      \ 'elixir': {
      \    'command': '~/.elixir_ls/rel/language_server.sh',
      \    'args': [],
      \    'filetypes': ['elixir', 'eelixir', 'ex', 'exs', 'eex'],
      \    'log_level': -1,
      \    'suppress_stderr': v:true,
      \ },
      \}

let g:lsc_auto_map = {
      \ 'GoToDefinition': '<leader>lgd',
      \ 'GoToDefinitionSplit': ['<C-W>]', '<C-W><C-]>'],
      \ 'FindReferences': '<leader>lgr',
      \ 'NextReference': '<C-n>',
      \ 'PreviousReference': '<C-p>',
      \ 'FindImplementations': '<leader>li',
      \ 'FindCodeActions': '<leader>la',
      \ 'Rename': '<leader>lr',
      \ 'ShowHover': v:true,
      \ 'DocumentSymbol': '<leader>lds',
      \ 'WorkspaceSymbol': '<leader>lws',
      \ 'SignatureHelp': '<leader>lh',
      \ 'Completion': 'omnifunc',
      \}
" \ 'Completion': 'completefunc',

let g:lsc_enable_autocomplete  = v:true
let g:lsc_enable_diagnostics   = v:true
let g:lsc_reference_highlights = v:true
let g:lsc_trace_level          = 'off'

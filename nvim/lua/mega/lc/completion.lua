local has_lsp, _ = pcall(require, "lspconfig")
if not has_lsp then
  print("[WARN] lspconfig not found/installed/loaded..")

  return
end

local M = {}

local chain_complete_list = {
  default = {
    {complete_items = {"lsp", "snippet"}},
    {complete_items = {"path"}, triggered_only = {"./", "/"}},
    {complete_items = {"buffers"}},
    {complete_items = {"ts"}},
    {mode = "<c-p>"},
    {mode = "<c-n>"}
  },
  string = {
    {complete_items = {"path"}, triggered_only = {"./", "/"}},
    {complete_items = {"buffers"}}
  },
  comment = {}
}

local customize_lsp_label = {
  Method = mega.utf8(0xf794) .. " [method]",
  Function = mega.utf8(0xf794) .. " [fun]",
  Variable = mega.utf8(0xf6a6) .. " [var]",
  Field = mega.utf8(0xf6a6) .. " [field]",
  Class = mega.utf8(0xfb44) .. " [class]",
  Struct = mega.utf8(0xfb44) .. " [struct]",
  Interface = mega.utf8(0xf836) .. " [interface]",
  Module = mega.utf8(0xf668) .. " [mod]",
  Property = mega.utf8(0xf0ad) .. " [prop]",
  Value = mega.utf8(0xf77a) .. " [val]",
  Enum = mega.utf8(0xf77a) .. " [enum]",
  Operator = mega.utf8(0xf055) .. " [operator]",
  Reference = mega.utf8(0xf838) .. " [ref]",
  Keyword = mega.utf8(0xf80a) .. " [keyword]",
  Color = mega.utf8(0xe22b) .. " [color]",
  Unit = mega.utf8(0xe3ce) .. " [unit]",
  ["snippets.nvim"] = mega.utf8(0xf68e) .. " [ns]",
  ["vim-vsnip"] = mega.utf8(0xf68e) .. " [vs]",
  Snippet = mega.utf8(0xf68e) .. " [s]",
  Text = mega.utf8(0xf52b) .. " [text]",
  Buffers = mega.utf8(0xf64d) .. " [buff]",
  TypeParameter = mega.utf8(0xf635) .. " [type]"
}

-- local function check_back_space()
--   local col = vim.fn.col(".") - 1
--   if col == 0 or vim.fn.getline("."):sub(col, col):match("%s") then
--     return true
--   else
--     return false
--   end
-- end

-- local function imap_cr()
--   if vim.fn.pumvisible() ~= 0 then
--     if vim.fn["complete_info"]()["selected"] ~= -1 then
--       vim.fn["completion#wrap_completion"]()
--     else
--       vim.api.nvim_feedkeys(vim.api.nvim_replace_termcodes("<c-e><CR>", true, false, true), "n", true)
--     end
--   else
--     vim.api.nvim_feedkeys(vim.api.nvim_replace_termcodes("<CR>", true, false, true), "n", true)
--   end
--   return ""
-- end

-- local function imap_tab()
--   if vim.fn.pumvisible() ~= 0 then
--     vim.api.nvim_feedkeys(vim.api.nvim_replace_termcodes("<c-n>", true, false, true), "n", true)
--   elseif vim.fn["vsnip#available"](1) ~= 0 then
--     -- "<Plug>(vsnip-expand-or-jump)"
--     return false
--   elseif M.check_back_space() then
--     vim.api.nvim_feedkeys(vim.api.nvim_replace_termcodes("<Tab>", true, false, true), "n", true)
--   else
--     vim.fn["completion#trigger_completion"]()
--   end
--   return true
-- end

-- -- local function show_documentation()
-- -- end

local function init_mappings()
  -- https://github.com/whyreal/dotfiles/blob/master/vim/lua/wr/plugins.lua#L92-L102
  -- https://github.com/whyreal/dotfiles/blob/master/vim/lua/wr/global.lua#L11-L45
  vim.api.nvim_exec(
    [[
function! check_back_space() abort
  let col = col('.') - 1
  return !col || getline('.')[col - 1]  =~ '\s'
endfunction

  function! show_documentation()
    if (index(['vim','help'], &filetype) >= 0)
      execute 'vert h '.expand('<cword>')
    elseif (index(['c','sh'], &filetype) >=0)
      execute 'vert Man '.expand('<cword>')
    else
      lua vim.lsp.buf.hover()
    endif
  endfunction

  imap <expr> <Tab>
        \ pumvisible() ? "\<C-n>" :
        \ vsnip#available(1)  ? '<Plug>(vsnip-expand-or-jump)' :
        \ check_back_space() ? "\<Tab>" :
        \ completion#trigger_completion()
  smap <expr> <Tab> vsnip#available(1) ? '<Plug>(vsnip-expand-or-jump)' : '<Tab>'

  imap <expr> <S-Tab>
        \ pumvisible() ? "\<C-p>" :
        \ vsnip#available(-1) ? '<Plug>(vsnip-jump-prev)' :
        \ "\<C-h>"
  smap <expr> <S-Tab> vsnip#available(-1) ? '<Plug>(vsnip-jump-prev)' : '<S-Tab>'

  let g:endwise_no_mappings = 1
  let g:completion_confirm_key = ""
  imap <expr> <CR>  pumvisible() ?
              \ complete_info()["selected"] != "-1" ?
                  \ "\<Plug>(completion_confirm_completion)" :
                  \ get(b:, 'closer') ?
                      \ "\<c-e>\<CR>\<Plug>DiscretionaryEnd\<Plug>CloserClose"
                      \ : "\<c-e>\<CR>\<Plug>DiscretionaryEnd"
              \ : get(b:, 'closer') ?
                  \ "\<CR>\<Plug>DiscretionaryEnd\<Plug>CloserClose"
                  \ : "\<CR>\<Plug>DiscretionaryEnd"

  nnoremap <silent> K :call show_documentation()<CR>

  ]],
    true
  )
end

function M.activate()
  -- [ snippets ] --------------------------------------------------------------
  vim.api.nvim_set_var("vsnip_snippet_dir", "~/.dotfiles/nvim/vsnips")

  -- [ nvim-completion ] --------------------------------------------------------------
  local has_completion, completion = pcall(require, "completion")
  if has_completion then
    completion.on_attach(
      {
        chain_complete_list = chain_complete_list,
        customize_lsp_label = customize_lsp_label,
        enable_auto_popup = 1,
        enable_auto_signature = 1,
        auto_change_source = 1,
        enable_auto_hover = 1,
        completion_enable_fuzzy_match = 1,
        completion_enable_snippet = "vim-vsnip",
        completion_trigger_on_delete = 0,
        completion_trigger_keyword_length = 2,
        max_items = 10,
        sorting = "none", -- 'alphabet'
        matching_strategy_list = {"exact", "substring", "fuzzy"}
      }
    )
    init_mappings()
  end
end

return M

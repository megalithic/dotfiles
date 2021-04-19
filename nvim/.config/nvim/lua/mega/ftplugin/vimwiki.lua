-- ## vimwiki

local zettel = {
  path = "~/Documents/_zettel",
  syntax = "markdown",
  ext = ".md",
  links_space_char = "_",
  auto_diary_index = 1,
  automatic_nested_syntaxes = 1,
  diary_header = "Daily Notes",
  diary_rel_path = "dailies/",
  diary_index = "index"
}

vim.g.vimwiki_list = {zettel}
vim.g.vimwiki_global_ext = 0
vim.g.vimwiki_auto_chdir = 1
-- vim.g.vimwiki_tags_header = "Wiki tags"
vim.g.vimwiki_auto_header = 1
vim.g.vimwiki_hl_headers = 1 --too colourful
vim.g.vimwiki_conceal_pre = 1
vim.g.vimwiki_hl_cb_checked = 1
vim.g.vimwiki_folding = "expr"
vim.g.vimwiki_markdown_link_ext = 1
vim.g.vimwiki_key_mappings = {all_maps = 0}
vim.g.vimwiki_ext2syntax = {
  [".md"] = "markdown",
  [".markdown"] = "markdown",
  [".mdown"] = "markdown"
}

-- function! VimwikiLinkHandler(link)
--   if a:link =~ '\.\(pdf\|jpg\|jpeg\|png\|gif\)$'
--     call vimwiki#base#open_link(':e ', 'file:'.a:link)
--     return 1
--   endif
--   return 0
-- endfunction


-- ## zettel

-- function! ZettelVisualLink(line,...)
--   " Mark the start, cut the text, insert a buffer character at the end of the line (in case the cut went through to the
--   " end of the line, which will cause an off-by-one error), then jump back to the location of the start of the selection
--   silent! normal! m<gvxA0`<
--   let filename = substitute(a:line, ":[0-9]\*:[0-9]\*:.\*$", "", "")
--   let title = @"
--   " insert the filename and title into the current buffer
--   let wikiname = s:get_wiki_file(filename)
--   " if the title is empty, the link will be hidden by vimwiki, use the filename
--   " instead
--   if empty(title)
--     let title = wikiname
--   end
--   let link = zettel#vimwiki#format_search_link(wikiname, title)
--   let line = getline('.')
--   " replace the [[ with selected link and title
--   let caret = col('.')
--   let length = strlen(title)
--   echom caret
--   call setline('.', strpart(line, 0, caret-1) . link .  strpart(line, caret-1))
--   " Remove the buffer character
--   silent! normal! $x
--   " Jump to the end of the replacement
--   call cursor(line('.'), caret-1 + len(link))
-- endfunction

-- function! s:get_wiki_file(filename)
--   let fileparts = split(a:filename, '\V.')
--   return join(fileparts[0:-2],".")
-- endfunction

-- autocmd BufEnter * call zettel#vimwiki#initialize_wiki_number()


-- let g:zettel_format = '%Y%m%d%H%M-%S'
-- let g:zettel_options = [{},{"front_matter" : {"tags" : ""}, "template" :  "~/Templates/zettel.tpl"}]
-- nnoremap <leader>vt :VimwikiSearchTags<space>
-- nnoremap <leader>vs :VimwikiSearch<space>
-- nnoremap <leader>gt :VimwikiRebuildTags!<cr>:ZettelGenerateTags<cr><c-l>
-- nnoremap <leader>zl :ZettelSearch<cr>
-- nnoremap <leader>zn :ZettelNew<cr><cr>:4d<cr>:w<cr>ggA
-- nnoremap <leader>bl :VimwikiBacklinks<cr>
-- nmap <leader>www <Plug>VimwikiIndex
-- nmap -- <Plug>VimwikiRemoveHeaderLevel
-- nmap <C-Left> <Plug>VimwikiDiaryPrevDay
-- nmap <C-Right> <Plug>VimwikiDiaryNextDay

-- vim.g.zettel_format = "%Y%m%d%H%M-%S"
vim.g.zettel_format = "%Y%m%d%H%M%S_%title"
vim.g.zettel_default_title = "%Y%m%d%H%M %title"
vim.g.zettel_title_format = "%Y%m%d%H%M %title"
vim.g.zettel_link_format = "[%title](%link)"
vim.g.zettel_backlinks_title = "[%title](%link)"

local function insert_zettel_id()
  if vim.g.zettel_current_id ~= nil then
    return vim.g.zettel_current_id
  else
    return ""
  end
end

-- function! s:insert_id()
--     if exists("g:zettel_current_id")
--       return g:zettel_current_id
--     else
--       return "unnamed"
--     endif
-- endfunction

-- let g:zettel_options = [{"front_matter" : [ [ "id" , function("s:insert_id")]], "template" :  "~/.vim/templates/default.tpl" }]
-- REF:
-- https://github.com/JamieJQuinn/dotenv/blob/master/.vimrc#L213-L221
-- https://github.com/shaine/dotfiles/blob/master/home/.config/nvim/init.vim#L431-L535
-- https://github.com/WizzardAlex/dotfiles/blob/master/vim/.vimrc#L173-L217
-- https://github.com/svemagie/dotfiles/blob/main/vim/dot.vim/.vimrc#L62-L125
-- https://github.com/cawal/cwl-dotfiles/blob/master/neovim/config/init.vim#L61-L169
-- https://github.com/abers/dotfiles/blob/master/.config/nvim/init.vim#L313-L347
-- https://github.com/phux/.dotfiles/blob/master/roles/neovim/files/lua/plugins/_zettel.lua

vim.g.zettel_options = {
  {},
  {
    front_matter = {
      id = insert_zettel_id(),
      tags = "",
      type = "note"
    }
    -- template = "~/Documents/zettel/_templates/zettel.tpl"
  }
}

vim.g.zettel_fzf_command = "rg --column --line-number --ignore-case --no-heading --color=always "

-- vim.g.zettel_format = "%Y%m%d%H%M"
-- vim.g.vimwiki_list = [{'path': '~/path/to/zettelkasten/', 'syntax': 'markdown', 'ext': '.md'}]
-- vim.g.vimwiki_markdown_link_ext = 1
-- vim.g.vimwiki_ext2syntax = {'.md': 'markdown', '.markdown': 'markdown', '.mdown': 'markdown'}
-- vim.g.nv_search_paths = ['~/path/to/Zettelkasten']
-- vim.g.zettel_options = [{"front_matter" : [["tags", ""], ["citation", ""]]}]
-- vim.g.zettel_fzf_command = "rg --column --line-number --ignore-case --no-heading --color=always "
-- nnoremap <leader>nz :ZettelNew<space>

-- do
--   -- vim.g.wiki_root = "~/Documents/_wiki"
--   -- vim.g.wiki_filetypes = {"md"}
--   -- vim.g.wiki_link_target_type = "md"
--   -- vim.g.wiki_map_link_create = "CreateLinks" -- cannot use anonymous functions
--   -- vim.cmd [[
--   --   function! CreateLinks(text) abort
--   --     return substitute(tolower(a:text), '\s\+', '-', 'g')
--   --   endfunction
--   -- ]]

--   -- vimwiki REFS:
--   -- https://github.com/peterhajas/dotfiles/blob/master/vim/.vimrc#L392-L441
--   -- https://github.com/akinsho/dotfiles/blob/main/.config/nvim/lua/as/plugins/vimwiki.lua

--   vim.g.vimwiki_list = {
--     {
--       path = vim.fn.expand("$HOME/Documents/_wiki"),
--       syntax = "markdown",
--       ext = ".md",
--       auto_diary_index = 1,
--       auto_toc = 1,
--       auto_generate_links = 1,
--       auto_tags = 1
--       -- auto_tags = true,
--       -- auto_toc = true,
--       -- auto_generate_links = true,
--       -- auto_generate_tags = true,
--       -- auto_diary_index = true
--     }
--   }
--   vim.g.vimwiki_global_ext = 0
--   vim.g.vimwiki_auto_chdir = 1
--   vim.g.vimwiki_tags_header = "Wiki tags"
--   vim.g.vimwiki_auto_header = 1
--   vim.g.vimwiki_hl_headers = 1 --too colourful
--   vim.g.vimwiki_conceal_pre = 1
--   vim.g.vimwiki_hl_cb_checked = 1
--   -- vim.g.vimwiki_list = {vim.g.wiki, vim.g.learnings_wiki, vim.g.system_wiki}
--   vim.g.vimwiki_folding = "expr"
--   vim.g.vimwiki_markdown_link_ext = 1
--   vim.g.vimwiki_ext2syntax = {
--     [".md"] = "markdown",
--     [".markdown"] = "markdown",
--     [".mdown"] = "markdown"
--   }
--   -- vim.g.vimwiki_key_mappings = {all_maps = 0}

--   -- vim.g.vimwiki_global_ext = 0
--   -- vim.g.vimwiki_list = {
--   --     path = "~/src/github.com/evantravers/undo-zk/wiki/",
--   --     syntax = "markdown",
--   --     ext = ".md",
--   --     diary_rel_path = "journal"
--   --   }
--   -- }

--   vim.g.nv_search_paths = {"~/Documents/_wiki/"}
--   vim.g.zettel_format = "%Y%m%d-%H%M%S"
--   -- vim.g.zettel_format = "%Y%m%d%H%M-%S"
--   -- vim.g.zettel_options = [{},{"front_matter" : {"tags" : ""}, "template" :  "~/Templates/zettel.tpl"}]
--   vim.g.zettel_fzf_command = "rg --column --line-number --ignore-case --no-heading --color=always "
--   --
--   -- nnoremap <leader>vt :VimwikiSearchTags<space>
--   -- nnoremap <leader>vs :VimwikiSearch<space>
--   -- nnoremap <leader>gt :VimwikiRebuildTags!<cr>:ZettelGenerateTags<cr><c-l>
--   -- nnoremap <leader>zl :ZettelSearch<cr>
--   -- nnoremap <leader>zn :ZettelNew<cr><cr>:4d<cr>:w<cr>ggA
--   -- nnoremap <leader>bl :VimwikiBacklinks<cr>
--   -- let g:vimwiki_list = [{'path': '~/Documents/notes/', 'syntax': 'markdown', 'ext': '.md', 'auto_tags': 1, 'auto_diary_index': 1},
--   --                      \{'path': '~/Documents/wiki/', 'syntax': 'markdown', 'ext': '.md', 'auto_tags': 1}]

--   -- let g:nv_search_paths = ['~/Documents/notes/']

--   -- " Filename format. The filename is created using strftime() function
--   -- let g:zettel_format = "%y%m%d-%H%M"

--   -- let g:zettel_fzf_command = "rg --column --line-number --ignore-case --no-heading --color=always "

--   -- " Set template and custom header variable for the second Wiki
--   -- " let g:zettel_options = [{"front_matter" : {"tags" : ""}, "template" :  "./vimztl.tpl"},{}]

--   -- nnoremap <leader>sn/ :NV<CR>

--   -- nnoremap <leader>zn :ZettelNew<space>
--   -- nnoremap <leader>z<leader>i :ZettelGenerateLinks<CR>
--   -- nnoremap <leader>z<leader>t :ZettelGenerateTags<CR>
--   vim.cmd "packadd vimwiki"
-- end

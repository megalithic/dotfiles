" Fancy macros
nnoremap q <Nop>
nnoremap Q @q
vnoremap Q :norm @q<cr>

" esc mechanisms
imap jk <ESC>

" Jump key
nnoremap ` '
nnoremap ' `

" flip between two last edited files
nnoremap <leader><leader> <C-^>

" Change pane
nnoremap <C-h> <C-w>h
nnoremap <C-j> <C-w>j
nnoremap <C-k> <C-w>k
nnoremap <C-l> <C-w>l
" ## Splits with vim-tmux-navigator
nnoremap <silent><C-h> :TmuxNavigateLeft<CR>
nnoremap <silent><C-j> :TmuxNavigateDown<CR>
nnoremap <silent><C-k> :TmuxNavigateUp<CR>
nnoremap <silent><C-l> :TmuxNavigateRight<CR>

" Turn off search highlight
nnoremap <localleader>/ :nohlsearch<CR>

" ## Writing / quitting
silent! unmap <leader>w
nnoremap <silent><leader>w :w<CR>
nnoremap <silent><leader>W :w !sudo tee > /dev/null %<CR>
cmap w!! w !sudo tee > /dev/null %
nnoremap <leader>q :q<CR>

" open a (new)file in a new vsplit
nnoremap <silent><leader>o :vnew<CR>:e<space><C-d>
nnoremap <leader>o :vnew<CR>:e<space>

" Background (n)vim
vnoremap <C-z> <ESC>zv`<ztgv

" Default to case insensitive search
nnoremap / /\v
vnoremap / /\v

" Don't overwrite blackhole register with selection
" https://www.reddit.com/r/vim/comments/clccy4/pasting_when_selection_touches_eol/
" xnoremap p "_c<c-r>"<esc>
" xmap P p

" clear incsearch term
nnoremap <silent><ESC> :syntax sync fromstart<CR>:nohlsearch<CR>:redrawstatus!<CR><ESC>

" Start substitute on current word under the cursor
nnoremap <leader>s :%s///gc<Left><Left><Left>

" Start search on current word under the cursor
nnoremap <leader>/ /<CR>

" Start reverse search on current word under the cursor
nnoremap <leader>? ?<CR>

" Faster sort
vnoremap <leader>s :!sort<CR>

" Command mode conveniences
noremap <leader>: :!
noremap <leader>; :<Up>

" Remap VIM 0 to first non-blank character
map 0 ^

" Easier to type, however, i hurt my muscle memory when on remote vim  for now
noremap H ^
noremap L $
vnoremap L g_

" ## Selections
" reselect pasted content:
nnoremap gV `[v`]
" select all text in the file
nnoremap <leader>v ggVG
" Easier linewise reselection of what you just pasted.
nnoremap <leader>V V`]
" gi already moves to 'last place you exited insert mode', so we'll map gI to
" something similar: move to last change
nnoremap gI `.
" reselect visually selected content:
xnoremap > >gv

" ## Indentions
" Indent/dedent/autoindent what you just pasted.
nnoremap <lt>> V`]<
nnoremap ><lt> V`]>
nnoremap =- V`]=

" make the tab key match bracket pairs
silent! unmap [%
silent! unmap ]%
map <Tab> %
smap <Tab> %
noremap <Tab> %
nnoremap <Tab> %
vnoremap <Tab> %
xnoremap <Tab> %

" Quick edit of certain files
map <leader>ev :vnew! ~/.dotfiles/nvim/init.vim<CR>
map <leader>ek :vnew! ~/.dotfiles/kitty/kitty.conf<CR>
map <leader>eg :vnew! ~/.gitconfig<CR>
map <leader>et :vnew! ~/.dotfiles/tmux/tmux.conf.symlink<CR>
map <leader>ez :vnew! ~/.dotfiles/zsh/zshrc.symlink<CR>
map <leader>eh :vnew! ~/.dotfiles/hammerspoon/hammerspoon.symlink/config.lua<CR>

" ## Join and Split Lines
" Keep the cursor in place while joining lines
nnoremap J mzJ`z
" Split line (sister to [J]oin lines above)
" The normal use of S is covered by cc, so don't worry about shadowing it.
nnoremap S i<CR><ESC>^mwgk:silent! s/\v +$//<CR>:noh<CR>`w

" Easily escape terminel
" tnoremap <leader><esc> <C-\><C-n><esc><cr>

" Copy command
vnoremap <C-x> :!pbcopy<CR>
vnoremap <C-c> :w !pbcopy<CR><CR>

" mbbill/undotree
nnoremap <F7> :UndotreeToggle<CR>

" These create newlines like o and O but stay in normal mode
nmap zj o<Esc>
nmap zk O<Esc>

" ## buffers
nnoremap <leader>bd :bdelete<cr>
nnoremap <leader>bf :bfirst<cr>
nnoremap <leader>bl :blast<cr>
nnoremap <leader>bn :bnext<cr>
nnoremap <leader>bp :bprevious<cr>
nnoremap <leader>b# :b#<cr>
nnoremap <leader>bx :%bd\|e#<cr>

" open vertical term for REPL tings
" noremap <leader>r :only<CR> :vert terminal<CR>

" ## vim-plug
noremap <F5> :PlugUpdate<CR>
map <F5> :PlugUpdate<CR>
noremap <S-F5> :PlugClean!<CR>
map <S-F5> :PlugClean!<CR>

" Zoom buffer to a tab
function! s:zoom()
  if winnr('$') > 1
    tab split
  elseif len(filter(map(range(tabpagenr('$')), 'tabpagebuflist(v:val + 1)'),
                  \ 'index(v:val, '.bufnr('').') >= 0')) > 1
    tabclose
  endif
endfunction
nnoremap <silent> <leader>z :call <sid>zoom()<cr>

" Things 3
command! -nargs=* Things :silent !open "things:///add?show-quick-entry=true&title=%:t&notes=%<cr>"
nnoremap <Leader>T :Things<cr>

" Bubble single lines
nnoremap <C-Up> :m .-2<CR>
nnoremap <C-Down> :m  .+1<CR>

" Bubble multiple lines
vnoremap <silent> <C-Up>  @='"zxk"zP`[V`]'<CR>
vnoremap <silent> <C-Down>  @='"zx"zp`[V`]'<CR>

" Break undo sequences into chunks (after punctuation); see: `:h i_CTRL-G_u`
"
" From:
"
"   https://twitter.com/vimgifs/status/913390282242232320
"
" Via:
"
"   https://github.com/wincent/wincent/commit/0d0b647b97a794b99a648d4c18ad0f6c0dfeedce
"   https://github.com/ahmedelgabri/dotfiles/blob/f2b74f6cd4d/files/.vim/plugin/mappings.vim#L27-L33
"
inoremap <buffer> ! !<C-g>u
inoremap <buffer> , ,<C-g>u
inoremap <buffer> . .<C-g>u
inoremap <buffer> : :<C-g>u
inoremap <buffer> ; ;<C-g>u
inoremap <buffer> ? ?<C-g>u

nnoremap <leader>ft :echo luaeval("require('window').floating_window(false, 0.8, 0.6)") <bar> :term<CR>
" https://github.com/pwntester/dotfiles/blob/master/config/nvim/plugins.vim#L297
nnoremap <leader>gg :echo luaeval("require('window').floating_window(false, 0.8, 0.6)") <bar> :call termopen("lazygit")<CR>

" debug syntax
nmap <silent> gs :echo 'hi<'.synIDattr(synID(line('.'), col('.'), 1), 'name')
	\.'> trans<'.synIDattr(synID(line('.'), col('.'), 0), 'name').'> lo<'
	\.synIDattr(synIDtrans(synID(line('.'), col('.'), 1)), 'name').'>'<CR>

" For moving quickly up and down,
" Goes to the first line above/below that isn't whitespace
" Thanks to: http://vi.stackexchange.com/a/213
nnoremap <silent> gj :let _=&lazyredraw<CR>:set lazyredraw<CR>/\%<C-R>=virtcol(".")<CR>v\S<CR>:nohl<CR>:let &lazyredraw=_<CR>

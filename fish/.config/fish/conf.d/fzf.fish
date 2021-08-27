set -q FZF_TMUX_HEIGHT; or set -U FZF_TMUX_HEIGHT "40%"
set -q FZF_DEFAULT_OPTS; or set -U FZF_DEFAULT_OPTS "--height $FZF_TMUX_HEIGHT"
set -q FZF_LEGACY_KEYBINDINGS; or set -U FZF_LEGACY_KEYBINDINGS 1
set -q FZF_DISABLE_KEYBINDINGS; or set -U FZF_DISABLE_KEYBINDINGS 0
set -q FZF_PREVIEW_FILE_CMD; or set -U FZF_PREVIEW_FILE_CMD "head -n 10"
set -q FZF_PREVIEW_DIR_CMD; or set -U FZF_PREVIEW_DIR_CMD ls

if test "$FZF_DISABLE_KEYBINDINGS" -ne 1
    if test "$FZF_LEGACY_KEYBINDINGS" -eq 1
        bind \ct __fzf_find_file
        bind \cr __fzf_reverse_isearch
        bind \ec __fzf_cd
        bind \eC '__fzf_cd --hidden'
        bind \cg __fzf_open
        bind \co '__fzf_open --editor'

        if bind -M insert >/dev/null 2>/dev/null
            bind -M insert \ct __fzf_find_file
            bind -M insert \cr __fzf_reverse_isearch
            bind -M insert \ec __fzf_cd
            bind -M insert \eC '__fzf_cd --hidden'
            bind -M insert \cg __fzf_open
            bind -M insert \co '__fzf_open --editor'
        end
    else
        bind \co __fzf_find_file
        bind \cr __fzf_reverse_isearch
        bind \ec __fzf_cd
        bind \eC '__fzf_cd --hidden'
        bind \eO __fzf_open
        bind \eo '__fzf_open --editor'

        if bind -M insert >/dev/null 2>/dev/null
            bind -M insert \co __fzf_find_file
            bind -M insert \cr __fzf_reverse_isearch
            bind -M insert \ec __fzf_cd
            bind -M insert \eC '__fzf_cd --hidden'
            bind -M insert \eO __fzf_open
            bind -M insert \eo '__fzf_open --editor'
        end
    end

    if not bind --user \t >/dev/null 2>/dev/null
        if set -q FZF_COMPLETE
            bind \t __fzf_complete
            if bind -M insert >/dev/null 2>/dev/null
                bind -M insert \t __fzf_complete
            end
        end
    end
end

function _fzf_uninstall -e fzf_uninstall
    bind --user \
        | string replace --filter --regex -- "bind (.+)( '?__fzf.*)" 'bind -e $1' \
        | source

    set --names \
        | string replace --filter --regex '(^FZF)' 'set --erase $1' \
        | source

    functions --erase _fzf_uninstall
end

# https://github.com/folke/dot/blob/master/config/fish/conf.d/fzf.fish
bind \cr __fzf_history
bind \ch __fzf_tldr
bind \ct __fzf_files

set -l color00 '#323d43'
set -l color01 '#3c474d'
set -l color02 '#465258'
set -l color03 '#505a60'
set -l color04 '#d8caac'
set -l color05 '#d5c4a1'
set -l color06 '#ebdbb2'
set -l color07 '#fbf1c7'
set -l color08 '#fb4934'
set -l color09 '#fe8019'
set -l color0A '#fabd2f'
set -l color0B '#b8bb26'
set -l color0C '#8ec07c'
set -l color0D '#83a598'
set -l color0E '#d3869b'
set -l color0F '#d65d0e'


# set -q FZF_TMUX_HEIGHT; or set -U FZF_TMUX_HEIGHT "40%"
# set -q FZF_DEFAULT_OPTS; or set -U FZF_DEFAULT_OPTS "--height $FZF_TMUX_HEIGHT"
# set -q FZF_LEGACY_KEYBINDINGS; or set -U FZF_LEGACY_KEYBINDINGS 1
# set -q FZF_DISABLE_KEYBINDINGS; or set -U FZF_DISABLE_KEYBINDINGS 0
# set -q FZF_PREVIEW_FILE_CMD; or set -U FZF_PREVIEW_FILE_CMD "head -n 10"
# set -q FZF_PREVIEW_DIR_CMD; or set -U FZF_PREVIEW_DIR_CMD ls

set -U FZF_TMUX 1
set -x FZF_TMUX_HEIGHT "30%"
set -x FZF_DEFAULT_OPTS " \
--inline-info \
--select-1 \
--ansi \
--extended \
--bind ctrl-j:ignore,ctrl-k:ignore \
--bind ctrl-f:page-down,ctrl-b:page-up,J:down,K:up \
--cycle \
--no-multi \
--no-border \
--preview-window=right:60%:wrap \
--preview 'bat --theme="base16" --style=numbers,changes --color always {}' \
"

set -x FZF_DEFAULT_OPTS " \
  --color=bg+:$color01,bg:$color00,spinner:$color0C,hl:$color0D \
  --color=fg:$color04,header:$color0D,info:$color0A,pointer:$color0C \
  --color=marker:$color0C,fg+:$color06,prompt:$color0A,hl+:$color0D \
"

# set -x FZF_DEFAULT_OPTS "--cycle --layout=reverse --border --height 40% --preview-window=right:70% \
#     --color=bg+:$color01,bg:$color00,spinner:$color0C,hl:$color0D \
#     --color=fg:$color04,header:$color0D,info:$color0A,pointer:$color0C \
#     --color=marker:$color0C,fg+:$color06,prompt:$color0A,hl+:$color0D"

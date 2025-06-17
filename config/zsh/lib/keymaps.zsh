# see all zle widgets to be keybound: zle -al
# see all keybindings:                bindkey
# see keycodes in realtime:           \cat -v

typeset -g -A key # TODO: need to figure out what this is doing

# unbind my pane/window/buffer/split navigation keys that zsh steals
bindkey -r '^J'
bindkey -r '^K'
bindkey -r '^L'
bindkey -r '^H'

bindkey '^H' delete-word    # iterm
bindkey '^[[3~' delete-char # tmux

bindkey '^[[1;9D' backward-word # iterm
bindkey '^[^[[D' backward-word  # tmux os x

bindkey '^[[1;9C' forward-word # iterm
bindkey '^[^[[C' forward-word  # tmux os x

bindkey '^[[H' beginning-of-line  # iterm
bindkey '^[[1~' beginning-of-line # tmux

bindkey '^[[F' end-of-line  # iterm
bindkey '^[[4~' end-of-line # tmux

# FZF keybindings for completion
# https://github.com/junegunn/fzf/wiki/Fuzzy-completion
# bindkey '^T' fzf-completion
# bindkey '^I' $fzf_default_completion
# bindkey "^d" fzf-cd-widget

# Interesting keybindings from "pjg"
# https://github.com/pjg/dotfiles/blob/master/.zshrc#L443
#
# alt + arrows
bindkey '[D' backward-word
bindkey '[C' forward-word
bindkey '^[[1;3D' backward-word
bindkey '^[[1;3C' forward-word

# ctrl + arrows
bindkey '^[OD' backward-word
bindkey '^[OC' forward-word
bindkey '^[[1;5D' backward-word
bindkey '^[[1;5C' forward-word

# home / end
bindkey '^[[1~' beginning-of-line
bindkey '^[[4~' end-of-line

# delete
bindkey '^[[3~' delete-char
bindkey '^[3;5~' delete-char

# page up / page down
bindkey '^[[5~' history-beginning-search-backward
bindkey '^[[6~' history-beginning-search-forward

# shift + tab
bindkey '^[[Z' reverse-menu-complete

# for autosuggestions phrase accept
# bindkey '^j' vi-forward-blank-word

# Add Some Emacs Keybindings
bindkey '^p' up-history
bindkey '^n' down-history
bindkey '^w' backward-kill-word
bindkey '^u' backward-kill-line
bindkey '^a' beginning-of-line
bindkey '^e' end-of-line
bindkey -M vicmd '^a' beginning-of-line
bindkey -M vicmd '^e' end-of-line
bindkey -M viins '^e' end-of-line
# bindkey -M vicmd '^[[1~' beginning-of-line
# bindkey -M vicmd '^[[4~' end-of-line

# Fix ESC-/ Chord (Perform Search)
vi-search-fix() {
  zle vi-cmd-mode
  zle .vi-history-search-backward
}

autoload vi-search-fix
zle -N vi-search-fix
bindkey -M viins '\e/' vi-search-fix

# Fix Backspace
bindkey "^?" backward-delete-char

# vim-like reverse history search
bindkey -M vicmd '/' history-incremental-search-backward

# bindkey "^R" history-search-multi-word
bindkey "^R" fzf-history-widget
bindkey "^D" fzf-cd-widget

# REF: https://github.com/jose-elias-alvarez/dotfiles/blob/1b1d725459df1ba1fc62b1bacc510fe8f28b3eaa/home/zshrc#L1-L2
bindkey "^P" up-line-or-search
bindkey "^N" down-line-or-search

# -- zsh-users/zsh-history-substring-search
# REF: https://github.com/agkozak/dotfiles/blob/master/.zshrc#L550-L556
# up and down arrows:
bindkey '^[[A' history-substring-search-up
bindkey '^[[B' history-substring-search-down

bindkey -M vicmd 'k' history-substring-search-up
bindkey -M vicmd 'j' history-substring-search-down

bindkey "^k" history-substring-search-up
bindkey "^j" history-substring-search-down

bindkey '^P' history-substring-search-up
bindkey '^N' history-substring-search-down

bindkey "$terminfo[kcuu1]" history-substring-search-up
bindkey "$terminfo[kcud1]" history-substring-search-down

# REF: https://jdhao.github.io/2019/06/13/zsh_bind_keys/#bind-key-to-run-a-custom-command
# bindkey -s '^o' 'nvim $(fzf)^M'

bindkey '^]' clear-screen

# -- edit command in vim
# REF:
# - https://nuclearsquid.com/writings/edit-long-commands/
# - https://twitter.com/citizen428/status/13260131377
# - https://unix.stackexchange.com/questions/6620/how-to-edit-command-line-in-full-screen-editor-in-zsh

# Emacs style
# Enable Ctrl-x-e to edit command line
# zle -N edit-command-line
# bindkey '^xe' edit-command-line
# bindkey '^x^e' edit-command-line

autoload -U edit-command-line
bindkey -M vicmd "^V" edit-command-line
bindkey "^V" edit-command-line

# repeat-prev-command() {
#     if [[ $BUFFER == "k" ]]; then
#         BUFFER=$history[$((HISTCMD-1))]
#     fi
#     zle accept-line
# }
# zle -N repeat-prev-command
# bindkey -M viins '^g' repeat-prev-command
# bindkey -M vicmd '^g' repeat-prev-command
# bindkey '^g' repeat-prev-command

bindkey '^y' autosuggest-accept

# Enable shift-tab to cycle back completions
bindkey -M menuselect '^[[Z' reverse-menu-complete
setopt menu_complete

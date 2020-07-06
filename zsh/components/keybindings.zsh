typeset -g -A key # TODO: need to figure out what this is doing

# bindkey -e # use emacs key bindings # potentially breaking? first char gobbled on focus in zsh? remove to fix it, but lose the below bindings
# bindkey -v # use vi key bindings # potentially breaking? first char gobbled on focus in zsh? remove to fix it, but lose the below bindings

bindkey '^H' delete-word # iterm
bindkey '^[[3~' delete-char # tmux

bindkey '^[[1;9D' backward-word # iterm
bindkey '^[^[[D' backward-word # tmux os x

bindkey '^[[1;9C' forward-word # iterm
bindkey '^[^[[C' forward-word # tmux os x

bindkey '^[[H' beginning-of-line # iterm
bindkey '^[[1~' beginning-of-line # tmux

bindkey '^[[F' end-of-line # iterm
bindkey '^[[4~' end-of-line # tmux

# FZF keybindings for completion
# https://github.com/junegunn/fzf/wiki/Fuzzy-completion
# bindkey '^T' fzf-completion
# bindkey '^I' $fzf_default_completion

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
bindkey '^j' vi-forward-blank-word


# Add Some Emacs Keybindings
bindkey '^p' up-history
bindkey '^n' down-history
bindkey '^w' backward-kill-word
# bindkey '^f' autosuggest-accept
bindkey '^u' backward-kill-line
bindkey '^a' beginning-of-line
bindkey '^e' end-of-line

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

# Initialize colors.
autoload -U colors; colors

# colors
# The variables are wrapped in %{%}. This should be the case for every
# variable that does not contain space.
for COLOR in RED GREEN YELLOW BLUE MAGENTA CYAN BLACK WHITE; do
  eval PR_$COLOR='%{$fg_no_bold[${(L)COLOR}]%}'
  eval PR_BOLD_$COLOR='%{$fg_bold[${(L)COLOR}]%}'
done

eval RESET='$reset_color'
export PR_RED PR_GREEN PR_YELLOW PR_BLUE PR_WHITE PR_BLACK
export PR_BOLD_RED PR_BOLD_GREEN PR_BOLD_YELLOW PR_BOLD_BLUE
export PR_BOLD_WHITE PR_BOLD_BLACK

# Clear LSCOLORS
# unset LSCOLORS

# Main change, you can see directories on a dark background
# export LSCOLORS=gxfxcxdxbxegedabagacad
# export CLICOLOR=true
# export LSCOLORS="ExGxBxDxCxEgEdxbxgxcxd"
export CLICOLOR=1

# -------- do not want here right now; breaking stuff
# # color stuffs
(command -v gdircolors &>/dev/null) && eval `gdircolors $HOME/.dircolors`

# Fallback to built in ls colors
# zstyle ':completion:*' list-colors ''
# ref: https://github.com/robbyrussell/oh-my-zsh/issues/1563#issuecomment-53638038
# zstyle ':completion:*:default' list-colors "${(@s.:.)LS_COLORS}"
# zstyle ':completion:*:default' list-colors ${(s.:.)LS_COLORS}
zstyle ':completion:*' list-colors ${(s.:.)LS_COLORS}

# https://github.com/xPMo/zsh-ls-colors#customizing-colors-with-styles
zstyle -e '*' list-colors 'reply=(${(s[:])LS_COLORS})'

export LS_COLORS="$(vivid generate nord)"


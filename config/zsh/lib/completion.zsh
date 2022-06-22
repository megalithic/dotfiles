# REFS:
# https://github.com/ahmedelgabri/dotfiles/blob/main/config/zsh.d/zsh/config/completion.zsh#L54

setopt always_to_end
setopt auto_menu
setopt list_packed
setopt extended_glob

_comp_options+=(globdots) # Include hidden files.

# zsh speedsup: https://carlosbecker.com/posts/speeding-up-zsh/
autoload -Uz +X compinit
for dump in ~/.zcompdump(N.mh+24); do
  compinit
done
compinit -C


# REF:
# https://github.com/mhanberg/.dotfiles/blob/main/zsh/funcs#L3
# https://github.com/mhanberg/.dotfiles/blob/main/zsh/git.zsh
compdef g=git

# FIXME: fixes insecure directory warnings
# TODO: should we run this on every sourcing?
# compaudit | xargs chmod g-w

# Kitty completions
if [[ "$TERM" == "xterm-kitty" && "$(uname)" == "Darwin" ]]; then
  kitty + complete setup zsh | source /dev/stdin
fi

# Colorize completions using default `ls` colors.
zstyle ':completion:*' list-colors ''

# Enable keyboard navigation of completions in menu
# (not just tab/shift-tab but cursor keys as well):
zstyle ':completion:*' menu select
zmodload zsh/complist

# use the vi navigation keys in menu completion
bindkey -M menuselect 'h' vi-backward-char
bindkey -M menuselect 'k' vi-up-line-or-history
bindkey -M menuselect 'l' vi-forward-char
bindkey -M menuselect 'j' vi-down-line-or-history

# persistent reshahing i.e puts new executables in the $path
# if no command is set typing in a line will cd by default
zstyle ':completion:*' rehash true

# Allow completion of ..<Tab> to ../ and beyond.
zstyle -e ':completion:*' special-dirs '[[ $PREFIX = (../)#(..) ]] && reply=(..)'

# Categorize completion suggestions with headings:
zstyle ':completion:*' group-name ''
# Style the group names
zstyle ':completion:*' format %F{yellow}%B%U%{$__DOTS[ITALIC_ON]%}%d%{$__DOTS[ITALIC_OFF]%}%b%u%f

# Added by running `compinstall`
zstyle ':completion:*' verbose yes
zstyle ':completion:*' expand suffix # or:  expand yes
zstyle ':completion:*' file-sort modification
zstyle ':completion:*' list-prompt %SAt %p: Hit TAB for more, or the character to insert%s
zstyle ':completion:*' list-suffixes true
# End of lines added by compinstall

# -- process names -------------------------------------------------------------
zstyle ':completion:*:processes-names' command \
  'ps c -u ${USER} -o command | uniq'

# -- ssh hosts -----------------------------------------------------------------
[[ -r "$HOME/.ssh/config" ]] && _ssh_config_hosts=(${${(s: :)${(ps:\t:)${${(@M)${(f)"$(<$HOME/.ssh/config)"}:#Host *}#Host }}}:#*[*?]*}) || _ssh_config_hosts=()
# [[ -r ~/.ssh/known_hosts ]] && _ssh_hosts=(${${${${(f)"$(<$HOME/.ssh/known_hosts)"}:#[\|]*}%%\ *}%%,*}) || _ssh_hosts=()
# [[ -r /etc/hosts ]] && : ${(A)_etc_hosts:=${(s: :)${(ps:\t:)${${(f)~~"$(</etc/hosts)"}%%\#*}##[:blank:]#[^[:blank:]]#}}} || _etc_hosts=()
hosts=(
  "$(hostname)"
  "$_ssh_config_hosts[@]"
  # "$_ssh_hosts[@]"
  # "$_etc_hosts[@]"
  localhost
)
zstyle ':completion:*:hosts' hosts $hosts

# Make completion:
# (stolen from Wincent)
# - Try exact (case-sensitive) match first.
# - Then fall back to case-insensitive.
# - Accept abbreviations after . or _ or - (ie. f.b -> foo.bar).
# - Substring complete (ie. bar -> foobar).
zstyle ':completion:*' matcher-list '' \
  '+m:{[:lower:]}={[:upper:]}' \
  '+m:{[:upper:]}={[:lower:]}' \
  '+m:{_-}={-_}' \
  'r:|[._-]=* r:|=*' 'l:|=* r:|=*'

zstyle ':completion:*' use-cache on
zstyle ':completion:*' cache-path "$ZSH_CACHE_DIR/zcompcache"


# -- CDR -----------------------------------------------------------------------
# https://github.com/zsh-users/zsh/blob/master/Functions/Chpwd/cdr

zstyle ':completion:*:*:cdr:*:*' menu selection
# $WINDOWID is an environment variable set by kitty representing the window ID
# of the OS window (NOTE this is not the same as the $KITTY_WINDOW_ID)
# @see: https://github.com/kovidgoyal/kitty/pull/2877
zstyle ':chpwd:*' recent-dirs-file $ZSH_CACHE_DIR/.chpwd-recent-dirs-${WINDOWID##*/} +
zstyle ':completion:*' recent-dirs-insert always
zstyle ':chpwd:*' recent-dirs-default yes


# -- FZF-TAB -----------------------------------------------------------------------
# disable sort when completing `git checkout`
zstyle ':completion:*:git-checkout:*' sort false
# set descriptions format to enable group support
zstyle ':completion:*:descriptions' format '[%d]'
# set list-colors to enable filename colorizing
zstyle ':completion:*' list-colors ${(s.:.)LS_COLORS}
# preview directory's content with exa when completing cd
zstyle ':fzf-tab:complete:cd:*' fzf-preview 'exa -1 --color=always $realpath'
# switch group using `,` and `.`
zstyle ':fzf-tab:*' switch-group ',' '.'
zstyle ':fzf-tab:*' show-group brief # brief, full, none
# zstyle ':fzf-tab:*' fzf-command ftb-tmux-popup
FZF_TAB_GROUP_COLORS=(
    $'\033[94m' $'\033[32m' $'\033[33m' $'\033[35m' $'\033[31m' $'\033[38;5;27m' $'\033[36m' \
    $'\033[38;5;100m' $'\033[38;5;98m' $'\033[91m' $'\033[38;5;80m' $'\033[92m' \
    $'\033[38;5;214m' $'\033[38;5;165m' $'\033[38;5;124m' $'\033[38;5;120m'
)
zstyle ':fzf-tab:*' group-colors $FZF_TAB_GROUP_COLORS

# SOME STUFF:
# https://github.com/j-hui/pokerus/blob/main/zsh.config/zsh/plugins/fzf-tab.zsh
# # Bindings
# zstyle ':fzf-tab:*' fzf-bindings 'ctrl-u:cancel' 'ctrl-c:cancel' 'ctrl-a:cancel' 'ctrl-e:accept' 'ctrl-l:accept'

# # Automatically accept with enter for cd
# zstyle ':fzf-tab:*:cd:*' accept-line enter

# # Use typed query instead of selected entry
# zstyle ':fzf-tab:*' print-query ctrl-j

# # Colors
# zstyle ':fzf-tab:*' default-color $'\033[34m'

# # Previewing

# ## Directories
# if command -v exa &> /dev/null ; then
#     zstyle ':fzf-tab:complete:cd:*' fzf-preview 'exa -1 --color=always $realpath'
# else
#     zstyle ':fzf-tab:complete:cd:*' fzf-preview 'ls -1 --color=always $realpath'
# fi

# ## ps and kill
# zstyle ':completion:*:*:*:*:processes' command "ps -u $USER -o pid,user,comm -w -w"
# zstyle ':fzf-tab:complete:(kill|ps):argument-rest' fzf-preview \
#   '[[ $group == "[process ID]" ]] && ps --pid=$word -o cmd --no-headers -w -w'
# zstyle ':fzf-tab:complete:(kill|ps):argument-rest' fzf-flags --preview-window=down:3:wrap

# ## systemd
# zstyle ':fzf-tab:complete:systemctl-*:*' fzf-preview 'SYSTEMD_COLORS=1 systemctl status $word'

# ## Variables
# zstyle ':fzf-tab:complete:(-command-|-parameter-|-brace-parameter-|export|unset|expand):*' \
#     fzf-preview 'echo ${(P)word}'

# ## Git
# zstyle ':fzf-tab:complete:git-(add|diff|restore):*' fzf-preview \
#     'git diff $word | delta'
# zstyle ':fzf-tab:complete:git-log:*' fzf-preview \
#     'git log --color=always $word'
# zstyle ':fzf-tab:complete:git-help:*' fzf-preview \
#     'git help $word | bat -plman --color=always'
# zstyle ':fzf-tab:complete:git-show:*' fzf-preview \
#     'case "$" in
#     "commit tag") git show --color=always $word ;;
#     *) git show --color=always $word | delta ;;
#     esac'
# zstyle ':fzf-tab:complete:git-checkout:*' fzf-preview \
#     'case "$" in
#     "modified file") git diff $word | delta ;;
#     "recent commit object name") git show --color=always $word | delta ;;
#     *) git log --color=always $word ;;
#     esac'

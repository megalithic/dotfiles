zmodload zsh/datetime

_comp_options+=(globdots) # Include hidden files.

# zsh speedsup: https://carlosbecker.com/posts/speeding-up-zsh/
autoload -Uz compinit
for dump in ~/.zcompdump(N.mh+24); do
  compinit
done
compinit -C

# FIXME: fixes insecure directory warnings
# TODO: should we run this on every sourcing?
# compaudit | xargs chmod g-w

# Completion for kitty
if [[ "$TERM" == "xterm-kitty" ]]; then
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
zstyle ':completion:*' expand suffix
zstyle ':completion:*' file-sort modification
zstyle ':completion:*' list-prompt %SAt %p: Hit TAB for more, or the character to insert%s
zstyle ':completion:*' list-suffixes true
# End of lines added by compinstall

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


# #provides a menu list from where we can highlight and select completion results
# zmodload -i zsh/complist

# # man zshcontrib
# zstyle ':vcs_info:*' actionformats '%F{5}(%f%s%F{5})%F{3}-%F{5}[%F{2}%b%F{3}|%F{1}%a%F{5}]%f '
# zstyle ':vcs_info:*' formats '%F{5}(%f%s%F{5})%F{3}-%F{5}[%F{2}%b%F{5}]%f '
# zstyle ':vcs_info:*' enable git #svn cvs

# # Enable completion caching, use rehash to clear
# zstyle ':completion:*' use-cache on
# zstyle ':completion:*' cache-path "$ZSH_CACHE_DIR/zcompcache"


# # Make the list prompt friendly
# zstyle ':completion:*' list-prompt '%SAt %p: Hit TAB for more, or the character to insert%s'

# # Make the selection prompt friendly when there are a lot of choices
# zstyle ':completion:*' select-prompt '%SScrolling active: current selection at %p%s'

# # Add simple colors to kill
# zstyle ':completion:*:*:kill:*:processes' list-colors '=(#b) #([0-9]#) ([0-9a-z-]#)*=01;34=0=01'

# # list of completers to use
# zstyle ':completion:*::::' completer _expand _complete _ignored _approximate

# zstyle ':completion:*' menu select=1 _complete _ignored _approximate

# # insert all expansions for expand completer
# # zstyle ':completion:*:expand:*' tag-order all-expansions

# # offer indexes before parameters in subscripts
# zstyle ':completion:*:*:-subscript-:*' tag-order indexes parameters

# # formatting and messages
# zstyle ':completion:*' verbose yes
# zstyle ':completion:*:descriptions' format '%B%d%b'
# zstyle ':completion:*:messages' format '%d'
# zstyle ':completion:*:warnings' format 'No matches for: %d'
# zstyle ':completion:*:corrections' format '%B%d (errors: %e)%b'
# zstyle ':completion:*' group-name ''

# # ignore completion functions (until the _ignored completer)
# zstyle ':completion:*:functions' ignored-patterns '_*'
# zstyle ':completion:*:scp:*' tag-order files users 'hosts:-host hosts:-domain:domain hosts:-ipaddr"IP\ Address *'
# zstyle ':completion:*:scp:*' group-order files all-files users hosts-domain hosts-host hosts-ipaddr
# zstyle ':completion:*:ssh:*' tag-order users 'hosts:-host hosts:-domain:domain hosts:-ipaddr"IP\ Address *'
# zstyle ':completion:*:ssh:*' group-order hosts-domain hosts-host users hosts-ipaddr
# zstyle '*' single-ignored show

# # pasting with tabs doesn't perform completion
# zstyle ':completion:*' insert-tab pending

# # Uses git's autocompletion for inner commands. Assumes an install of git's
# # bash `git-completion` script at $completion below (this is where Homebrew
# # tosses it, at least).
# if [[ "$(uname)" == "Darwin" ]]; then
#   completion='$(brew --prefix)/share/zsh/site-functions/_git'
#   if test -f $completion
#   then
#     source $completion
#   fi
# fi

# if type brew &>/dev/null; then
#   FPATH=$(brew --prefix)/share/zsh-completions:$FPATH
# fi

# # Completion for teamocil autocompletion definitions: http://www.teamocil.com/#zsh-autocompletion
# compctl -g '~/.teamocil/*(:t:r)' teamocil

# # Completion for kitty (https://sw.kovidgoyal.net/kitty/#zsh)
# #
# if [[ "$(uname)" == "Darwin" ]]; then
#   if command -v kitty >/dev/null; then
#     kitty + complete setup zsh | source /dev/stdin
#   fi
# fi

# # ============================================================================
# # Completion settings
# # - completion stolen from:
# # https://github.com/davidosomething/dotfiles/blob/dev/zsh/.zshrc#L248
# # Order by * specificity
# # ============================================================================

# # --------------------------------------------------------------------------
# # Completion: Caching
# # --------------------------------------------------------------------------

# zstyle ':completion:*' use-cache true
# zstyle ':completion:*' cache-path "$ZSH_CACHE_DIR"

# # --------------------------------------------------------------------------
# # Completion: Display
# # --------------------------------------------------------------------------

# # group all by the description above
# zstyle ':completion:*' group-name ''

# # colorful completion
# zstyle ':completion:*' list-colors ''

# # Updated to respect LS_COLORS
# zstyle ':completion:*' list-colors ${(s.:.)LS_COLORS}

# zstyle ':completion:*' list-dirs-first yes

# # go into menu mode on second tab (like current vim wildmenu setting)
# # only if there's more than two things to choose from
# zstyle ':completion:*' menu select=2

# # show descriptions for options
# zstyle ':completion:*' verbose yes

# # in Bold, specify what type the completion is, e.g. a file or an alias or
# # a cmd
# zstyle ':completion:*:descriptions' format '%F{black}%B%d%b%f'

# # --------------------------------------------------------------------------
# # Completion: Matching
# # --------------------------------------------------------------------------

# # Make completion:
# # (stolen from akinsho -> Wincent)
# # - Try exact (case-sensitive) match first.
# # - Then fall back to case-insensitive.
# # - Accept abbreviations after . or _ or - (ie. f.b -> foo.bar).
# # - Substring complete (ie. bar -> foobar).
# zstyle ':completion:*' matcher-list '' \
#   '+m:{[:lower:]}={[:upper:]}' \
#   '+m:{[:upper:]}={[:lower:]}' \
#   '+m:{_-}={-_}' \
#   'r:|[._-]=* r:|=*' 'l:|=* r:|=*'

# # don't complete usernames
# zstyle ':completion:*' users ''

# # don't autocomplete homedirs
# zstyle ':completion::complete:cd:*' tag-order '! users'

# # --------------------------------------------------------------------------
# # Completion: Output transformation
# # --------------------------------------------------------------------------

# # expand completions as much as possible on tab
# # e.g. start expanding a path up to wherever it can be until error
# zstyle ':completion:*' expand yes

# # process names
# zstyle ':completion:*:processes-names' command \
#   'ps c -u ${USER} -o command | uniq'

# # ssh host completion
# [[ -r ~/.ssh/config ]] && _ssh_config_hosts=(${${(s: :)${(ps:\t:)${${(@M)${(f)"$(<$HOME/.ssh/config)"}:#Host *}#Host }}}:#*[*?]*}) || _ssh_config_hosts=()
# # [[ -r ~/.ssh/known_hosts ]] && _ssh_hosts=(${${${${(f)"$(<$HOME/.ssh/known_hosts)"}:#[\|]*}%%\ *}%%,*}) || _ssh_hosts=()
# # [[ -r /etc/hosts ]] && : ${(A)_etc_hosts:=${(s: :)${(ps:\t:)${${(f)~~"$(</etc/hosts)"}%%\#*}##[:blank:]#[^[:blank:]]#}}} || _etc_hosts=()
# hosts=(
#   "$(hostname)"
#   "$_ssh_config_hosts[@]"
#   # "$_ssh_hosts[@]"
#   # "$_etc_hosts[@]"
#   localhost
# )
# zstyle ':completion:*:hosts' hosts $hosts

# # colorful kill command completion -- probably overridden by fzf
# zstyle ':completion:*:*:kill:*:processes' list-colors \
#   "=(#b) #([0-9]#)*=36=31"

# # complete .log filenames if redirecting stderr
# zstyle ':completion:*:*:-redirect-,2>,*:*' file-patterns '*.log'


# # --------------------------------------------------------------------------
# # Aloxaf/fzf-tab
# # --------------------------------------------------------------------------

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

# #-------------------------------------------------------------------------------
# #  CDR
# #-------------------------------------------------------------------------------
# # https://github.com/zsh-users/zsh/blob/master/Functions/Chpwd/cdr

# zstyle ':completion:*:*:cdr:*:*' menu selection
# # $WINDOWID is an environment variable set by kitty representing the window ID
# # of the OS window (NOTE this is not the same as the $KITTY_WINDOW_ID)
# # @see: https://github.com/kovidgoyal/kitty/pull/2877
# zstyle ':chpwd:*' recent-dirs-file $ZSH_CACHE_DIR/.chpwd-recent-dirs-${WINDOWID##*/} +
# zstyle ':completion:*' recent-dirs-insert always
# zstyle ':chpwd:*' recent-dirs-default yes

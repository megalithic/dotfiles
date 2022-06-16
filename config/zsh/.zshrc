#!/usr/bin/env zsh

# zmodload zsh/zprof # -> top of your .zshrc file

# REFS:
# exec - replaces the current shell. This means no subshell is
# created and the current process is replaced with this new command.
# fd/FD - file descriptor
# &- closes a FD e.g. "exec 3<&-" closes FD 3
# file descriptor 0 is stdin (the standard input),
# 1 is stdout (the standard output),
# 2 is stderr (the standard error).
# https://www.reddit.com/r/commandline/comments/vde0lw/wondering_what_a_line_of_code_does/icjsmei/
#
# ╭────────────────────────────────────────────────────────────────────────────╮
# │ Expression │ Description                                                   │
# │────────────────────────────────────────────────────────────────────────────│
# │ $#         │ Number of arguments                                           │
# │ $*         │ All positional arguments (as a single word)                   │
# │ $@         │ All positional arguments (as separate strings)                │
# │ $1         │ First argument                                                │
# │ $_         │ Last argument of the previous command                         │
# │ $?         │ Exit code of previous command                                 │
# │ $!         │ PID of last command run in the background                     │
# │ $0         │ The name of the shell script itself                           │
# │ $-         │ Current option flags set by the script                        │
# ╰────────────────────────────────────────────────────────────────────────────╯
# NOTE: $@ and $* must be quoted in order to perform as described. Otherwise,
# they do exactly the same thing (arguments as separate strings).
#
# (EXPANSIONS)
# ╭────────────────────────────────────────────────────────────────────────────╮
# │ Expression │ Description                                                   │
# │────────────────────────────────────────────────────────────────────────────│
# │ !$	       │ Expand last parameter of most recent command                  │
# │ !*	       │ Expand all parameters of most recent command                  │
# │ !-n	       │ Expand nth most recent command                                │
# │ !n	       │ Expand nth command in history                                 │
# │ !<command> │ Expand most recent invocation of command <command>            │
# ╰────────────────────────────────────────────────────────────────────────────╯
#
# (OPERATIONS)
# ╭────────────────────────────────────────────────────────────────────────────╮
# │ Code               │ Description                                           │
# │────────────────────────────────────────────────────────────────────────────│
# │ !!	               │ Execute last command again                            │
# │ !!:s/<FROM>/<TO>/	 │ Replace first occurrence of <FROM> to <TO> in most    │
# │                    │   recent command                                      │
# │ !!:gs/<FROM>/<TO>/ │ Replace all occurrences of <FROM> to <TO> in most     │
# │                    │   recent command                                      │
# │ !$:t	             │ Expand only basename from last parameter of most      │
# │                    │   recent command                                      │
# │ !$:h	             │ Expand only directory from last parameter of most     │
# │                    │   recent command                                      │
# ╰────────────────────────────────────────────────────────────────────────────╯
# NOTE: !! and !$ can be replaced with any valid expansion.
#
# (SLICES)
# ╭────────────────────────────────────────────────────────────────────────────╮
# │ Code    │ Description                                                      │
# │────────────────────────────────────────────────────────────────────────────│
# │ !!:n	  │ Expand only nth token from most recent command                   │
# │         │   (command is 0; first argument is 1)                            │
# │ !^	    │ Expand first argument from most recent command                   │
# │ !$	    │ Expand last token from most recent command                       │
# │ !!:n-m	│ Expand range of tokens from most recent command                  │
# │ !!:n-$	│ Expand nth token to last from most recent command                │
# ╰────────────────────────────────────────────────────────────────────────────╯
# NOTE: !! can be replaced with any valid expansion i.e. !cat, !-2, !42, etc.
#

# -- required helpers and our env variables
ZLIB="$ZDOTDIR/lib"
[[ -f "$ZLIB/env.zsh" ]] && source "$ZLIB/env.zsh"
[[ -f "$ZLIB/helpers.zsh" ]] && source "$ZLIB/helpers.zsh"
[[ -f "$ZDOTDIR/plugins.zsh" ]] && source "$ZDOTDIR/plugins.zsh"

# -- plugins
zsh_add_plugin "Aloxaf/fzf-tab"
zsh_add_plugin "zsh-users/zsh-history-substring-search"
zsh_add_plugin "zsh-users/zsh-autosuggestions"
zsh_add_plugin "zsh-users/zsh-completions"
zsh_add_plugin "djui/alias-tips"
zsh_add_plugin "MichaelAquilina/zsh-auto-notify" "auto-notify.plugin"
# zsh_add_plugin "hlissner/zsh-autopair"
zsh_add_plugin "zsh-users/zsh-syntax-highlighting"
# @trial:
# zsh_add_plugin "marlonrichert/zsh-autocomplete"

# adds `zmv` tool (https://twitter.com/wesbos/status/1443570300529086467)
autoload -U zmv # builtin zsh rename command

# -- completions
[[ -f "$ZLIB/completion.zsh" ]] && source "$ZLIB/completion.zsh"

# -- prompt
[[ -f "$ZDOTDIR/prompt/megaprompt.zsh" ]] && source "$ZDOTDIR/prompt/megaprompt.zsh"

# -- scripts/libs
for file in $ZLIB/{keybindings,opts,aliases,funcs,colors,kitty,ssh,tmux}.zsh; do
  [[ -r "$file" && -f "$file" ]] && source "$file"
done
unset file

if exists zoxide; then
  eval "$(zoxide init zsh)"
fi

# if [[ "$(uname)" == "Linux" ]]; then
#   exists starship && eval "$(starship init zsh)"
# fi

# NOTE: http://asdf-vm.com/learn-more/faq.html#shell-not-detecting-newly-installed-shims
[[ -f "$ZLIB/asdf.zsh" ]] && source "$ZLIB/asdf.zsh"

# work things
[[ -f "/opt/dev-env/ansible/dash_profile" ]] && source /opt/dev-env/ansible/dash_profile
[[ -n "$DESK_ENV" ]] && source "$DESK_ENV" || true

# fzf just desparately wants this here
[[ -f ~/.fzf.zsh ]] && source ~/.fzf.zsh
[[ -f "$ZLIB/fzf.zsh" ]] && source "$ZLIB/fzf.zsh"

# zprof # -> bottom of .zshrc
# vim:ft=zsh:foldenable:foldmethod=marker:ts=2:sts=2:sw=2

#!/usr/bin/env zsh

# HT: @akinsho / @sindresorhus/pure

# NOTES:
# git:
# %b => current branch
# %a => current action (rebase/merge)
#
# prompt:
# %F => color dict
# %f => reset color
# %~ => current path
# %* => time
# %n => username
# %m => shortname host
# %(?..) => prompt conditional - %(condition.true.false)
#
# terminal codes:
# \e7     => save cursor position
# \e[2A   => move cursor 2 lines up
# \e[1G   => go to position 1 in terminal
# \e8     => restore cursor position
# \e[K    => clears everything after the cursor on the current line
# \e[2K   => clear everything on the current line
# \e[25l  => will hide the text cursor
# \e[25h  => will show the text cursor
#

autoload -U colors && colors # Enable colors in prompt

# -- ICONS ---------------------------------------------------------------------
prompt_icon=""           #  ❯    ➜ 
prompt_failure_icon=""   # 
placeholder_icon="…"
vimode_insert_icon=""    # 
git_staged_icon=""
git_unstaged_icon="﯂"     # • ﯂ ●
git_conflicted_icon=""   # 
git_stash_icon=""        #   ≡
# TODO: check for deleted: https://github.com/spaceship-prompt/spaceship-prompt/blob/master/sections/git_status.zsh#L66-L71
git_deleted_icon=""
git_diverged_icon="⇕"
git_untracked_icon="?"    # 
git_ahead_icon="⇡"        # 
git_behind_icon="⇣"       # 
git_renamed_icon=""
deskfile_icon=""         #    ◲  🚀
background_job_icon=""   # ✦
root_icon=""



# -- VI-MODE -------------------------------------------------------------------
# @see: https://thevaluable.dev/zsh-install-configure-mouseless/
bindkey -e # enables vi mode, using -e = emacs
export KEYTIMEOUT=1

# Add vi-mode text objects e.g. da" ca(
autoload -Uz select-bracketed select-quoted
zle -N select-quoted
zle -N select-bracketed
for km in viopp visual; do
  bindkey -M $km -- '-' vi-up-line-or-history
  for c in {a,i}${(s..)^:-\'\"\`\|,./:;=+@}; do
    bindkey -M $km $c select-quoted
  done
  for c in {a,i}${(s..)^:-'()[]{}<>bB'}; do
    bindkey -M $km $c select-bracketed
  done
done
# Mimic tpope's vim-surround
autoload -Uz surround
zle -N delete-surround surround
zle -N add-surround surround
zle -N change-surround surround
bindkey -M vicmd cs change-surround
bindkey -M vicmd ds delete-surround
bindkey -M vicmd ys add-surround
bindkey -M visual S add-surround

# https://superuser.com/questions/151803/how-do-i-customize-zshs-vim-mode
# http://pawelgoscicki.com/archives/2012/09/vi-mode-indicator-in-zsh-prompt/
vim_insert_mode=""
vim_normal_mode="%F{green}$vimode_insert_icon %f"
vim_mode=$vim_insert_mode

function zle-line-finish {
  vim_mode=$vim_insert_mode
}
zle -N zle-line-finish

# When you C-c in CMD mode and you'd be prompted with CMD mode indicator,
# while in fact you would be in INS mode Fixed by catching SIGINT (C-c),
# set vim_mode to INS and then repropagate the SIGINT,
# so if anything else depends on it, we will not break it
function TRAPINT() {
  vim_mode=$vim_insert_mode
  return $(( 128 + $1 ))
}

cursor_mode() {
  # See https://ttssh2.osdn.jp/manual/4/en/usage/tips/vim.html for cursor shapes
  cursor_block='\e[2 q'
  cursor_beam='\e[6 q'

  function zle-keymap-select {
    vim_mode="${${KEYMAP/vicmd/${vim_normal_mode}}/(main|viins)/${vim_insert_mode}}"
    zle && zle reset-prompt

    if [[ ${KEYMAP} == vicmd ]] ||
        [[ $1 = 'block' ]]; then
        echo -ne $cursor_block
    elif [[ ${KEYMAP} == main ]] ||
        [[ ${KEYMAP} == viins ]] ||
        [[ ${KEYMAP} = '' ]] ||
        [[ $1 = 'beam' ]]; then
        echo -ne $cursor_beam
    fi
  }

  zle-line-init() {
    echo -ne $cursor_beam
  }

  zle -N zle-keymap-select
  zle -N zle-line-init
}

cursor_mode

# -- GIT -----------------------------------------------------------------------
# vcs_info is a zsh native module for getting git info into your
# prompt. It's not as fast as using git directly in some cases
# but easy and well documented.
# Resources:
# 1. http://zsh.sourceforge.net/Doc/Release/User-Contributions.html
# 2. https://github.com/zsh-users/zsh/blob/master/Misc/vcs_info-examples
# 3. using vcs_infow with check-for-changes can be expensive if used in large repos
#    see the link below if looking for how to avoid running these check for changes on large repos
#    https://github.com/zsh-users/zsh/blob/545c42cdac25b73134a9577e3c0efa36d76b4091/Misc/vcs_info-examples#L72
# %c - git staged
# %u - git untracked
# %b - git branch
# %r - git repo
autoload -Uz vcs_info

# Using named colors means that the prompt automatically adapts to how these
# are set by the current terminal theme
zstyle ':vcs_info:*' enable git
zstyle ':vcs_info:*' check-for-changes true
zstyle ':vcs_info:*' stagedstr "%F{green} $git_staged_icon%f"
zstyle ':vcs_info:*' unstagedstr "%F{#db9c5e} $git_unstaged_icon%f"
zstyle ':vcs_info:*' use-simple true
zstyle ':vcs_info:git+set-message:*' hooks git-untracked git-stash git-deleted git-compare git-remotebranch
zstyle ':vcs_info:git*:*' actionformats '(%B%F{red}%b|%a%c%u%%b%f) '
zstyle ':vcs_info:git:*' formats "%F{249}(%f%F{245}%{$__DOTS[ITALIC_ON]%}%b%{$__DOTS[ITALIC_OFF]%}%f%F{249})%f%c%u%m"

__in_git() {
  [[ $(git rev-parse --is-inside-work-tree 2> /dev/null) == "true" ]]
}

# on the output of the git command adds an indicator to the the vcs info
# use --directory and --no-empty-directory to speed up command
# https://stackoverflow.com/questions/11122410/fastest-way-to-get-git-status-in-bash
function +vi-git-untracked() {
  emulate -L zsh
  if __in_git; then
    if [[ -n $(git ls-files --directory --no-empty-directory --exclude-standard --others 2> /dev/null) ]]; then
      hook_com[unstaged]+="%F{white} $git_untracked_icon%f"
    fi
  fi
}

function +vi-git-deleted() {
  emulate -L zsh
  if __in_git; then
    if [[ -n $(git ls-files --deleted 2> /dev/null) ]]; then
      hook_com[unstaged]+="%F{red} $git_deleted_icon%f"
    fi
  fi
}

# function +vi-git-renamed() {
#   emulate -L zsh
#   if __in_git; then
#     if [[ -n $(git ls-files --deleted 2> /dev/null) ]]; then
#       hook_com[unstaged]+="%F{red} $git_deleted_icon%f"
#     fi
#   fi
# }

function +vi-git-stash() {
  emulate -L zsh
  if __in_git; then
    if [[ -n $(git rev-list --walk-reflogs --count refs/stash 2> /dev/null) ]]; then
      hook_com[unstaged]+="%F{yellow} $git_stash_icon%f"
    fi
  fi
}
# git: Show +N/-N when your local branch is ahead-of or behind remote HEAD.
# Make sure you have added misc to your 'formats':  %m
# source: https://github.com/zsh-users/zsh/blob/545c42cdac25b73134a9577e3c0efa36d76b4091/Misc/vcs_info-examples#L180
function +vi-git-compare() {
  local ahead behind
  local -a gitstatus

  # Exit early in case the worktree is on a detached HEAD
  git rev-parse ${hook_com[branch]}@{upstream} >/dev/null 2>&1 || return 0

  local -a ahead_and_behind=(
    $(git rev-list --left-right --count HEAD...${hook_com[branch]}@{upstream} 2>/dev/null)
  )

  ahead=${ahead_and_behind[1]}
  behind=${ahead_and_behind[2]}

  local ahead_symbol="%{$fg[red]%}$git_ahead_icon%{$reset_color%}${ahead}"
  local behind_symbol="%{$fg[cyan]%}$git_behind_icon%{$reset_color%}${behind}"
  (( $ahead )) && gitstatus+=( "${ahead_symbol}" )
  (( $behind )) && gitstatus+=( "${behind_symbol}" )
  hook_com[misc]+=" ${(j:/:)gitstatus}"
}

## git: Show remote branch name for remote-tracking branches
function +vi-git-remotebranch() {
    local remote

    # Are we on a remote-tracking branch?
    remote=${$(git rev-parse --verify ${hook_com[branch]}@{upstream} \
        --symbolic-full-name 2>/dev/null)/refs\/remotes\/}

    # The first test will show a tracking branch whenever there is one. The
    # second test, however, will only show the remote branch's name if it
    # differs from the local one.
    # if [[ -n ${remote} ]] ; then
    if [[ -n ${remote} && ${remote#*/} != ${hook_com[branch]} ]] ; then
        hook_com[branch]="${hook_com[branch]}→[${remote}]"
    fi
}

# -- PROMPT --------------------------------------------------------------------
setopt PROMPT_SUBST
# %F...%f - - foreground color
# toggle color based on success %F{%(?.green.red)}
# %F{a_color} - color specifier
# %B..%b - bold
# %* - reset highlight
# %j - background jobs


# Approximate prompt output: ---------------------------------------------------
# ╭────────────────────────────────────────────────────────────────────────────╮
# │                                                                            │
# │ ~/.dotfiles(branch)  ﯂ ?                                                │
# │  █                                                           28s 10:51:04 │
# ╰────────────────────────────────────────────────────────────────────────────╯
# NOTE:
# There are other modes and features not represented in this illustration...
#
# For instance, Deskfile mode (loaded $DESK_FILE and indicator), vimode indicator,
# and much more.
# ------------------------------------------------------------------------------

function _prompt_ssh() {
  # inspired by https://github.com/sindresorhus/pure/blob/main/pure.zsh#L660-L714
	# setopt localoptions noshwordsplit

	# Check SSH_CONNECTION and the current state.
	local ssh_connection=${SSH_CONNECTION:-$PROMPT_MEGA_SSH_CONNECTION}
	local username hostname
	if [[ -z $ssh_connection ]] && (( $+commands[who] )); then
		# When changing user on a remote system, the $SSH_CONNECTION
		# environment variable can be lost. Attempt detection via `who`.
		local who_out
		who_out=$(who -m 2>/dev/null)
		if (( $? )); then
			# Who am I not supported, fallback to plain who.
			local -a who_in
			who_in=( ${(f)"$(who 2>/dev/null)"} )
			who_out="${(M)who_in:#*[[:space:]]${TTY#/dev/}[[:space:]]*}"
		fi

		local reIPv6='(([0-9a-fA-F]+:)|:){2,}[0-9a-fA-F]+'  # Simplified, only checks partial pattern.
		local reIPv4='([0-9]{1,3}\.){3}[0-9]+'   # Simplified, allows invalid ranges.
		# Here we assume two non-consecutive periods represents a
		# hostname. This matches `foo.bar.baz`, but not `foo.bar`.
		local reHostname='([.][^. ]+){2}'

		# Usually the remote address is surrounded by parenthesis, but
		# not on all systems (e.g. busybox).
		local -H MATCH MBEGIN MEND
		if [[ $who_out =~ "\(?($reIPv4|$reIPv6|$reHostname)\)?\$" ]]; then
			ssh_connection=$MATCH

			# Export variable to allow detection propagation inside
			# shells spawned by this one (e.g. tmux does not always
			# inherit the same tty, which breaks detection).
			export PROMPT_MEGA_SSH_CONNECTION=$ssh_connection
		fi
		unset MATCH MBEGIN MEND
	fi

	hostname='%F{yellow}@%m%f'
	# Show `username@host` if logged in through SSH.
	[[ -n $ssh_connection ]] && username='%F{magenta}%n%f'"$hostname "

  # Show `username@host` if root, with username in default color.
	[[ $UID -eq 0 ]] && username='%F{red}$root_icon%n%f'"$hostname "

  echo "$username"
}

# truncate our path to something like ~/.d/c/zsh for ~/.dotfiles/config/zsh
function _prompt_path() {
  local prompt_path=''
  local pwd="${PWD/#$HOME/~}"
  if [[ "$pwd" == (#m)[~] ]]; then # also, if you want both `/` and `~`, then [/~]
    prompt_path="~"
  else
    prompt_path="%B%F{blue}${${${(@j:/:M)${(@s:/:)pwd}##.#?}:h}%/}/${pwd:t}%{$reset_color%}%b"
    # prompt_path="%B%{$fg[blue]%}${${${(@j:/:M)${(@s:/:)pwd}##.#?}:h}%/}/${pwd:t}%{$reset_color%}%b"
  fi

  echo "$prompt_path"
}

function _prompt_deskfile_loaded() {
  # (command desk -v &>/dev/null && (desk | grep -q 'No desk activated.' && echo '' || echo "%F{243}[%f%F{magenta}$deskfile_icon%f %F{245}$DESK_NAME%f%F{243}]%f ")) || echo ''
  [[ -n $DESK_NAME ]] && echo "%F{243}[%f%F{magenta}$deskfile_icon%f %F{245}$DESK_NAME%f%F{243}]%f "
}

function __prompt_eval() {
  local dots_prompt_icon="%F{green}$prompt_icon %f"
  local dots_prompt_failure_icon="%F{red}$prompt_failure_icon %f"
  local placeholder="(%F{blue}%{$__DOTS[ITALIC_ON]%}$placeholder_icon%{$__DOTS[ITALIC_OFF]%}%f)"
  local top="$(_prompt_ssh)$(_prompt_path)${_git_status_prompt:-$placeholder}"
  # local top="%B%F{magenta}%1~%f%b${_git_status_prompt:-$placeholder}"
  local character="%(1j.%F{cyan}%j$background_job_icon%f.)%(?.${dots_prompt_icon}.${dots_prompt_failure_icon})"
  local bottom=$([[ -n "$vim_mode" ]] && echo "$(_prompt_deskfile_loaded)$vim_mode" || echo "$(_prompt_deskfile_loaded)$character")
  local newline=$'\n'
  echo $newline$top$newline$bottom
}
# NOTE: VERY IMPORTANT: the type of quotes used matters greatly. Single quotes MUST be used for these variables
export PROMPT='$(__prompt_eval)'
# Right prompt
export RPROMPT='%F{yellow}%{$__DOTS[ITALIC_ON]%}${cmd_exec_time}%{$__DOTS[ITALIC_OFF]%}%f %F{240}%*%f'
# Correction prompt
export SPROMPT="correct %F{red}'%R'%f to %F{red}'%r'%f [%B%Uy%u%bes, %B%Un%u%bo, %B%Ue%u%bdit, %B%Ua%u%bbort]? "

# -- EXECUTION TIME ------------------------------------------------------------
# inspired by https://github.com/sindresorhus/pure/blob/81dd496eb380aa051494f93fd99322ec796ec4c2/pure.zsh#L47
#
# Turns seconds into human readable time.
# 165392 => 1d 21h 56m 32s
# https://github.com/sindresorhus/pretty-time-zsh
__human_time_to_var() {
  local human total_seconds=$1 var=$2
  local days=$(( total_seconds / 60 / 60 / 24 ))
  local hours=$(( total_seconds / 60 / 60 % 24 ))
  local minutes=$(( total_seconds / 60 % 60 ))
  local seconds=$(( total_seconds % 60 ))
  (( days > 0 )) && human+="${days}d "
  (( hours > 0 )) && human+="${hours}h "
  (( minutes > 0 )) && human+="${minutes}m "
  human+="${seconds}s"

  # Store human readable time in a variable as specified by the caller
  typeset -g "${var}"="${human}"
}

# Stores (into cmd_exec_time) the execution
# time of the last command if set threshold was exceeded (5 seconds).
__check_cmd_exec_time() {
  integer elapsed
  (( elapsed = EPOCHSECONDS - ${cmd_timestamp:-$EPOCHSECONDS} ))
  typeset -g cmd_exec_time=
  (( elapsed > 5 )) && {
    __human_time_to_var $elapsed "cmd_exec_time"
  }
}

__timings_preexec() {
  emulate -L zsh
  typeset -g cmd_timestamp=$EPOCHSECONDS
}

__timings_precmd() {
  __check_cmd_exec_time
  unset cmd_timestamp
}

# -- HOOKS ---------------------------------------------------------------------
autoload -Uz add-zsh-hook
# Async prompt in Zsh
# Rather than using zpty (a pseudo terminal) under the hood
# as is the case with zsh-async this method forks a process sends
# it the command to evaluate which is written to a file descriptor
#
# terminology:
# exec - replaces the current shell. This means no subshell is
# created and the current process is replaced with this new command.
# fd/FD - file descriptor
# &- closes a FD e.g. "exec 3<&-" closes FD 3
# file descriptor 0 is stdin (the standard input),
# 1 is stdout (the standard output),
# 2 is stderr (the standard error).
#
# https://www.zsh.org/mla/users/2018/msg00424.html
# https://github.com/sorin-ionescu/prezto/pull/1805/files#diff-6a24e7644c4c0969110e86872283ec82L79
# https://github.com/zsh-users/zsh-autosuggestions/pull/338/files
__async_vcs_start() {
  # Close the last file descriptor to invalidate old requests
  if [[ -n "$__prompt_async_fd" ]] && { true <&$__prompt_async_fd } 2>/dev/null; then
    exec {__prompt_async_fd}<&-
    zle -F $__prompt_async_fd
  fi
  # fork a process to fetch the vcs status and open a pipe to read from it
  exec {__prompt_async_fd}< <(
    __async_vcs_info $PWD
  )

  # When the fd is readable, call the response handler
  zle -F "$__prompt_async_fd" __async_vcs_info_done
}

__async_vcs_info() {
  cd -q "$1"
  vcs_info
  print ${vcs_info_msg_0_}
}

# Called when new data is ready to be read from the pipe
__async_vcs_info_done() {
  # Read everything from the fd
  _git_status_prompt="$(<&$1)"
  # check if vcs info is returned, if not set the prompt
  # to a non visible character to clear the placeholder
  # NOTE: -z returns true if a string value has a length of 0
  if [[ -z $_git_status_prompt ]]; then
    _git_status_prompt=" "
  fi
  # remove the handler and close the file descriptor
  zle -F "$1"
  exec {1}<&-
  zle && zle reset-prompt
}

# When the terminal is resized, the shell receives a SIGWINCH signal.
# So redraw the prompt in a trap.
# https://unix.stackexchange.com/questions/360600/reload-zsh-when-resizing-terminator-window
#
# Resource: [TRAP functions]
# http://zsh.sourceforge.net/Doc/Release/Functions.html#Trap-Functions
function TRAPWINCH () {
  zle && zle reset-prompt
}

add-zsh-hook precmd () {
  __timings_precmd
  __async_vcs_start # start async job to populate git info
}

autoload -Uz chpwd_recent_dirs cdr
add-zsh-hook chpwd

add-zsh-hook chpwd () {
  _git_status_prompt="" # clear current vcs_info
  chpwd_recent_dirs
}

add-zsh-hook preexec () {
  __timings_preexec
}

# Edit line in vim with v whilst in normal mod in vi mode
autoload -Uz edit-command-line;
zle -N edit-command-line
bindkey -M vicmd v edit-command-line

# -- TODO: ---------------------------------------------------------------------
# # Return true if executing inside a Docker, LXC or systemd-nspawn container.
# prompt_pure_is_inside_container() {
# 	local -r cgroup_file='/proc/1/cgroup'
# 	local -r nspawn_file='/run/host/container-manager'
# 	[[ -r "$cgroup_file" && "$(< $cgroup_file)" = *(lxc|docker)* ]] \
# 		|| [[ "$container" == "lxc" ]] \
# 		|| [[ -r "$nspawn_file" ]]
# }

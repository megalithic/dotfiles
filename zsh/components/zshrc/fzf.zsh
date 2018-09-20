#!/bin/zsh

# setup fzf
# consider these handy fzf functions: https://github.com/junegunn/dotfiles/blob/master/bashrc#L267
[ -f ~/.fzf.zsh ] && source ~/.fzf.zsh

_gen_fzf_default_opts() {
  local color00='#002b36'
  local color01='#073642'
  local color02='#586e75'
  local color03='#657b83'
  local color04='#839496'
  local color05='#93a1a1'
  local color06='#eee8d5'
  local color07='#fdf6e3'
  local color08='#dc322f'
  local color09='#cb4b16'
  local color0A='#b58900'
  local color0B='#859900'
  local color0C='#2aa198'
  local color0D='#268bd2'
  local color0E='#6c71c4'
  local color0F='#d33682'

  export FZF_DEFAULT_OPTS="
  --no-height
  --bind 'ctrl-j:ignore,ctrl-k:ignore'
  --inline-info
  --color=bg+:$color01,bg:$color00,spinner:$color0C,hl:$color0D
  --color=fg:$color04,header:$color0D,info:$color0A,pointer:$color0C
  --color=marker:$color0C,fg+:$color06,prompt:$color0A,hl+:$color0D
  "

  export FZF_DEFAULT_OPTS="
  --inline-info
  --select-1
  --ansi
  --extended
  --bind ctrl-f:page-down,ctrl-b:page-up,J:down,K:up
  "
}

_gen_fzf_default_opts

# using ripgrep/rg
export FZF_DEFAULT_COMMAND='rg --files --hidden --follow --no-heading --line-number --glob "!{.git,node_modules}/*" 2> /dev/null'
export FZF_CTRL_T_COMMAND="$FZF_DEFAULT_COMMAND"
export FZF_TMUX_HEIGHT='20%'

# Use fd (https://github.com/sharkdp/fd) instead of the default find
# REF: https://github.com/mattfritz/.dotfiles/blob/master/zsh/fzf.zsh#L12
# command for listing path candidates.
# - The first argument to the function ($1) is the base path to start traversal
# - See the source code (completion.{bash,zsh}) for the details.
# _fzf_compgen_path() {
#   fd --hidden --follow --exclude ".git" --color=always . "$1"
# }

# Use fd to generate the list for directory completion
# _fzf_compgen_dir() {
#   fd --type d --hidden --follow --exclude ".git" --color=always . "$1"
# }

# export FZF_DEFAULT_COMMAND='fd --type file --follow --hidden --exclude .git --color=always'
# export FZF_ALT_C_COMMAND='fd --type d . --color=never'
# export FZF_CTRL_T_COMMAND="$FZF_DEFAULT_COMMAND"
# export FZF_TMUX_HEIGHT='20%'


# these must be set *after* loading fzf:
export FZF_COMPLETION_TRIGGER=''
bindkey '^G' fzf-completion
bindkey '^I' $fzf_default_completion

# # ==/ FZF Helpers /============================================================

# https://github.com/junegunn/fzf/wiki/examples#git
function gco () {
    # git checkout fuzzy finder
    local tags branches target
    tags=$(
        git tag | awk '{print "\x1b[31;1mtag\x1b[m\t" $1}') || return
    branches=$(
        git branch --all |
        grep -v HEAD     |
        sed "s/.* //"    |
        # sed "s#remotes/[^/]*/##" |
        sort -u          |
        awk '{print "\x1b[34;1mbranch\x1b[m\t" $1}') || return
    target=$(
        (echo "$tags"; echo "$branches") |
        fzf-tmux -- --no-hscroll --ansi +m -d "\t" -n 2 \
        --preview "git log -20 --pretty='(%cr) %s <%an> -%d' --abbrev-commit {2}" \
        --preview-window "up") || return
    git checkout $(echo "$target" | awk '{print $2}')
}

# fe [FUZZY PATTERN] - Open the selected file with the default editor
#   - Bypass fuzzy finder if there's only one match (--select-1)
#   - Exit if there's no match (--exit-0)
fe() {
  local files
  IFS=$'\n' files=($(fzf-tmux --query="$1" --multi --select-1 --exit-0))
  [[ -n "$files" ]] && ${EDITOR:-vim} "${files[@]}"
}

# Modified version where you can press
#   - CTRL-O to open with `open` command,
#   - CTRL-E or Enter key to open with the $EDITOR
fo() {
  local out file key
  IFS=$'\n' out=($(fzf-tmux --query="$1" --exit-0 --expect=ctrl-o,ctrl-e))
  key=$(head -1 <<< "$out")
  file=$(head -2 <<< "$out" | tail -1)
  if [ -n "$file" ]; then
    [ "$key" = ctrl-o ] && open "$file" || ${EDITOR:-vim} "$file"
  fi
}

# vf - fuzzy open with vim from anywhere
# ex: vf word1 word2 ... (even part of a file name)
# zsh autoload function
vf() {
  local files

  files=(${(f)"$(locate -Ai -0 $@ | grep -z -vE '~$' | fzf --read0 -0 -1 -m)"})

  if [[ -n $files ]]
  then
     vim -- $files
     print -l $files[1]
  fi
}

# fuzzy grep open via ag
vg() {
  local file

  file="$(ag --nobreak --noheading $@ | fzf -0 -1 | awk -F: '{print $1 " +" $2}')"

  if [[ -n $file ]]
  then
     vim $file
  fi
}

# fkill - kill processes - list only the ones you can kill. Modified the earlier script.
fkill() {
    local pid
    if [ "$UID" != "0" ]; then
        pid=$(ps -f -u $UID | sed 1d | fzf -m | awk '{print $2}')
    else
        pid=$(ps -ef | sed 1d | fzf -m | awk '{print $2}')
    fi

    if [ "x$pid" != "x" ]
    then
        echo $pid | xargs kill -${1:-9}
    fi
}

# prev() {
#   git ls-files | fzf --preview "pygmentize {}" --color light --margin 5,20
# }

# # fe [FUZZY PATTERN] - Open the selected file with the default editor
# #   - Bypass fuzzy finder if there's only one match (--select-1)
# #   - Exit if there's no match (--exit-0)
# fe() {
#   IFS='
# '
#   local declare files=($(fzf-tmux --query="$1" --select-1 --exit-0))
#   [[ -n "$files" ]] && ${EDITOR:-vim} "${files[@]}"
#   unset IFS
# }

# # vf - fuzzy open with vim from anywhere
# # ex: vf word1 word2 ... (even part of a file name)
# # zsh autoload function
# vf() {
#   local files

#   files=(${(f)"$(locate -Ai -0 $@ | grep -z -vE '~$' | fzf-tmux --read0 -0 -1 -m)"})

#   if [[ -n $files ]]
#   then
#      vim -- $files
#      print -l $files[1]
#   fi
# }

# # fd - cd to selected directory
# # ::: commenting this for now because i've got an `fd` binary from homebrew now
# # fd() {
# #   local dir
# #   dir=$(find ${1:-*} -path '*/\.*' -prune \
# #                   -o -type d -print 2> /dev/null | fzf-tmux +m) &&
# #   cd "$dir"
# # }

# # fda - including hidden directories
# fda() {
#   local dir
#   dir=$(find ${1:-.} -type d 2> /dev/null | fzf-tmux +m) && cd "$dir"
# }

# # cf - fuzzy cd from anywhere
# # ex: cf word1 word2 ... (even part of a file name)
# # zsh autoload function
# cf() {
#   local file

#   file="$(locate -Ai -0 $@ | grep -z -vE '~$' | fzf-tmux --read0 -0 -1)"

#   if [[ -n $file ]]
#   then
#      if [[ -d $file ]]
#      then
#         cd -- $file
#      else
#         cd -- ${file:h}
#      fi
#   fi
# }

# # fkill - kill process
# fkill() {
#   pid=$(ps -ef | sed 1d | fzf-tmux -m | awk '{print $2}')

#   if [ "x$pid" != "x" ]
#   then
#     kill -${1:-9} $pid
#   fi
# }

# # - GIT ------------------
# # fbr - checkout git branch
# fbr() {
#   local branches branch
#   branches=$(git branch -vv) &&
#   branch=$(echo "$branches" | fzf-tmux +m) &&
#   git checkout $(echo "$branch" | awk '{print $1}' | sed "s/.* //")
# }

# # fbr - checkout git branch (including remote branches)
# fbr() {
#   local branches branch
#   branches=$(git branch --all | grep -v HEAD) &&
#   branch=$(echo "$branches" |
#            fzf-tmux -d $(( 2 + $(wc -l <<< "$branches") )) +m) &&
#   git checkout $(echo "$branch" | sed "s/.* //" | sed "s#remotes/[^/]*/##")
# }

# # fshow - git commit browser
# fshow() {
#   git log --graph --color=always \
#       --format="%C(auto)%h%d %s %C(black)%C(bold)%cr" "$@" |
#   fzf-tmux --ansi --no-sort --reverse --tiebreak=index --bind=ctrl-s:toggle-sort \
#       --bind "ctrl-m:execute:
#                 (grep -o '[a-f0-9]\{7\}' | head -1 |
#                 xargs -I % sh -c 'git show --color=always % | less -R') << 'FZF-EOF'
#                 {}
# FZF-EOF"
# }

# # fcs - get git commit sha
# # example usage: git rebase -i `fcs`
# fcs() {
#   local commits commit
#   commits=$(git log --color=always --pretty=oneline --abbrev-commit --reverse) &&
#   commit=$(echo "$commits" | fzf-tmux --tac +s +m -e --ansi --reverse) &&
#   echo -n $(echo "$commit" | sed "s/ .*//")
# }

# # fstash - easier way to deal with stashes
# # type fstash to get a list of your stashes
# # enter shows you the contents of the stash
# # ctrl-d shows a diff of the stash against your current HEAD
# # ctrl-b checks the stash out as a branch, for easier merging
# fstash() {
#   local out q k sha
#     while out=$(
#       git stash list --pretty="%C(yellow)%h %>(14)%Cgreen%cr %C(blue)%gs" |
#       fzf-tmux --ansi --no-sort --query="$q" --print-query \
#           --expect=ctrl-d,ctrl-b);
#     do
#       q=$(head -1 <<< "$out")
#       k=$(head -2 <<< "$out" | tail -1)
#       sha=$(tail -1 <<< "$out" | cut -d' ' -f1)
#       [ -z "$sha" ] && continue
#       if [ "$k" = 'ctrl-d' ]; then
#         git diff $sha
#       elif [ "$k" = 'ctrl-b' ]; then
#         git stash branch "stash-$sha" $sha
#         break;
#       else
#         git stash show -p $sha
#       fi
#     done
# }

# # Use `fzf` to browse/select a recent git branch
# # h/t @jeremywrowe
# cb() {
#   git checkout $(git short-recent | fzf)
# }

# # - GIT ------------------
# # fs [FUZZY PATTERN] - Select selected tmux session
# #   - Bypass fuzzy finder if there's only one match (--select-1)
# #   - Exit if there's no match (--exit-0)
# fs() {
#   local session
#   session=$(tmux list-sessions -F "#{session_name}" | \
#     fzf-tmux --query="$1" --select-1 --exit-0) &&
#   tmux switch-client -t "$session"
# }

# # - Z ------------------
# # unalias z 2> /dev/null
# # z() {
# #   [ $# -gt 0 ] && _z "$*" && return
# #   cd "$(_z -l 2>&1 | fzf-tmux +s --tac --query "$*" | sed 's/^[0-9,.]* *//')"
# # }

# unalias z 2> /dev/null
# z() {
#   if [[ -z "$*" ]]; then
#     cd "$(_z -l 2>&1 | fzf-tmux +s --tac | sed 's/^[0-9,.]* *//')"
#   else
#     _last_z_args="$@"
#     _z "$@"
#   fi
# }

# # zz() {
# #   cd "$(_z -l 2>&1 | sed 's/^[0-9,.]* *//' | fzf-tmux -q $_last_z_args)"
# # }

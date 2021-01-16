#
# Functions
#

disable_symantec() {
  for f in /Library/LaunchDaemons/com.symantec.*.plist; do sudo mv -- "$f" "${f%.plist}.plist.disabled"; done
  for f in /Library/LaunchAgents/com.symantec.*.plist; do sudo mv -- "$f" "${f%.plist}.plist.disabled"; done
}
enable_symantec() {
  for f in /Library/LaunchDaemons/com.symantec.*.plist.disabled; do sudo mv -- "$f" "${f%.plist.disabled}.plist"; done
  for f in /Library/LaunchAgents/com.symantec.*.plist.disabled; do sudo mv -- "$f" "${f%.plist.disabled}.plist"; done
}

#
# git
#
function gss() { # smart show diffs
  git status &> /dev/null
  inside_git_repo=$?
  if [[ $inside_git_repo -eq 0 ]]; then

    git diff --quiet
    has_unstaged_changes=$?

    git diff --quiet --cached
    has_staged_changes=$?

    if [[ $has_unstaged_changes -eq 1 ]]; then
      echo "Showing diff of unstaged changes..."
      git difftool -d
    elif [[ $has_staged_changes -eq 1 ]]; then
      echo "Showing diff of staged changes..."
      git difftool -d --staged
    else
      echo "Showing last commit..."
      git difftool -d HEAD~1 HEAD
    fi

  else
    echo "Error: \"$0\" can only be used inside a Git repository."
  fi
}

# Test whether a given command exists
# Adapted from http://stackoverflow.com/questions/592620/check-if-a-program-exists-from-a-bash-script/3931779#3931779
# NOTE: This function is duplicated in .zshrc so that it doesn't have to depend on this file,
# but this shouldn't cause any issues
function command_exists() {
  hash "$1" &> /dev/null
}

# Shows how long processes have been up.
# No arguments shows all processes, one argument greps for a particular process.
# Found at <http://hints.macworld.com/article.php?story=20121127064752309>
function psup() {
  ps acxo etime,command | grep -- "$1"
}

# Pushes local SSH public key to another box
# Adapted from code found at <https://github.com/rtomayko/dotfiles/blob/rtomayko/.bashrc>
function push_ssh_cert() {
  if [[ $# -eq 0 || $# -gt 3 ]]; then
    echo "Usage: push_ssh_cert host [port] [username]"
    return
  fi
  local _host=$1
  local _port=22
  local _user=$USER
  if [[ $# -ge 2 ]]; then
    _port=$2
  fi
  if [[ $# -eq 3 ]]; then
    _user=$3
  fi
  test -f ~/.ssh/id_*sa.pub || ssh-keygen -t rsa
  echo "Pushing public key to $_user@$_host:$_port..."
  ssh -p $_port $_user@$_host 'mkdir -p ~/.ssh && cat >> ~/.ssh/authorized_keys' < ~/.ssh/id_*sa.pub
}

# Find and replace a string in all files recursively, starting from the current directory.
# Adapted from code found at <http://forums.devshed.com/unix-help-35/unix-find-and-replace-text-within-all-files-within-a-146179.html>
function replacein() {
  find . -type f | xargs perl -pi -e "s/$1/$2/g"
}

#
# home-assistant
#
lamp() {
  sh $HOME/.dotfiles/bin/hs-to-ha "script.hs_office_lamp_$1"
}

geoip() {
  curl ipinfo.io/$1
}

killport() { lsof -t -i tcp:$1 | xargs kill }
killport() { lsof -i tcp:$1 | awk 'NR!=1 {print $2}' | xargs kill }

remac() {
  sudo /System/Library/PrivateFrameworks/Apple80211.framework/Resources/airport -z
  sudo ifconfig en0 ether $(openssl rand -hex 6 | sed 's/\(..\)/\1:/g; s/.$//')
  sudo networksetup -detectnewhardware
  echo $(ifconfig en0 | grep ether)
}

chk() { grep $1 =(ps auxwww) }

portchk() { lsof -n -i4TCP:$1 }
alias chkport=portchk

changeMac() {
  local mac=$(openssl rand -hex 6 | sed 's/\(..\)/\1:/g; s/.$//')
  sudo ifconfig en0 ether $mac
  sudo ifconfig en0 down
  sudo ifconfig en0 up
  echo "Your new physical address is $mac"
}

# childprocs() {
#   htop -p $(ps -ef | awk -v proc=$1 '$3 == proc { cnt++;if (cnt == 1) { printf "%s",$2 } else { printf ",%s",$2 } }')
# }

# children() {
#   proc="$1"
#   echo "getting children for $proc"
#   chk $1 | awk '/$proc/ { print $2 }' | head -n 1 | xargs pstree -p
# }

path() {
  echo $PATH | tr ":" "\n" | \
    awk "{ sub(\"/usr\",   \"$fg_no_bold[green]/usr$reset_color\"); \
      sub(\"/bin\",   \"$fg_no_bold[blue]/bin$reset_color\"); \
      sub(\"/opt\",   \"$fg_no_bold[cyan]/opt$reset_color\"); \
      sub(\"/sbin\",  \"$fg_no_bold[magenta]/sbin$reset_color\"); \
      sub(\"/local\", \"$fg_no_bold[yellow]/local$reset_color\"); \
      sub(\"/.rvm\",  \"$fg_no_bold[red]/.rvm$reset_color\"); \
      print }"
}

mcd() { mkdir -p $1 && cd $1 }
alias cdm=mcd

cdf() { cd *$1*/ } # stolen from @topfunky

# run() { open -a "/Applications/$1.app" } revert() { git reset $1 #resets index to former commit; replace '56e05fced' with your commit code git reset --soft HEAD@{1} #moves pointer back to previous HEAD git commit -m "Revert to $1"
#   git reset --hard #updates working copy to reflect the new commit
# }

note () {
  local notes_dir="$HOME/Dropbox/notes"
  case "$1" in
    c)
      cd "$notes_dir"
      ;;
    l)
      ls "$notes_dir"
      ;;
    *)
      pushd "$notes_dir"
      nvim "$1"
      popd
  esac
}

# Codi
# Usage: codi [filetype] [filename]
codi() {
  local syntax="${1:-elixir}"
  shift
  nvim -c \
    "let g:startify_disable_at_vimenter = 1 |\
    set bt=nofile ls=0 noru nonu nornu |\
    hi CodiVirtualText guifg=red
    hi ColorColumn ctermbg=NONE |\
    hi VertSplit ctermbg=NONE |\
    hi NonText ctermfg=0 |\
    Codi $syntax" "$@"
}

# iron.nvim
# Usage: repl [filetype] [filename]
iron() {
  local syntax="${1:-javascript}"
  shift
  nvim -c \
    "startinsert |\
    set bt=nofile ls=0 noru nonu nornu |\
    hi ColorColumn ctermbg=NONE |\
    hi VertSplit ctermbg=NONE |\
    hi NonText ctermfg=0 |\
    call IronStartRepl('$syntax', 0, 1)"
}

function ssh_ec2() {
  ssh $(aws ec2 describe-instances --filters "Name=tag:Name,Values=$1" | jq -r '.Reservations[].Instances[] | .PublicDnsName');
}

## FZF FUNCTIONS ##

# fo [FUZZY PATTERN] - Open the selected file with the default editor
#   - Bypass fuzzy finder if there's only one match (--select-1)
#   - Exit if there's no match (--exit-0)
fo() {
  local files
  IFS=$'\n' files=($(fzf-tmux --query="$1" --multi --select-1 --exit-0))
  [[ -n "$files" ]] && ${EDITOR:-vim} "${files[@]}"
}

# fh [FUZZY PATTERN] - Search in command history
fh() {
  print -z $( ([ -n "$ZSH_NAME" ] && fc -l 1 || history) | fzf +s --tac | sed 's/ *[0-9]* *//')
}

# fbr [FUZZY PATTERN] - Checkout specified branch
# Include remote branches, sorted by most recent commit and limited to 30
fgb() {
  local branches branch
  branches=$(git for-each-ref --count=30 --sort=-committerdate refs/heads/ --format="%(refname:short)") &&
  branch=$(echo "$branches" |
           fzf-tmux -d $(( 2 + $(wc -l <<< "$branches") )) +m) &&
  git checkout $(echo "$branch" | sed "s/.* //" | sed "s#remotes/[^/]*/##")
}

# tm [SESSION_NAME | FUZZY PATTERN] - create new tmux session, or switch to existing one.
# Running `tm` will let you fuzzy-find a session mame
# Passing an argument to `ftm` will switch to that session if it exists or create it otherwise
ftm() {
  [[ -n "$TMUX" ]] && change="switch-client" || change="attach-session"
  if [ $1 ]; then
    tmux $change -t "$1" 2>/dev/null || (tmux new-session -d -s $1 && tmux $change -t "$1"); return
  fi
  session=$(tmux list-sessions -F "#{session_name}" 2>/dev/null | fzf --exit-0) &&  tmux $change -t "$session" || echo "No sessions found."
}

# tm [SESSION_NAME | FUZZY PATTERN] - delete tmux session
# Running `tm` will let you fuzzy-find a session mame to delete
# Passing an argument to `ftm` will delete that session if it exists
ftmk() {
  if [ $1 ]; then
    tmux kill-session -t "$1"; return
  fi
  session=$(tmux list-sessions -F "#{session_name}" 2>/dev/null | fzf --exit-0) &&  tmux kill-session -t "$session" || echo "No session found to delete."
}

# fuzzy grep via rg and open in vim with line number
fgr() {
  local file
  local line

  read -r file line <<<"$(rg --no-heading --line-number $@ | fzf -0 -1 | awk -F: '{print $1, $2}')"

  if [[ -n $file ]]
  then
     vim $file +$line
  fi
}

# fstash - easier way to deal with stashes
# type fstash to get a list of your stashes
# enter shows you the contents of the stash
# ctrl-d shows a diff of the stash against your current HEAD
# ctrl-b checks the stash out as a branch, for easier merging
fzstash() {
  local out q k sha
  while out=$(
    git stash list --pretty="%C(yellow)%h %>(14)%Cgreen%cr %C(blue)%gs" |
    fzf --ansi --no-sort --query="$q" --print-query \
        --expect=ctrl-d,ctrl-b);
  do
    mapfile -t out <<< "$out"
    q="${out[0]}"
    k="${out[1]}"
    sha="${out[-1]}"
    sha="${sha%% *}"
    [[ -z "$sha" ]] && continue
    if [[ "$k" == 'ctrl-d' ]]; then
      git diff $sha
    elif [[ "$k" == 'ctrl-b' ]]; then
      git stash branch "stash-$sha" $sha
      break;
    else
      git stash show -p $sha
    fi
  done
}

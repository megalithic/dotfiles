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

# HASS / HA / HOMEASSISTANT
# -----------------------------------------------------------------------------
lamp() {
  sh $HOME/.dotfiles/bin/hs-to-ha "script.hs_office_lamp_$1"
}

geoip() {
  curl ipinfo.io/$1
}

killport() {
  lsof -t -i tcp:$1 | xargs kill
}

remac() {
  sudo /System/Library/PrivateFrameworks/Apple80211.framework/Resources/airport -z
  sudo ifconfig en0 ether $(openssl rand -hex 6 | sed 's/\(..\)/\1:/g; s/.$//')
  sudo networksetup -detectnewhardware
  echo $(ifconfig en0 | grep ether)
}


chk() { grep $1 =(ps auxwww) }

portchk() { lsof -n -i4TCP:$1 }
alias chkport=portchk

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
    "startinsert |\
    set bt=nofile ls=0 noru nonu nornu |\
    hi ColorColumn guibg=NONE |\
    hi VertSplit guibg=NONE |\
    hi NonText guifg=0 |\
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

# Note taking function and command completion
_n() {
  local lis cur
  lis=$(fd . "${NOTE_DIR}" -e md | \
    sed -e "s|${NOTE_DIR}/||" | \
    sed -e 's/\.md$//')
  cur=${COMP_WORDS[COMP_CWORD]}
  COMPREPLY=( $(compgen -W "$lis" -- "$cur") )
}
note() {
  : "${NOTE_DIR:?'NOTE_DIR ENV Var not set'}"
  if [ $# -eq 0 ]; then
    local file
    file=$(ls -td $(fd . "${NOTE_DIR}" -e md) | \
      sed -e "s|${NOTE_DIR}/||" | \
      sed -e 's/\.md$//' | \
      fzf \
        --multi \
        --select-1 \
        --exit-0 \
        --preview="bat --color=always ${NOTE_DIR}/{}.md" \
        --preview-window=right:60%:wrap)
    [[ -n $file ]] && \
      ${EDITOR:-vim} "${NOTE_DIR}/${file}.md"
  else
    case "$1" in
      "-d")
        rm "${NOTE_DIR}"/"$2".md
        ;;
      "-w")
        ${EDITOR:-vim} "${WORK_NOTE_DIR}"/"$2".md
        ;;
      "-wa")
        local file="$(date +%Y-%m-%d)"
        if [ -e "${WORK_NOTE_DIR}/$file.md" ]; then
          echo "\n## $(date +%H:%M:%S)" >> "${WORK_NOTE_DIR}/${file}.md"
        # else
        #   echo "## $(date +%H:%M:%S)" >> "${WORK_NOTE_DIR}/${file}.md"
        fi
        if [ ! -z "$2" ]; then
          echo "$2" >> "${WORK_NOTE_DIR}/${file}.md"
        else
          ${EDITOR:-vim} "${WORK_NOTE_DIR}/${file}.md"
        fi
        ;;
      "-cd")
        cd ${NOTE_DIR}
        ;;
      "-a")
        local file="$(date +%Y-%m-%d)"
        if [ -e "${NOTE_DIR}/$file.md" ]; then
          echo "\n## $(date +%H:%M:%S)" >> "${NOTE_DIR}/${file}.md"
        # else
        #   echo "## $(date +%H:%M:%S)" >> "${NOTE_DIR}/${file}.md"
        fi
        if [ ! -z "$2" ]; then
          echo "$2" >> "${NOTE_DIR}/${file}.md"
        else
          ${EDITOR:-vim} "${NOTE_DIR}/${file}.md"
        fi
        ;;
      "-j")
        local file="journal-$(date +%Y).md"
        echo "\n## $(date +%c)" >> "${NOTE_DIR}/${file}"
        ${EDITOR:-vim} "${NOTE_DIR}/${file}"
        ;;
      "-p")
        local file
        file=$(ls -td $(fd . "${NOTE_DIR}/pocket" -e md -e txt) | \
          sed -e "s|${NOTE_DIR}/pocket||" | \
          fzf \
            --multi \
            --select-1 \
            --exit-0 \
            --preview="cat ${NOTE_DIR}/pocket{}" \
            --preview-window=right:60%:wrap)
        [[ -n $file ]] && \
          ${EDITOR:-vim} "${NOTE_DIR}/${file}"
        ;;
      "-s")
        local file
        if [ -z "$2" ]; then
          echo "no search string supplied"
        else
          file=$(ls -td $(ag --nobreak --nonumbers --noheading --markdown -l "$2" ${NOTE_DIR}) | \
            sed -e "s|${NOTE_DIR}/||" | \
            sed -e 's/\.md$//' | \
            fzf \
              -i \
              --exact \
              --multi \
              --select-1 \
              --exit-0 \
              --preview="cat ${NOTE_DIR}/{}.md" \
              --preview-window=right:60%:wrap | \
              awk -F: '{print $1}')
        fi
        [[ -n $file ]] && \
          ${EDITOR:-vim} "${NOTE_DIR}"/"${file}".md
        ;;
      *)
        ${EDITOR:-vim} "${NOTE_DIR}"/"$1".md
        ;;
    esac
  fi
}
# complete -F _n note

# Override Z for use with fzf
unalias z 2> /dev/null
z() {
  if [[ -z "$*" ]]; then
    cd "$(_z -l 2>&1 | fzf +s --tac | sed 's/^[0-9,.]* *//')"
  else
    _z "$@"
  fi
}

# Todo List & Completion
_todo() {
  local iter use cur
  cur=${COMP_WORDS[COMP_CWORD]}
  use=$( awk '{gsub(/ /,"\\ ")}8' "$TODOFILE" )
  use="${use//\\ /___}"
  for iter in $use; do
    if [[ $iter =~ ^$cur ]]; then
      COMPREPLY+=( "${iter//___/ }" )
    fi
  done
}
todo() {
  : "${TODO:?'TODO ENV Var not set. Please set to path of default todo file.'}"
  TODOFILE=$TODO
  TODOARCHIVEFILE=${TODO%.*}.archive.md

  if [ $# -eq 0 ]; then
    if [ -f "$TODOFILE" ] ; then
      awk '{ print NR, "-", $0 }' "$TODOFILE"
    fi
  else
    case "$1" in
      -h|--help)
        echo "todo - Command Line Todo List Manager"
        echo " "
        echo "Creates a text-based todo list and provides basic operations to add and remove elements from the list. If using TMUX, the todo list is session based, using the name of your active session."
        echo " "
        echo "usage: todo                                 # display todo list"
        echo "usage: todo (--help or -h)                  # show this help"
        echo "usage: todo (--add or -a) [activity name]   # add a new activity to list"
        echo "usage: todo (--archive)                     # show completed tasks in archive list"
        echo "usage: todo (--done or -d) [name or #]      # complete and archive activity"
        ;;
      -a|--add)
        echo "${*:2}" >> "$TODOFILE"
        ;;
      -d|--done)
        re='^[0-9]+$'
        if ! [[ "$2" =~ $re ]] ; then
          match=$(sed -n "/$2/p" "$TODOFILE" 2> /dev/null)
          sed -i "" -e "/$2/d" "$TODOFILE" 2> /dev/null
        else
          match=$(sed -n "$2p" "$TODOFILE" 2> /dev/null)
          sed -i "" -e "$2d" "$TODOFILE" 2> /dev/null
        fi
        if [ ! -z "$match" ]; then
          echo "$(date +"%Y-%m-%d %H:%M:%S") - $match" >> "$TODOARCHIVEFILE"
        fi
        ;;
    esac
  fi

}

# find todo notes in current project
function todos {
  LOCAL_DIR=$(git rev-parse --show-toplevel 2> /dev/null)
  LOCAL_DIR=${LOCAL_DIR:-.}
  if [ $# -eq 0 ]; then
    ag '(\bTODO\b|\bFIX(ME)?\b|\bREFACTOR\b)' ${LOCAL_DIR}
  else
    ag ${*:1} '(\bTODO\b|\bFIX(ME)?\b|\bREFACTOR\b)' ${LOCAL_DIR}
  fi
}

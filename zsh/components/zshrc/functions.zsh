#
# Functions
#

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

myip() {
  ifconfig lo0 | grep 'inet ' | sed -e 's/:/ /' | awk '{print "lo0       : " $2}'
  ifconfig en0 | grep 'inet ' | sed -e 's/:/ /' | awk '{print "en0 (IPv4): " $2 " " $3 " " $4 " " $5 " " $6}'
  ifconfig en0 | grep 'inet6 ' | sed -e 's/ / /' | awk '{print "en0 (IPv6): " $2 " " $3 " " $4 " " $5 " " $6}'
  ifconfig en1 | grep 'inet ' | sed -e 's/:/ /' | awk '{print "en1 (IPv4): " $2 " " $3 " " $4 " " $5 " " $6}'
  ifconfig en1 | grep 'inet6 ' | sed -e 's/ / /' | awk '{print "en1 (IPv6): " $2 " " $3 " " $4 " " $5 " " $6}'
}

remac() {
  sudo /System/Library/PrivateFrameworks/Apple80211.framework/Resources/airport -z
  sudo ifconfig en0 ether $(openssl rand -hex 6 | sed 's/\(..\)/\1:/g; s/.$//')
  sudo networksetup -detectnewhardware
  echo $(ifconfig en0 | grep ether)
}


chk() { grep $1 =(ps auxwww) }

portchk() { lsof -n -i4TCP:$1 }

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

tmateip () {
  output=$(tmate show-message | grep -m 1 "Remote session:")
  echo ${output#*session: } # display it
  echo ${output#*session: } | pbcopy # and copy it to clipboard
}

mcd() { mkdir -p $1 && cd $1 }
alias cdm=mcd

cdf() { cd *$1*/ } # stolen from @topfunky

run() { open -a "/Applications/$1.app" }

revert() {
  git reset $1 #resets index to former commit; replace '56e05fced' with your commit code
  git reset --soft HEAD@{1} #moves pointer back to previous HEAD
  git commit -m "Revert to $1"
  git reset --hard #updates working copy to reflect the new commit
}

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
  local syntax="${1:-javascript}"
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


# -------------------------------------------------------------------
# any function from http://onethingwell.org/post/14669173541/any
# search for running processes
# -------------------------------------------------------------------
# any() {
#     emulate -L zsh
#     unsetopt KSH_ARRAYS
#     if [[ -z "$1" ]] ; then
#         echo "any - grep for process(es) by keyword" >&2
#         echo "Usage: any " >&2 ; return 1
#     else
#         ps xauwww | grep -i --color=auto "[${1[1]}]${1[2,-1]}"
#     fi
# }


# TMATE Functions

TMATE_PAIR_NAME="$(whoami)-pair"
TMATE_SOCKET_LOCATION="~/tmp/tmate-pair.sock"
TMATE_TMUX_SESSION="~/tmp/tmate-tmux-session"

# Get current tmate connection url
tmate-url() {
  url="$(tmate -S $TMATE_SOCKET_LOCATION display -p '#{tmate_ssh}')"
  echo "$url" | tr -d '\n' | pbcopy
  echo "Copied tmate url for $TMATE_PAIR_NAME:"
  echo "$url"
}



# Start a new tmate pair session if one doesn't already exist
# If creating a new session, the first argument can be an existing TMUX session to connect to automatically
tmate-pair() {
  if [ ! -e "$TMATE_SOCKET_LOCATION" ]; then
    tmate -S "$TMATE_SOCKET_LOCATION" -f "$HOME/.tmate.conf" new-session -d -s "$TMATE_PAIR_NAME"

    while [ -z "$url" ]; do
      url="$(tmate -S $TMATE_SOCKET_LOCATION display -p '#{tmate_ssh}')"
      echo "url: $url"
    done
    tmate-url
    sleep 1

    if [ -n "$1" ]; then
      echo $1 > $TMATE_TMUX_SESSION
      tmate -S "$TMATE_SOCKET_LOCATION" send -t "$TMATE_PAIR_NAME" "TMUX='' tmux attach-session -t $1" ENTER
    fi
  fi
  tmate -S "$TMATE_SOCKET_LOCATION" attach-session -t "$TMATE_PAIR_NAME"
}



# Close the pair because security
tmate-unpair() {
  if [ -e "$TMATE_SOCKET_LOCATION" ]; then
    if [ -e "$TMATE_SOCKET_LOCATION" ]; then
      tmux detach -s $(cat $TMATE_TMUX_SESSION)
      rm -f $TMATE_TMUX_SESSION
    fi

    tmate -S "$TMATE_SOCKET_LOCATION" kill-session -t "$TMATE_PAIR_NAME" || echo 'Already detached'
    echo "Killed session $TMATE_PAIR_NAME"
  else
    echo "Session already killed"
  fi
}






# Pair Programming
PAIR_IP=107.170.115.65
pair() {
  ssh -f -N -R 1337:127.0.0.1:22 root@$PAIR_IP
  echo
  echo
  echo "Pair session started"
  echo
  echo "To connect, execute the following command (copied to clipboard):"
  echo "ssh -p 1337 pair@$PAIR_IP"
  echo "ssh -p 1337 pair@$PAIR_IP" | pbcopy
  sleep 5
  wemux start
}

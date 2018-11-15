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


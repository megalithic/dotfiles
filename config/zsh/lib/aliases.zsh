#!/usr/bin/env zsh
# shellcheck shell=bash

# delete symlinks (remove evertyhing after '*' to just search for symlinks): find /home -maxdepth 1 -lname '*' -exec rm {} \;
# create the target folder and move the source to the new destination: mkdir -p ~/.dotfiles/git/bak && mv git* "$_"

# Useful
alias cp="${aliases[cp]:-cp} -iv"
alias ln="${aliases[ln]:-ln} -iv"
alias mv="${aliases[mv]:-mv} -iv"
alias rm="${aliases[rm]:-rm} -i"
alias mkdir="${aliases[mkdir]:-mkdir} -p"
alias sudo="sudo "
alias type='type -a'
alias which='which -as'

# Auto-correction exceptions
# -----------------------------------------------------------------------------
alias man='nocorrect man'
alias mkdir='nocorrect mkdir'
alias mv='nocorrect mv'
alias cp='nocorrect cp'
alias sudo='nocorrect sudo'
alias git="nocorrect git"
alias nmap="nocorrect nmap"
# if $(gh &>/dev/null); then
# 	alias git="gh"
# fi

# Files & directories
# -----------------------------------------------------------------------------
alias ..="cd .."
alias ...="cd ../.."
alias ....="cd ../../.."
alias fd="fd --hidden"
alias fdd="fd -H -t d -d 10"

alias ls="ls --color=auto --hyperlink=auto $@"
alias l='ls -lFh' # size,show type,human readable

# grc overides for ls
#   Made possible through contributions from generous benefactors like
#   `brew install coreutils`

if $(eza &>/dev/null); then
  alias exa=\eza
  alias ls="\eza -gahF --group-directories-first"
  # alias l="\eza -lahF --icons --group-directories-first --git"
  alias l="\eza --long --git-repos --all --git --color=always --group-directories-first --icons $@"
elif $(exa &>/dev/null); then
  alias ls="exa -gahF --group-directories-first"
  alias l="exa -lahF --icons --group-directories-first --git"
elif $(gls &>/dev/null); then
  alias gls="tmux select-pane -P bg=default,fg=default &> /dev/null; gls --color=auto --group-directories-first"
  alias ls="gls -FA"
  alias lst="gls -FAt"
  alias l="gls -lAh"
  alias lt="gls -lAht"
  alias ll="gls -l"
  alias la="gls -A"
  alias las='find . -maxdepth 1 -type l -printf "%p -> %l\n" | sort'
fi

if $(erdtree &>/dev/null); then
  alias tree="erdtree"
  # alias tree="erdtree -I 'dotbot|node_modules|cache|test_*'"
fi

# REF: https://www.reddit.com/r/zsh/comments/3anb4c/zsh_function_to_run_last_command/
alias fk="r" #  runs the last command

alias s="ls"
alias last='ls *(.om[1])'
# alias bat='BAT_CONFIG_PATH="~/.batrc" BAT_THEME="base16" bat'
alias cat='bat'
alias du="ncdu --color dark -rr -x --exclude .git --exclude node_modules"
alias help='tldr'

alias utc="date -u"
# alias s='ssh $(grep -iE "^host[[:space:]]+[^*]" ~/.ssh/config | fzf | awk "{print \$2}")'
alias webcam="sudo killall VDCAssistant"
alias dsnuke="find . -name '*.DS_Store' -type f -ls -delete"
alias pkey="pbcopy < ~/.ssh/id_rsa.pub"
alias pubkey="more ~/.ssh/id_rsa.pub | pbcopy | echo '=> Public key copied to pasteboard.'"
alias unixts="date +%s"
# alias exit="exit; tmux select-pane -P bg=default"
alias xit="exit"
alias q="exit"
alias ,q="exit"
alias please='sudo $(fc -ln -1)'
alias count='wc -l'
alias dirsize="du -sh * | sort -n"
alias dus='du -sckx * | sort -nr'
alias top='top -o cpu'
has htop && alias top='htop -s PERCENT_CPU'
alias icat="kitty +kitten icat"

# alias back="slack back; dnd off"
# alias gone="slack gone; dnd on"
# alias away="slack away; dnd off"
# alias lunch="slack lunch; dnd off"
alias back="slack back"
alias gone="slack gone"
alias away="slack away"
alias lunch="slack lunch"
alias brb="slack brb"
alias coffee="slack coffee"

# ZMV
# -----------------------------------------------------------------------------
autoload -U zmv
# alias for zmv for no quotes
# mmv *.c.orig orig/*.c
alias mmv='noglob zmv -W'

# TMUX / SSH
# -----------------------------------------------------------------------------
# alias mux="tmux" #-> see function for tmux in tmux.zsh
alias takeover="tmux detach -a"
alias outa="tmux attach-session -t outstand"
alias trw="tmux rename-window"
alias trs="tmux rename-session"
alias tpmi="$XDG_CONFIG_HOME/tmux/plugins/tpm/bin/install_plugins"
alias tpmu="$XDG_CONFIG_HOME/tmux/plugins/tpm/bin/update_plugins"
alias tpmc="$XDG_CONFIG_HOME/tmux/plugins/tpm/bin/clean_plugins"
alias mega="ftm mega"

# alias s="kitty +kitten ssh"
alias kssh="kitty +kitten ssh"

alias fixssh="chmod 700 ~/.ssh && chmod 600 ~/.ssh/*"

## - ag/ack/grep/fzf/rg/ripgrep --------------------------------------
# https://github.com/junegunn/fzf/wiki/Examples#searching-file-contents
# alias ag="ag --nobreak --nonumbers --noheading . | fzf"
# alias g="rg"
# alias g="grep -r -i --color='auto'"
# alias g="rg -F"

# DOCKER
# -----------------------------------------------------------------------------
# alias docker="sudo docker -H $DOCKER_HOST"
alias docker-ip=dockerip
alias docker-ubuntu="docker run -i -t ubuntu /bin/bash"

# BREW
# -----------------------------------------------------------------------------
alias b="brew"

# PYTHON
# -----------------------------------------------------------------------------
# alias py="python"
# alias python=/usr/local/bin/python3
# alias python=python3.8
# alias pip3=/usr/local/Cellar/python@3.8/3.8.2/bin/pip3

# (NEO)VIM
# -----------------------------------------------------------------------------

if type nvim >/dev/null 2>&1; then
  # REF: in neovim -> `:help remote.txt` / https://www.youtube.com/watch?v=xO5yMutC-rM
  # alias nvim="nvim --listen /tmp/nvim.pipe -O" # let's always open multiple files passed in as vsplits
  #
  alias nvim="nvim -O"

  alias slownvim="nvim --startuptime /dev/stdout slow_to_open_file.ex +q | less"
  # alias profilenvim="f() {nvim --startuptime /dev/stderr "$1" +q} && f $1"
  alias profilenvim='hyperfine "nvim --headless +qa" --warmup 5'
  # alias nvimupdate="brew update && brew uninstall neovim && brew install neovim --HEAD && brew postinstall neovim && pip3 install --upgrade pynvim && npm install -g neovim --force && gem install neovim && brew outdated"
  # alias nvimbuild="pushd ~/.local/share/src/neovim && git co master && git up && rm -rf ./.deps && make CMAKE_BUILD_TYPE=RelWithDebInfo && sudo make install && popd"
  # alias buildnvim=nvimbuild
  alias im="nvim"
  alias vm="nvim"
  alias nvm=nv
  alias vim="NVIM_APPNAME=nvim nvim"
  # alias vim="NVIM_APPNAME=nvim nvim" # <-- original!
  # alias wipvim="NVIM_APPNAME=wipvim nvim"
  # alias folkevim="NVIM_APPNAME=folkevim nvim"
  # alias akinvim="NVIM_APPNAME=akinvim nvim"
  # alias ribvim="NVIM_APPNAME=ribvim nvim"
  alias ribvim="NVIM_APPNAME=ribvim nvim"
  alias penvim="NVIM_APPNAME=penvim nvim"
  alias newvim="NVIM_APPNAME=newmega nvim"
  alias kickvim="NVIM_APPNAME=kickvim nvim"
  alias e="NVIM_APPNAME=wipvim nvim"
  alias ogvim="NVIM_APPNAME=ogvim nvim"
  alias og="NVIM_APPNAME=ogvim nvim"
  alias mvim="NVIM_APPNAME=mvim nvim"
  alias rvim="NVIM_APPNAME=rvim nvim"
  alias minvim="NVIM_APPNAME=minvim nvim"
  alias v=vim
  alias vi="/usr/local/bin/vim"
  alias novim="nvim -u NONE"
  alias barevim="nvim -u NONE"
  alias ngit="CUSTOM_NVIM=1 nvim -c \":Neogit kind=replace\""
  alias ndiff="CUSTOM_NVIM=1 nvim -c \":DiffviewOpen\""
  alias ndb="CUSTOM_NVIM=1 nvim -c \":Dbee toggle\""

  # suffix aliases set the program type to use to open a particular file with an extension
  alias -s {js,html,js,ts,css,md}=nvim
fi

# CONFIG EDITS
# -----------------------------------------------------------------------------
alias ez="nvim $DOTS/config/zsh/.zshrc"
alias ezz="nvim $DOTS/config/zsh/.zshenv"
alias ea="nvim $DOTS/config/zsh/**/aliases.zsh"
alias eaz=ea
alias ezp="nvim $DOTS/config/zsh/prompt_megalithic_setup"
alias ezf="nvim $DOTS/config/zsh/**/funcs.zsh"
alias ezo="nvim $DOTS/config/zsh/**/opts.zsh"
alias eze="nvim $DOTS/config/zsh/**/env.zsh"
alias ezkb="nvim $DOTS/config/zsh/**/keybindings.zsh"
alias ezl="nvim $DOTS/config/zsh/**/local.zsh"

alias ev="nvim $DOTS/config/nvim/init.lua"
alias evp="nvim $DOTS/config/nvim/lua/plugins/init.lua"
alias evo="nvim $DOTS/config/nvim/lua/config/options.lua"
alias evg="nvim $DOTS/config/nvim/lua/config/globals.lua"
alias evu="nvim $DOTS/config/nvim/lua/config/utils/init.lua"
alias evk="nvim $DOTS/config/nvim/lua/config/keymaps.lua"
alias eva="nvim $DOTS/config/nvim/lua/config/autocmds.lua"
alias evl="nvim $DOTS/config/nvim/plugin/lsp/init.lua"
alias evs="nvim $DOTS/config/nvim/plugin/lsp/servers.lua"
alias evf="nvim $DOTS/config/nvim/after/plugin/filetypes.lua"
alias evt="nvim $DOTS/config/nvim/after/plugin/term.lua"

alias ehs="nvim $DOTS/config/hammerspoon/config.lua"
alias eh="nvim $DOTS/config/hammerspoon/init.lua"
alias eg="nvim $DOTS/git/gitconfig"
alias egc="nvim $DOTS/config/ghostty/config"
alias eb="nvim $DOTS/brew/Brewfile"
alias essh="nvim $DOTS/home/ssh/config"

alias ek="nvim $DOTS/config/kitty/kitty.conf"
alias ekm="nvim $DOTS/config/kitty/maps.conf"
alias eks="nvim $DOTS/config/kitty/sessions/default.session"

alias eq="nvim $DOTS/home/qutebrowser/config.py"

alias ew="nvim $DOTS/config/wezterm/wezterm.lua"
alias wezup="brew upgrade wezterm@nightly --no-quarantine --greedy-latest"

alias ezmk="nvim $HOME/code/zmk-config/config/leeloo.keymap"
alias eqmk="nvim $HOME/code/megalithic_qmk/keyboards/atreus62/keymaps/megalithic/keymap.c"

alias ebt="nvim $DOTS/misc/newtab/index.html"

alias ee="nvim $DOTS/config/espanso/match/base.yml"

alias etm="nvim $DOTS/config/tmux/megaforest.tmux.conf"

# kitty session connections:
alias kapp="et -c 'cd ~/code/app && ls; exec /usr/bin/zsh' seth-dev; /usr/local/bin/zsh"
alias katlas="et -c 'cd ~/code/atlas && ls; exec /usr/bin/zsh' seth-dev; /usr/local/bin/zsh"
alias kpages="et -c 'cd ~/code/pages && ls; exec /usr/bin/zsh' seth-dev; /usr/local/bin/zsh"

# see ~/.dotfiles/bin/et
# alias et="nvim $DOTS/config/tmux/tmux.conf"

# ZK/notes/zettelkasten
# -----------------------------------------------------------------------------
alias zkn="zknew"
alias zknc='zk new --print-path --title "$*" | pbcopy'
alias zkl="zk list $@"
alias zke="zk edit --interactive"
alias zkd="zk edit 202302272113"
alias ezk='$EDITOR "$HOME/.dotfiles/config/zk/config.toml"'

# FOLDERS
# -----------------------------------------------------------------------------
alias dot="cd $DOTS"
alias dots="cd $DOTS"
alias priv="cd $PRIVATES"
alias ot=dot
alias code="cd $HOME/code"
alias repos="cd $HOME/code"
alias play="cd $HOME/code/playground"
alias logs="cd $HOME/code/logs/"
alias docs="cd $HOME/Documents"
alias box="cd $HOME/Dropbox/"
alias dl="cd $HOME/Downloads/"
alias icloud="cd $HOME/Library/Mobile\ Documents/com\~apple\~CloudDocs"
alias idocs="cd $HOME/Library/Mobile\ Documents/com\~apple\~CloudDocs/Documents"
alias zknotes="cd $HOME/Library/Mobile\ Documents/com\~apple\~CloudDocs/Documents/_notes"
alias inotes="${zknotes}"
alias notes="cd $HOME/Library/Mobile\ Documents/com\~apple\~CloudDocs/Documents/_notes"
alias nvim-plugins="cd ~/.local/share/nvim/site/pack/paqs/start"

# MISC
# -----------------------------------------------------------------------------
alias gem="$(mise where ruby latest)/bin/gem"
alias rm="rm -v"
[[ "$(uname)" == "Darwin" ]] && alias rm="${HOMEBREW_PREFIX}/bin/trash"
alias dash="open dash://" # lang:query
alias pyserve="python -m SimpleHTTPServer"
# alias srv=server
alias chromedebug="/Applications/Google\ Chrome.app/Contents/MacOS/Google\ Chrome --remote-debugging-port=9222 --js-flags=--stack_trace_limit=-1 --user-data-dir=/tmp/jsleakcheck"
alias chrome="open -a '/Applications/Google Chrome.app' --args --disable-web-security"
# Kill all the tabs in Chrome to free up memory
# [C] explained: http://www.commandlinefu.com/commands/view/402/exclude-grep-from-your-grepped-output-of-ps-alias-included-in-description
# Thanks @sindersorhus: https://github.com/mathiasbynens/dotfiles/commit/bd9429af1cfdc7f4caa73e6f98773ed69a161c9c
alias chromekill="ps ux | grep '[C]hrome Helper --type=renderer' | grep -v extension-process | tr -s ' ' | cut -d ' ' -f2 | xargs kill"
alias bravekill="ps ux | grep '[B]rave Helper --type=renderer' | grep -v extension-process | tr -s ' ' | cut -d ' ' -f2 | xargs kill"
alias die='pkill -9 -f'
alias killport='port "$1" | xargs kill -9'
alias sz="source $HOME/.config/zsh/.zshenv && source $HOME/.config/zsh/.zshrc && source $HOME/.config/zsh/prompt_megalithic_setup" # && \reset"
alias zz=z
alias cls="clr && ls"
alias get="curl -OL"
alias get="http --download"
alias safe="xattr -d com.apple.quarantine"
alias nvm='n'
# alias irc="LANG=en_US.UTF-8 LC_ALL=en_US.UTF-8 weechat-curses"
# alias irc="PERL_MM_OPT="INSTALL_BASE=$HOME/perl5" cpan local::lib; eval \"$(perl -I$HOME/perl5/lib/perl5 -Mlocal::lib=$HOME/perl5)\"; weechat-curses"
# alias weechat="weechat-curses"
alias irc="weechat"
# alias irc="rm ~/.weechat/weechat_crash*.log; sh ~/.dotfiles/zsh/base16-ocean.dark.sh; weechat-curses"
# alias irc="rm ~/.weechat/weechat_crash*.log; weechat-curses"
alias rc=irc
alias clr=clear
alias zshtime="/usr/bin/time $(which zsh) -i -c echo"
# alias zshtime="for i in $(seq 1 10); do /usr/bin/time zsh -i -c exit; done"
alias timezsh="time $(which zsh) -i -c exit"
alias zshprofile="time ZPROFILE=1 $(which zsh) -i -c exit"
alias zshclear="rm -f ~/.zcompdump ~/.zsh-dotfiles-compiled.zsh"

# Intuitive map function
# For example, to list all directories that contain a certain file:
# find . -name .gitattributes | map dirname
alias map="xargs -n1"

# GIT
# -----------------------------------------------------------------------------

# alias hub -> git
(command -v hub &>/dev/null) && alias ghub="hub"
(command -v hub &>/dev/null) && alias gub="hub"
(command -v git-crypt &>/dev/null) && alias gc="git-crypt"

alias it=git
alias gt=g
alias dangled="git dangled" #gitk --all $( git fsck --no-reflog | awk '/dangling commit/ {print $3}' )
alias conflicted="git econs"
alias conflicts="git cons"
alias uncommit="git reset --soft 'HEAD^'"  # re-commit with `git commit -c ORIG_HEAD`
alias gex="git archive master | tar -x -C" # update this to support more than the master branch
alias resolve="git mergetool --tool=nvimdiff"
alias gs="git status --branch --short ."
alias gwt="git worktree"
alias gp="git push -u"
alias gfp="git push origin +HEAD"
alias gcv="git cv"
alias gcm='git commit -m "$(gum input)" -m "$(gum write)"'
alias gaa="git aa"
alias gcp="git branch --show-current | tr -d '[:space:]' | pbcopy"
alias gcy="git branch --show-current | tr -d '[:space:]' | pbcopy"
alias gup="git up"
# alias rebase="git pull --rebase origin master"
# alias grm="git status | grep deleted | awk '{\$1=\$2=\"\"; print \$0}' | \
  #            perl -pe 's/^[ \t]*//' | sed 's/ /\\\\ /g' | xargs git rm"

# GH
# -----------------------------------------------------------------------------
alias ghc='gh repo clone'
alias ghv='gh repo view -w'
prs() {
  get_pr="$(gh pr list | fzf | awk '{ print $1 }')"

  echo "$get_pr"

  [[ -z $get_pr ]] && gh pr view -w "$get_pr"
}
function pr() {
  gh pr view --web &> /dev/null

  if [ $? -ne 0 ]; then
    gh pr create --web
  fi
}
alias ghpr="pr"
function prr() {
  export GH_PEERS="alinmarsh
  DanThiffault
  jia614
  agundy"

  echo $GH_PEERS | fzf -m --tmux |  sed "N;s/\n/,/" | xargs gh pr edit --add-reviewer
}

alias ghb="gh browse"
alias ghi="gh issue create --label='' --assignee='@me' --body='' --title"

# elixir
# -----------------------------------------------------------------------------
alias imix="iex -S mix"

function mt() {
  if [ -z $1 ]; then
    mix test \
      && terminal-notifier -title "mix test" -subtitle "Test Suite" -message "Success!" \
      || terminal-notifier -title "mix test" -subtitle "Test Suite" -message "Failure!"
  else
    mix test "$1" \
      && terminal-notifier -title "mix test" -subtitle "$1" -message "Success!" \
      || terminal-notifier -title "mix test" -subtitle "$1" -message "Failure!"
  fi
}

function mix-test-watch() {
  fswatch -o . | mix test --stale --listen-on-stdin
}

alias mtw="mix-test-watch"
# wallaby
alias mtc="WALLABY_DRIVER=chrome mix test"
alias mts="WALLABY_DRIVER=selenium mix test"

# MISC / RANDOM
# -----------------------------------------------------------------------------
alias memhog="ps -eo pid,ppid,%mem,%cpu,cmd --sort=-%mem | head"

# http://unix.stackexchange.com/a/174596
(command -v gdircolors &>/dev/null) && alias dircolors="gdircolors"

# IP addresses
alias findlan="sudo nmap -sP -n 192.168.1.0/24"

# Fix LSD pegging the CPU
# https://discussions.apple.com/message/30186026#message30186026
alias fixlsd="/System/Library/Frameworks/CoreServices.framework/Frameworks/LaunchServices.fram ework/Support/lsregister -kill -r -domain local -domain system -domain user ; killall Dock"
alias resetlsd=fixlsd

# remove .DS_Store files from current directory, recursively
alias rmds="find . -name '*.DS_Store' -type f -delete"

# Enhanced WHOIS lookups
# alias whois="whois -h whois-servers.net"

alias dns="dig"
# Flush Directory Service cache; http://osxdaily.com/2014/11/20/flush-dns-cache-mac-os-x/
alias dnsflush="sudo dscacheutil -flushcache; sudo killall -HUP mDNSResponder"
alias flush="dscacheutil -flushcache"

# View HTTP traffic
alias sniff="sudo ngrep -d 'en1' -t '^(GET|POST) ' 'tcp and port 80'"
alias httpdump="sudo tcpdump -i en1 -n -s 0 -w - | grep -a -o -E \"Host\: .*|GET \/.*\""

# Show/hide hidden files in Finder
alias show="defaults write com.apple.Finder AppleShowAllFiles -bool true && killall Finder"
alias hide="defaults write com.apple.Finder AppleShowAllFiles -bool false && killall Finder"

alias secureinput='ioreg -l -w 0 | grep SecureInput'
alias geo='curl -s "http://www.geoiptool.com/en/?IP=${IP}" | textutil -stdin -format html -stdout -convert txt | sed -n "/Host Name/,/Postal code/p"'
# alias geoip="curl ipinfo.io/"
alias sleepdisplay='pmset displaysleepnow'

# Lock the screen (when going AFK)
alias afk="/System/Library/CoreServices/Menu\ Extras/User.menu/Contents/Resources/CGSession -suspend"

# SED reminder:
alias sedhelp="echo \"sed -i -e 's/old-thing/new-thing/g' relative/path/to/*.js\""

# weather
alias weather='curl -s wttr.in | sed -n "1,7p"'
alias wthr='curl -s wttr.in/hoover,al | sed -n "1,7p"'
alias moon='curl -4 http://wttr.in/Moon'

alias nerd="echo -ne \\u"
alias nf="echo -ne \\u"

# -- linux-specific aliases..
if [[ $(uname) == "Linux" ]]; then
  alias pbcopy="xclip -sel clip"
  alias pbpaste='xclip -sel clip -o'
  # TODO: why do we have this luamake entry
  alias luamake=$HOME/.config/lsp/sumneko_lua/3rd/luamake/luamake

  if (command -v lemonade &>/dev/null); then
    # ln -s /path/to/lemonade /usr/bin/xdg-open
    # xdg-open, pbcopy and pbpaste.
    alias xdg-open="lemonade open"
    alias pbcopy="lemonade copy"
    alias pbpaste="lemonade paste"
    alias open="lemonade open"
    alias xclip="lemonade copy"
    alias xsel="lemonade copy"
  fi
  alias distro="cat /etc/*release"
  alias ports="netstat -lntu"
  alias port="sudo netstat -lp | rg"

  # REF: https://www.digitalocean.com/community/tutorials/how-to-list-and-delete-iptables-firewall-rules
  alias rules="sudo iptables -L -nv"

  alias dsk='eval $(desk load)'
  alias kitty="$HOME/.dotfiles/bin/kitty_remote"
fi

# macos / signing apps
# -- REF: https://github.com/Jelmerro/Vieb/blob/master/FAQ.md#mac
alias sign="sudo codesign --force --deep --sign -"
# https://github.com/Jelmerro/Vieb/releases/download/7.2.0/Vieb-7.2.0-mac.zip

# handy things that iuse for work
alias tmlaunch="~/.dotfiles/bin/tmux-launch"
alias tmexpo="sh tmux-launch expo 'cd ~/code/outstand/mobile; expo start'"

alias compress="c() { zip -f "$1".zip "$1"} && c $1"

alias yt='yt-dlp --sponsorblock-remove default --part --format "bv*[ext=mp4]+ba[ext=m4a]/b[ext=mp4]"'
alias ytaudio='yt --extract-audio --audio-format mp3 --audio-quality 0 --write-thumbnail'

alias b="m1ddc set luminance"

alias gpt="chatgpt-cli -k $OPENAI_API_KEY chat"

alias fkill="ps -e | fzf | awk '{print $1}' | xargs kill"
alias ms="m s"

# FUNCTIONS
# ------------------------------------------------------------------------------

function get_workdir () { basename "$PWD" | sed -e s'/[.-]/_/g' }

function mixx() {
  mix $(mix help --names | fzf --delimiter=' ' --preview 'mix help {}' --reverse)
}

function zknew() {
  local note_title="${*:-}"

  if [[ -z "$note_title" ]]; then
    vared -p "$(tput bold)$(tput setaf 5) new note title:$(tput sgr 0) " -c note_title
  fi

  if [[ -z "$note_title" ]]; then
    zk new
  else
    zk new --title "$note_title"
  fi
}

fuzzy-xdg-open() {
  local output
  output=$(fzf --height 40% --reverse </dev/tty) && xdg-open ${(q-)output}
  zle reset-prompt
}

zle -N fuzzy-xdg-open
bindkey '^o' fuzzy-xdg-open

# Shorten Github URL with vanity (url, vanity code) - saves to clipboard!
ghurl() {
  curl -i -s https://git.io -F "url=$1" -F "code=$2" | rg "Location" | cut -f 2 -d " " | pbcopy
}

function __close_all_apps() {
  if [[ "$(uname)" != "Darwin" ]]; then
    exit 0
  fi

  apps=$(osascript -e 'tell application "System Events" to get name of (processes where background only is false)' | awk -F ', ' '{for(i=1;i<=NF;i++) printf "%s;", $i}')
  while [ "$apps" ] ;do
    app=${apps%%;*}
    if [[ $app != 'alacritty' && $app != 'kitty' ]]
    then
      pkill -x echo $app
    fi

    [ "$apps" = "$app" ] && \
      apps='' || \
      apps="${apps#*;}"
  done
}

function reboot() {
  __close_all_apps

  sudo reboot
}

function shutdown() {
  __close_all_apps

  sudo shutdown -h now
}

function def() {
  cmd="${@[$#]}" # last argument
  res=$(whence -v "$cmd"); raw=$(whence "$cmd" | cut -d ' ' -f 1); lesscmd='less'
  [ x"$cmd" = x"$raw" ] && res=${res//an alias/a recursive}
  [ $(alias less &>/dev/null; echo $?) -eq 0 ] && lesscmd="$lesscmd -l zsh -pn"
  echo "$res"; draw_help () { c=$(basename $1); tldr $c 2>/dev/null || eval "$1 --help | $MANPAGER" || man $c }
  case $res in
    *'not found'*)  checkyes "Google it?" && eval "?g linux cli $cmd" ;;
    *function*)     (printf '#!/usr/bin/env zsh\n\n'; whence -f "$raw") | eval "$lesscmd" ;;
    *alias*)        def "$raw" ;;
    *)              echo; draw_help "$raw"; whence "$raw" ;; # binary, builtin
  esac
}

function dotenv() {
  [ -f .env ] && source .env
  [ -f .env.sh ] && source .env.sh
  return 0
}

function ex() {
  for filename in "$@"; do
    if [ -f "$filename" ]; then
      case "$filename" in
        *.tar.bz2)  tar xjf "$filename"  ;;
        *.tar.gz)   tar xzf "$filename"  ;;
        *.bz2)      bunzip2 "$filename"  ;;
        *.rar)      unrar x "$filename"  ;;
        *.gz)       gunzip "$filename"   ;;
        *.tar)      tar xf "$filename"   ;;
        *.tbz2)     tar xjf "$filename"  ;;
        *.tgz)      tar xzf "$filename"  ;;
        *.zip)      unzip "$filename"    ;;
        *.Z)        uncompress "$filename" ;;
        *.7z)       7z x "$filename"     ;;
        *)          echo "'$filename' cannot be extracted via ex()" ;;
      esac
    else
      echo "'$filename' is not found"
    fi
  done
}

function pfwd() {
  # ssh -fNT -L 127.0.0.1:$2:127.0.0.1:$2 $1 && echo "Port forward to: http://127.0.0.1:$2"
  svr="$1"; port="$2"; shift 2
  eval "ssh -fNT $@ 127.0.0.1:${port}:127.0.0.1:${port} ${svr}" && echo "Port forward to: http://127.0.0.1:${port}"
}

function bak() {
  for filename in $@; do
    bak_file="$filename.bak"
    if [ -f "$filename" ]; then
      mv -i "$filename" "$bak_file"
      [ -f "$filename" ] && warning "Skipping $filename"
    fi
  done
}

function unbak() {
  for filename in $@; do
    if ! [[ x"$filename" =~ .*bak ]]; then
      error "$filename does not end with '.bak'. Skipping."
      continue
    fi
    bak_file="${filename:r}"
    if [ -f "$filename" ]; then
      mv -i "$filename" "${bak_file}"
      [ -f "$filename" ] && warning "Skipping $filename"
    fi
  done
}

function pdf2img() {
  convert -density 192 "$1" -quality 100 -alpha remove "$2"
}

alias listening='lsof -Pn -i'

function listening-ports() {
  if [ -z "$1" ]; then
    echo "Usage: $0 tcp|udp|..."
    echo "See /etc/protocols for full list"
    return 1
  fi
  netstat -tulanp "$1"
}

# find and replace in a directory (current by default)
# ignores hidden files
# `replace <before> <after> [directory]`
replace() {
    rg -l --no-hidden "$1" "${3-.}" | xargs sd "$1" "$2"
}

# REFS:
# https://github.com/zackproser/zsh-shell-functions/tree/main/autogit
# https://github.com/zackproser/automations/blob/master/docs/usage.md
# function cd() {
#   builtin cd "$@" && gum spin --title "Autogit updating git repo if necessary..." --show-output ~/.dotfiles/bin/autogit.sh
# }


# cdr: run fzf with dir history
# if [[ -n $(echo ${^fpath}/chpwd_recent_dirs(N)) && -n $(echo ${^fpath}/cdr(N)) ]]; then
#   autoload -Uz chpwd_recent_dirs cdr add-zsh-hook
#   add-zsh-hook chpwd chpwd_recent_dirs
#   zstyle ':completion:*' recent-dirs-insert both
#   zstyle ':chpwd:*' recent-dirs-default true
#   zstyle ':chpwd:*' recent-dirs-max 1000
#   zstyle ':chpwd:*' recent-dirs-file "$HOME/.cache/chpwd-recent-dirs"
# fi
# function fzf-cdr() {
#   local selected_dir="$(cdr -l | sed 's/^[0-9]\+ \+//' | fzf --query="$LBUFFER" --prompt='cd > ' +s --preview 'eval exa -aFhl {}')"
#   if [ -n "$selected_dir" ]; then
#     BUFFER="cd ${selected_dir}"
#     zle accept-line
#   else
#     BUFFER=''
#     zle accept-line
#   fi
# }
# zle -N fzf-cdr
# bindkey '^E' fzf-cdr

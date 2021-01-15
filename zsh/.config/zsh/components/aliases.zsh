#!/usr/bin/env zsh
# shellcheck shell=bash

# delete symlinks (remove evertyhing after '*' to just search for symlinks): find /home -maxdepth 1 -lname '*' -exec rm {} \;
# create the target folder and move the source to the new destination: mkdir -p ~/.dotfiles/git/bak && mv git* "$_"

# Auto-correction exceptions
# -----------------------------------------------------------------------------
alias bundle='nocorrect bundle'
alias cabal='nocorrect cabal'
alias man='nocorrect man'
alias mkdir='nocorrect mkdir'
alias mv='nocorrect mv'
alias cp='nocorrect cp'
alias stack='nocorrect stack'
alias sudo='nocorrect sudo'
alias git="nocorrect git"
alias nmap="nocorrect nmap"
# alias avn='nocorrect avn'

# Files & directories
# -----------------------------------------------------------------------------
alias ..="cd .."
alias ...="cd ../.."
alias ....="cd ../../.."
alias dirs="ls *(/)"
alias ff="ffind -S"
alias ff="fd"
alias files="find . -type f | wc -l"
alias new="print -rl -- **/*(Dom[1,5])"

# grc overides for ls
#   Made possible through contributions from generous benefactors like
#   `brew install coreutils`
if $(gls &>/dev/null)
then
  alias gls="tmux select-pane -P bg=default,fg=default &> /dev/null; gls --color=auto --group-directories-first"
  alias ls="gls -FA"
  alias lst="gls -FAt"
  alias l="gls -lAh"
  alias lt="gls -lAht"
  alias ll="gls -l"
  alias la="gls -A"
fi
alias ls="exa -gahF --group-directories-first"
alias l="exa -lahF --icons --group-directories-first --git"
alias s="ls"
alias last='ls *(.om[1])'
alias bat='BAT_CONFIG_PATH="~/.batrc" BAT_THEME="base16" bat'
alias cat='bat'
alias du="ncdu --color dark -rr -x --exclude .git --exclude node_modules"
alias help='tldr'
alias dotup='_dotup'


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
alias tree="tree -L"

alias icat="kitty +kitten icat"

alias back="slack back; dnd off"
alias gone="slack gone; dnd on"
alias away="slack away; dnd off"
alias lunch="slack lunch; dnd off"

# ZMV
# -----------------------------------------------------------------------------
autoload -U zmv
# alias for zmv for no quotes
# mmv *.c.orig orig/*.c
alias mmv='noglob zmv -W'

# TMUX
# -----------------------------------------------------------------------------
# alias tm="(tmux ls | grep -vq attached && tmux at) || tmux"
alias tm=tmux -2 #"tmux attach || tmux new"
# alias mux="tmux -2 attach-session || tmux -2"
alias mux="tmux"
alias takeover="tmux detach -a"
alias teama="tmux attach-session -t enbala"
alias team="teamocil --here enbala"
alias fmate="unset TMUX tmate"
alias trw="tmux rename-window"
alias trs="tmux rename-session"

## - ag/ack/grep/fzf/rg/ripgrep --------------------------------------
# https://github.com/junegunn/fzf/wiki/Examples#searching-file-contents
# alias ag="ag --nobreak --nonumbers --noheading . | fzf"
alias g="rg"

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

# ALACRITTY
# -----------------------------------------------------------------------------
alias updatealacritty='cd ~/code/rust/alacritty; git co master; git fetch; git merge origin/master; rustup override set nightly; cargo build --release; sudo cp target/release/alacritty /usr/local/bin; cd -'
alias ala='alacritty;'

# KITTY
# -----------------------------------------------------------------------------
alias kitty='/Applications/kitty.app/Contents/MacOS/kitty'

# EMACS/SPACEMACS
# -----------------------------------------------------------------------------
alias em='emacsclient -create-frame --alternate-editor=""'
alias ec=em

# (NEO)VIM
# -----------------------------------------------------------------------------
alias nvimupdate="brew update; brew reinstall neovim; brew postinstall neovim; pip install --upgrade pynvim; pip3 install --upgrade pynvim; pip2 install --upgrade pynvim; npm install -g neovim --force; yarn global add neovim; gem install neovim; nvim +PaqUpdate +qall; brew outdated"
alias im="nvim"
alias nv="nvim"
alias vm="nvim"
alias nvm="nvim"
alias vim="nvim"
alias v=vim
alias vi="/usr/local/bin/vim"
alias minvim="nvim -u NONE"
alias darkMode="2>/dev/null defaults read -g AppleInterfaceStyle"

# alias nvt="nv +tabe +term +NvimuxVerticalSplit +term +tabnext"
# alias nvts="nv +tabe +term +NvimuxVerticalSplit +term +NvimuxHorizontalSplit +term +tabnext"
# # While in a nvim terminal, open file to current session
# if [ -n "${NVIM_LISTEN_ADDRESS+x}" ]; then
#   alias nvh='nvr -o'
#   alias nvv='nvr -O'
#   alias nvt='nvr --remote-tab'
# fi

# CONFIG EDITS
# -----------------------------------------------------------------------------
alias ez="nvim ~/.config/zsh/.zshrc"
alias ezz="nvim ~/.config/zsh/.zshenv"
alias ezl="nvim ~/.localrc"
alias eza="nvim ~/.config/zsh/**/aliases.zsh"
alias ezf="nvim ~/.config/zsh/**/functions.zsh"
alias ezo="nvim ~/.config/zsh/**/opts.zsh"
alias ehs="nvim ~/.config/hammerspoon/config.lua"
alias eh="nvim ~/.config/hammerspoon/init.lua"
alias eg="nvim ~/.gitconfig"
alias eb="nvim ~/.dotfiles/Brewfile"
alias essh="nvim ~/.ssh/config"
alias eze="nvim ~/.config/zsh/**/env.zsh"
alias ezkb="nvim ~/.config/zsh/**/keybindings.zsh"
alias ev="nvim ~/.config/nvim/init.lua"
alias evp="nvim ~/.config/nvim/lua/mega/packages.lua"
alias ek="nvim ~/.config/kitty/kitty.conf"
alias et="nvim ~/.tmux.conf"

# FOLDERS
# -----------------------------------------------------------------------------
alias dot="cd $DOTS"
alias priv="cd $PRIVATES"
alias ot=dot
alias code="cd ~/code"
# alias dev="cd ~/code"
alias repos="cd ~/code"
alias logs="cd ~/code/logs/"
alias docs="cd ~/Documents"
alias box="cd $HOME/Dropbox/"
alias icloud="cd $HOME/Library/Mobile\ Documents/com\~apple\~CloudDocs"
alias dropbox="box"
alias scripts="cd ~/Dropbox/scripts/"
# alias android="cd ~/Dropbox/Android/adb/"
# alias adb="/Users/replicant/Dropbox/Android/adb/platform-tools/adb"
# alias fastboot="/Users/replicant/Dropbox/Android/adb/platform-tools/fastboot"
alias dl="cd $HOME/Downloads/"
alias gop="cd $GOPATH"
alias geny="/Applications/Genymotion\ Shell.app/Contents/MacOS/genyshell -c "
alias genyplay="/Applications/Genymotion.app/Contents/MacOS/player.app/Contents/MacOS/player --vm-name "

# POSTGRES
# -----------------------------------------------------------------------------
alias startpg="pg_ctl -D /usr/local/var/postgres -l logfile start" #`pg_ctl -D /usr/local/var/postgres -l ~/code/logs/server.log start` OR `postgres -D /usr/local/var/postgres` OR `pg_ctl -D /usr/local/var/postgres -l logfile start`
alias stoppg="pg_ctl -D /usr/local/var/postgres -l logfile stop" #`postgres -D /usr/local/var/postgres`
alias pgstart="launchctl load ~/Library/LaunchAgents/homebrew.mxcl.postgresql.plist"
alias pgstop="launchctl unload ~/Library/LaunchAgents/homebrew.mxcl.postgresql.plist"
  # To have launchd start postgresql at login:
  #     ln -sfv /usr/local/opt/postgresql/*.plist ~/Library/LaunchAgents
  # Then to load postgresql now:
  #     launchctl load ~/Library/LaunchAgents/homebrew.mxcl.postgresql.plist
  # Or, if you don't want/need launchctl, you can just run:
  #     pg_ctl -D /usr/local/var/postgres -l /usr/local/var/postgres/server.log start
alias pgsetup="sh ~/Dropbox/scripts/postgresql_db_setup.sh"
alias fixpg="kill $(head -1 /usr/local/var/postgres/postmaster.pid)"

# MISC
# -----------------------------------------------------------------------------
alias rm="rm -v"
[[ "$(uname)" == "Darwin" ]] && alias rm="/usr/local/bin/trash"
alias dash="open dash://" # lang:query
alias trunc=": > "
alias server="python -m SimpleHTTPServer"
# alias srv=server
alias chromedebug="/Applications/Google\ Chrome.app/Contents/MacOS/Google\ Chrome --remote-debugging-port=9222 --js-flags=--stack_trace_limit=-1 --user-data-dir=/tmp/jsleakcheck"
alias chrome="open -a '/Applications/Google Chrome.app' --args --disable-web-security"
# Kill all the tabs in Chrome to free up memory
# [C] explained: http://www.commandlinefu.com/commands/view/402/exclude-grep-from-your-grepped-output-of-ps-alias-included-in-description
# Thanks @sindersorhus: https://github.com/mathiasbynens/dotfiles/commit/bd9429af1cfdc7f4caa73e6f98773ed69a161c9c
alias chromekill="ps ux | grep '[C]hrome Helper --type=renderer' | grep -v extension-process | tr -s ' ' | cut -d ' ' -f2 | xargs kill"
alias die='pkill -9 -f'
alias port='lsof -i :'
alias ex=extract
alias cleanrails="rm -rf .DS_Store .gitignore .rspec .rvmrc Gemfile GuardFile README.md"
alias sz="source $HOME/.config/zsh/.zshenv && source $HOME/.config/zsh/.zshrc && \reset"
alias zz=z
alias cls="clr && ls"
alias get="curl -OL"
alias get="http --download"
# alias g="grep -r -i --color='auto'"
alias g="rg -F"
alias nvm='n'
# alias irc="LANG=en_US.UTF-8 LC_ALL=en_US.UTF-8 weechat-curses"
# alias irc="PERL_MM_OPT="INSTALL_BASE=$HOME/perl5" cpan local::lib; eval \"$(perl -I$HOME/perl5/lib/perl5 -Mlocal::lib=$HOME/perl5)\"; weechat-curses"
# alias weechat="weechat-curses"
alias irc="weechat"
# alias irc="rm ~/.weechat/weechat_crash*.log; sh ~/.dotfiles/zsh/base16-ocean.dark.sh; weechat-curses"
# alias irc="rm ~/.weechat/weechat_crash*.log; weechat-curses"
alias rc=irc
alias clr=clear
alias syncoctoprint="scp pi@octopi.local:/home/pi/.octoprint/config.yaml $HOME/Dropbox/3d/configs/octoprint"
alias dif="kitty +kitten diff"
alias zshtime="/usr/bin/time $(which zsh) -i -c echo"
# alias zshtime="for i in $(seq 1 10); do /usr/bin/time zsh -i -c exit; done"
alias timezsh="time $(which zsh) -i -c exit"
alias zshprofile="time ZPROFILE=1 $(which zsh) -i -c exit"
alias zshclear="rm -f ~/.zcompdump ~/.zsh-dotfiles-compiled.zsh"
alias vimtime="ruby $HOME/.dotfiles/bin/vim-plugins-profile.rb nvim"

# Intuitive map function
# For example, to list all directories that contain a certain file:
# find . -name .gitattributes | map dirname
alias map="xargs -n1"

# GIT
# -----------------------------------------------------------------------------
alias tig="nvim +:GV" # https://github.com/junegunn/gv.vim#mappings
alias lg="lazygit"
alias gin="gitin"
# alias gc='git co `git b | fzf | sed -e "s/\* //g" | awk "{print \$1}"`'
alias gb='git b | fzf | xargs git branch -d'
alias gcb="git rev-parse --abbrev-ref HEAD | tr -d '\n'"
alias gcp="gcb | pbcopy"
alias push="git push"
alias gs="git s"
alias gst="git status"
alias gcv="git cv"
alias gcm="git cm"
alias gpreq="~/.dotfiles/bin/git-pr"
alias preq=gpreq
alias req=gpreq
alias changes="git diff --cached"
alias clean="git clean -f"
alias reset="git reset --hard HEAD"
alias log="git log --stat"
alias show='git show --pretty="format:" --name-only '
alias branch='git for-each-ref --sort=-committerdate refs/heads/ | less'
alias glog="git l"
alias dangled="git fsck --no-reflog | awk '/dangling commit/ {print $3}'" #gitk --all $( git fsck --no-reflog | awk '/dangling commit/ {print $3}' )
alias conflicted="git diff --name-only --diff-filter=U | uniq  | xargs $EDITOR"
alias conflicts="git ls-files -u | cut -f 2 | sort -u"
alias uncommit="git reset --soft 'HEAD^'" # re-commit with `git commit -c ORIG_HEAD`
alias gex="git archive master | tar -x -C" # update this to support more than the master branch
alias resolve="git mergetool --tool=nvimdiff"
# alias rebase="git pull --rebase origin master"
# alias grm="git status | grep deleted | awk '{\$1=\$2=\"\"; print \$0}' | \
#            perl -pe 's/^[ \t]*//' | sed 's/ /\\\\ /g' | xargs git rm"

# elixir
# -----------------------------------------------------------------------------
alias imix="iex -S mix"

# RUBY/RAILS
# -----------------------------------------------------------------------------
alias be="bundle exec"
alias br="bundle exec ruby"
alias b="bundle"
alias bu="bundle"
alias gen="bundle exec rails g"
alias annotate="bundle exec annotate"
alias dbm="rake db:migrate"
alias dbt="rake db:test:prepare"
alias dbrb="rake db:rollback STEP=1"
alias spork="bundle exec spork"
alias guard="bundle exec guard start"
alias nodeapp="nodemon app.js 3000"
alias rs="bundle exec rails server"
alias rsp="bundle exec rails server -p"
alias rc="bundle exec rails console"
alias bec=rc
alias migrate="rake db:migrate db:test:prepare"
alias rollback="rake db:rollback"
alias uuid="ruby -r securerandom -e 'puts SecureRandom.uuid'"

# MISC / RANDOM
# -----------------------------------------------------------------------------

# http://unix.stackexchange.com/a/174596
alias dircolors="gdircolors"

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

# Flush Directory Service cache; http://osxdaily.com/2014/11/20/flush-dns-cache-mac-os-x/
alias dnsflush="sudo dscacheutil -flushcache; sudo killall -HUP mDNSResponder"
alias flush="dscacheutil -flushcache"

# View HTTP traffic
alias sniff="sudo ngrep -d 'en1' -t '^(GET|POST) ' 'tcp and port 80'"
alias httpdump="sudo tcpdump -i en1 -n -s 0 -w - | grep -a -o -E \"Host\: .*|GET \/.*\""

# Show/hide hidden files in Finder
alias show="defaults write com.apple.Finder AppleShowAllFiles -bool true && killall Finder"
alias hide="defaults write com.apple.Finder AppleShowAllFiles -bool false && killall Finder"

# Show/hide the desktop
alias hidedesk="defaults write com.apple.finder CreateDesktop false; killall Finder; open /Applications/TotalFinder"
alias showdesk="defaults write com.apple.finder CreateDesktop true; killall Finder; open /Applications/TotalFinder"

# enable yubikey and ssh
alias remote="osascript -e 'tell application \"yubiswitch\" to KeyOn' && ssh remote.github.com -t gh-screen && osascript -e 'tell application \"yubiswitch\" to KeyOff' "

# edit home-assistant (hass) config
alias hassconfig="pushd ~/.dotfiles/private/homeassistant; vim configuration.yaml; popd"
alias haconfig=hassconfig
# alias rsync="/usr/local/bin/rsync"
alias hasssync="/usr/local/bin/rsync -a root@homeassistant.local:/config ~/.dotfiles/private/homeassistant"
alias hasync=hasssync
alias synchass=hasssync
alias syncha=hasssync

alias elmserve='elm-reactor -p 8080'
alias rn='react-native'

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

# covid-19
alias covidst='curl "https://corona-stats.online/states/us?minimal=true"'
alias covid='curl "https://corona-stats.online/usa?minimal=true"'

alias nerd="echo -ne \\u"
alias nf="echo -ne \\u"

alias tidy="/usr/local/bin/tidy"

# -- linux-specific aliases..
if [[ "$PLATFORM" == "linux" ]]; then
  alias nvim="VIMRUNTIME=$HOME/builds/neovim/runtime $HOME/builds/neovim/build/bin/nvim"
  # alias fd="fdfind"
fi

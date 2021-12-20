#!/usr/bin/env zsh
# shellcheck shell=bash

# delete symlinks (remove evertyhing after '*' to just search for symlinks): find /home -maxdepth 1 -lname '*' -exec rm {} \;
# create the target folder and move the source to the new destination: mkdir -p ~/.dotfiles/git/bak && mv git* "$_"

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

# grc overides for ls
#   Made possible through contributions from generous benefactors like
#   `brew install coreutils`
if $(gls &>/dev/null); then
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
# alias bat='BAT_CONFIG_PATH="~/.batrc" BAT_THEME="base16" bat'
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
# alias tree="tree -L"

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
alias out="tmuxinator start outstand -n outstand"
alias trw="tmux rename-window"
alias trs="tmux rename-session"

alias ssh="kitty +kitten ssh"

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

# (NEO)VIM
# -----------------------------------------------------------------------------

if type nvim >/dev/null 2>&1; then
	alias slownvim="nvim --startuptime /dev/stdout slow_to_open_file.ex +q | less"
	alias nvimupdate="brew update && brew uninstall neovim && brew install neovim --HEAD && brew postinstall neovim && pip3 install --upgrade pynvim && npm install -g neovim --force && gem install neovim && brew outdated"
	alias nvimbuild="cd ~/code/neovim && make CMAKE_BUILD_TYPE=RelWithDebInfo && sudo make install"
	alias buildnvim=nvimbuild
	alias nvim="nvim -O" # let's always open multiple files passed in as vsplits
	alias im="nvim"
	alias nv="/usr/local/Cellar/neovim/0.6.0/bin/nvim"
	alias vm="nvim"
	alias nvm=nv
	alias vim="nvim"
	alias v=vim
	alias vi="/usr/local/bin/vim"
	alias minvim="nvim -u NONE"
	alias barevim="nvim -u NONE"
	alias packs="cd \"${XDG_DATA_HOME:-$HOME/.local/share}\"/nvim/site/pack/"
	alias rmpaqs="packs; rm -rf paqs; cd -"
	# alias darkMode="2>/dev/null defaults read -g AppleInterfaceStyle"

	# alias nvt="nv +tabe +term +NvimuxVerticalSplit +term +tabnext"
	# alias nvts="nv +tabe +term +NvimuxVerticalSplit +term +NvimuxHorizontalSplit +term +tabnext"
	# # While in a nvim terminal, open file to current session
	# if [ -n "${NVIM_LISTEN_ADDRESS+x}" ]; then
	#   alias nvh='nvr -o'
	#   alias nvv='nvr -O'
	#   alias nvt='nvr --remote-tab'
	# fi
fi

# CONFIG EDITS
# -----------------------------------------------------------------------------
alias ez="nvim $DOTS/zsh/.config/zsh/.zshrc"
alias ezz="nvim $DOTS/zsh/.config/zsh/.zshenv"
alias eza="nvim $DOTS/zsh/.config/zsh/**/aliases.zsh"
alias ezf="nvim $DOTS/zsh/.config/zsh/**/functions.zsh"
alias ezo="nvim $DOTS/zsh/.config/zsh/**/opts.zsh"
alias eze="nvim $DOTS/zsh/.config/zsh/**/env.zsh"
alias ezkb="nvim $DOTS/zsh/.config/zsh/**/keybindings.zsh"
alias ezl="nvim $HOME/.localrc"

alias ev="nvim $DOTS/nvim/.config/nvim/init.lua"
alias evv="nvim $DOTS/nvim/.config/nvim/.vimrc"
alias evp="nvim $DOTS/nvim/.config/nvim/lua/plugins.lua"
alias evs="nvim $DOTS/nvim/.config/nvim/lua/settings.lua"
alias evo="nvim $DOTS/nvim/.config/nvim/lua/options.lua"
alias evl="nvim $DOTS/nvim/.config/nvim/lua/lsp/init.lua"
alias evm="nvim $DOTS/nvim/.config/nvim/lua/mappings.lua"
alias evg="nvim $DOTS/nvim/.config/nvim/lua/globals.lua"

alias ehs="nvim $DOTS/hammerspoon/.config/hammerspoon/config.lua"
alias eh="nvim $DOTS/hammerspoon/.config/hammerspoon/init.lua"
alias eg="nvim $DOTS/git/.gitconfig"
alias eb="nvim $DOTS/Brewfile"
alias essh="nvim $HOME/.ssh/config"

alias ek="nvim $DOTS/kitty/.config/kitty/kitty.conf"
alias et="nvim $DOTS/tmux/.tmux.conf"

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
alias box="cd $HOME/Downloads/"
alias icloud="cd $HOME/Library/Mobile\ Documents/com\~apple\~CloudDocs"
alias nvim-plugins="cd ~/.local/share/nvim/site/pack/packer/start"
# alias icloud="cd $HOME/Library/Mobile\ Documents/com~apple~CloudDocs"

# POSTGRES
# -----------------------------------------------------------------------------
alias fixpg="kill $(head -1 /usr/local/var/postgres/postmaster.pid)"

# MISC
# -----------------------------------------------------------------------------
alias rm="rm -v"
[[ "$(uname)" == "Darwin" ]] && alias rm="/usr/local/bin/trash"
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
alias port='lsof -i :'
alias sz="source $HOME/.config/zsh/.zshrc && source $HOME/.config/zsh/.zshenv && source $HOME/.config/zsh/.zprofile && \reset"
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

# alias hub -> git
(command -v hub &>/dev/null) && alias git="hub"

alias dangled="git fsck --no-reflog | awk '/dangling commit/ {print $3}'" #gitk --all $( git fsck --no-reflog | awk '/dangling commit/ {print $3}' )
alias conflicted="git diff --name-only --diff-filter=U | uniq  | xargs $EDITOR"
alias conflicts="git ls-files -u | cut -f 2 | sort -u"
alias uncommit="git reset --soft 'HEAD^'"  # re-commit with `git commit -c ORIG_HEAD`
alias gex="git archive master | tar -x -C" # update this to support more than the master branch
alias resolve="git mergetool --tool=nvimdiff"
alias gs="git status --branch --short ."
alias gwt="git worktree"
# alias rebase="git pull --rebase origin master"
# alias grm="git status | grep deleted | awk '{\$1=\$2=\"\"; print \$0}' | \
#            perl -pe 's/^[ \t]*//' | sed 's/ /\\\\ /g' | xargs git rm"

# elixir
# -----------------------------------------------------------------------------
alias imix="iex -S mix"

# MISC / RANDOM
# -----------------------------------------------------------------------------

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
if [[ $PLATFORM == "linux" ]]; then
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
	fi
	alias distro="cat /etc/*release"
	alias ports="netstat -lntu"
	alias port="sudo netstat -lp | rg"

	# REF: https://www.digitalocean.com/community/tutorials/how-to-list-and-delete-iptables-firewall-rules
	alias rules="sudo iptables -L -nv"
fi

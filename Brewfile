#!/usr/bin/env zsh

cask_args appdir: "/Applications"

# -- taps --

tap "homebrew/bundle"
tap "homebrew/services"
tap "homebrew/cask-versions"
tap "homebrew/cask"
tap "homebrew/cask-fonts"
tap "neovim/neovim"
tap "caius/jo"
tap "simeji/jid"
tap "browsh-org/homebrew-browsh"
tap "qmk/qmk"
tap "heroku/brew"
# NOTE/REF: https://github.blog/2020-07-02-git-credential-manager-core-building-a-universal-authentication-experience/#macos
tap "microsoft/git"
tap "isacikgoz/taps"

# -- for qmk_toolbox --

# brew tap osx-cross/avr; brew tap PX4/homebrew-px4; brew install avr-gcc@8; brew link --force avr-gcc@8; brew install dfu-programmer dfu-util gcc-arm-none-eabi avrdude qmk; brew cask install qmk-toolbox;
tap "osx-cross/avr"
tap "PX4/homebrew-px4"
tap "homebrew/cask-drivers"
# NOTE: at present, 20200327, qmk doesn't support >=avr-gcc@9
brew "avr-gcc@8", link: true
brew "dfu-programmer"
brew "dfu-util"
brew "gcc-arm-none-eabi"
brew "avrdude"
cask "qmk-toolbox"
brew "qmk"


# -- cli --

brew "ansible"
brew "autoconf"
brew "automake"
brew "aspell"
brew "awscli"
brew "bat"
brew "browsh"
brew "ccls" # c-lang lsp vs., c-lang lsp in llvm
brew "cmake"
brew "coreutils"
brew "curl"
brew "dbus"
brew "diff-so-fancy"
brew "dnsmasq"
brew "docker"
brew "docker-compose"
brew "docker-credential-helper-ecr"
brew "docker-machine" #, restart_service: true, link: false
brew "exa"
brew "exercism"
brew "fasd"
brew "fd"
brew "ffind"
brew "findutils"
brew "fish"
brew "fontforge"
brew "fzf" # -> $(brew --prefix)/opt/fzf/install
brew "fzy"
brew "gawk"
brew "gist"
brew "git"
brew "gitin"
brew "romkatv/gitstatus/gitstatus"
brew "gh"
brew "gnutls"
brew "gnupg"
brew "gnu-sed"
brew "gpg" # required for asdf-nodejs
brew "grc"
brew "grv"
brew "heroku"
brew "hub"
brew "highlight"
brew "htop"
brew "jq"
brew 'lazydocker'
brew 'lazygit'
brew "llvm" # contains c-lang lsp (the preferred one?)
brew "lnav"
brew "lsd"
brew "luajit"
brew "luarocks"
brew "mas"
brew "moreutils"
brew "ncurses"
brew "neovim", args: ["HEAD"]
brew "ninja" # for lua sumneko lsp
brew "nmap"
brew "noti"
brew "openssl"
brew "openssl@1.1"
brew "p7zip"
brew "perl"
brew "pgcli"
brew "pkg-config"
brew "pinentry-mac"
brew "postgresql"
# initdb /usr/local/var/postgres -E utf8
brew "python@3.7", link: false
brew "python@3.8", link: false
brew "python@3.9", link: true
brew "readline"
brew "reattach-to-user-namespace"
brew "ren"
brew "redis"
brew "ripgrep"
# brew "ruby-install"
# brew "ruby-build"
brew "rust"
brew "rustup-init"
brew "shellcheck"
brew "ssh-copy-id"
brew "stack"
brew "stow"
brew "switchaudio-osx"
brew "terminal-notifier"
brew "tidy-html5"
brew "tldr"
brew "tmux"
brew "trash"
brew "tree"
brew "tree-sitter"
brew "urlview"
brew "weechat"
brew "wget"
brew "wifi-password"
brew "wxmac" # for erlang
brew "yubico-piv-tool"
brew "libyubikey"
brew "pam_yubico"
brew "yubikey-personalization"
brew "zsh"
brew "zsh-autosuggestions"
brew "zsh-completions"
brew "zsh-lovers"
brew "zsh-syntax-highlighting"
brew "zsh-history-substring-search"

# - fonts
cask "font-jetbrains-mono"
cask "font-jetbrains-mono-nerd-font"
cask "font-ia-writer-quattro"

# - gui
cask "1password"
cask "1password-cli"
cask "alfred"
cask "balenaetcher"
cask "bettertouchtool"
cask "bartender"
cask "box-drive"
cask "brave-browser"
cask "colorsnapper"
cask "dash"
# cask "caldigit-thunderbolt-charging"
# cask "caldigit-docking-utility"
cask "contexts"
cask "controlplane"
cask "docker-edge"
cask "dropbox"
cask "discord"
cask "expressvpn"
cask "git-credential-manager-core"
cask "hazel"
cask "hammerspoon"
cask "intel-power-gadget"
cask "insomnia"
cask "istat-menus"
cask "itsycal"
cask "kap"
cask "karabiner-elements"
cask "kitty"
cask "micro-snitch"
cask "little-snitch4"
cask "loom"
cask "ngrok"
cask "oracle-jdk"
cask "signal"
cask "slack"
cask "spotify"
cask "thingsmacsandboxhelper"
cask "vagrant"
cask "the-unarchiver"
# cask "usb-overdrive" # causes issues with QMK keyboards
cask "virtualbox"
cask "witch"
cask "yubico-authenticator"
cask "yubico-yubikey-manager"
cask "yubico-yubikey-piv-manager"
cask "zoom"


# -- app store (mas) --

mas "Fantastical", id: 975937182
mas "Spark", id: 1176895641
# mas "Tweetbot", id: 557168941
mas "Drafts", id: 1435957248
mas "Things", id: 904280696
# mas "Xcode", id: 497799835
# mas "Canary Mail", id: 1236045954

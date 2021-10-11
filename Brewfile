#!/usr/bin/env zsh

# -- taps --

tap "homebrew/bundle"
tap "homebrew/services"
tap "neovim/neovim"
tap "caius/jo"
tap "simeji/jid"
tap "browsh-org/homebrew-browsh"
tap "qmk/qmk"
tap "heroku/brew"
# NOTE/REF: https://github.blog/2020-07-02-git-credential-manager-core-building-a-universal-authentication-experience/#macos
tap "microsoft/git"
tap "isacikgoz/taps"
tap "vitorgalvao/tiny-scripts"
tap "mutagen-io/mutagen"
tap "bvgastel/clippy"
tap "olets/tap"

# -- for qmk_toolbox --

# brew tap osx-cross/avr; brew tap PX4/homebrew-px4; brew install avr-gcc@8; brew link --force avr-gcc@8; brew install dfu-programmer dfu-util gcc-arm-none-eabi avrdude qmk; brew cask install qmk-toolbox;
tap "osx-cross/avr"
tap "PX4/homebrew-px4"
# NOTE: at present, 20200327, qmk doesn't support >=avr-gcc@9
brew "avr-gcc@8", link: true
brew "dfu-programmer"
brew "dfu-util"
brew "gcc-arm-none-eabi"
brew "avrdude"
brew "qmk"

# -- cli --

brew "ansible"
brew "autoconf"
brew "automake"
# brew "asdf"
brew "aspell"
brew "awscli"
brew "bat"
brew "browsh"
brew "vitorgalvao/tiny-scripts/calm-notifications"
brew "ccls" # c-lang lsp vs., c-lang lsp in llvm
brew "cmake"
brew "coreutils"
brew "curl"
brew "dbus"
brew "diff-so-fancy"
brew "dnsmasq"
brew "dockutil"
brew "docker"
brew "docker-compose"
brew "docker-credential-helper-ecr"
brew "docker-machine" #, restart_service: true, link: false
brew "duck"
brew "efm-langserver", args: ["HEAD"]
brew "exa"
brew "exercism"
brew "fasd"
brew "fd"
brew "ffind"
brew "findutils"
brew "fontforge"
brew "fzf" # -> $(brew --prefix)/opt/fzf/install
brew "fzy"
brew "gawk"
brew "gdb"
brew "gist"
brew "git"
brew "isacikgoz/taps/gitin"
brew "git-delta"
brew "gh"
brew "gnutls"
brew "gnupg"
brew "gnu-sed"
brew "gpg" # required for asdf-nodejs
brew "grc"
brew "heroku"
brew "hub"
brew "highlight"
brew "htop"
brew "httpie"
brew "hunspell"
brew "ical-buddy"
brew "jq"
brew 'lazydocker'
brew 'lazygit'
brew "llvm" # contains c-lang lsp (the preferred one?)
brew "lnav"
brew "lsd"
brew "luajit", args: ["HEAD"]
brew "luarocks"
brew "luv"
brew "mas"
brew "mkcert"
brew "moreutils"
brew "mosh", args: ["HEAD"]
brew "mutagen-io/mutagen/mutagen-beta"
brew "mycli"
brew "mysql"
brew "ncurses"
brew "neovim", args: ["HEAD"]
brew "ninja" # for lua sumneko lsp
brew "nmap"
brew "nnn"
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
brew "shfmt"
brew "ssh-copy-id"
brew "stack"
brew "starship"
brew "stow"
brew "switchaudio-osx"
brew "terminal-notifier"
brew "the_silver_searcher"
brew "tidy-html5"
brew "timg" # for image rendering in kitty
brew "tldr"
brew "tmux" #, args: ["HEAD"]
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
brew "yj"
brew "zoxide"
brew "zsh"
brew "olets/tap/zsh-abbr"
brew "zsh-autosuggestions"
brew "zsh-completions"
brew "zsh-lovers"
brew "zsh-syntax-highlighting"
brew "zsh-history-substring-search"

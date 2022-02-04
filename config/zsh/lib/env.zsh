#!/usr/bin/env zsh
# shellcheck shell=bash

# -- make helpers available to all the frens:
[[ -f "$XDG_CONFIG_HOME/zsh/lib/helpers.zsh" ]] && source "$XDG_CONFIG_HOME/zsh/lib/helpers.zsh"

fpath+=(
    $ZDOTDIR/prompt
    $ZDOTDIR/completions
    $ZDOTDIR/plugins
    $ZDOTDIR/funcs
    ${ASDF_DIR}/completions
    $fpath
)

#
# -- term
export TERM=${TERM:=xterm-kitty}
export TERM_ITALICS="TRUE"
export COLORTERM=${COLORTERM:=truecolor}
# if [[ "$PLATFORM" == "linux" ]]; then
#     export TERMINAL="kitty --single-instance --listen-on unix:/tmp/mykitty -o allow_remote_control=yes"
# else
#     export TERMINAL="kitty"
# fi
#
# -- editors
export EDITOR="nvim"
export VISUAL="$EDITOR"
export SUDO_EDITOR="$EDITOR"
export GIT_EDITOR="$EDITOR"
export ALTERNATE_EDITOR="vim"
export PAGER="less"
export MANPAGER="$EDITOR -c Man!"
export MANWIDTH=999
export LESS="-F -g -i -M -R -S -w -X -z-4"
#
# -- lang
export LANG="en_US.UTF-8"
export LC_ALL="en_US.UTF-8"
export LC_CTYPE="en_US.UTF-8"
export TZ="/usr/share/zoneinfo/US/Central"
#
# -- directories/locations
export XDG_CONFIG_HOME  # we've set this .zshenv
export ZDOTDIR          # we've set this .zshenv
export XDG_DATA_HOME="$HOME/.local/share"
export XDG_CACHE_HOME="$HOME/.cache"
export DOTS="$HOME/.dotfiles"
export DOTFILES="$DOTS"
export DOTDIR="$DOTS"
export DOTSDIR="$DOTS"
export PRIVATES="$DOTS/private"
export PRIVATE="$PRIVATES"
export HOMEDIR="$HOME"
export PROJECTS="$HOME/code"
export WORKSPACE="$HOME/code"
export LINODES="$HOME/code/linodes"
export GIT_REPO_DIR="$PROJECTS"
# export TERMINFO="$HOME/.terminfo"
# export _Z_DATA="$HOME/.z-history"
#
# -- qmk
export QMK_HOME="$HOME/code/qmk_firmware"
#
# -- golang
export GOPATH="$HOME/.go"
export GOBIN="$GOPATH/bin"
#
# -- rust/cargo
export CARGOPATH="$HOME/.cargo"
export CARGOBIN="$CARGOPATH/bin"
#
# -- asdf
export ASDF_DIR="$HOME/.asdf"
export ASDF_SHIMS="$ASDF_DIR/shims"
export ASDF_BIN="$ASDF_SHIMS"
export ASDF_INSTALLS="$ASDF_DIR/installs"
# [ -f "$ZDOTDIR/lib/asdf.zsh" ] && source "$ZDOTDIR/lib/asdf.zsh" && echo "from env.zsh -- sourced $ZDOTDIR/lib/asdf.zsh.."
# export ASDF_LUAROCKS="$ASDF_INSTALLS/lua/5.3.5/luarocks/bin"
#
# -- rg
export RIPGREP_CONFIG_PATH="$XDG_CONFIG_HOME/ripgrep/rc"
#
# -- weechat
export WEECHAT_HOME="$XDG_CONFIG_HOME/weechat"
# -- bat
#
if ! type "$bat" > /dev/null; then
  export BAT_THEME="Forest%20Night%20Italic"
  export BAT_CONFIG_PATH="$XDG_CONFIG_HOME/bat"
fi
# -- zsh plugins
# export ZSH_AUTOSUGGEST_HIGHLIGHT_STYLE="fg=#6A7D89"
export ZSH_AUTOSUGGEST_HIGHLIGHT_STYLE="fg=#6A7D89,bg=#3c4c55"
export ZSH_AUTOSUGGEST_MANUAL_REBIND=1  # make prompt faster
export ZSH_AUTOSUGGEST_USE_ASYNC=1
# export ZSH_AUTOSUGGEST_STRATEGY=(history completion) # or match_prev_cmd
export ZSH_AUTOSUGGEST_USE_ASYNC=true
export _ZO_DATA_DIR="$XDG_DATA_HOME/zoxide"
export _ZO_ECHO=1


# HT: https://github.com/nicknisi/dotfiles/blob/master/zsh/zprofile.symlink
# if [[ -f /opt/homebrew/bin/brew ]]; then
#     # Homebrew exists at /opt/homebrew for arm64 macos
#     eval $(/opt/homebrew/bin/brew shellenv)
# elif [[ -f /usr/local/bin/brew ]]; then
#     # or at /usr/local for intel macos
#     eval $(/usr/local/bin/brew shellenv)
# elif [[ -f /home/linuxbrew/.linuxbrew ]]; then
#     # TODO: Can this just call brew shellenv too?
#     export HOMEBREW_PREFIX="/home/linuxbrew/.linuxbrew";
#     export HOMEBREW_CELLAR="$HOMEBREW_PREFIX/Cellar";
#     export HOMEBREW_REPOSITORY="$HOMEBREW_PREFIX/Homebrew";
#     export MANPATH="$HOMEBREW_PREFIX/share/man${MANPATH+:$MANPATH}:";
#     export INFOPATH="$HOMEBREW_PREFIX/share/info:${INFOPATH}";
#     export PATH="$HOMEBREW_PREFIX/bin:$HOMEBREW_PREFIX/sbin${PATH+:$PATH}";
# fi

#
# platform-specific
if [[ "$PLATFORM" == "macos" ]]; then
  export ICLOUD_DIR="$HOME/Library/Mobile Documents/com~apple~CloudDocs"
  export DOCUMENTS_DIR="$ICLOUD_DIR/Documents"
  export ZK_NOTEBOOK_DIR="$DOCUMENTS_DIR/_notes"
  export ZK_CONFIG_DIR="$XDG_CONFIG_HOME/zk"

  export BROWSER="open"
  export HOMEBREW_NO_ANALYTICS=1
  export HOMEBREW_CASK_OPTS="--appdir=/Applications"
  export HOMEBREW_NO_INSTALL_CLEANUP=TRUE
  export HOMEBREW_NO_INSTALLED_DEPENDENTS_CHECK=FALSE
  export HOMEBREW_PREFIX="$(/usr/local/bin/brew --prefix)"
  export BREW_PATH="$HOMEBREW_PREFIX/Homebrew"
  export BREW_CASK_PATH="/opt/homebrew-cask/Caskroom"

  # FIXME:
  # THIS IS A MAJOR SLOWDOWN
  # export RUBY_CONFIGURE_OPTS="--with-openssl-dir=$(brew --prefix openssl@1.1) --with-readline-dir=$(brew --prefix readline)"

  export LIBARCHIVE=/usr/local/opt/libarchive/lib/libarchive.dylib
  export LIBCRYPTO=/usr/local/opt/openssl@1.1/lib/libcrypto.dylib

  # for libffi and ruby things
  export LDFLAGS="$LDFLAGS -L/usr/local/opt/libffi/lib"
  export LDFLAGS="$LDFLAGS -L/usr/local/opt/openssl/lib"
  export LDFLAGS="$LDFLAGS -L/usr/local/opt/openssl@1.1/lib"
  export LDFLAGS="$LDFLAGS -I/usr/local/opt/openssl/include"

  export CPPFLAGS="$CPPFLAGS -I/usr/local/opt/libffi/include"
  export CPPFLAGS="$CPPFLAGS -I/usr/local/opt/openssl@1.1/include"

  export PKG_CONFIG_PATH="$PKG_CONFIG_PATH /usr/local/opt/libffi/lib/pkgconfig"
  export PKG_CONFIG_PATH="$PKG_CONFIG_PATH /usr/local/opt/openssl@1.1/lib/pkgconfig"

  export ERLANG_OPENSSL_PATH="/usr/local/opt/openssl@1.1"
  # export KERL_CONFIGURE_OPTIONS="--with-ssl=/usr/local/opt/openssl@1.1"
elif [[ "$PLATFORM" == "linux" ]]; then
  export BREW_PATH="$(/home/linuxbrew/.linuxbrew/bin/brew --prefix)"
  export HOMEBREW_PREFIX=$BREW_PATH
  export BROWSER="xdg-open"
  has lemonade && export BROWSER="lemonade open"
fi

# REF: https://coletiv.com/blog/how-to-correctly-install-erlang-and-elixir
export KERL_CONFIGURE_OPTIONS="--disable-debug --without-javac"

export NVIMRUNTIME='/usr/local/share/nvim/runtime'
export NVIM_TUI_ENABLE_TRUE_COLOR=1

# by default: export WORDCHARS='*?_-.[]~=/&;!#$%^(){}<>'
# we take out the slash, period, angle brackets, dash here.
export WORDCHARS='*?_[]~=&;!#$%^(){}'
export ACK_COLOR_MATCH='red'
export CC=/usr/bin/gcc

# reduce ESC key delay to 0.1
export KEYTIMEOUT=1

# so I can run USPTO/jboss stuff sensibly
export JAVA_OPTS="$JAVA_OPTS -Xms2048M -Xmx4096M -XX:MaxPermSize=512M -Djboss.vfs.forceCopy=false"
export ANDROID_SDK_ROOT="/usr/local/share/android-sdk"

# This resolves issues install the mysql, postgres, and other gems with native non universal binary extensions
export ARCHFLAGS='-arch x86_64'

# CTAGS Sorting in VIM/Emacs is better behaved with this in place
export LC_COLLATE=C

# Custom GC options for custom compiled 1.9.3 rubies
export RUBY_GC_MALLOC_LIMIT=1000000000
export RUBY_GC_HEAP_FREE_SLOTS=500000
export RUBY_GC_HEAP_INIT_SLOTS=40000

export NODEJS_CHECK_SIGNATURES=no # https://github.com/asdf-vm/asdf-nodejs#use

export SSL_CERT_FILE=''
unset SSL_CERT_FILE

export CURL_CA_BUNDLE=''

#
# yubikey
# GNUpg setup: https://github.com/drduh/YubiKey-Guide#create-temporary-working-directory-for-gpg
# export GNUPGHOME=$(mktemp -d) #; echo $GNUPGHOME
# export GNUPGHOME="$HOME/.gnupg"
# https://github.com/asdf-vm/asdf-nodejs#using-a-dedicated-openpgp-keyring
# export GNUPGHOME="${ASDF_DIR:-$HOME/.asdf}/keyrings/nodejs" && mkdir -p "$GNUPGHOME" && chmod 0700 "$GNUPGHOME"

# export MYSQL=/usr/local/mysql/bin
# export PATH=$PATH:$MYSQL
export LD_LIBRARY_PATH=$LD_LIBRARY_PATH:.:/usr/local/lib

# elixir and erlang things for `iex`, etc:
export ERL_AFLAGS="-kernel shell_history enabled"

#
# Paths
#
typeset -agU cdpath fpath manpath infopath path

# Set the the list of directories that cd searches.
cdpath=(
    $HOME/code
    $cdpath
)

# Set the list of directories that info searches for manuals.
infopath=(
    /usr/local/share/info
    /usr/share/info
    $infopath
)

# Set the list of directories that man searches for manuals.
manpath=(
    /usr/local/share/man
    /usr/share/man
    ${HOMEBREW_PREFIX}/opt/*/libexec/gnuman(N-/)
    $manpath
)
for man_file in /etc/manpaths.d/*(.N); do
    manpath+=($(<$man_file))
done
unset man_file

# Set the list of directories that Zsh searches for programs.
# "${HOME}/.asdf/installs/elixir/`asdf current elixir | awk '{print $1}'`/.mix"
path=(
    ./bin
    ./.bin
    ./vendor/bundle/bin
    $HOME/bin
    $HOME/.bin
    $HOME/.local/bin
    $DOTS/bin
    $PRIVATES/bin
    $ASDF_DIR
    $ASDF_BIN
    $ASDF_SHIMS
    $ASDF_INSTALLS
    $ASDF_LUAROCKS
    $GOBIN
    $CARGOPATH
    $CARGOBIN
    /usr/local/{bin,sbin}
    /usr/local/share/npm/bin
    /usr/local/lib/node_modules
    /usr/local/opt/libffi/lib
    # $HOME/.yarn/bin
    # $HOME/.config/yarn/global/node_modules/.bin
    /usr/local/opt/gnu-sed/libexec/gnubin
    /usr/local/opt/imagemagick@6/bin
    /usr/local/opt/qt@5.5/bin
    /usr/local/opt/mysql@5.6/bin
    /usr/local/opt/postgresql@9.5/bin
    /Applications/Postgres.app/Contents/Versions/9.5/bin
    /usr/local/lib/python2.7/site-packages
    $HOME/Library/Python/3.8/bin
    /usr/local/lib/python3.8/bin
    /usr/local/lib/python3.8/site-packages
    /usr/local/opt/python@3.8/bin
    $HOME/Library/Python/3.9/bin
    /usr/local/lib/python3.9/bin
    /usr/local/lib/python3.9/site-packages
    /usr/local/opt/python@3.9/bin
    $HOME/.asdf/installs/rust/stable/bin
    # /usr/local/opt/openssl@1.1/bin
    /usr/{bin,sbin}
    /{bin,sbin}
    # $HOME/.yarn/bin
    # $HOME/.config/yarn/global/node_modules/.bin
    ${HOME}/.dotfiles/bin(N-/)
    ${HOMEBREW_PREFIX}/opt/curl/bin(N-/)
    ${HOMEBREW_PREFIX}/opt/openssl@*/bin(Nn[-1]-/)
    ${HOMEBREW_PREFIX}/opt/gnu-sed/libexec/gnubin(N-/)
    ${HOMEBREW_PREFIX}/opt/coreutils/libexec/gnubin(N-/)
    ${HOMEBREW_PREFIX}/opt/python@3.*/libexec/bin(Nn[-1]-/)
    ${CARGO_HOME}/bin(N-/)
    ${GOBIN}(N-/)
    ${HOME}/Library/Python/3.*/bin(Nn[-1]-/)
    ${HOME}/Library/Python/2.*/bin(Nn[-1]-/)
    /usr/local/{bin,sbin}
    ${HOMEBREW_CELLAR}/git/*/share/git-core/contrib/git-jump(Nn[-1]-/)
    $path
)

# ${HOMEBREW_PREFIX}/opt/ruby/bin(N-/)

for path_file in /etc/paths.d/*(.N); do
    path+=($(<$path_file))
done
unset path_file

# use .localrc for SUPER SECRET stuff
if [[ -e $HOME/.localrc ]]; then
  source "$HOME/.localrc"
fi

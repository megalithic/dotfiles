# hf [[ "$PLATFORM" == "linux" ]]; then
#     export TERMINAL="kitty --single-instance --listen-on unix:/tmp/mykitty -o allow_remote_control=yes"
# else
#     export TERMINAL="kitty"
# fi

#
# editors
export EDITOR="nvim"
export VISUAL="$EDITOR"
export SUDO_EDITOR="$EDITOR"
export ALTERNATE_EDITOR="vim"
export PAGER="less"
export MANPAGER="$EDITOR +Man!"
export MANWIDTH=999
export LESS="-F -g -i -M -R -S -w -X -z-4"
export ZK_NOTEBOOK_DIR="$HOME/Documents/_notes"
# if (( $+commands[lesspipe.sh] )); then
#     # Set the Less input preprocessor.
#     export LESSOPEN='| /usr/bin/env lesspipe.sh %s 2>&-'
# fi

#
# lang
export LANG="en_US.UTF-8"
export LC_ALL="en_US.UTF-8"
export LC_CTYPE="en_US.UTF-8"
export TZ="/usr/share/zoneinfo/US/Central"

#
# dir locatons
export DOTS="$HOME/.dotfiles"
export DOTFILES="$DOTS"
export DOTDIR="$DOTS"
export DOTSDIR="$DOTS"
export PRIVATES="$DOTS/private"
export PRIVATE="$PRIVATES"
export HOMEDIR="$HOME"

export QMK_HOME="$HOME/code/qmk_firmware"

export GOPATH="$HOME/.go"
export GOBIN="$GOPATH/bin"

# export CARGOPATH="$HOME/.cargo"
# export CARGOBIN="$CARGOPATH/bin"

export ASDF_DIR="$HOME/.asdf"
export ASDF_SHIMS="$ASDF_DIR/shims"
export ASDF_BIN="$ASDF_SHIMS"
export ASDF_INSTALLS="$ASDF_DIR/installs"
# export ASDF_LUAROCKS="$ASDF_INSTALLS/lua/5.3.5/luarocks/bin"

export XDG_CONFIG_HOME  # Value is set in .zshenv
# export XDG_CONFIG_HOME="$HOME/.config"
export XDG_DATA_HOME="$HOME/.local/share"
export XDG_CACHE_HOME="$HOME/.cache"

export RIPGREP_CONFIG_PATH="$HOME/.ripgreprc"
export WEECHAT_HOME="$XDG_CONFIG_HOME/weechat"

export GIT_REPO_DIR="$HOME/code"
# export TERMINFO="$HOME/.terminfo"
export _Z_DATA="$HOME/.z-history"
export TERM_ITALICS="TRUE"

export BAT_THEME="base16"
export BAT_CONFIG_PATH="$HOME/.batrc"

export ZSH_AUTOSUGGEST_HIGHLIGHT_STYLE="fg=#6A7D89"
# export ZSH_AUTOSUGGEST_HIGHLIGHT_STYLE="fg=#6A7D89,bg=#3c4c55"  # nova bg
export ZSH_AUTOSUGGEST_USE_ASYNC=1

#
# platform-specific
if [[ "$PLATFORM" == "macos" ]]; then
  export BROWSER="open"
  export HOMEBREW_NO_ANALYTICS=1
  export HOMEBREW_CASK_OPTS="--appdir=/Applications"
  export HOMEBREW_PREFIX=$BREW_PATH
  export BREW_PATH="$(/usr/local/bin/brew --prefix)"
  export BREW_CASK_PATH="/opt/homebrew-cask/Caskroom"

  # FIXME:
  # THIS IS A MAJOR SLOWDOWN
  # export RUBY_CONFIGURE_OPTS="--with-openssl-dir=$(brew --prefix openssl@1.1) --with-readline-dir=$(brew --prefix readline)"

  export LIBARCHIVE=/usr/local/opt/libarchive/lib/libarchive.dylib
  export LIBCRYPTO=/usr/local/opt/openssl@1.1/lib/libcrypto.dylib

  # for libffi and ruby things
  export LDFLAGS="$LDFLAGS -L/usr/local/opt/libffi/lib"
  export LDFLAGS="$LDFLAGS -L/usr/local/opt/perl@5.32/lib"
  export LDFLAGS="$LDFLAGS -L/usr/local/opt/perl/lib"
  export LDFLAGS="$LDFLAGS -L/usr/local/opt/openssl/lib"
  export LDFLAGS="$LDFLAGS -L/usr/local/opt/openssl@1.1/lib"
  export LDFLAGS="$LDFLAGS -I/usr/local/opt/openssl/include"

  export CPPFLAGS="$CPPFLAGS -I/usr/local/opt/libffi/include"
  export CPPFLAGS="$CPPFLAGS -I/usr/local/opt/openssl@1.1/include"

  export PKG_CONFIG_PATH="$PKG_CONFIG_PATH /usr/local/opt/libffi/lib/pkgconfig"
  export PKG_CONFIG_PATH="$PKG_CONFIG_PATH /usr/local/opt/openssl@1.1/lib/pkgconfig"

  export ERLANG_OPENSSL_PATH="/usr/local/opt/openssl@1.1"
  export KERL_CONFIGURE_OPTIONS="--with-ssl=/usr/local/opt/openssl@1.1"
fi

export NVIMRUNTIME='/usr/local/share/nvim/runtime'
export NVIM_TUI_ENABLE_TRUE_COLOR=1

# by default: export WORDCHARS='*?_-.[]~=/&;!#$%^(){}<>'
# we take out the slash, period, angle brackets, dash here.
export WORDCHARS='*?_[]~=&;!#$%^(){}'
export ACK_COLOR_MATCH='red'
export CC=/usr/bin/gcc
export DISPLAY=:0.0

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
    $DOTS/bin
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
    # /usr/local/opt/perl/bin
    # /usr/local/opt/perl6/bin
    # /usr/local/opt/perl@5.28/bin
    # /usr/local/opt/perl@5.32/bin
    # /usr/local/opt/perl@5.32
    # /usr/local/opt/openssl@1.1/bin
    /usr/{bin,sbin}
    /{bin,sbin}
    # $HOME/.yarn/bin
    # $HOME/.config/yarn/global/node_modules/.bin
    ${HOME}/.dotfiles/bin(N-/)
    ${HOMEBREW_PREFIX}/opt/curl/bin(N-/)
    ${HOMEBREW_PREFIX}/opt/openssl@*/bin(Nn[-1]-/)
    ${HOMEBREW_PREFIX}/opt/perl@*/bin(Nn[-1]-/)
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


fpath+=(
    $ZDOTDIR/prompt
    $ZDOTDIR/completions
    $ZDOTDIR/plugins
    $ZDOTDIR/functions
    ${ASDF_DIR}/completions
    $fpath
)

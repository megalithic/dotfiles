zmodload zsh/datetime

# Create a hash table for globally stashing variables without polluting main
# scope with a bunch of identifiers.
typeset -A __DOTS

__DOTS[ITALIC_ON]=$'\e[3m'
__DOTS[ITALIC_OFF]=$'\e[23m'

# -- dirs
# export XDG_CONFIG_HOME="$HOME/config"
# export XDG_CACHE_HOME="$HOME/.cache"
# export XDG_DATA_HOME="$HOME/.local/share"
# export ZDOTDIR="$XDG_CONFIG_HOME/zsh"
# export ZSH_CACHE_DIR="$XDG_CACHE_HOME/zsh"

export XDG_CONFIG_HOME
export XDG_CACHE_HOME
export XDG_DATA_HOME
export ZDOTDIR
export ZSH_CACHE_DIR

export DOTS="${HOME}/.dotfiles"
export DOTFILES="$DOTS"
export PRIVATES="${DOTS}/private"
export PROJECTS_DIR="${HOME}/code"
export PROJECTS="$PROJECTS_DIR"
export PERSONAL_PROJECTS_DIR="${PROJECTS_DIR}/personal"
export GIT_REPO_DIR="$PROJECTS_DIR"

# -- term
export TERM=${TERM:=xterm-kitty}
export TERM_ITALICS="TRUE"
export COLORTERM=${COLORTERM:=truecolor}
export TERMINAL="kitty"

# -- editors
if which nvim >/dev/null; then
  if [ -n "$NVIM_LISTEN_ADDRESS" ]; then
    # FIXME: move to the latest nvim-remote api:
    # https://github.com/ahmedelgabri/dotfiles/commit/b5d0824c60f19ab52a391e0c33930ddad9767910
    export EDITOR="nvr -cc split --remote-wait +'set bufhidden=wipe'"
    export VISUAL="nvr -cc split --remote-wait +'set bufhidden=wipe'"
  else
    export EDITOR="nvim"
    export VISUAL="nvim"
  fi

  export NVIMRUNTIME="/usr/local/share/nvim/runtime"
  export NVIM_TUI_ENABLE_TRUE_COLOR=1
  export MANPAGER="${EDITOR} +Man!"
  export ALTERNATE_EDITOR="vim"
else
  export EDITOR="vim"
  export VISUAL="vim"
fi

export USE_EDITOR=$EDITOR
export SUDO_EDITOR="$EDITOR"
export GIT_EDITOR="$EDITOR"
export PAGER="less"
export MANWIDTH=999
export LESS="-F -g -i -M -R -S -w -X -z-4"
export MANPATH="/usr/local/man:$MANPATH"

# -- lang
export LANG="en_US.UTF-8"
export LC_ALL="en_US.UTF-8"
export LC_CTYPE="en_US.UTF-8"
export TZ="/usr/share/zoneinfo/US/Central"

# -- qmk
export QMK_HOME="$PROJECTS_DIR/qmk_firmware"

# -- golang
export GOPATH="$HOME/.go"
export GOBIN="$GOPATH/bin"

# -- rust/cargo
export CARGOPATH="$HOME/.cargo"
export CARGOBIN="$CARGOPATH/bin"
[ -f "$CARGOPATH/env" ] && . "$CARGOPATH/env"

# -- asdf
export ASDF_DIR="$HOME/.asdf"
export ASDF_SHIMS="$ASDF_DIR/shims"
export ASDF_BIN="$ASDF_SHIMS"
export ASDF_INSTALLS="$ASDF_DIR/installs"
# [ -f "$ZDOTDIR/lib/asdf.zsh" ] && source "$ZDOTDIR/lib/asdf.zsh" && echo "from env.zsh -- sourced $ZDOTDIR/lib/asdf.zsh.."
# export ASDF_LUAROCKS="$ASDF_INSTALLS/lua/5.3.5/luarocks/bin"

# -- rg/ripgrep
# @see: https://github.com/BurntSushi/ripgrep/blob/master/GUIDE.md#configuration-file
if which rg >/dev/null; then
  export RIPGREP_CONFIG_PATH="${DOTS}/config/ripgrep/rc"
fi

# -- weechat
export WEECHAT_HOME="$XDG_CONFIG_HOME/weechat"

# -- wezterm
export WEZTERM_CONFIG_FILE="$XDG_CONFIG_HOME/wezterm/wezterm.lua"

# -- bat
if which bat >/dev/null; then
  export BAT_THEME="Forest%20Night%20Italic"
  export BAT_CONFIG_PATH="$XDG_CONFIG_HOME/bat"
fi

case "$(uname)" in
  Darwin)
    PLATFORM="macos"
    export PLATFORM="macos"
    export ANDROID_SDK_ROOT="${HOME}/Library/Android/sdk/"
    # export ANDROID_SDK_ROOT="/usr/local/share/android-sdk"

    # Add LUA_PATH to the environment ensuring the lua version is set since
    # luarocks from homebrew uses lua 5.4 by default so would otherwise add the
    # wrong path
    if which luarocks >/dev/null; then
      eval "$(luarocks --lua-version=5.1 path)"
    fi

    export SYNC_DIR="${HOME}/Dropbox"
    export ICLOUD_DIR="$HOME/Library/Mobile Documents/com~apple~CloudDocs"
    export DOCUMENTS_DIR="$ICLOUD_DIR/Documents"
    export ZK_NOTEBOOK_DIR="$DOCUMENTS_DIR/_notes"
    export ZK_CONFIG_DIR="$XDG_CONFIG_HOME/zk"

    export BROWSER="open"
    export HOMEBREW_NO_ANALYTICS=1
    export HOMEBREW_CASK_OPTS="--appdir=/Applications"
    export HOMEBREW_NO_INSTALL_CLEANUP=TRUE
    export HOMEBREW_NO_INSTALLED_DEPENDENTS_CHECK=FALSE
    export BREW_PATH="$HOMEBREW_PREFIX/Homebrew"
    export BREW_CASK_PATH="/opt/homebrew-cask/Caskroom"

    # REF: https://coletiv.com/blog/how-to-correctly-install-erlang-and-elixir
    if which brew >/dev/null; then
      # NOTE: erlang doesn't support openssl@3 yet (as of 2022-06-13)
      # export LDFLAGS="-L$(brew --prefix)/opt/openssl@1.1/lib"
      # export CPPFLAGS="-I$(brew --prefix)/opt/openssl@1.1/include"
      # export LDFLAGS="$LDFLAGS -L$(brew --prefix)/opt/libffi/lib"
      # export CPPFLAGS="$CPPFLAGS -I$(brew --prefix)/opt/libffi/include"
      export PKG_CONFIG_PATH="$PKG_CONFIG_PATH $(brew --prefix)/opt/libffi/lib/pkgconfig"
      export PKG_CONFIG_PATH="$PKG_CONFIG_PATH $(brew --prefix)/opt/openssl@1.1/lib/pkgconfig"
      # export ERLANG_OPENSSL_PATH="/usr/local/opt/openssl@1.1"
      # export ERLANG_OPENSSL_PATH="/usr/local/opt/openssl@3"

      # FIXME:
      # THIS IS A MAJOR SLOWDOWN
      # export RUBY_CONFIGURE_OPTS="--with-openssl-dir=$(brew --prefix openssl@1.1) --with-readline-dir=$(brew --prefix readline)"

      # export LIBARCHIVE="$(brew --prefix)/opt/libarchive/lib/libarchive.dylib"
      # export LIBCRYPTO="$(brew --prefix)/opt/openssl@1.1/lib/libcrypto.dylib"

      # REF: https://github.com/asdf-vm/asdf-erlang#osx
      export KERL_CONFIGURE_OPTIONS="--disable-debug --without-javac --with-ssl=$(brew --prefix) openssl@1.1)"
    fi
  ;;
  Linux)
    PLATFORM="linux"
    export PLATFORM="linux"
    # Java -----------------------------------------------------------------------
    # Use Java 8 because -> https://stackoverflow.com/a/49759126
    # ------------------------------------------------------------------------
    export JAVA_HOME=/usr/lib/jvm/java-8-openjdk-amd64
    path+=(
      ${JAVA_HOME}/bin(N-/)
    )
    export KERL_CONFIGURE_OPTIONS="--disable-debug --without-javac"
    export PATH="/home/linuxbrew/.linuxbrew/opt/openssl@1.1/bin:$PATH"
    export BROWSER="xdg-open"


    if which lemonade >/dev/null; then
      export BROWSER="lemonade open"
    fi
  ;;
esac

# by default: export WORDCHARS='*?_-.[]~=/&;!#$%^(){}<>'
# we take out the slash, period, angle brackets, dash here.
export WORDCHARS='*?_[]~=&;!#$%^(){}'
export ACK_COLOR_MATCH='red'
export CC=/usr/bin/gcc

# reduce ESC key delay to 0.1
export KEYTIMEOUT=1

# so I can run USPTO/jboss stuff sensibly
export JAVA_OPTS="$JAVA_OPTS -Xms2048M -Xmx4096M -XX:MaxPermSize=512M -Djboss.vfs.forceCopy=false"

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

# -- paths ---------------------------------------------------------------------
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
  ${HOME}/.local/bin(N-/)
  ${DOTS}/bin(N-/)
  $PRIVATES/bin
  $ASDF_DIR
  $ASDF_BIN
  $ASDF_SHIMS
  $ASDF_INSTALLS
  $ASDF_LUAROCKS
  # ${HOME}/neovim/bin(N-/)
  $GOBIN
  ${GOPATH}/bin(N-/)
  $CARGOPATH
  $CARGOBIN
  /usr/local/{bin,sbin}
  /usr/local/share/npm/bin
  /usr/local/lib/node_modules
  /usr/local/opt/libffi/lib
  /usr/local/opt/gnu-sed/libexec/gnubin
  # /usr/local/opt/imagemagick@6/bin
  # /usr/local/opt/qt@5.5/bin
  # /usr/local/opt/mysql@5.6/bin
  # /usr/local/opt/postgresql@9.5/bin
  # /Applications/Postgres.app/Contents/Versions/9.5/bin

  # /usr/local/opt/openssl@1.1/bin
  /usr/{bin,sbin}
  /{bin,sbin}

  ${HOMEBREW_PREFIX}/opt/curl/bin(N-/)
  ${HOMEBREW_PREFIX}/opt/openssl@*/bin(Nn[-1]-/)
  ${HOMEBREW_PREFIX}/opt/gnu-sed/libexec/gnubin(N-/)
  ${HOMEBREW_PREFIX}/opt/coreutils/libexec/gnubin(N-/)
  ${HOMEBREW_PREFIX}/opt/python@3.*/libexec/bin(Nn[-1]-/)
  ${HOMEBREW_CELLAR}/git/*/share/git-core/contrib/git-jump(Nn[-1]-/)

  ${CARGO_HOME}/bin(N-/)
  $HOME/.asdf/installs/rust/stable/bin

  ${GOBIN}(N-/)

  ${HOME}/Library/Python/3.*/bin(Nn[-1]-/)
  ${HOME}/Library/Python/2.*/bin(Nn[-1]-/)
  /usr/local/lib/python3.*/bin(Nn[-1]-/)
  /usr/local/lib/python3.*/site-packages(N-/)
  /usr/local/lib/python2.*/bin(Nn[-1]-/)
  /usr/local/lib/python2.*/site-packages(N-/)
  /usr/local/opt/python@3.*/bin(Nn[-1]-/)
  /usr/local/opt/python@2.*/bin(Nn[-1]-/)
  /usr/local/{bin,sbin}
  $path
)
export PATH

for path_file in /etc/paths.d/*(.N); do
  path+=($(<$path_file))
done
unset path_file

fpath+=(
  "$HOMEBREW_PREFIX/share/zsh/site-functions"
  "$ZDOTDIR/prompt"
  "$ZDOTDIR/completions"
  "$ZDOTDIR/plugins"
  "$ZDOTDIR/funcs"
  "$DOTS/bin"
  "${ASDF_DIR}/completions"
  "${fpath[@]}"
  # "$fpath"
)
export FPATH

# -- zsh plugins
# ------------------------------------------------------------------------------
export ZSH_AUTOSUGGEST_HIGHLIGHT_STYLE="fg=#323d43,bg=#7c8377,bold,underline"
# export ZSH_AUTOSUGGEST_HIGHLIGHT_STYLE="fg=#323d43,bg=#7c8377,bold,underline"
export ZSH_AUTOSUGGEST_MANUAL_REBIND=1  # make prompt faster
export ZSH_AUTOSUGGEST_USE_ASYNC=1
# export ZSH_AUTOSUGGEST_STRATEGY=(history completion) # or match_prev_cmd
export _ZO_DATA_DIR="$XDG_DATA_HOME/zoxide"
export _ZO_ECHO=1

# use .localrc for SUPER SECRET stuff
if [ -f "$HOME/.localrc" ]; then
  source "$HOME/.localrc"
fi


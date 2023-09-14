#!/usr/bin/env zsh
# shellcheck shell=bash

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

PLATFORM=$(uname -s)
export PLATFORM="$PLATFORM"

# ====================== from .zshenv ==========================================
XDG_CONFIG_HOME="$HOME/.config"
XDG_CACHE_HOME="$HOME/.cache"
XDG_DATA_HOME="$HOME/.local/share"

ZDOTDIR="$XDG_CONFIG_HOME/zsh"
ZSH_CACHE_DIR="$XDG_CACHE_HOME/zsh"

if [ ! -d "$ZSH_CACHE_DIR" ]; then
  mkdir -p "$ZSH_CACHE_DIR"
fi
# / =================== from .zshenv ===========================================

export XDG_CONFIG_HOME
export XDG_CACHE_HOME
export XDG_DATA_HOME
export ZDOTDIR
export ZSH_CACHE_DIR

export DOTS="${HOME}/.dotfiles"
export DOTFILES="$DOTS"
export PRIVATES="${DOTS}/private"
export CODE="${HOME}/code"
export PROJECTS="$CODE"
export PROJECTS_DIR="$CODE"
export PERSONAL_PROJECTS_DIR="${CODE}/personal"
export GIT_REPO_DIR="$CODE"

# ===================== from .zprofile =========================================
case `uname` in
  Darwin)
    # -- intel mac:
    [ -f "/usr/local/bin/brew" ] && eval "$(/usr/local/bin/brew shellenv)"
    # -- M1 mac:
    [ -f "/opt/homebrew/bin/brew" ] && eval "$(/opt/homebrew/bin/brew shellenv)"
    ;;
  Linux)
    [ -d "/home/linuxbrew/.linuxbrew" ] && eval "$(/home/linuxbrew/.linuxbrew/bin/brew shellenv)"
    ;;
esac

brew_prefix='/usr/local'
if [[ "$(arch)" == "arm64" ]]; then
  brew_prefix='/opt/homebrew'
  eval $(/opt/homebrew/bin/brew shellenv)
else
  eval $(/usr/local/bin/brew shellenv)
fi

export BREW_PREFIX="${brew_prefix}"
# export BREW_PREFIX="$(brew --prefix)"
export HOMEBREW_PREFIX="$BREW_PREFIX"

path=(
  "$BREW_PREFIX/opt/ruby/bin"
  "$BREW_PREFIX/lib/ruby/gems/3.0.0/bin"
  # NOTE: Add coreutils which make commands like ls run as they do on Linux rather than the BSD flavoured variant macos ships with
  "$BREW_PREFIX/opt/coreutils/libexec/gnubin"
  $path
)

export MANPATH="$BREW_PREFIX/opt/coreutils/libexec/gnuman:${MANPATH}"
# / =================== from .zprofile =========================================

# -- term (wezterm, xterm-kitty, xterm-256color, tmux-256color)
# export TERM=${TERM:=xterm-kitty}
export TERM_ITALICS="TRUE"
export COLORTERM=${COLORTERM:=truecolor}
export TERMINAL="kitty"

export LS_COLORS="$(vivid generate nord)"

# -- editors
if which nvim >/dev/null; then
  # if [ -n "${NVIM_LISTEN_ADDRESS+x}" ]; then
  #   # if [ -n "$NVIM_LISTEN_ADDRESS" ]; then
  #   # FIXME: move to the latest nvim-remote api:
  #   # https://github.com/ahmedelgabri/dotfiles/commit/b5d0824c60f19ab52a391e0c33930ddad9767910
  #   export EDITOR="nvr -cc split --remote-wait +'set bufhidden=wipe'"
  #   export VISUAL="nvr -cc split --remote-wait +'set bufhidden=wipe'"
  #   export MANPAGER="/usr/local/bin/nvr -c 'Man!' -o -"
  # else
    export EDITOR="nvim"
    export VISUAL="$EDITOR"
    export MANPAGER="$EDITOR +Man!"
    # export ELIXIR_EDITOR="$EDITOR +__LINE__ __FILE__"
    # export PLUG_EDITOR=$ELIXIR_EDITOR
    # export ECTO_EDITOR=$ELIXIR_EDITOR
    # export MANPAGER="/usr/local/bin/nvim -c 'Man!' -o -"
  # fi

  export NVIMRUNTIME="/usr/local/share/nvim/runtime"
  export NVIM_TUI_ENABLE_TRUE_COLOR=1
  export ALTERNATE_EDITOR="\vim"
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

# -- gnupg/gpg
export GNUPGHOME="$XDG_CONFIG_HOME/gnupg"

# -- lang
export LANG="en_US.UTF-8"
export LC_ALL="en_US.UTF-8"
export LC_CTYPE="en_US.UTF-8"
export TZ="/usr/share/zoneinfo/US/Central"
# export TZ="/usr/share/zoneinfo/US/Eastern"

# -- kitty
export KITTYMUX_STATE_DIR=$HOME/.local/state

# -- wezterm
export WEZTERM_CONFIG_FILE="$XDG_CONFIG_HOME/wezterm/wezterm.lua"
# [ -n "$WEZTERM_PANE" ] && export NVIM_LISTEN_ADDRESS="/tmp/nvim$WEZTERM_PANE"

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
# REF:
# https://github.com/ansible/ansible/issues/76322#issuecomment-974147955
export OBJC_DISABLE_INITIALIZE_FORK_SAFETY=YES


# -- bat
if which bat >/dev/null; then
  export BAT_THEME="Forest%20Night%20Italic"
  export BAT_CONFIG_PATH="$XDG_CONFIG_HOME/bat"
fi

case "$(uname)" in
  Darwin)
    export ANDROID_SDK_ROOT="${HOME}/Library/Android/sdk/"
    export ANDROID_HOME="$ANDROID_SDK_ROOT"
    # export ANDROID_SDK_ROOT="/usr/local/share/android-sdk"

    # Add LUA_PATH to the environment ensuring the lua version is set since
    # luarocks from homebrew uses lua 5.4 by default so would otherwise add the
    # wrong path
    if which luarocks >/dev/null; then
      eval "$(luarocks --lua-version=5.1 path)"
    fi

    export SYNC_DIR="${HOME}/Dropbox"
    export ICLOUD_DIR="$HOME/Library/Mobile Documents/com~apple~CloudDocs"
    export ICLOUD_DOCUMENTS_DIR="${ICLOUD_DIR}/Documents"
    export DOCUMENTS_DIR="${ICLOUD_DOCUMENTS_DIR}"
    export OBSIDIAN_VAULT_DIR="${ICLOUD_DIR}/Documents/_notes/vault"
    export ZK_NOTEBOOK_DIR="$DOCUMENTS_DIR/_notes"
    export ZK_CONFIG_DIR="$XDG_CONFIG_HOME/zk"

    export BROWSER="open"
    export HOMEBREW_NO_ANALYTICS=1
    export HOMEBREW_CASK_OPTS="--appdir=/Applications"
    export HOMEBREW_NO_INSTALL_CLEANUP=TRUE
    export HOMEBREW_NO_INSTALLED_DEPENDENTS_CHECK=FALSE
    export HOMEBREW_NO_INSTALL_FROM_API=1
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

      # REF:
      # https://github.com/asdf-vm/asdf-erlang#osx
      # https://github.com/erlang/otp/issues/4821#issuecomment-961308734
      # export KERL_CONFIGURE_OPTIONS="--disable-debug --without-javac --with-ssl=$(brew --prefix)/opt/openssl@1.1)"
      export KERL_CONFIGURE_OPTIONS="--disable-hipe --disable-sctp --enable-darwin-64bit --enable-kernel-poll --enable-shared-zlib --enable-smp-support --enable-threads --enable-wx --with-ssl=$(brew --prefix openssl@1.1) --without-docs --without-javac --without-jinterface --without-odbc"
      export KERL_BUILD_DOCS=yes

      # FIXME: asdf install erlang ->
      # EGREP=egrep CC=clang CPP="clang -E" KERL_USE_AUTOCONF=0 KERL_CONFIGURE_OPTIONS="--disable-hipe --disable-sctp --enable-darwin-64bit --enable-kernel-poll --enable-shared-zlib --enable-smp-support --enable-threads --enable-wx --with-ssl=$(brew --prefix openssl@1.1) --without-docs --without-javac --without-jinterface --without-odbc" asdf install erlang _version_
    fi
    ;;
  Linux)
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


  # postgresql
  # export LDFLAGS="-L/usr/local/opt/postgresql@15/lib"
  # export CPPFLAGS="-I/usr/local/opt/postgresql@15/include"
  # export PKG_CONFIG_PATH="/usr/local/opt/postgresql@15/lib/pkgconfig"

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

  export ABDUCO_CMD="echo 'abduco started'"

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
    /opt/homebrew/bin
    ./bin
    ./.bin
    ./vendor/bundle/bin
    $HOME/bin
    $HOME/.bin
    $HOME/.emacs.d/bin
    ${HOME}/.local/bin(N-/)
    ${DOTS}/bin(N-/)
    $PRIVATES/bin
    $ASDF_DIR
    $ASDF_BIN
    $ASDF_SHIMS
    $ASDF_INSTALLS
    $ASDF_LUAROCKS
    $GOBIN
    ${GOPATH}/bin(N-/)
    $CARGOPATH
    $CARGOBIN
    /usr/local/{bin,sbin}
    /usr/local/share/npm/bin
    /usr/local/lib/node_modules
    ${HOMEBREW_PREFIX}/opt/libffi/lib
    ${HOMEBREW_PREFIX}/opt/gnu-sed/libexec/gnubin
    ${HOMEBREW_PREFIX}/opt/postgresql@15/bin
    ${HOMEBREW_PREFIX}/opt/postgresql@14/bin

    # /usr/local/opt/openssl@1.1/bin
    /usr/{bin,sbin}
    /{bin,sbin}

    ${HOMEBREW_PREFIX}/opt/curl/bin(N-/)
    ${HOMEBREW_PREFIX}/opt/openssl@*/bin(Nn[-1]-/)
    ${HOMEBREW_PREFIX}/opt/gnu-sed/libexec/gnubin(N-/)
    ${HOMEBREW_PREFIX}/opt/coreutils/libexec/gnubin(N-/)
    ${HOMEBREW_PREFIX}/opt/python@3.11/libexec/bin(Nn[-1]-/)
    ${HOMEBREW_PREFIX}/opt/python@3.10/libexec/bin(Nn[-1]-/)
    ${HOMEBREW_PREFIX}/opt/python@3.9/libexec/bin(Nn[-1]-/)
    ${HOMEBREW_CELLAR}/git/*/share/git-core/contrib/git-jump(Nn[-1]-/)

    ${CARGO_HOME}/bin(N-/)
    $HOME/.asdf/installs/rust/stable/bin

    ${GOBIN}(N-/)

    ${HOME}/Library/Python/3.11/bin(Nn[-1]-/)
    ${HOME}/Library/Python/3.10/bin(Nn[-1]-/)
    ${HOME}/Library/Python/3.9/bin(Nn[-1]-/)
    ${HOME}/Library/Python/2.*/bin(Nn[-1]-/)
    ${HOMEBREW_PREFIX}/lib/python3.11/site-packages(N-/)
    ${HOMEBREW_PREFIX}/lib/python3.10/site-packages(N-/)
    ${HOMEBREW_PREFIX}/lib/python3.9/site-packages(N-/)
    ${HOMEBREW_PREFIX}/lib/python2.*/bin(Nn[-1]-/)
    ${HOMEBREW_PREFIX}/lib/python2.*/site-packages(N-/)
    ${HOMEBREW_PREFIX}/opt/python@3.*/bin(Nn[-1]-/)
    ${HOMEBREW_PREFIX}/opt/python@2.*/bin(Nn[-1]-/)
    ${HOMEBREW_PREFIX}/{bin,sbin}

    $ANDROID_HOME/emulator
    $ANDROID_HOME/platform-tools
    /Applications/WezTerm.app/Contents/MacOS
    $path
  )
  export PATH

  for path_file in /etc/paths.d/*(.N); do
    path+=($(<$path_file))
  done
  unset path_file

  fpath=(
    "$ZDOTDIR"
    "${HOMEBREW_PREFIX}/share/zsh/site-functions"
    "${HOMEBREW_PREFIX}/share/zsh/functions"
    "${ZDOTDIR}/prompt"
    "${ZDOTDIR}/completions"
    "${ZDOTDIR}/plugins"
    "${ZDOTDIR}/funcs"
    "${ZDOTDIR}/lib/fns"
    "${DOTS}/bin"
    "${ASDF_DIR}/completions"
    "${fpath[@]}"
    "$fpath"
  )
  export FPATH

  # -- zsh plugins
  # ------------------------------------------------------------------------------
  # zsweep zsh linter
  zs_set_path=1

  # autosuggest
  export ZSH_AUTOSUGGEST_HIGHLIGHT_STYLE="fg=#465258,bold,underline"
  export ZSH_AUTOSUGGEST_MANUAL_REBIND=1  # make prompt faster
  export ZSH_AUTOSUGGEST_USE_ASYNC=1
  # export ZSH_AUTOSUGGEST_STRATEGY=(history completion) # or match_prev_cmd
  export ZSH_AUTOSUGGEST_STRATEGY=("match_prev_cmd" "completion")

  # zoxide
  export _ZO_DATA_DIR="$XDG_DATA_HOME/zoxide"
  export _ZO_ECHO=1

  HISTORY_SUBSTRING_SEARCH_HIGHLIGHT_FOUND='fg=red,bold'
  HISTORY_SUBSTRING_SEARCH_HIGHLIGHT_NOT_FOUND='bg=red,fg=black,bold'
  # HISTORY_SUBSTRING_SEARCH_GLOBBING_FLAGS='i'
  # HISTORY_SUBSTRING_SEARCH_ENSURE_UNIQUE=''
  # HISTORY_SUBSTRING_SEARCH_FUZZY=''

  ##Remove % at end of print when not using \n
  PROMPT_EOL_MARK=""

  # use .localrc/local.zsh for SUPER SECRET stuff
  if [[ -f "$ZDOTDIR/lib/local.zsh" && "$(uname)" == "Darwin" ]]; then
    source "$ZDOTDIR/lib/local.zsh"
  fi

  if [ -f "$HOME/.localrc" ]; then
    source "$HOME/.localrc"
  fi

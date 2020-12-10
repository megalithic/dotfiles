#!/bin/zsh

export ZDOTDIR="$HOME/.config/zsh"

#
# Utils
#

is_linux() { [ "$(uname)" = "Linux" ]; }
is_mac() { [ "$(uname)" = "Darwin" ]; }

#
# Applications
#

if is_mac; then
    export BROWSER='open'
else
    # export BROWSER='firefox-developer-edition'
fi

if is_linux; then
    export TERMINAL="kitty --single-instance --listen-on unix:/tmp/mykitty -o allow_remote_control=yes"
else
    export TERMINAL="kitty"
fi

#
# Defines environment variables.
#

export EDITOR='nvim'
export VISUAL='nvim'
export SUDO_EDITOR='nvim'
export ALTERNATE_EDITOR='vim'
export PAGER='less'

#
# Language
#

if [[ -z "$LANG" ]]; then
  export LANG='en_US.UTF-8'
fi
export LC_ALL='en_US.UTF-8'

# duplicated in .zshrc
export DOTFILES="$HOME/.dotfiles"
export DOTDIR=$DOTFILES
export DOTS=$DOTFILES
export PRIVATES="$DOTS/private"
export PRIVATE=$PRIVATES
# export ZDOTDIR="$DOTS/zsh"
# export ZSH=$ZDOTDIR
# export ZSH_HOME=$ZDOTDIR
# export ZSHHOME=$ZDOTDIR

export GOPATH="$HOME/.go"
export GOBIN="$GOPATH/bin"
export CARGOPATH="$HOME/.cargo"
export CARGOBIN="$CARGOPATH/bin"
export ASDF_DIR="$HOME/.asdf"
# export ASDF_BIN="$ASDF_DIR/shims"
export ASDF_SHIMS="$ASDF_DIR/shims"
export ASDF_INSTALLS="$ASDF_DIR/installs"
export ASDF_LUAROCKS="$ASDF_INSTALLS/lua/5.3.5/luarocks/bin"

export XDG_CONFIG_HOME="$HOME/.config"
export XDG_DATA_HOME="$HOME/.local/share"
export XDG_CACHE_HOME="$HOME/.cache"

if [ ! -w ${XDG_RUNTIME_DIR:="/run/user/$UID"} ]; then
  XDG_RUNTIME_DIR=/tmp
fi
export XDG_RUNTIME_DIR

export ZINIT_HOME=$XDG_CONFIG_HOME/zinit

#
# Paths
#
# typeset -gU cdpath fpath mailpath path
# typeset -gxU MANPATH
# typeset -gxUT INFOPATH infopath
# typeset -gxU MANPATH
# typeset -gxUT INFOPATH infopath
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

for path_file in /etc/manpaths.d/*(.N); do
  manpath+=($(<$path_file))
done
unset path_file

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
    $N_PREFIX/bin
    $CARGOPATH
    $CARGOBIN
    /usr/local/{bin,sbin}
    /usr/local/share/npm/bin
    /usr/local/lib/node_modules
    /usr/local/opt/libffi/lib
    # $HOME/.yarn/bin
    # $HOME/.config/yarn/global/node_modules/.bin
    /Users/replicant/.local/bin
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
    /usr/local/opt/perl/bin
    /usr/local/opt/perl6/bin
    /usr/local/opt/perl@5.18/bin
    /usr/local/opt/perl@5.28/bin
    /usr/local/opt/perl@5.32/bin
    /usr/local/opt/perl@5.32
    /usr/local/opt/openssl@1.1/bin
    /usr/{bin,sbin}
    /{bin,sbin}
    /usr/local/opt/curl/bin
    # $HOME/.yarn/bin
    # $HOME/.config/yarn/global/node_modules/.bin
    ${ZDOTDIR:-${DOTFILES}/zsh}/bin(N-/)
    ${HOME}/.local/bin(N-/)
    ${HOMEBREW_PREFIX}/opt/curl/bin(N-/)
    ${HOMEBREW_PREFIX}/opt/openssl@*/bin(Nn[-1]-/)
    ${HOMEBREW_PREFIX}/opt/gnu-sed/libexec/gnubin(N-/)
    ${HOMEBREW_PREFIX}/opt/coreutils/libexec/gnubin(N-/)
    ${HOMEBREW_PREFIX}/opt/python@3.*/libexec/bin(Nn[-1]-/)
    ${CARGO_HOME}/bin(N-/)
    ${GOBIN}(N-/)
    ${HOME}/Library/Python/3.*/bin(Nn[-1]-/)
    ${HOME}/Library/Python/2.*/bin(Nn[-1]-/)
    ${HOMEBREW_PREFIX}/opt/ruby/bin(N-/)
    ${HOMEBREW_PREFIX}/lib/ruby/gems/*/bin(Nn[-1]-/)
    /usr/local/{bin,sbin}
    ${HOMEBREW_CELLAR}/git/*/share/git-core/contrib/git-jump(Nn[-1]-/)
    $path
)

for path_file in /etc/paths.d/*(.N); do
  path+=($(<$path_file))
done
unset path_file


#
# Function Paths
#
# fpath=( $fpath)
fpath+=(
  $ZDOTDIR
  $ZDOTDIR/components
  $ZDOTDIR/completions
  $ZDOTDIR/plugins
  $ZDOTDIR/functions
  $fpath
)


#
# Temporary Files
#
if [[ -d "$TMPDIR" ]]; then
  export TMPPREFIX="${TMPDIR%/}/zsh"
  if [[ ! -d "$TMPPREFIX" ]]; then
    mkdir -p "$TMPPREFIX"
  fi
fi


#
# asdf/ruby/node/misc
#
source "$ZDOTDIR/components/asdf.zsh"

# source "$DOTS/components/completion.zsh"
# source "$DOTS/components/colors.zsh"


#
# Privates
#
# if [[ -f "$HOME/.zprivate" ]] ; then
#   source "$HOME/.zprivate"
# fi

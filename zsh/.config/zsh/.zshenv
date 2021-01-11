export ZDOTDIR="$HOME/.config/zsh"

#
# Utils
#

function detect_platform {
    if [[ -z $PLATFORM ]]
    then
        platform="unknown"
        derived_platform=$(uname | tr "[:upper:]" "[:lower:]")

        if [[ "$derived_platform" == "darwin" ]]; then
            platform="macos"
        elif [[ "$derived_platform" == "linux" ]]; then
            platform="linux"
        fi

        export PLATFORM=$platform

        # if [[ "$PLATFORM" == "linux" ]]; then
        #     # If available, use LSB to identify distribution
        #     if [ -f /etc/lsb-release -o -d /etc/lsb-release.d ]; then
        #         export DISTRO=$(lsb_release -i | cut -d: -f2 | sed s/'^\t'//)
        #         # Otherwise, use release info file
        #     else
        #         export DISTRO=$(ls -d /etc/[A-Za-z]*[_-][rv]e[lr]* | grep -v "lsb" | cut -d'/' -f3 | cut -d'-' -f1 | cut -d'_' -f1)
        #     fi
        # fi
        unset platform
        unset derived_platform
    fi
}
detect_platform

#
# Applications
#

if [[ "$PLATFORM" == "darwin" ]]; then
    export BROWSER='open'
else
    # export BROWSER='firefox-developer-edition'
fi

if [[ "$PLATFORM" == "linux" ]]; then
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

export LANG='en_US.UTF-8'
export LC_ALL='en_US.UTF-8'

# duplicated in .zshrc
export DOTFILES="$HOME/.dotfiles"
export DOTDIR=$DOTFILES
export DOTS=$DOTFILES
export PRIVATES="$DOTS/private"
export PRIVATE=$PRIVATES

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
export RIPGREP_CONFIG_PATH="$HOME/.ripgreprc"

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
    # /usr/local/opt/perl@5.18/bin
    # /usr/local/opt/perl@5.28/bin
    # /usr/local/opt/perl@5.32/bin
    # /usr/local/opt/perl@5.32
    # /usr/local/opt/openssl@1.1/bin
    /usr/{bin,sbin}
    /{bin,sbin}
    /usr/local/opt/curl/bin
    # $HOME/.yarn/bin
    # $HOME/.config/yarn/global/node_modules/.bin
    ${HOME}/.local/bin(N-/)
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
    # ${HOMEBREW_PREFIX}/opt/ruby/bin(N-/)
    # ${HOMEBREW_PREFIX}/lib/ruby/gems/*/bin(Nn[-1]-/)
    /usr/local/{bin,sbin}
    ${HOMEBREW_CELLAR}/git/*/share/git-core/contrib/git-jump(Nn[-1]-/)
    $path
)

for path_file in /etc/paths.d/*(.N); do
  path+=($(<$path_file))
done
unset path_file


fpath+=(
  $ZDOTDIR
  $ZDOTDIR/components
  $ZDOTDIR/completions
  $ZDOTDIR/plugins
  $ZDOTDIR/functions
  $fpath
)

if [[ -d "$TMPDIR" ]]; then
  export TMPPREFIX="${TMPDIR%/}/zsh"
  if [[ ! -d "$TMPPREFIX" ]]; then
    mkdir -p "$TMPPREFIX"
  fi
fi

if [[ -f "$HOME/.asdf/asdf.sh" ]]; then
    source "$ZDOTDIR/components/asdf.zsh"
fi

if [[ "$PLATFORM" == "linux" ]]; then
  alias nvim="VIMRUNTIME=$HOME/builds/neovim/runtime $HOME/builds/neovim/build/bin/nvim"
  # alias fd="fdfind"
fi

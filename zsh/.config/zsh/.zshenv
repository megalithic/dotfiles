# set our working zsh directory
export ZDOTDIR="$HOME/.config/zsh"

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
    $ZDOTDIR
    $ZDOTDIR/components
    $ZDOTDIR/completions
    $ZDOTDIR/plugins
    $ZDOTDIR/functions
    ${ASDF_DIR}/completions
    $fpath
)

#ft=zsh:foldenable:foldmethod=marker:ft=zsh;ts=2;sts=2;sw=2

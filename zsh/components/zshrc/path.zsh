# PATHS
# ===========================================================================
if [ -x /usr/libexec/path_helper ]; then
  # Mac OS X uses path_helper and /etc/paths.d to preload PATH, clear it out first
  PATH=''
  eval `/usr/libexec/path_helper -s`
fi

export GOPATH=$HOME/.go

export PATH="/usr/local/sbin:$PATH"
export PATH="/usr/local/bin:$PATH"
export PATH="/usr/local/lib/node_modules:$PATH"
export PATH="/usr/local/opt/go/libexec/bin:$PATH"
export PATH="/usr/local/opt/gnu-sed/libexec/gnubin:$PATH" # make sure gnu-sed works as sed
export PATH="/usr/local/opt/imagemagick@6/bin:$PATH"
export PATH="/usr/local/opt/qt@5.5/bin:$PATH"
export PATH="$GOPATH/bin:$PATH"
export PATH="$HOME/.dotfiles/bin:$PATH"
export PATH="$HOME/.rubies:$PATH"
export PATH="/usr/local/bin:$PATH"
export PATH="$HOME/.cargo/bin:$PATH"
export PATH="/usr/local/opt/mysql@5.6/bin:$PATH"
export PATH="/usr/local/opt/curl/bin:$PATH"
export PATH="/usr/local/lib/python2.7/site-packages:$PATH"
export PATH="$HOME/Library/Python/3.6/lib/python/site-packages:$PATH"
export PATH="$HOME/.yarn/bin:$HOME/.config/yarn/global/node_modules/.bin:$PATH"

# Find where asdf should be installed.
# ASDF_DIR="${ASDF_DIR:-$HOME/.asdf}"

# Load asdf, if found.
# if [ -f $ASDF_DIR/asdf.sh ]; then
#   . $ASDF_DIR/asdf.sh
# fi

# remove duplicates from PATH.
typeset -U PATH

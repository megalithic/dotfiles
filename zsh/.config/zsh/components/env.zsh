#
# Locations
#

export HOMEDIR=$HOME
export ZDOTDIR=$HOME/.config/zsh
export DOTS=$HOME/.dotfiles
export PRIVATES=$HOME/.dotfiles/private
export DOTDIR=$DOTS
export DOTSDIR=$DOTS
export DOTFILES=$DOTS

export WEECHAT_HOME=$XDG_CONFIG_HOME/weechat

#
# Browser
#

if [[ "$platform" == darwin* ]]; then
  export BROWSER='open'
fi

#
# Editors
#

export EDITOR='nvim'
export VISUAL="$EDITOR"
export SUDO_EDITOR="$EDITOR"
export ALTERNATE_EDITOR='vim'
export PAGER='less'
export MANPAGER="$EDITOR +Man!"
export MANWIDTH=999

# export ALTERNATE_EDITOR=""
# export EDITOR="emacsclient -t"                  # $EDITOR opens in terminal
# export VISUAL="emacsclient -c -a emacs"         # $VISUAL opens in GUI mode

#
# Language
#

if [[ -z "$LANG" ]]; then
  eval "$(locale)"
fi

#
# Less
#

# Set the default Less options.
# Mouse-wheel scrolling has been disabled by -X (disable screen clearing).
# Remove -X and -F (exit if the content fits on one screen) to enable it.
export LESS='-F -g -i -M -R -S -w -X -z-4'

# Set the Less input preprocessor.
if (( $+commands[lesspipe.sh] )); then
  export LESSOPEN='| /usr/bin/env lesspipe.sh %s 2>&-'
fi


export GIT_REPO_DIR="$HOME/dev"
export HOMEBREW_NO_ANALYTICS=1
export HOMEBREW_CASK_OPTS="--appdir=/Applications"
export BREW_PATH="$(brew --prefix)"
export BREW_CASK_PATH="/opt/homebrew-cask/Caskroom"
export TERMINFO=$HOME/.terminfo
# export TERMINFO=/usr/share/terminfo
export LIBARCHIVE=/usr/local/opt/libarchive/lib/libarchive.dylib
export LIBCRYPTO=/usr/local/opt/openssl@1.1/lib/libcrypto.dylib
export _Z_DATA="$HOME/.z-history"
export TERM_ITALICS="TRUE"

export BAT_THEME="base16"
export BAT_CONFIG_PATH="~/.batrc"

export QMK_HOME='~/code/qmk_firmware'

export ZSH_AUTOSUGGEST_HIGHLIGHT_STYLE="fg=23"
export ZSH_AUTOSUGGEST_HIGHLIGHT_STYLE="fg=#6A7D89,bg=#3c4c55" 
export ZSH_AUTOSUGGEST_USE_ASYNC=1

#
# NVIM
#

export NVIMRUNTIME='/usr/local/share/nvim/runtime'
export NVIM_TUI_ENABLE_TRUE_COLOR=1
export NVIM_NODE_LOG_FILE="$DOTS/nvim/nvim-node-debug.log"
# export NVIM_NODE_LOG_LEVEL=debug
export NVIM_PYTHON_LOG_FILE="$DOTS/nvim/nvim-python-debug.log"
# export NVIM_PYTHON_LOG_LEVEL=debug
export NVIM_COC_LOG_LEVEL=debug

# by default: export WORDCHARS='*?_-.[]~=/&;!#$%^(){}<>'
# we take out the slash, period, angle brackets, dash here.
export WORDCHARS='*?_[]~=&;!#$%^(){}'
export ACK_COLOR_MATCH='red'
# export CC=/usr/bin/gcc
export DISPLAY=:0.0

# reduce ESC key delay to 0.1
export KEYTIMEOUT=1

# so I can run USPTO/jboss stuff sensibly
export JAVA_OPTS="$JAVA_OPTS -Xms2048M -Xmx4096M -XX:MaxPermSize=512M -Djboss.vfs.forceCopy=false"
# export JAVA_HOME="/Library/Java/JavaVirtualMachines/jdk1.8.0_66.jdk/Contents/Home"
# export ANDROID_HOME=/usr/local/opt/android-sdk
# export ANDROID_SDK_ROOT=/usr/local/share/android-sdk
export ANDROID_SDK_ROOT="/usr/local/share/android-sdk"

# Enable color in grep
export GREP_OPTIONS='--color=auto'
export GREP_COLOR='3;33'

# This resolves issues install the mysql, postgres, and other gems with native non universal binary extensions
export ARCHFLAGS='-arch x86_64'

# for libffi and ruby things
export LDFLAGS="-L/usr/local/opt/libffi/lib"
export LDFLAGS="-L/usr/local/opt/perl@5.18/lib"
# export LDFLAGS="-I/usr/local/opt/openssl/include -L/usr/local/opt/openssl/lib"
export CPPFLAGS="-I/usr/local/opt/libffi/include"
export PKG_CONFIG_PATH="/usr/local/opt/libffi/lib/pkgconfig"

# OPEN SSL
# =====================================================
# REF: https://github.com/dkarter/dotfiles/commit/9d4ebad752b4de8b2bdfbe204a34b89c1986f33b
export PATH="/usr/local/opt/openssl@1.1/bin:$PATH"

# For compilers to find openssl@1.1 you may need to set:
export LDFLAGS="$LDFLAGS -L/usr/local/opt/openssl@1.1/lib"
export CPPFLAGS="$CPPFLAGS -I/usr/local/opt/openssl@1.1/include"

# For pkg-config to find openssl@1.1 you may need to set:
export PKG_CONFIG_PATH="/usr/local/opt/openssl@1.1/lib/pkgconfig"

# Compile erlang with OpenSSL from Homebrew via asdf
export ERLANG_OPENSSL_PATH="/usr/local/opt/openssl@1.1"
export KERL_CONFIGURE_OPTIONS="--with-ssl=/usr/local/opt/openssl@1.1"


# CTAGS Sorting in VIM/Emacs is better behaved with this in place
export LC_COLLATE=C

# Custom GC options for custom compiled 1.9.3 rubies
export RUBY_GC_MALLOC_LIMIT=1000000000
export RUBY_GC_HEAP_FREE_SLOTS=500000
export RUBY_GC_HEAP_INIT_SLOTS=40000
export RUBY_CONFIGURE_OPTS=--with-readline-dir="$(brew --prefix readline)"

export NODEJS_CHECK_SIGNATURES=no # https://github.com/asdf-vm/asdf-nodejs#use

export ECLIPSE_HOME=/Applications/Eclipse
export SSL_CERT_FILE=''
unset SSL_CERT_FILE

export CURL_CA_BUNDLE=''

# GNUpg setup: https://github.com/drduh/YubiKey-Guide#create-temporary-working-directory-for-gpg
# export GNUPGHOME=$(mktemp -d) #; echo $GNUPGHOME

# export GNUPGHOME="$HOME/.gnupg"

# https://github.com/asdf-vm/asdf-nodejs#using-a-dedicated-openpgp-keyring
# export GNUPGHOME="${ASDF_DIR:-$HOME/.asdf}/keyrings/nodejs" && mkdir -p "$GNUPGHOME" && chmod 0700 "$GNUPGHOME"

# This setting is for the new UTF-8 terminal support
export LC_CTYPE=en_US.UTF-8
export LC_ALL=en_US.UTF-8

# export MYSQL=/usr/local/mysql/bin
# export PATH=$PATH:$MYSQL
export LD_LIBRARY_PATH=$LD_LIBRARY_PATH:.:/usr/local/lib

# elixir and erlang things for `iex`, etc:
export ERL_AFLAGS="-kernel shell_history enabled"

# fixing an issue for weechat and wee-slack: https://blog.phusion.nl/2017/10/13/why-ruby-app-servers-break-on-macos-high-sierra-and-what-can-be-done-about-it/
export OBJC_DISABLE_INITIALIZE_FORK_SAFETY='YES'

# PERL_MM_OPT="INSTALL_BASE=$HOME/perl5" cpan local::lib

# # export LD_LIBRARY_PATH=$LD_LIBRARY_PATH:.:/Users/replicant/.asdf/installs/python/3.8.2/python3.8/config-3.8-darwin/libpython3.8.a
# # export LD_PRELOAD="/Users/replicant/.asdf/installs/python/3.8.2/python3.8/config-3.8-darwin/libpython3.8.a""
# export DYLD_LIBRARY_PATH="/Users/replicant/.asdf/shims"
# # export PYTHONPATH="/Users/replicant/.asdf/shims"
# export LDFLAGS="-L/Users/replicant/.asdf/installs/python/3.8.2/lib"
# export PKG_CONFIG_PATH="/Users/replicant/.asdf/installs/python/3.8.2/lib/pkgconfig"
# export PYTHONPATH="$DYLD_LIBRARY_PATH:$LDFLAGS:$PKG_CONFIG_PATH:$PYTHONPATH"

# export LDFLAGS="-L/usr/local/opt/openssl/lib"
# export CPPFLAGS="-I/usr/local/opt/openssl/include"
# export PKG_CONFIG_PATH="/usr/local/opt/openssl/lib/pkgconfig"

export LDFLAGS="-L/usr/local/opt/openssl@1.1/lib"
export CPPFLAGS="-I/usr/local/opt/openssl@1.1/include"
export PKG_CONFIG_PATH="/usr/local/opt/openssl@1.1/lib/pkgconfig"

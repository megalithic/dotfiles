#!/usr/bin/env zsh


# we're on a familiar distro (debian based)
if [ -f "/etc/debian_version" ]; then
  export XDG_CONFIG_HOME="$HOME/.config"

  log "installing necessary deps"
  # install some deps..
  sudo apt-get -y install linux-headers-$(uname -r) build-essential autoconf m4 libncurses5-dev libwxgtk3.0-gtk3-dev libgl1-mesa-dev libglu1-mesa-dev libpng-dev libssh-dev unixodbc-dev xsltproc fop libxml2-utils libncurses-dev openjdk-11-jdk ninja-build gettext libtool libtool-bin autoconf automake cmake g++ pkg-config unzip zsh lib32readline-dev libreadline-dev dirmngr gpg curl && log_ok "DONE installing linux deps" || log_error "failed to install linux deps"

  log "installing neovim nightly"
  # install neovim nightly please..
  # REF: https://dev.to/creativenull/installing-neovim-nightly-alongside-stable-10d0
  [[ ! -d "$HOME/builds" ]] && mkdir -p $HOME/builds

  if [ ! -d "$HOME/builds/neovim" ]; then
    git clone https://github.com/neovim/neovim.git $HOME/builds/neovim
  fi

  cd $HOME/builds/neovim
  git fetch && git merge origin/master

  make distclean && make CMAKE_BUILD_TYPE=Release && log_ok "DONE building and installing neovim nightly" || log_error "failed to install neovim nightly"
  cd -

  log_warn "to launch neovim nightly, use: VIMRUNTIME=$HOME/builds/neovim/runtime $HOME/builds/neovim/build/bin/nvim"
fi

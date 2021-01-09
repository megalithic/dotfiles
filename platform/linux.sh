#!/usr/bin/env zsh


# we're on a familiar distro (debian based)
if [ -f "/etc/debian_version" ]; then
  log "-> installing necessary deps"
  # install some deps..
  sudo apt-get -y install build-essential autoconf m4 libncurses5-dev libwxgtk3.0-gtk3-dev libgl1-mesa-dev libglu1-mesa-dev libpng-dev libssh-dev unixodbc-dev xsltproc fop libxml2-utils libncurses-dev openjdk-11-jdk ninja-build gettext libtool libtool-bin autoconf automake cmake g++ pkg-config unzip zsh

  log "-> installing neovim nightly"
  # install neovim nightly please..
  # REF: https://dev.to/creativenull/installing-neovim-nightly-alongside-stable-10d0
  mkdir -p $HOME/builds
  git clone https://github.com/neovim/neovim.git $HOME/builds/neovim
  cd $HOME/builds/neovim
  make CMAKE_BUILD_TYPE=Release
  cd -

  log_warn "to launch neovim nightly, use: VIMRUNTIME=$HOME/neovim/runtime $HOME/neovim/build/bin/nvim
"
fi

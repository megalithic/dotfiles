#!/usr/bin/env zsh

log "-> linux-specific configuration.."

echo ""
echo ":: setting up linux system related things"
echo ""

# we're on a familiar distro (debian based)
if [ -f "/etc/debian_version" ]; then
  # install some deps..
  sudo apt-get install ninja-build gettext libtool libtool-bin autoconf automake cmake g++ pkg-config unzip

  # install neovim nightly please..
  # REF: https://dev.to/creativenull/installing-neovim-nightly-alongside-stable-10d0
  mkdir -p $HOME/builds
  git clone https://github.com/neovim/neovim.git $HOME/builds/neovim
  cd $HOME/builds/neovim
  make CMAKE_BUILD_TYPE=Release
  cd -
fi

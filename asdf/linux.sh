#!/usr/bin/env zsh

# we're on a familiar distro (debian-based)
if [ -f "/etc/debian_version" ]; then
  log "-> installing asdf dependencies for linux"

  #erlang specific requirements:
  # sudo apt-get -y install build-essential git wget libssl-dev libreadline-dev libncurses5-dev zlib1g-dev m4 curl wx-common libwxgtk3.0-dev autoconf

  #erlang specific requirements:
  sudo apt-get -y install build-essential autoconf m4 libncurses5-dev libwxgtk3.0-gtk3-dev libgl1-mesa-dev libglu1-mesa-dev libpng-dev libssh-dev unixodbc-dev xsltproc fop libxml2-utils libncurses-dev openjdk-11-jdk

  # echo '. $HOME/.asdf/asdf.sh' >> ~/.bashrc
  # echo '. $HOME/.asdf/completions/asdf.bash' >> ~/.bashrc
  echo -e '\n. $HOME/.asdf/asdf.sh' >> ~/.profile
  echo -e '\n. $HOME/.asdf/completions/asdf.bash' >> ~/.bashrc

  source $DOTS/asdf/all.sh
fi


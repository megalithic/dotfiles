#!/usr/bin/env zsh

# we're on a familiar distro (debian-based)
if [ -f "/etc/debian_version" ]; then
  log "-> installing asdf dependencies for linux"

  #erlang specific requirements:
  sudo apt-get install build-essential git wget libssl-dev libreadline-dev libncurses5-dev zlib1g-dev m4 curl wx-common libwxgtk3.0-dev autoconf

  #erlang specific requirements:
  sudo apt-get install libxml2-utils xsltproc fop unixodbc unixodbc-bin unixodbc-dev

  echo '. $HOME/.asdf/asdf.sh' >> ~/.bashrc
  echo '. $HOME/.asdf/completions/asdf.bash' >> ~/.bashrc

  source $DOTS/asdf/all.sh
fi


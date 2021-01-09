#!/usr/bin/env zsh

# we're on a familiar distro (debian-based)
if [ -f "/etc/debian_version" ]; then
  log "-> asdf configuration for linux"

  # echo '. $HOME/.asdf/asdf.sh' >> ~/.bashrc
  # echo '. $HOME/.asdf/completions/asdf.bash' >> ~/.bashrc
  echo -e '\n. $HOME/.asdf/asdf.sh' >> ~/.profile
  echo -e '\n. $HOME/.asdf/completions/asdf.bash' >> ~/.bashrc

  source $DOTS/asdf/all.sh
fi


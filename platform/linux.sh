#!/usr/bin/env zsh


# we're on a familiar distro (debian based)
if [ -f "/etc/debian_version" ]; then
  export XDG_CONFIG_HOME="$HOME/.config"
  builds_path = "$HOME/builds"

  [[ ! -d "$builds_path" ]] && mkdir -p $builds_path

  log "installing necessary deps"
  sudo apt-get -y install linux-headers-$(uname -r) build-essential autoconf m4 libncurses5-dev libwxgtk3.0-gtk3-dev libgl1-mesa-dev libglu1-mesa-dev libpng-dev libssh-dev unixodbc-dev xsltproc fop libxml2-utils libncurses-dev openjdk-11-jdk ninja-build gettext libtool libtool-bin autoconf automake cmake g++ pkg-config unzip zsh lib32readline-dev libreadline-dev dirmngr gpg curl exa libgsl-dev && log_ok "DONE installing linux deps" || log_error "failed to install linux deps"

  log "installing gitstatus for zsh"
  git clone --depth=1 https://github.com/romkatv/gitstatus.git $builds_path/gitstatus

  log "installing zsh addons"
  git clone https://github.com/zsh-users/zsh-autosuggestions.git $builds_path/zsh-autosuggestions
  git clone https://github.com/zsh-users/zsh-syntax-highlighting.git $builds_path/zsh-syntax-highlighting
  git clone https://github.com/zsh-users/zsh-history-substring-search $builds_path/zsh-history-substring-search

  log "installing neovim nightly"
  # REF: https://dev.to/creativenull/installing-neovim-nightly-alongside-stable-10d0
  if [ ! -d "$builds_path/neovim" ]; then
    git clone https://github.com/neovim/neovim.git $builds_path/neovim
  fi

  cd $builds_path/neovim
  git fetch && git merge origin/master

  skip_message="skipping clean"
  vared -p "[?] clean before the rebuild? [yN]" -c continue_reply

  case $continue_reply in
    [Yy]) make distclean && log_ok "DONE dist-cleaning" || log_error "failed to make distclean" ;;
    [Nn]) log_warn "$skip_message" ;;
    *) log_warn "$skip_message" ;;
  esac

  make CMAKE_BUILD_TYPE=Release && log_ok "DONE building and installing neovim nightly" || log_error "failed to build and install neovim nightly"
  cd -
fi

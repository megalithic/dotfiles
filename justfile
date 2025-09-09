default:
  @just --list

# update your flake.lock
update-flake:
  #!/usr/bin/env bash
  set -euxo pipefail
  nix flake update
  if git diff --exit-code flake.lock > /dev/null 2>&1; then
    echo "no changes to flake.lock"
  else
    echo "committing flake.lock"
    git add flake.lock
    git commit -m "chore(nix): update flake.lock"
  fi

# run home-manager switch
hm:
  home-manager switch --flake ~/.dotfiles -b backup

# rebuild nix darwin
[macos]
rebuild:
  sudo darwin-rebuild switch --flake ~/.dotfiles

# update and upgrade homebrew packages
[macos]
update-brew:
  brew update && brew upgrade

# fix shell files. this happens sometimes with nix-darwin
[macos]
fix-shell-files:
  #!/usr/bin/env bash
  set -euxo pipefail

  sudo mv /etc/zshenv /etc/zshenv.before-nix-darwin
  sudo mv /etc/zshrc /etc/zshrc.before-nix-darwin
  sudo mv /etc/bashrc /etc/bashrc.before-nix-darwin

# updates brew, flake, and runs home-manager
[macos]
update: update-brew update-flake hm

news:
  home-manager news --flake .


# legacy dotbot usages
[macos]
link:
  source ~/.dotfiles/install --only link

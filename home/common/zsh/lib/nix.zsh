#!/usr/bin/env zsh

if [[ -e "/nix/var/nix/profiles/default/etc/profile.d/nix-daemon.sh" ]]; then
  source "/nix/var/nix/profiles/default/etc/profile.d/nix-daemon.sh"
fi

alias ns="nix-shell"
alias nsp="nix-shell --pure"
alias nsz="nix-shell --run zsh"
alias nda="direnv allow ."

# echo "$([[ -n $IN_NIX_SHELL ]] && mise deactivate)"

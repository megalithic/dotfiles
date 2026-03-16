#!/usr/bin/env bash
set -euo pipefail

echo "🚀 Initializing megadotfiles..."

if ! command -v nix &>/dev/null; then
  echo "📦 Installing Nix (prefer Determinate Nix)..." &&
    curl --proto '=https' --tlsv1.2 -sSf -L https://install.determinate.systems/nix | sh -s -- install --determinate
  # curl --proto '=https' --tlsv1.2 -sSf -L https://install.determinate.systems/nix | sh -s -- install macos --case-sensitive --determinate
  # curl --proto '=https' --tlsv1.2 -sSf -L https://install.determinate.systems/nix | sh -s -- install --case-sensitive --determinate

  # sh <(curl -L https://nixos.org/nix/install) --daemon
  # echo "✅ Nix installed - please restart your shell and run this script again"
  exit 0
else
  echo "✅ Nix already installed: $(nix --version)"
fi

source "/nix/var/nix/profiles/default/etc/profile.d/nix-daemon.sh" &&
  echo "✅ Sourced Nix ($(nix --version)); ready to use!" || echo "❌ Unable to find Nix; you may need to restart your shell and source '/nix/var/nix/profiles/default/etc/profile.d/nix-daemon.sh' "

echo "📦 Installing dotfiles..." &&
  nix run github:megalithic/dotfiles

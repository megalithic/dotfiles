# Dotfiles docs

This directory documents durable design decisions for this single-flake nix-darwin + Home Manager repo, split into topic files for faster agent lookup.

Top-level topics:

- [[architecture]] — flake topology, `lib.mega` and builders, custom package overlay, out-of-store config symlinks, rebuilds, devenv, secrets, linting, and agent policy.
- [[system-config]] — nix-darwin layer: hosts, Determinate Nix, Homebrew/`mas`, darwin modules, Spotlight exclusions.
- [[home-configs]] — Home Manager layer: module auto-import, package/app composition, per-tool conventions, fish/tmux helpers, and the full config index.
- [[migration]] — migration plans that change the dotfiles ownership model.
- [[programs]] — per-program deep dives for the intricate tools (Pi, Neovim/pinvim, Helium, Hammerspoon, Ghostty).

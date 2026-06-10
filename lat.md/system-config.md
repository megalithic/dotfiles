# System configuration (nix-darwin)

This file covers the nix-darwin layer: shared host settings, per-host overrides, Homebrew, Mac App Store, and the darwin modules. Apply with `just darwin`.

## Host layout

`hosts/common.nix` holds settings shared by every host; `hosts/megabookpro.nix` and `hosts/workbookpro.nix` carry per-host overrides. The builder passes `username`, `hostname`, `paths`, and `arch` through special args.

`hosts/common.nix` sets system fonts, the `seth` user (uid 501, fish shell), hostname, timezone (`America/New_York`), and locale (`en_US.UTF-8`). It defines system-wide `environment.variables` including editor (`nvim-nightly`), pager, XDG paths, project paths (`CODE`, `DOTS`), cloud-storage paths, tmux layout paths, and FZF defaults, plus a minimal `environment.systemPackages` set.

Bootstrap-critical packages stay in `hosts/common.nix` `environment.systemPackages` because they are needed before Home Manager runs: `just`, `git`, `curl`, `vim`, plus core archive and nix tooling.

## Determinate Nix integration

`nix.enable = false` because Determinate Nix owns `/etc/nix/nix.conf`.

The repo generates `/etc/nix/nix.custom.conf` declaratively (trusted users, extra substituters, `keep-derivations`, `keep-outputs`, `warn-dirty = false`), which Determinate's config includes.

`environment.systemPath` explicitly adds `/nix/var/nix/profiles/system/sw/bin` and `/opt/homebrew/bin` because Determinate Nix does not create the `/run/current-system` symlink.

System programs enabled in common include `bash`, `fish` (with babelfish), and `gnupg.agent` with SSH support. `services.tailscale.enable = true`. The SSH auth socket points at 1Password's agent through `environment.extraInit`.

## Homebrew and Mac App Store

Homebrew is the last-resort path for casks and apps that resist Nix packaging. `nix-homebrew` is configured in the flake `brew_config` with Rosetta enabled, auto-migrate on, immutable taps, and the four Homebrew taps wired from flake inputs.

`modules/brew.nix` declares Homebrew casks and `homebrew.masApps` for Mac App Store apps. `brew-nix` provides a cask overlay used for `mas` packaging.

## Darwin modules

`modules/` holds the nix-darwin modules: `system.nix` for core system settings, `brew.nix` for Homebrew, and `darwin/` for `kanata.nix`, `services.nix`, and `spotlight.nix`. Custom kanata support also comes from the `kanata-darwin` flake input.

## Spotlight exclusions

`spotlight.exclusions` (from `modules/darwin/spotlight.nix`) prevents Spotlight from indexing build artifacts, dependencies, and devenv state.

It seeds exclusion patterns from `home/common/programs/git/gitignore` plus explicit paths such as `node_modules`, `.devenv`, `.direnv`, `_build`, `deps`, and Elixir tool caches, scanning under `~/code`. Hosts can extend it via `spotlight.exclusions.paths` and `scanPaths`.

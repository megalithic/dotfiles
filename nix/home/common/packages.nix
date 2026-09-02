{
  pkgs,
  lib,
  ...
}:
let
  # ── gui tools ──────────────────────────────────────────────────────────────────
  # Custom apps built with mkApp - these have passthru.appLocation
  customApps = [ ];

  # Filter: only apps with appLocation = "home-manager" go to home.packages
  # (home-manager copies these to ~/Applications/Home Manager Apps/)
  homeManagerApps = builtins.filter (
    pkg: ((pkg.passthru or { }).appLocation or "home-manager") == "home-manager"
  ) customApps;

  # Standard GUI apps from nixpkgs (not custom mkApp derivations)
  guiPkgs = [ ];

  # GUI apps from brew-nix overlay (pkgs.brewCasks.*) — migrated from
  # nix-darwin homebrew.casks. Tokens with leading digits or '@' need
  # string-keyed access. Handled elsewhere (not brewCasks):
  #   1password    — nix-darwin programs._1password*, see modules/darwin/_1password.nix
  brewCaskPkgs = [ ];

  # ── cli tools ──────────────────────────────────────────────────────────────────
  # NOTE: Some tools are enabled via programs.* (auto-installs package):
  #   bat, eza, fd, ripgrep, starship, zoxide, mise, k9s
  cliPkgs = with pkgs; [
    amber
    argc
    awscli2
    blueutil
    chafa
    curlie
    desktoppr # declarative wallpaper setter
    devbox
    # devenv # managed by programs/devenv module
    # gh — mise github-cli owns it (CLI dedupe 2026-08)
    # hunk — installed via mise (aqua:modem-dev/hunk + npm:hunkdiff); nix flake
    # input dropped 2026-07-20: bun2nix master broke eval and mise ships newer
    inetutils # telnet, ftp, etc.
    # jq — mise owns it (CLI dedupe 2026-08); nix modules keep using ${pkgs.jq} store paths
    # just — mise owns user-level just; bootstrap copy stays in hosts/common.nix systemPackages
    jwt-cli
    ldns # DNS tools (drill)
    libvterm-neovim
    libwebp # WebP image tools
    magika
    # mas — mise owns it (brew:mas + mas:497799835 Xcode); HM mas module removed 2026-08
    mprocs
    netcat # nc networking utility
    nix-update
    nix-search-cli
    openconnect
    openvpn
    procs
    switchaudio-osx
    tesseract # OCR fallback for clipper (Vision is primary)
    tldr
    transcrypt
    whisperkit-cli # Apple Silicon Whisper speech recognition (was homebrew formula)
    w3m
    yq # YAML processor (jq for YAML)
    yubikey-personalization
  ];

  # ── fonts ──────────────────────────────────────────────────────────────────────
  # NOTE: Fonts moved to nix-darwin (hosts/common.nix) via fonts.packages
  # This ensures they're installed system-wide to /Library/Fonts/Nix Fonts
  # where macOS apps (Hammerspoon, Terminal, etc.) can find them.

  # ── languages & toolchains ─────────────────────────────────────────────────────
  langPkgs = with pkgs; [
    harper # grammar checker

    # kubernetes
    # lua
    lua54Packages.luacheck
    lua54Packages.luarocks

    # docker (CLI provided by OrbStack, installed via brew cask)
    docker-compose-language-service
    dockerfile-language-server
    podman

    # node/js/ts — node binary is mise-owned (CLI dedupe 2026-08)
    vue-language-server

    # nix
    alejandra
    nil
    nixfmt

    # markdown
  ];
in
{
  # Export customApps for mkAppActivation (used in default.nix)
  # These are ALL custom apps regardless of appLocation
  # Other modules can extend this with: mega.customApps = [ pkgs.myApp ];
  options.mega.customApps = lib.mkOption {
    type = lib.types.listOf lib.types.package;
    default = [ ];
    description = "Custom apps built with mkApp for activation script processing";
  };

  config.mega.customApps = customApps;

  config.home.packages = cliPkgs ++ langPkgs ++ guiPkgs ++ brewCaskPkgs ++ homeManagerApps;
}

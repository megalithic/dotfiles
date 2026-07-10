{
  pkgs,
  lib,
  inputs,
  ...
}:
let
  # ── gui tools ──────────────────────────────────────────────────────────────────
  # Custom apps built with mkApp - these have passthru.appLocation
  customApps = with pkgs; [
    tidewave # Tidewave GUI app for web app development
    tidewave-cli # Tidewave MCP CLI
    # bloom
    # mailmate app managed via home/common/programs/mailmate/default.nix
  ];

  # Filter: only apps with appLocation = "home-manager" go to home.packages
  # (home-manager copies these to ~/Applications/Home Manager Apps/)
  homeManagerApps = builtins.filter (
    pkg: ((pkg.passthru or { }).appLocation or "home-manager") == "home-manager"
  ) customApps;

  hunk = inputs.hunk.packages.${pkgs.stdenv.hostPlatform.system}.hunk;

  # Standard GUI apps from nixpkgs (not custom mkApp derivations)
  guiPkgs = with pkgs; [
    iina # migrated from homebrew 2026-02-13
    inkscape # migrated from homebrew 2026-02-13
    # neovide # Native neovim GUI - potential future use for floating notes window
    obsidian
    slack # migrated from homebrew 2026-02-13
    # spotify
    # telegram-desktop
    zoom-us
  ];

  # GUI apps from brew-nix overlay (pkgs.brewCasks.*) — migrated from
  # nix-darwin homebrew.casks. Tokens with leading digits or '@' need
  # string-keyed access. Handled elsewhere (not brewCasks):
  #   okta-verify  — privileged .pkg installer, see modules/darwin/okta-verify.nix
  #   1password    — nix-darwin programs._1password*, see modules/darwin/_1password.nix
  brewCaskPkgs = [
    pkgs.brewCasks."obs@beta"
  ];

  # ── cli tools ──────────────────────────────────────────────────────────────────
  # NOTE: Some tools are enabled via programs.* (auto-installs package):
  #   bat, eza, fd, ripgrep, starship, zoxide, mise, k9s
  cliPkgs = with pkgs; [
    amber
    apfel-llm # Apple Intelligence CLI/server — shade-next compact_ai interpreter
    argc
    awscli2
    bash # macOS ships with ancient bash
    blueutil
    chafa
    curlie
    delta
    difftastic
    desktoppr # declarative wallpaper setter
    devbox
    # devenv # managed by programs/devenv module
    difftastic
    dust # disk usage analyzer (du replacement)
    espanso
    ffmpeg
    flyctl
    gh
    git-lfs
    gnupg
    gum
    hunk
    imagemagickBig
    inetutils # telnet, ftp, etc.
    jq # JSON processor
    just # command runner
    jwt-cli
    ldns # DNS tools (drill)
    libvterm-neovim
    libwebp # WebP image tools
    magika
    mas
    mprocs
    netcat # nc networking utility
    nix-update
    nix-search-cli
    openconnect
    openssl_3
    openvpn
    pre-commit
    procs
    s3cmd
    sox # audio recording/processing for whisper dictation
    sqlite
    switchaudio-osx
    tesseract # OCR fallback for clipper (Vision is primary)
    tldr
    transcrypt
    tmux
    whisperkit-cli # Apple Silicon Whisper speech recognition (was homebrew formula)
    w3m
    yq # YAML processor (jq for YAML)
    yubikey-manager
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
    k9s
    kubectl
    kubernetes-helm
    kubie

    # lua (use lowPrio on 5.1 to avoid fish completion collision with 5.4)
    (lib.lowPrio lua5_1)
    lua5_4
    lua-language-server
    lua54Packages.luacheck
    lua54Packages.luarocks
    stylua

    # shell
    shellcheck
    shfmt

    # docker (CLI provided by OrbStack, installed via brew cask)
    docker-compose-language-service
    dockerfile-language-server
    podman

    # node/js/ts
    nodejs_22
    pnpm
    vue-language-server

    # python
    basedpyright
    python313
    python313Packages.ipython
    python313Packages.pip
    python313Packages.sqlfmt
    python313Packages.websocket-client
    python313Packages.websockets
    python313Packages.pdf2image
    uv

    # nix
    alejandra
    nil
    nix-direnv
    nixfmt

    # markdown
    markdown-oxide
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

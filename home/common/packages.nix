{
  config,
  pkgs,
  lib,
  ...
}: let
  # ── gui tools ──────────────────────────────────────────────────────────────────
  # Custom apps built with mkApp - these have passthru.appLocation
  customApps = with pkgs; [
    # bloom
    fantastical
    tidewave # Tidewave GUI app for web app development
    tidewave-cli # Tidewave MCP CLI
    # mailmate app managed via home/common/programs/mailmate/default.nix
  ];

  # Filter: only apps with appLocation = "home-manager" go to home.packages
  # (home-manager copies these to ~/Applications/Home Manager Apps/)
  homeManagerApps =
    builtins.filter (
      pkg: (pkg.passthru or {}).appLocation or "home-manager" == "home-manager"
    )
    customApps;

  # Standard GUI apps from nixpkgs (not custom mkApp derivations)
  guiPkgs = with pkgs; [
    iina # migrated from homebrew 2026-02-13
    inkscape # migrated from homebrew 2026-02-13
    # neovide # Native neovim GUI - potential future use for floating notes window
    obsidian
    shade # Floating terminal panel for macOS (prebuilt from GitHub release v0.1.0)
    slack # migrated from homebrew 2026-02-13
    spotify
    # telegram-desktop
    vscode # migrated from homebrew cask 2026-05-05 (brew-nix can't extract Electron symlinks)
    zed-editor # migrated from homebrew cask 2026-05-05
    zoom-us
  ];

  # GUI apps from brew-nix overlay (pkgs.brewCasks.*) — migrated from
  # nix-darwin homebrew.casks. Tokens with leading digits or '@' need
  # string-keyed access. Excluded:
  #   raycast      — zlib-wrapped DMG, brew-nix's 7zz can't unpack
  #   okta-verify  — .pkg with URL-encoded paths, cpio/gzip pipeline fails
  # Both stay in modules/brew.nix until upstream fixes packaging.
  brewCaskPkgs = (with pkgs.brewCasks; [
    colorsnapper
    contexts
    hammerspoon
    homerow
    kitty
    mouseless
    protonvpn
    proton-drive
    yubico-authenticator
  ]) ++ [
    pkgs.brewCasks."1password"
    pkgs.brewCasks."1password-cli"
    pkgs.brewCasks."obs@beta"
  ];

  # ── cli tools ──────────────────────────────────────────────────────────────────
  # NOTE: Some tools are enabled via programs.* (auto-installs package):
  #   bat, eza, fd, ripgrep, starship, zoxide, mise, k9s
  cliPkgs = with pkgs; [
    amber
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
    devenv
    difftastic
    dust # disk usage analyzer (du replacement)
    espanso
    ffmpeg
    flyctl
    gh
    git-lfs
    gnupg
    gum
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
    ollama # local LLM for AI-powered note summarization
    openconnect
    openssl_3
    openvpn
    poppler
    pre-commit
    procs
    s3cmd
    sox # audio recording/processing for whisper dictation
    sqlite
    switchaudio-osx
    tesseract # OCR fallback for clipper (Vision is primary)
    tldr
    transcrypt
    unstable.tmux
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
in {
  # Export customApps for mkAppActivation (used in default.nix)
  # These are ALL custom apps regardless of appLocation
  # Other modules can extend this with: mega.customApps = [ pkgs.myApp ];
  options.mega.customApps = lib.mkOption {
    type = lib.types.listOf lib.types.package;
    default = [];
    description = "Custom apps built with mkApp for activation script processing";
  };

  config.mega.customApps = customApps;

  config.home.packages = cliPkgs ++ langPkgs ++ guiPkgs ++ brewCaskPkgs ++ homeManagerApps;
}

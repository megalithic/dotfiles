{
  config,
  pkgs,
  lib,
  ...
}: let
  # ── gui tools ──────────────────────────────────────────────────────────────────
  # Custom apps built with mkApp - these have passthru.appLocation
  customApps = with pkgs; [
    bloom
    fantastical
    helium-browser
    # tidewave GUI app moved to home/programs/ai/default.nix
    tuna # Menu bar app that fixes audio in video calls
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
    neovide # Native neovim GUI - potential future use for floating notes window
    obsidian
    # shade  # FIXME: Disabled - GhosttyKit build failing, see overlays/default.nix
    slack # migrated from homebrew 2026-02-13
    spotify
    telegram-desktop
    zoom-us
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
    desktoppr # declarative wallpaper setter
    devbox
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
    w3m
    yq # YAML processor (jq for YAML)
    yubikey-manager
    yubikey-personalization
  ];

  # ── fonts ──────────────────────────────────────────────────────────────────────
  fontPkgs = with pkgs; [
    atkinson-hyperlegible
    emacs-all-the-icons-fonts
    fira-code
    fira-mono
    font-awesome
    inter
    jetbrains-mono
    maple-mono.NF
    maple-mono.truetype
    maple-mono.variable
    nerd-fonts.fantasque-sans-mono
    nerd-fonts.fira-code
    nerd-fonts.iosevka
    nerd-fonts.jetbrains-mono
    nerd-fonts.symbols-only
    nerd-fonts.victor-mono
    # nerd-fonts.berkeley-mono
    noto-fonts-color-emoji
    twemoji-color-font
    victor-mono
  ];

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

    # docker
    colima
    docker
    docker-compose
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
    nixfmt-rfc-style

    # markdown
    markdown-oxide
  ];
in {
  # Export customApps for mkAppActivation (used in default.nix)
  # These are ALL custom apps regardless of appLocation
  options.mega.customApps = lib.mkOption {
    type = lib.types.listOf lib.types.package;
    default = customApps;
    description = "Custom apps built with mkApp for activation script processing";
  };

  config.home.packages = cliPkgs ++ fontPkgs ++ langPkgs ++ guiPkgs ++ homeManagerApps;
}

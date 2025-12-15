{
  config,
  pkgs,
  ...
}: let
  # ── gui tools ──────────────────────────────────────────────────────────────────
  guiPkgs = with pkgs; [
    telegram-desktop
  ];

  # ── cli tools ──────────────────────────────────────────────────────────────────
  cliPkgs = with pkgs; [
    amber
    argc
    desktoppr # declarative wallpaper setter
    awscli2
    bash # macOS ships with ancient bash
    blueutil
    chafa
    curlie
    delta
    devbox
    difftastic
    espanso
    ffmpeg
    flyctl
    gh
    git-lfs
    gum
    jwt-cli
    libvterm-neovim
    magika
    mas
    mprocs
    nix-update
    obsidian
    openconnect
    openssl_3
    poppler
    pre-commit
    procs
    ripgrep
    s3cmd
    sqlite
    switchaudio-osx
    terminal-notifier
    unstable.tmux
    transcrypt
    w3m
    yubikey-manager
    yubikey-personalization
    zoom-us
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
    noto-fonts-color-emoji
    twemoji-color-font
    victor-mono
  ];

  # ── languages & toolchains ─────────────────────────────────────────────────────
  langPkgs = with pkgs; [
    # rust
    cargo
    harper

    # kubernetes
    k9s
    kubectl
    kubernetes-helm
    kubie

    # lua (use lowPrio on 5.1 to avoid fish completion collision with 5.4)
    (lib.lowPrio lua5_1)
    lua5_4
    lua-language-server
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
  home.packages = cliPkgs ++ fontPkgs ++ langPkgs ++ guiPkgs;
}

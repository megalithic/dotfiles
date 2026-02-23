{
  lib,
  pkgs,
  config,
  username,
  ...
}: {
  # Use .vimrc for standard vim settings
  # xdg.configFile."nvim/.vimrc".source = nvim/.vimrc;
  # xdg.configFile."nvim/.vimrc".source = nvim-next/.vimrc;

  # Create folders for backups, swaps, and undo
  home.activation.mkdirNvimFolders = lib.hm.dag.entryAfter ["writeBoundary"] ''
    mkdir -p $HOME/.config/nvim/backups $HOME/.config/nvim/swaps $HOME/.config/nvim/undo
  '';

  xdg.configFile = {
    ripgrep_ignore.text = ''
      .git/
      yarn.lock
      package-lock.json
      packer_compiled.lua
      .DS_Store
      .netrwhist
      dist/
      node_modules/
      **/node_modules/
      wget-log
      wget-log.*
      /vendor
    '';
    nvim = {
      source = config.lib.mega.linkConfig "nvim";
      recursive = true;
    };
  };

  programs.neovim = {
    enable = true;
    defaultEditor = true;
    package = pkgs.nvim-nightly;
    withPython3 = true;
    withNodeJs = true;
    withRuby = true;
    vimdiffAlias = true;
    vimAlias = true;
    extraWrapperArgs =
      [
        # "--set"
        # "NVIM_RUST_ANALYZER"
        # "${pkgs.rust-analyzer}/bin/rust-analyzer"
        "--set"
        "LIBSQLITE"
      ]
      ++ ["${pkgs.sqlite.out}/lib/libsqlite3.dylib"];
    extraPackages = with pkgs; [
      # actionlint
      # bash-language-server
      # biome
      # black
      # bun
      # cmake
      # copilot-language-server
      # deno
      # dotenv-linter
      # expert
      # gcc # For treesitter compilation
      # git
      # gnumake # For various build processes
      # golangci-lint
      # gopls
      # gotools
      # hadolint # Docker linter
      # isort
      # lua51Packages.luarocks
      # nixd # nix lsp
      # nixfmt-rfc-style # cannot be installed via Mason on macOS, so installed here instead
      # nodePackages.prettier
      # par
      # pngpaste # For Obsidian paste_img command
      # ruff
      # shfmt # Doesn't work with zsh, only sh & bash
      # statix
      # stylelint-lsp
      # # (tailwindcss-language-server.override {nodejs_latest = nodejs_22;})
      # taplo # TOML linter and formatter
      # tree-sitter # required for treesitter "auto-install" option to work
      # typos
      # typos-lsp
      # typst
      # uv
      # vscode-langservers-extracted # HTML, CSS, JSON & ESLint LSPs
      # vtsls # js/ts LSP
      # yaml-language-server

      # for compiling Treesitter parsers
      gcc
      tree-sitter

      # debuggers
      lldb # comes with lldb-vscode

      # formatters and linters
      alejandra
      biome
      eslint_d
      nixfmt
      nixfmt-rfc-style
      prettierd
      rustfmt
      selene
      shfmt
      statix
      stylua
      yamlfmt

      # LSP servers
      bash-language-server
      basedpyright
      # cargo # sometimes required for rust-analyzer to work
      copilot-language-server
      gopls
      graphql-language-service-cli
      harper
      just-lsp
      llvmPackages.clang-tools
      # lua (use lowPrio on 5.1 to avoid fish completion collision with 5.4)
      (lib.lowPrio lua5_1)
      lua5_4
      lua-language-server
      markdown-oxide
      nil
      nixd
      nodePackages_latest.typescript-language-server
      nodejs
      ruff
      rust-analyzer
      shellcheck
      taplo
      typos
      typos-lsp
      typst
      vscode-langservers-extracted # this includes css-lsp, html-lsp, json-lsp, eslint-lsp
      yaml-language-server

      # other utils and plugin dependencies
      cargo
      cargo-nextest
      clippy
      curl
      fd
      fzf
      gh
      glow
      gnumake
      imagemagick
      jq
      lemmy-help
      mariadb
      openssl
      pngpaste
      ripgrep
      sqlite
      uv
      yq-go
    ];
  };
}

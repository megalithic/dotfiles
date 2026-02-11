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

  xdg.configFile."nvim".source = config.lib.mega.linkConfig "nvim";
  # xdg.configFile."nvim/lua/nix_provided.lua" = with pkgs; {
  #   text = ''
  #     return {
  #       -- bashls = { "${unstable.nodePackages.bash-language-server}/bin/bash-language-server", "start" },
  #       -- dockerls = { "${unstable.dockerfile-language-server}/bin/docker-langserver", "--stdio" },
  #       -- elixirls = { "${unstable.elixir-ls}/bin/elixir-ls" },
  #       -- eslint = { "${unstable.vscode-langservers-extracted}/bin/vscode-eslint-language-server", "--stdio" },
  #       -- html = { "${unstable.vscode-langservers-extracted}/bin/vscode-html-language-server", "--stdio" },
  #       -- jsonls = { "${unstable.vscode-langservers-extracted}/bin/vscode-json-language-server", "--stdio" },
  #       -- cssls = { "${unstable.vscode-langservers-extracted}/bin/vscode-css-language-server", "--stdio" },
  #       -- ts_ls = { "${unstable.nodePackages.typescript-language-server}/bin/typescript-language-server", "--stdio" },
  #       -- vue_ls = { "${unstable.vue-language-server}/bin/vue-language-server", "--stdio" },
  #       -- nil_ls = { "${unstable.nil}/bin/nil" },
  #       -- lua_ls = { "${unstable.lua-language-server}/bin/lua-language-server" },
  #       -- vue_ts_plugin = "${unstable.vue-language-server}/lib/node_modules/@vue/language-server",
  #       -- vtsls = { "${unstable.vtsls}/bin/vtsls", "--stdio" },
  #       -- awesomewm_lib = "${pkgs.awesome-git}/share/awesome/lib",
  #       -- expert = { "${pkgs.expert-lsp}/bin/expert-lsp", "--stdio" }
  #     }
  #   '';
  # };
  #
  programs.neovim = {
    enable = true;
    defaultEditor = true;
    package = pkgs.nvim-nightly;
    withPython3 = true;
    withNodeJs = true;
    withRuby = true;
    vimdiffAlias = true;
    vimAlias = true;
    extraPackages = with pkgs; [
      actionlint
      bash-language-server
      biome
      black
      bun
      cmake
      copilot-language-server
      deno
      dotenv-linter
      expert
      gcc # For treesitter compilation
      git
      gnumake # For various build processes
      golangci-lint
      gopls
      gotools
      hadolint # Docker linter
      isort
      lua51Packages.luarocks
      nixd # nix lsp
      nixfmt-rfc-style # cannot be installed via Mason on macOS, so installed here instead
      nodePackages.prettier
      par
      pngpaste # For Obsidian paste_img command
      ruff
      shfmt # Doesn't work with zsh, only sh & bash
      statix
      stylelint-lsp
      # (tailwindcss-language-server.override {nodejs_latest = nodejs_22;})
      taplo # TOML linter and formatter
      tree-sitter # required for treesitter "auto-install" option to work
      typos
      typos-lsp
      typst
      uv
      vscode-langservers-extracted # HTML, CSS, JSON & ESLint LSPs
      vtsls # js/ts LSP
      yaml-language-server
    ];
  };
}

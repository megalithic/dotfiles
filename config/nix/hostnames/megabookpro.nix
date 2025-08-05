{ config, pkgs, inputs, ... }:

{
  # Home Manager needs a bit of information about you and the
  # paths it should manage.
  home.username = "seth";
  home.homeDirectory = "/Users/seth";

  # This value determines the Home Manager release that your
  # configuration is compatible with. This helps avoid breakage
  # when a new Home Manager release introduces backwards
  # incompatible changes.
  home.stateVersion = "24.05";

  # Let Home Manager install and manage itself.
  programs.home-manager.enable = true;

  # Configure git
  programs.git = {
    enable = true;
    userName = "Seth Messer";
    userEmail = "seth@megalithic.io";

    extraConfig = {
      init.defaultBranch = "main";
      push.default = "simple";
      pull.rebase = true;
      core.editor = "nvim";
      diff.tool = "vimdiff";
      merge.tool = "vimdiff";

      # Enable rerere (reuse recorded resolution)
      rerere.enabled = true;

      # Better diff algorithm
      diff.algorithm = "patience";

      # Use delta for diff output
      core.pager = "delta";
      interactive.diffFilter = "delta --color-only";
      delta = {
        navigate = true;
        light = false;
        side-by-side = true;
        line-numbers = true;
      };
    };

    aliases = {
      st = "status";
      co = "checkout";
      br = "branch";
      ci = "commit";
      df = "diff";
      lg = "log --oneline --graph --decorate";
      unstage = "reset HEAD --";
      last = "log -1 HEAD";
      visual = "!gitk";
      wt = "worktree";
    };

    ignores = [
      ".DS_Store"
      "*.swp"
      "*.swo"
      "*~"
      ".vscode/"
      "node_modules/"
      ".env"
      ".env.local"
    ];
  };

  # Configure shell
  programs.zsh = {
    enable = true;
    enableCompletion = true;
    autosuggestion.enable = true;
    syntaxHighlighting.enable = true;

    shellAliases = {
      ll = "eza -la";
      la = "eza -la";
      ls = "eza";
      cat = "bat";
      grep = "rg";
      find = "fd";
      top = "btop";
      vim = "nvim";
      vi = "nvim";

      # Git aliases
      g = "git";
      gs = "git status";
      ga = "git add";
      gc = "git commit";
      gp = "git push";
      gl = "git pull";
      gd = "git diff";
      gco = "git checkout";
      gb = "git branch";

      # Directory navigation
      ".." = "cd ..";
      "..." = "cd ../..";
      "...." = "cd ../../..";

      # Nix aliases
      nr = "nix run";
      ns = "nix-shell";
      nsp = "nix-shell --pure";
      nsz = "nix-shell --run zsh";

      # Docker aliases
      d = "docker";
      dc = "docker-compose";
      dps = "docker ps";
      dpa = "docker ps -a";
      di = "docker images";

      # Tmux aliases
      t = "tmux";
      ta = "tmux attach";
      tl = "tmux list-sessions";
      tn = "tmux new-session";
    };

    initExtra = ''
      # Set up FZF key bindings and fuzzy completion
      if [ -n "''${commands[fzf-share]}" ]; then
        source "$(fzf-share)/key-bindings.zsh"
        source "$(fzf-share)/completion.zsh"
      fi

      # Custom functions
      mkcd() {
        mkdir -p "$1" && cd "$1"
      }

      # Better history
      setopt HIST_VERIFY
      setopt SHARE_HISTORY
      setopt APPEND_HISTORY
      setopt INC_APPEND_HISTORY
      setopt HIST_IGNORE_DUPS
      setopt HIST_IGNORE_ALL_DUPS
      setopt HIST_IGNORE_SPACE
      setopt HIST_SAVE_NO_DUPS
      setopt HIST_REDUCE_BLANKS

      # Directory stack
      setopt AUTO_PUSHD
      setopt PUSHD_IGNORE_DUPS
      setopt PUSHD_SILENT

      # Completion
      setopt COMPLETE_ALIASES
      setopt ALWAYS_TO_END
      setopt COMPLETE_IN_WORD
      setopt CORRECT
      setopt AUTO_LIST
      setopt AUTO_MENU
      setopt AUTO_PARAM_SLASH
      setopt AUTO_PARAM_KEYS

      # Load custom dotfiles config if it exists
      [[ -f ~/.config/zsh/.zshrc ]] && source ~/.config/zsh/.zshrc
    '';

    history = {
      size = 50000;
      save = 50000;
      path = "$HOME/.cache/zsh/history";
      ignoreDups = true;
      ignoreSpace = true;
      extended = true;
    };
  };

  # Tmux managed via existing config files
  programs.tmux.enable = true;

  # Configure FZF
  programs.fzf = {
    enable = true;
    enableZshIntegration = true;

    defaultCommand = "fd --type f --hidden --exclude .git";
    defaultOptions = [
      "--height 40%"
      "--border"
      "--layout=reverse"
      "--info=inline"
      "--multi"
      "--preview='bat --color=always --style=header,grid --line-range :300 {}'"
    ];

    fileWidgetCommand = "fd --type f --hidden --exclude .git";
    fileWidgetOptions = [
      "--preview 'bat --color=always --style=header,grid --line-range :300 {}'"
    ];

    changeDirWidgetCommand = "fd --type d --hidden --exclude .git";
    changeDirWidgetOptions = [
      "--preview 'eza --tree --color=always {} | head -200'"
    ];
  };

  # Configure direnv
  programs.direnv = {
    enable = true;
    enableZshIntegration = true;
    nix-direnv.enable = true;
  };

  # Configure language servers and development tools
  home.packages = with pkgs; [
    # Language servers
    lua-language-server
    nil # Nix LSP
    nodePackages.typescript-language-server
    nodePackages.vscode-langservers-extracted

    # Development tools
    jq
    yq
    tree
    htop
    btop
    lazygit
    lazydocker

    # File utilities
    file
    unzip
    zip
    p7zip

    # Network tools
    curl
    wget
    httpie

    # JSON/YAML tools
    gojq
    yq-go

    # Text processing
    sd
    choose

    # Modern alternatives
    dust # du alternative
    procs # ps alternative
    tokei # code statistics

    # Nix tools
    nix-tree
    nix-output-monitor
    nvd # nix version diff
  ];

  # Configure XDG directories and symlink existing config files
  xdg = {
    enable = true;

    configFile = {
      # Symlink all existing configuration directories (except nix folder)
      "bat".source = ../../bat;
      "borders".source = ../../borders;
      "broot".source = ../../broot;
      "btop".source = ../../btop;
      "espanso".source = ../../espanso;
      "exercism".source = ../../exercism;
      "fd".source = ../../fd;
      "gh".source = ../../gh;
      "ghostty".source = ../../ghostty;
      "git".source = ../../git;
      "gnupg".source = ../../gnupg;
      "hammerspoon".source = ../../hammerspoon;
      "helix".source = ../../helix;
      "jj".source = ../../jj;
      "kanata".source = ../../kanata;
      "karabiner".source = ../../karabiner;
      "kitty".source = ../../kitty;
      "mise".source = ../../mise;
      "ngrok".source = ../../ngrok;
      "nvim".source = ../../nvim;
      "ripgrep".source = ../../ripgrep;
      "sketchybar".source = ../../sketchybar;
      "surfingkeys".source = ../../surfingkeys;
      "svim".source = ../../svim;
      "tmux".source = ../../tmux;
      "ueberzugpp".source = ../../ueberzugpp;
      "weechat".source = ../../weechat;
      "wezterm".source = ../../wezterm;
      "zk".source = ../../zk;
      "zsh".source = ../../zsh;
    };
  };

  # Configure fonts
  fonts.fontconfig.enable = true;

  # Environment variables
  home.sessionVariables = {
    EDITOR = "nvim";
    BROWSER = "brave";
    TERMINAL = "ghostty";

    # Development
    GOPATH = "$HOME/go";
    CARGO_HOME = "$HOME/.cargo";

    # FZF
    FZF_DEFAULT_COMMAND = "fd --type f --hidden --exclude .git";
    FZF_CTRL_T_COMMAND = "$FZF_DEFAULT_COMMAND";
    FZF_ALT_C_COMMAND = "fd --type d --hidden --exclude .git";

    # Less
    LESS = "-R";
    LESSOPEN = "|${pkgs.bat}/bin/bat --color=always --style=plain %s";

    # Nix
    NIX_PATH = "nixpkgs=${inputs.nixpkgs}";
  };

  # Configure shell integration for tools
  home.shellAliases = {
    # Override with better tools
    cat = "bat --style=plain";
    less = "bat --style=plain --paging=always";
    man = "batman"; # bat-powered man pages
  };
}

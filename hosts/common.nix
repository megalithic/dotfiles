# Shared darwin configuration for all hosts
# Host-specific overrides go in hosts/<hostname>/default.nix
{
  inputs,
  pkgs,
  config,
  lib,
  username,
  hostname,
  paths,
  version,
  arch,
  ...
}: let
  lang = "en_US.UTF-8";
in {
  # NOTE: home-manager runs independently via homeConfigurations
  # Use `just home` for HM-only rebuilds

  users.users.${username} = {
    name = username;
    home = paths.home;
    isHidden = false;
    shell = pkgs.fish;
  };

  networking.hostName = hostname;
  system.defaults.smb.NetBIOSName = hostname;

  time.timeZone = "America/New_York";
  ids.gids.nixbld = 30000;

  # System paths and shells
  environment.systemPath = ["/opt/homebrew/bin"];
  environment.pathsToLink = ["/Applications"];
  environment.shells = [pkgs.fish pkgs.zsh];

  environment.variables = {
    SHELL = "${pkgs.fish}/bin/fish";
    LANG = lang;
    LC_CTYPE = lang;
    LC_ALL = lang;
    PAGER = "less -FirSwX";
    EDITOR = "${pkgs.nvim-nightly}/bin/nvim";
    VISUAL = "$EDITOR";
    GIT_EDITOR = "$EDITOR";
    JJ_EDITOR = "$EDITOR";
    MANPAGER = "$EDITOR +Man!";

    # XDG paths
    XDG_CACHE_HOME = "${paths.home}/.local/cache";
    XDG_CONFIG_HOME = paths.config;
    XDG_DATA_HOME = "${paths.home}/.local/share";
    XDG_STATE_HOME = "${paths.home}/.local/state";

    # Project paths
    CODE = "${paths.home}/code";
    DOTS = paths.dotfiles;

    # Cloud storage paths
    PROTON_HOME = paths.proton;
    ICLOUD_HOME = paths.icloud;
    ICLOUD_DOCUMENTS_HOME = "${paths.icloud}/Documents";
    NOTES_HOME = paths.notes;
    OBSIDIAN_HOME = "$NOTES_HOME";
    NVIM_DB_HOME = paths.nvimDb;

    # Tmux
    TMUX_LAYOUTS = "${paths.config}/tmux/layouts";
    TMUX_PLUGIN_MANAGER_PATH = "${paths.home}/.local/share/tmux/plugins";
    TMUX_PLUGINS_HOME = "${paths.home}/.local/share/tmux/plugins";

    # FZF configuration
    FZF_ALT_C_COMMAND = "$FZF_CTRL_T_COMMAND --type d .";
    FZF_ALT_C_OPTS = "--preview='($FZF_PREVIEW_COMMAND) 2> /dev/null' --walker-skip .git,node_modules";
    FZF_CTRL_R_OPTS = "--preview 'echo {}' --preview-window down:3:wrap:hidden --bind 'ctrl-y:execute-silent(echo -n {2..} | pbcopy)+abort' --header 'Press CTRL-Y to copy command into clipboard'";
    FZF_CTRL_T_COMMAND = "${pkgs.fd}/bin/fd --strip-cwd-prefix --hidden --follow --no-ignore-vcs";
    FZF_CTRL_T_OPTS = "--preview-window right:border-left:60%:hidden --preview='($FZF_PREVIEW_COMMAND)' --walker-skip .git,node_modules";
    FZF_DEFAULT_COMMAND = "$FZF_CTRL_T_COMMAND --type f";
    FZF_PREVIEW_COMMAND = "COLORTERM=truecolor previewer {}";

    # Shell aliases as env vars
    cat = "bat";
    grep = "grep --color=auto";
    get = "wget --continue --progress=bar --timestamping";
    EZA_ICON_SPACING = "2";

    NH_SEARCH_CHANNEL = "nixos-unstable";

  
     
    
  };

  environment.shellAliases = {
    e = "$EDITOR";
    vim = "$EDITOR";
    tmux = "direnv exec / tmux";
  };

  environment.extraInit = ''
    export SSH_AUTH_SOCK=~/Library/Group\ Containers/2BUA8C4S2C.com.1password/t/agent.sock
  '';

  # Minimal system packages - most should go to home-manager
  # These are essentials needed system-wide or before home-manager runs
  environment.systemPackages = with pkgs; [
    # Core tools
    curl
    coreutils
    git
    vim
    wget
    gnumake

    # Nix tools
    nix-index
    nurl

    # Darwin-specific
    darwin.trash

    # Archive tools
    unzip
    p7zip
    zip

    # Shell tools (needed early in boot/login)
    zsh-autosuggestions
    zsh-syntax-highlighting
  ];

  # Determinate nix installer handles nix itself
  nix = {
    enable = false;
    package = pkgs.nixVersions.latest;
    linux-builder = {
      enable = false;
      maxJobs = 4;
      ephemeral = true;
      config = {
        virtualisation = {
          darwin-builder = {
            diskSize = 40 * 1024;
            memorySize = 8 * 1024;
          };
          cores = 6;
        };
      };
    };
    settings = {
      trusted-users = [
        "@admin"
        "root"
        username
      ];
      experimental-features = [
        "nix-command"
        "flakes"
        "extra-platforms = aarch64-darwin x86_64-darwin"
        "external-builders"
      ];
      external-builders = [
        {
          systems = ["aarch64-linux" "x86_64-linux"];
          program = "/usr/local/bin/determinate-nixd";
          args = ["builder"];
        }
      ];
      download-buffer-size = 5368709120;
      warn-dirty = false;
      substituters = [
        "https://cache.nixos.org"
        "https://nix-community.cachix.org"
        "https://nixpkgs.cachix.org"
        "https://yazi.cachix.org"
      ];
      trusted-public-keys = [
        "cache.nixos.org-1:6NCHdD59X431o0gWypbMrAURkbJ16ZPMQFGspcDShjY="
        "nix-community.cachix.org-1:mB9FSh9qf2dCimDSUo8Zy7bkq5CX+/rkCWyvRCYg3Fs="
        "nixpkgs.cachix.org-1:q91R6hxbwFvDqTSDKwDAV4T5PxqXGxswD8vhONFMeOE="
        "yazi.cachix.org-1:Dcdz63NZKfvUCbDGngQDAZq6kOroIrFoyO064uvLh8k="
      ];
      keep-derivations = true;
      keep-outputs = true;
    };
    nixPath = {
      inherit (inputs) nixpkgs nixpkgs-stable nixpkgs-unstable;
      inherit (inputs) darwin;
      inherit (inputs) home-manager;
    };
  };

  nix.registry = {
    n.to = {
      type = "path";
      path = inputs.nixpkgs;
    };
    u.to = {
      type = "path";
      path = inputs.nixpkgs;
    };
  };

  programs = {
    zsh.enable = true;
    bash.enable = true;
    fish = {
      enable = true;
      useBabelfish = true;
    };
    gnupg.agent = {
      enable = true;
      enableSSHSupport = true;
    };
  };

  services.jankyborders = {
    enable = false;
    blur_radius = 5.0;
    hidpi = true;
    active_color = "0xAAB279A7";
    inactive_color = "0x33867A74";
  };

  nixpkgs.hostPlatform = arch;
}

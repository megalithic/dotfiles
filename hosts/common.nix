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
  # ── fonts ──────────────────────────────────────────────────────────────────────
  # System-wide fonts via nix-darwin (installs to /Library/Fonts/Nix Fonts)
  # Required for macOS apps like Hammerspoon, Terminal, etc.
  fonts.packages = with pkgs; [
    atkinson-hyperlegible
    emacs-all-the-icons-fonts
    fira-code
    fira-mono
    font-awesome
    inter
    # jetbrains-mono # temporarily disabled — gftools dep pulls ffmpeg-python which fails in sandbox
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
  # NOTE: home-manager runs independently via homeConfigurations
  # Use `just home` for HM-only rebuilds

  users.knownUsers = [username];
  users.users.${username} = {
    uid = 501;
    name = username;
    inherit (paths) home;
    isHidden = false;
    shell = pkgs.fish;
  };

  networking.hostName = hostname;
  # Disabled: macOS Sequoia blocks `defaults write` to
  # /Library/Preferences/SystemConfiguration/com.apple.smb.server (system-protected).
  # nix-darwin's launchctl activation context lacks the entitlements to write here.
  # Set NetBIOS name manually via System Settings → Sharing → File Sharing if needed.
  # system.defaults.smb.NetBIOSName = hostname;

  time.timeZone = "America/New_York";
  ids.gids.nixbld = 30000;

  # System paths and shells
  # Note: Determinate Nix doesn't create /run/current-system symlink,
  # so we explicitly add the nix profiles system path for coreutils etc.
  environment.systemPath = [
    "/nix/var/nix/profiles/system/sw/bin"
    "/opt/homebrew/bin"
  ];
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

    just

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

  # Determinate Nix handles nix daemon configuration via /etc/nix/nix.conf
  # Custom settings go in /etc/nix/nix.custom.conf (managed by `just apply-nix-config`)
  nix.enable = false;

  environment.etc."nix/nix.custom.conf".source = ../nix.custom.conf;
  # environment.etc."nix/nix.custom.conf".text = ''
  #   !include ${config.sops.secrets.github.path}
  # '';

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

  services = {
    tailscale.enable = true;

    jankyborders = {
      enable = false;
      blur_radius = 5.0;
      hidpi = true;
      active_color = "0xAAB279A7";
      inactive_color = "0x33867A74";
    };
  };

  nixpkgs.hostPlatform = arch;
}

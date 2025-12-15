{
  config,
  pkgs,
  lib,
  inputs,
  username,
  arch,
  hostname,
  version,
  overlays,
  ...
}: let
  inherit (pkgs.stdenv.hostPlatform) isDarwin;
in {
  imports = [
    ./lib.nix # Custom helpers (linkConfig, linkHome, etc.)
    ./packages.nix
    ./programs/ai.nix
    ./programs/agenix.nix
    ./programs/email
    ./programs/browsers
    ./programs/jujutsu.nix
    ./programs/fish.nix
    ./programs/fzf.nix
    ./programs/nvim.nix
    # ./kanata
    # ./tmux
  ];

  home.username = username;
  home.homeDirectory = "/Users/${username}";
  home.stateVersion = version;
  home.sessionPath = [
    "${config.home.homeDirectory}/.local/bin"
    "${config.home.homeDirectory}/bin"
    "${config.home.homeDirectory}/.dotfiles-nix/bin"
    "${config.home.homeDirectory}/.cargo/bin"
  ];

  home.file =
    {
      "code/.keep".text = "";
      "src/.keep".text = "";
      "tmp/.keep".text = "";
      ".hushlogin".text = "";
      "bin".source = config.lib.mega.linkBin;
      ".editorconfig".text = ''
        root = true
        [*]
        indent_style = space
        indent_size = 2
        end_of_line = lf
        insert_final_newline = true
        trim_trailing_whitespace=true
        # max_line_length = 80
        charset = utf-8
      '';
      ".ignore".source = git/tool_ignore;
      ".gitignore".source = git/gitignore;
      ".gitconfig".source = git/gitconfig;
      ".ssh/config".source = config.lib.mega.linkConfig "ssh/config";
      "Library/Application Support/espanso".source = config.lib.mega.linkConfig "espanso";
      "iclouddrive".source = config.lib.file.mkOutOfStoreSymlink "${config.home.homeDirectory}/Library/Mobile Documents/com~apple~CloudDocs";
    }
    // lib.optionalAttrs (builtins.pathExists "${config.home.homeDirectory}/Library/CloudStorage/ProtonDrive-seth@megalithic.io-folder") {
      # Only create protondrive symlink if ProtonDrive folder exists
      "protondrive".source = config.lib.file.mkOutOfStoreSymlink "${config.home.homeDirectory}/Library/CloudStorage/ProtonDrive-seth@megalithic.io-folder";
    };

  home.preferXdgDirectories = true;

  # Activation script to symlink apps that require /Applications folder
  home.activation.linkSystemApplications = lib.hm.dag.entryAfter ["writeBoundary"] (
    lib.mega.mkAppActivation {inherit pkgs; packages = config.home.packages;}
  );

  # Create symlinks in ~/.local/bin for nix-managed binaries
  # This keeps ~/.dotfiles-nix/bin clean for version-controlled hand-written scripts
  # These are recreated on each rebuild to track changing store paths
  home.activation.linkBinaries = let
    # Define custom packages that should have CLI symlinks in ~/.local/bin
    # Format: { name = package; } where package has bin/${name}
    customBinaries = {
      brave-browser-nightly = pkgs.brave-browser-nightly;
      fantastical = pkgs.fantastical;
      helium = pkgs.helium;
    };

    # Generate removal commands for all binaries
    removeCommands = lib.concatStringsSep "\n" (
      lib.mapAttrsToList (name: _: ''rm -f "$BIN_DIR/${name}" 2>/dev/null || true'') customBinaries
    );

    # Generate symlink commands for all binaries
    linkCommands = lib.concatStringsSep "\n" (
      lib.mapAttrsToList (name: pkg: ''ln -sf "${pkg}/bin/${name}" "$BIN_DIR/${name}"'') customBinaries
    );
  in
    lib.hm.dag.entryAfter ["writeBoundary"] ''
      BIN_DIR="${config.home.homeDirectory}/.local/bin"
      mkdir -p "$BIN_DIR"

      # Remove old symlinks (they may point to outdated store paths)
      ${removeCommands}

      # Create fresh symlinks to current store paths
      ${linkCommands}
    '';

  xdg.enable = true;

  xdg.configFile."ghostty".source = ./ghostty;
  xdg.configFile."ghostty".recursive = true;

  xdg.configFile."hammerspoon".source = config.lib.mega.linkConfig "hammerspoon";
  xdg.configFile."hammerspoon".recursive = true;
  xdg.configFile."hammerspoon".force = true;

  xdg.configFile."tmux".source = config.lib.mega.linkConfig "tmux";
  xdg.configFile."tmux".recursive = true;
  xdg.configFile."tmux".force = true;

  xdg.configFile."kitty".source = config.lib.mega.linkConfig "kitty";
  xdg.configFile."kitty".recursive = true;
  xdg.configFile."kitty".force = true;

  # FIXME: remove when sure; i don't use zsh anymore, i don't need this, right?
  xdg.configFile."zsh".source = ./zsh;
  xdg.configFile."zsh".recursive = true;

  xdg.configFile."1Password/ssh/agent.toml".text = ''
    [[ssh-keys]]
    vault = "Shared"
    item = "megaenv_ssh_key"
  '';
  # process-compose shortcuts - vim-friendly keybindings
  # NOTE: Navigation (j/k/arrows) and scrolling (PgUp/PgDn) are hardcoded in tview library
  # Only these action shortcuts are configurable:
  xdg.configFile."process-compose/shortcuts.yaml".text = ''
    shortcuts:
      log_follow:
        shortcut: Ctrl-F
        toggle_description:
          false: Follow Off
          true: Follow On
      log_screen:
        shortcut: Ctrl-L
        toggle_description:
          false: Half Screen
          true: Full Screen
      log_wrap:
        shortcut: Ctrl-W
        toggle_description:
          false: Wrap Off
          true: Wrap On
      process_restart:
        shortcut: Ctrl-R
        description: Restart
      process_screen:
        shortcut: Ctrl-P
        toggle_description:
          false: Half Screen
          true: Full Screen
      process_start:
        shortcut: Ctrl-S
        description: Start
      process_stop:
        shortcut: Ctrl-X
        description: Stop
      quit:
        shortcut: Ctrl-Q
        description: Quit
  '';

  # process-compose theme - match ghostty/tmux background
  # Use "Custom Style" theme (Ctrl-T to open theme selector)
  xdg.configFile."process-compose/theme.yaml".text = ''
    style:
      body:
        bgColor: '#2e353c'
        fgColor: '#d3c6aa'
        borderColor: '#475258'
        secondaryTextColor: '#859289'
        tertiaryTextColor: '#7a8478'
      stat_table:
        keyFgColor: '#a7c080'
        valueFgColor: '#d3c6aa'
        logoColor: '#7fbbb3'
      proc_table:
        fgColor: '#d3c6aa'
        fgWarning: '#dbbc7f'
        fgPending: '#7fbbb3'
        fgCompleted: '#a7c080'
        fgError: '#e67e80'
      help:
        fgColor: '#d3c6aa'
        keyColor: '#a7c080'
      dialog:
        bgColor: '#343f44'
        fgColor: '#d3c6aa'
        buttonBgColor: '#475258'
        buttonFgColor: '#d3c6aa'
        labelFgColor: '#a7c080'
        fieldBgColor: '#2e353c'
        fieldFgColor: '#d3c6aa'
  '';

  xdg.configFile."surfingkeys/config.js".text = builtins.readFile surfingkeys/config.js;
  xdg.configFile."starship.toml".text = builtins.readFile starship/starship.toml;
  xdg.configFile."karabiner/karabiner.json".text = builtins.readFile karabiner/karabiner.json;
  xdg.configFile."eza/theme.yml".text = ''
    colourful: true

    # Everforest Medium Palette
    # Background: #2d353b
    # Foreground: #d3c6aa
    # Black: #343f44
    # Red: #e67e80
    # Green: #a7c080
    # Yellow: #dbbc7f
    # Blue: #7fbbb3
    # Magenta: #d699b6
    # Cyan: #83c092
    # White: #d3c6aa
    # Gray: #859289
    # Bright Black: #475258
    # Bright Red: #e67e80
    # Bright Green: #a7c080
    # Bright Yellow: #dbbc7f
    # Bright Blue: #7fbbb3
    # Bright Magenta: #d699b6
    # Bright Cyan: #83c092
    # Bright White: #d3c6aa

    filekinds:
      normal: { foreground: "#d3c6aa" }
      directory: { foreground: "#e69875" }
      symlink: { foreground: "#859289" }
      pipe: { foreground: "#475258" }
      block_device: { foreground: "#e67e80" }
      char_device: { foreground: "#dbbc7f" }
      socket: { foreground: "#343f44" }
      special: { foreground: "#d699b6" }
      executable: { foreground: "#a7c080" }
      mount_point: { foreground: "#475258" }

    perms:
      user_read: { foreground: "#859289" }
      user_write: { foreground: "#475258" }
      user_execute_file: { foreground: "#a7c080" }
      user_execute_other: { foreground: "#a7c080" }
      group_read: { foreground: "#859289" }
      group_write: { foreground: "#475258" }
      group_execute: { foreground: "#a7c080" }
      other_read: { foreground: "#859289" }
      other_write: { foreground: "#475258" }
      other_execute: { foreground: "#a7c080" }
      special_user_file: { foreground: "#d699b6" }
      special_other: { foreground: "#475258" }
      attribute: { foreground: "#859289" }

    size:
      major: { foreground: "#859289" }
      minor: { foreground: "#e69875" }
      number_byte: { foreground: "#859289" }
      number_kilo: { foreground: "#859289" }
      number_mega: { foreground: "#83c092" }
      number_giga: { foreground: "#d699b6" }
      number_huge: { foreground: "#d699b6" }
      unit_byte: { foreground: "#859289" }
      unit_kilo: { foreground: "#83c092" }
      unit_mega: { foreground: "#d699b6" }
      unit_giga: { foreground: "#d699b6" }
      unit_huge: { foreground: "#e69875" }

    users:
      user_you: { foreground: "#dbbc7f" }
      user_root: { foreground: "#e67e80" }
      user_other: { foreground: "#d699b6" }
      group_yours: { foreground: "#859289" }
      group_other: { foreground: "#475258" }
      group_root: { foreground: "#e67e80" }

    links:
      normal: { foreground: "#e69875" }
      multi_link_file: { foreground: "#83c092" }

    git:
      new: { foreground: "#a7c080" }
      modified: { foreground: "#dbbc7f" }
      deleted: { foreground: "#e67e80" }
      renamed: { foreground: "#83c092" }
      typechange: { foreground: "#d699b6" }
      ignored: { foreground: "#475258" }
      conflicted: { foreground: "#e67e80" }

    git_repo:
      branch_main: { foreground: "#859289" }
      branch_other: { foreground: "#d699b6" }
      git_clean: { foreground: "#a7c080" }
      git_dirty: { foreground: "#e67e80" }

    security_context:
      colon: { foreground: "#859289" }
      user: { foreground: "#e69875" }
      role: { foreground: "#d699b6" }
      typ: { foreground: "#475258" }
      range: { foreground: "#d699b6" }

    file_type:
      image: { foreground: "#dbbc7f" }
      video: { foreground: "#e67e80" }
      music: { foreground: "#e69875" }
      lossless: { foreground: "#475258" }
      crypto: { foreground: "#343f44" }
      document: { foreground: "#859289" }
      compressed: { foreground: "#d699b6" }
      temp: { foreground: "#e67e80" }
      compiled: { foreground: "#83c092" }
      build: { foreground: "#475258" }
      source: { foreground: "#a7c080" }

    punctuation: { foreground: "#859289" }
    date: { foreground: "#83c092" }
    inode: { foreground: "#859289" }
    blocks: { foreground: "#859289" }
    header: { foreground: "#859289" }
    octal: { foreground: "#e69875" }
    flags: { foreground: "#d699b6" }

    symlink_path: { foreground: "#e69875" }
    control_char: { foreground: "#83c092" }
    broken_symlink: { foreground: "#e67e80" }
    broken_path_overlay: { foreground: "#859289" }
  '';

  programs = {
    home-manager.enable = true;

    # speed up rebuilds // HT: @tmiller
    man.generateCaches = false;

    starship = {enable = true;};

    git = {
      enable = true;
      package = pkgs.gitFull;
      includes = [
        {path = "~/.gitconfig";}
      ];

      settings.gpg.ssh.program = "/Applications/1Password.app/Contents/MacOS/op-ssh-sign";
      settings.gpg.format = "ssh";
      settings.user.signingkey = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAICyxphJ0fZhJP6OQeYMsGNQ6E5ZMVc/CQdoYrWYGPDrh";
      settings.commit.gpgSign = true;
    };

    direnv = {
      enable = true;
      enableZshIntegration = true;
      # NOTE: can't set this on my setup; it's readonly?
      # enableFishIntegration = true;
      nix-direnv.enable = true;
      mise.enable = true;
      config = {
        global.load_dotenv = true;
        global.warn_timeout = 0;
        global.hide_env_diff = true;
        whitelist.prefix = [config.home.homeDirectory];
      };
    };

    nh = {
      enable = true;
      package = pkgs.nh;
      clean.enable = true;
      flake = ../../.;
    };

    # yazi = import ./yazi/default.nix {inherit config pkgs lib;};

    htop = {
      enable = true;
      settings = {
        sort_direction = true;
        sort_key = "PERCENT_CPU";
      };
    };

    zoxide = {
      enable = true;
      enableFishIntegration = true;
      enableZshIntegration = true;
    };

    ssh = {
      matchBlocks."* \"test -z $SSH_TTY\"".identityAgent = "~/Library/Group\ Containers/2BUA8C4S2C.com.1password/t/agent.sock";
    };

    mise = {
      enable = true;
      enableFishIntegration = true;
      enableZshIntegration = true;
      settings = {
        auto_install = true;
        experimental = true;
        verbose = false;
      };

      # globalConfig = {
      #   tools = {
      #     elixir = "1.18.4-otp-27"; # alts: 1.18.4-otp-28
      #     erlang = "27.3.4.1"; # alts: 28.0.1
      #     python = "3.13.4";
      #     rust = "beta";
      #     node = "lts";
      #     pnpm = "latest";
      #     aws-cli = "2";
      #   };
      # };
    };

    eza = {
      enable = true;
      enableZshIntegration = true;
      enableFishIntegration = true;
      colors = "always";
      git = true;
      icons = "always";
      extraOptions = ["-lah" "--group-directories-first" "--color-scale"];
    };

    bat = {
      enable = true;
      extraPackages = with pkgs.bat-extras; [batman prettybat batgrep];
      config = {
        theme = "everforest";
      };
      themes = {
        everforest = {
          src =
            pkgs.fetchFromGitHub {
              owner = "neuromaancer";
              repo = "everforest_collection";
              rev = "main";
              sha256 = "9XPriKTmFapURY66f7wu76aojtBXFsp//Anug8e5BTk=";
            }
            + "/bat";

          file = "everforest-soft.tmtheme";
        };
      };
    };

    ripgrep = {
      enable = true;
    };

    fd = {
      enable = true;
      ignores = [
        ".git"
        ".jj"
        ".direnv"
        "pkg"
        "Library"
        ".Trash"
      ];
    };

    television = {
      enable = false;
      enableFishIntegration = false;
    };

    k9s.enable = true;

    jq.enable = true;

    tiny = {
      enable = true;
      settings = {
        servers = [
          {
            addr = "irc.libera.chat";
            port = 6697;
            tls = true;
            realname = "Seth";
            nicks = ["replicant"];
            join = ["#nethack" "#nixos" "#neovim"];
          }
        ];
        defaults = {
          nicks = ["replicant"];
          realname = "Seth";
          join = [];
          tls = true;
        };
      };
    };
  };
}

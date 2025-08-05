{ config, pkgs, inputs, ... }:

{
  # List packages installed in system profile. To search by name, run:
  # $ nix-env -qaP | grep wget
  environment.systemPackages = with pkgs; [
    # Core system tools
    vim
    git
    curl
    wget

    # Development tools
    neovim
    tmux

    # Shell utilities
    zsh
    fzf
    ripgrep
    fd
    bat
    eza

    # Language support
    nodejs
    python3

    # Nix tools
    home-manager
  ];

  # Enable nix-daemon service
  services.nix-daemon.enable = true;

  # Nix package manager settings
  nix = {
    package = pkgs.nix;
    settings = {
      # Enable flakes and new command
      experimental-features = [ "nix-command" "flakes" ];

      # Make these features available to all users
      extra-experimental-features = [ "nix-command" "flakes" ];

      # Disable auto-optimise-store because of this issue:
      # https://github.com/NixOS/nix/issues/7273
      auto-optimise-store = false;

      # Enable binary cache for faster builds
      substituters = [
        "https://cache.nixos.org/"
        "https://nix-community.cachix.org"
      ];
      trusted-public-keys = [
        "cache.nixos.org-1:6NCHdD59X431o0gWypbMrAURkbJ16ZPMQFGspcDShjY="
        "nix-community.cachix.org-1:mB9FSh9qf2dCimDSUo8Zy7bkq5CX+/rkCWyvRCYg3Fs="
      ];
    };

    # Garbage collection
    gc = {
      automatic = true;
      interval.Day = 7;
      options = "--delete-older-than 30d";
    };
  };

  # Enable sudo authentication with Touch ID
  security.pam.enableSudoTouchIdAuth = true;

  # macOS system defaults
  system = {
    # macOS system preferences
    defaults = {
      NSGlobalDomain = {
        # Disable automatic capitalization
        NSAutomaticCapitalizationEnabled = false;

        # Disable smart dashes
        NSAutomaticDashSubstitutionEnabled = false;

        # Disable automatic period substitution
        NSAutomaticPeriodSubstitutionEnabled = false;

        # Disable smart quotes
        NSAutomaticQuoteSubstitutionEnabled = false;

        # Disable auto-correct
        NSAutomaticSpellingCorrectionEnabled = false;

        # Enable full keyboard access for all controls
        AppleKeyboardUIMode = 3;

        # Set initial key repeat
        InitialKeyRepeat = 14;

        # Set key repeat
        KeyRepeat = 1;

        # Disable press-and-hold for keys in favor of key repeat
        ApplePressAndHoldEnabled = false;

        # Save to disk (not to iCloud) by default
        NSDocumentSaveNewDocumentsToCloud = false;
      };

      dock = {
        # Auto-hide the dock
        autohide = true;

        # Set dock size
        tilesize = 48;

        # Disable showing recent applications
        show-recents = false;

        # Position dock on the left
        orientation = "left";

        # Minimize windows using scale effect
        mineffect = "scale";

        # Don't show Dashboard as a space
        dashboard-in-overlay = true;
      };

      finder = {
        # Show all filename extensions
        AppleShowAllExtensions = true;

        # Show path bar
        ShowPathbar = true;

        # Show status bar
        ShowStatusBar = true;

        # Default to list view
        FXPreferredViewStyle = "Nlsv";

        # Disable warning when changing file extensions
        FXEnableExtensionChangeWarning = false;
      };

      trackpad = {
        # Enable tap to click
        Clicking = true;

        # Enable three finger drag
        TrackpadThreeFingerDrag = true;
      };

      # Mission Control settings
      spaces.spans-displays = false;
    };

    # Keyboard settings
    keyboard = {
      enableKeyMapping = true;
      remapCapsLockToControl = true;
    };

    # Set the build version for this configuration
    stateVersion = 4;
  };

  # Define fonts available to the system
  fonts = {
    packages = with pkgs; [
      # Nerd fonts
      (nerdfonts.override {
        fonts = [
          "JetBrainsMono"
          "FiraCode"
          "Hack"
          "VictorMono"
          "CascadiaCode"
          "Monaspace"
        ];
      })

      # Other fonts
      recursive
      sf-mono-liga-bin
    ];
  };

  # Configure programs
  programs = {
    # Enable zsh
    zsh.enable = true;

    # Enable fish
    fish.enable = true;
  };

  # Configure services
  services = {
    # Enable locate database
    locate.enable = true;
  };

  # Configure users
  users.users.seth = {
    home = "/Users/seth";
    shell = pkgs.zsh;
  };

  # Home-manager integration is handled in flake.nix

  # Configure Homebrew integration
  homebrew = {
    enable = true;

    # Automatically cleanup old versions
    cleanup = "zap";

    # Update homebrew and upgrade packages on rebuild
    global.autoUpdate = false;

    # Install from App Store
    masApps = {
      "Signal Shifter" = 6446061552;
      "Fantastical" = 975937182;
      "Battery Indicator" = 1206020918;
    };

    # Install GUI applications via cask
    casks = [
      # Essential apps
      "1password"
      "1password-cli"
      "alfred"
      "hammerspoon"
      "karabiner-elements"

      # Development
      "docker"
      "kitty-nightly"
      "wezterm-nightly"
      "ghostty"

      # Browsers
      "brave-browser-dev"
      "firefox-developer-edition"
      "google-chrome-dev"

      # Media & Communication
      "spotify"
      "slack"
      "signal"
      "zoom"

      # Utilities
      "contexts"
      "bartender"
      "bettertouchtool"
      "stats"
      "hazel"
      "raycast"

      # File management
      "marta"

      # Design & productivity
      "figma"
      "obsidian"
    ];

    # Install CLI tools via brew that aren't in nixpkgs or need special handling
    brews = [
      # macOS specific tools
      "blueutil"
      "defaultbrowser"
      "dockutil"
      "m1ddc"
      "mas"
      "pinentry-mac"
      "reattach-to-user-namespace"
      "switchaudio-osx"
      "terminal-notifier"
      "trash"
      "wifi-password"

      # Development tools that work better via brew
      "espanso"
      "transcrypt"

      # Fonts
      "font-jetbrains-mono-nerd-font"
      "font-hack-nerd-font"
      "font-victor-mono-nerd-font"
      "font-cascadia-code"
      "font-monaspace-nerd-font"
    ];

    # Configure taps
    taps = [
      "homebrew/bundle"
      "homebrew/services"
      "homebrew/cask-fonts"
      "homebrew/cask-versions"
      "espanso/espanso"
      "FelixKratz/formulae"
      "koekeishiya/formulae"
    ];
  };
}

{
  pkgs,
  lib,
  config,
  inputs,
  username,
  ...
}:
# TODO:
# - wallpaper setting: https://github.com/Lalit64/snowflake/blob/main/modules/darwin/suites/desktop/default.nix#L25
# NOTE: docs for nix-darwin found
# https://daiderd.com/nix-darwin/manual/index.html
# macOS user-specific defaults using home-manager's built-in support
#
# VALIDATION BEST PRACTICES:
# 1. Test settings manually first: `defaults write com.apple.finder ShowStatusBar -bool true`
# 2. Check existing settings: `defaults read com.apple.finder`
# 3. Use `defaults domains` to see available domains
# 4. Invalid domains/keys will build but silently fail to apply
# 5. Some settings require logout/restart to take effect
# 6. Case sensitivity matters for both domains and keys
# 7. Not all `defaults` commands have targets.darwin.defaults equivalents
{
  power = {
    restartAfterFreeze = true;
    # restartAfterPowerFailure = true;
    sleep = {
      display = 10;
      computer = "never";
      harddisk = "never";
      allowSleepByPowerButton = false;
    };
  };

  networking = {
    applicationFirewall.enableStealthMode = true;
    applicationFirewall.allowSignedApp = true;
    applicationFirewall.allowSigned = true;
    applicationFirewall.enable = true;
  };

  system = {
    primaryUser = "${username}";
    # Used for backwards compatibility, please read the changelog before changing.
    # Darwin state version 6 - defines system configuration schema/compatibility
    # See flake.nix for actual package channel selection (stable vs unstable)
    # Reference: https://github.com/LnL7/nix-darwin/blob/master/modules/system/default.nix
    # $ darwin-rebuild changelog
    stateVersion = 6;
    startup.chime = false;
    # power = {
    #   restartAfterFreeze = true;
    #   # restartAfterPowerFailure = true;
    #   sleep = {
    #     allowSleepByPowerButton = false;
    #     computer = "never";
    #     display = 2;
    #     harddisk = 10;
    #   };
    # };
    defaults = {
      # Reduce window resize animation duration.
      NSGlobalDomain.NSWindowResizeTime = 0.001;

      # Reduce motion.
      CustomSystemPreferences."com.apple.Accessibility".ReduceMotionEnabled = 1;
      # universalaccess.reduceMotion = true;

      controlcenter = {
        BatteryShowPercentage = true;
        # Control Center menu bar items (null = system default, true = show, false = hide)
        AirDrop = false; # AirDrop control - use system default
        Bluetooth = true; # Bluetooth control in menu bar
        Display = true; # Screen brightness control in menu bar
        FocusModes = false; # Focus modes control (Do Not Disturb)
        NowPlaying = true; # Now Playing media control
        Sound = true; # Volume control in menu bar
      };

      dock = {
        autohide = true;
        autohide-time-modifier = 0.7;
        # autohide-delay = 600.;
        orientation = "bottom";
        show-process-indicators = true;
        show-recents = false;
        static-only = true;
        launchanim = false;
        expose-animation-duration = 0.0;
        minimize-to-application = true;
        mineffect = "scale";
        magnification = false;
        persistent-others = null;
        persistent-apps = [
          {app = "~/Applications/Finder.app";}
          {app = "~/Applications/Brave Browser Nightly.app";}
          {app = "~/Applications/Ghostty.app";}
          {app = "/System/Applications/Messages.app";}

          # {
          #   spacer = {
          #     small = false;
          #   };
          # }
          # {
          #   spacer = {
          #     small = true;
          #   };
          # }
          # {
          #   folder = "/System/Applications/Utilities";
          # }
          # {
          #   file = "/User/example/Downloads/test.csv";
          # }
        ];
        tilesize = 60;
        # Mission Control and Spaces behavior
        # Disable automatic rearrangement of spaces based on most recent use
        "mru-spaces" = false;
        # Hot corners configuration
        # Values correspond to specific macOS actions:
        # 0: No-op (disabled)
        # 2: Mission Control - shows all open windows and spaces
        # 3: Application Windows - shows all windows of current app
        # 4: Desktop - shows desktop by hiding all windows
        # 5: Start Screen Saver
        # 6: Disable Screen Saver
        # 7: Dashboard (deprecated in newer macOS versions)
        # 10: Put Display to Sleep
        # 11: Launchpad - shows app launcher grid
        # 12: Notification Center
        # 13: Lock Screen - immediately locks the screen
        # 14: Quick Note - opens Notes app for quick note-taking
        "wvous-tl-corner" = 1; # Top-left: Mission Control (overview of all spaces)
        "wvous-tr-corner" = 1; # Top-right: Desktop (show desktop)
        "wvous-bl-corner" = 1; # Bottom-left: Lock Screen (security)
        "wvous-br-corner" = 1; # Bottom-right: Quick Note (productivity)
        # "wvous-tl-corner" = 2; # Top-left: Mission Control (overview of all spaces)
        # "wvous-tr-corner" = 4; # Top-right: Desktop (show desktop)
        # "wvous-bl-corner" = 13; # Bottom-left: Lock Screen (security)
        # "wvous-br-corner" = 14; # Bottom-right: Quick Note (productivity)
      };

      finder = {
        AppleShowAllExtensions = true;
        AppleShowAllFiles = true;
        FXDefaultSearchScope = "SCcf";
        FXPreferredViewStyle = "Nlsv";
        FXEnableExtensionChangeWarning = false;
        ShowPathbar = true;
        ShowStatusBar = true;
        _FXShowPosixPathInTitle = true;
        ShowExternalHardDrivesOnDesktop = true;
        ShowHardDrivesOnDesktop = false;
        ShowMountedServersOnDesktop = false;
        ShowRemovableMediaOnDesktop = true;
        _FXSortFoldersFirst = true;
        QuitMenuItem = true;
        NewWindowTarget = "Home";
      };

      trackpad = {
        Clicking = true;
        TrackpadRightClick = true;
        TrackpadThreeFingerDrag = true;
      };

      NSGlobalDomain = {
        AppleInterfaceStyle = "Dark";
        _HIHideMenuBar = false;
        AppleICUForce24HourTime = true;
        AppleKeyboardUIMode = 3;
        "com.apple.keyboard.fnState" = true;
        NSAutomaticWindowAnimationsEnabled = false;
        NSWindowShouldDragOnGesture = true;
        NSDocumentSaveNewDocumentsToCloud = false;
        PMPrintingExpandedStateForPrint = true;
        PMPrintingExpandedStateForPrint2 = true;
        NSNavPanelExpandedStateForSaveMode = true;
        NSNavPanelExpandedStateForSaveMode2 = true;
        "com.apple.swipescrolldirection" = false;
        # Use scroll gesture with the Ctrl (^) modifier key to
        # zoom, this requires to have "Full disk access" in the
        # program which run nix-darwin command
        # NOTE: doesn't exist on sequoia?
        # universalaccess.closeViewScrollWheelToggle = true;
        "com.apple.trackpad.scaling" = 3.0;
        AppleInterfaceStyleSwitchesAutomatically = false;
        AppleShowScrollBars = "Automatic";
        InitialKeyRepeat = 12;
        KeyRepeat = 1;
        # _HIHideMenuBar = false;

        # Disable press and hold for diacritics.
        # I want to be able to press and hold j and k
        # in VSCode with vim keys to move around.
        ApplePressAndHoldEnabled = false;
        NSAutomaticCapitalizationEnabled = false;
        NSAutomaticDashSubstitutionEnabled = false;
        NSAutomaticPeriodSubstitutionEnabled = false;
        NSAutomaticQuoteSubstitutionEnabled = false;
        NSAutomaticSpellingCorrectionEnabled = false;
      };

      screencapture = {
        location = "/Users/${username}/_screenshots";
        type = "png";
        disable-shadow = true;
      };

      LaunchServices = {
        LSQuarantine = false;
      };

      CustomUserPreferences = {
        bluetoothaudiod = {
          "AAC Bitrate" = 320;
          "AAC max packet size" = 644;
          "Apple Bitpool Max" = 80;
          "Apple Bitpool Min" = 80;
          "Apple Initial Bitpool Min" = 80;
          "Apple Initial Bitpool" = 80;
          "Enable AAC codec" = true;
          "Enable AptX codec" = true;
          "Negotiated Bitpool Max" = 80;
          "Negotiated Bitpool Min" = 80;
          "Negotiated Bitpool" = 80;
        };
        "com.apple.BluetoothAudioAgent" = {
          "Apple Bitpool Max (editable)" = 80;
          "Apple Bitpool Min (editable)" = 80;
          "Apple Initial Bitpool (editable)" = 80;
          "Apple Initial Bitpool Min (editable)" = 80;
          "Negotiated Bitpool Max" = 80;
          "Negotiated Bitpool Min" = 80;
          "Negotiated Bitpool" = 80;
          "Stream - Flush Ring on Packet Drop (editable)" = 0;
          "Stream - Max Outstanding Packets (editable)" = 16;
          "Stream Resume Delay" = "0.75";
        };
        "com.apple.print.PrintingPrefs" = {"Quit When Finished" = true;}; # quit printer app once jobs complete
        NSGlobalDomain = {
          # Add a context menu item for showing the Web Inspector in web views
          WebKitDeveloperExtras = true;
          # automatically switch to a new space when switching to the application
          AppleSpacesSwitchOnActivate = true;
          WebAutomaticSpellingCorrectionEnabled = false;
        };
        "com.mitchellh.ghostty" = {
          SUAutomaticallyUpdate = false;
          SUEnableAutomaticChecks = false;
          SUHasLaunchedBefore = true;
          SUSendProfileInfo = false;
        };
        "com.raycast.macos" = {
          # cmd-space
          initialSpotlightHotkey = "Command-49";
          raycastGlobalHotkey = "Command-49";
          raycastPreferredWindowMode = "compact";
          raycastShouldFollowSystemAppearance = true;
          "NSStatusItem Visible raycastIcon" = false;
          showGettingStartedLink = false;
          onboardingCompleted = true;
          developerFlags = false;
          organizationsPreferencesTabVisited = 1;
          popToRootTimeout = 60;
          raycastAPIOptions = 8;
          suggestedPreferredGoogleBrowser = 1;
          "permissions.folders.read:/Users/${username}/Desktop" = true;
          "permissions.folders.read:/Users/${username}/Documents" = true;
          "permissions.folders.read:/Users/${username}/Downloads" = true;
          "permissions.folders.read:cloudStorage" = true;
          # "raycast_hyperKey_state" = {
          #   enabled = 1;
          #   includeShiftKey = 1;
          #   # use Right Option for hyper key
          #   keyCode = 230;
          # };
          # useHyperKeyIcon = 1;
        };
        # REF: https://medium.com/@zmre/nix-darwin-quick-tip-activate-your-preferences-f69942a93236
        "com.apple.messages.text" = {
          Autocapitalization = 1;
          EmojiReplacement = 1;
          SmartDashes = 1;
          SmartInsertDelete = 2;
          SmartQuotes = 1;
          SpellChecking = 1;
          ApplePressAndHoldEnabled = false;
        };
        "com.apple.ActivityMonitor" = {
          OpenMainWindow = true;
          IconType = 5;
          SortColumn = "CPUUsage";
          SortDirection = 0;
        };
        "com.apple.desktopservices" = {
          # Avoid creating .DS_Store files on network or USB volumes
          DSDontWriteNetworkStores = true;
          DSDontWriteUSBStores = true;
        };
        "com.apple.WindowManager" = {
          EnableStandardClickToShowDesktop = 0; # Click wallpaper to reveal desktop
          StandardHideDesktopIcons = 0; # Show items on desktop
          HideDesktop = 0; # Do not hide items on desktop & stage manager
          StageManagerHideWidgets = 0;
          StandardHideWidgets = 0;
        };
        "com.apple.screensaver" = {
          # Require password immediately after sleep or screen saver begins
          askForPassword = true;
          askForPasswordDelay = 0;
        };
        "com.apple.AdLib".allowApplePersonalizedAdvertising = false;
        # turns on app auto-updating
        "com.apple.commerce".AutoUpdate = true;
        # Prevent Photos from opening automatically when devices are plugged in
        "com.apple.ImageCapture".disableHotPlug = true;

        # tell HS where to find its config file
        "org.hammerspoon.Hammerspoon".MJConfigFile = "~/.config/hammerspoon/init.lua";

        # https://tyler.io/2020/04/additional-mailmate-tips/
        "com.freron.MailMate" = {
          SoftwareUpdateChannel = "beta";
          MmShowTips = "never";
          MmCustomKeyBindingsEnabled = true;
          MmCustomKeyBindingsName = "Mega";
          MmComposerInitialFocus = "alwaysTextView";
          MmShowAttachmentsFirst = true;
          MmSingleMessageWindowClosesAfterMove = true;

          MmHeadersViewWebKitDefaultFontSize = 13;
          MmHeadersViewWebKitStandardFont = "Helvetica";
          MmMessagesWebViewMinimumFontSize = 12;
          MmMessagesWebViewWebKitDefaultFixedFontSize = 13;
          MmMessagesWebViewWebKitDefaultFontSize = 13;
          MmMessagesWebViewWebKitMinimumFontSize = 12;
          MmMessagesWebViewWebKitStandardFont = "Helvetica";
          MmMessagesOutlineOpenMessageOnDoubleClick = true;
          MmMessagesOutlineShowUnreadMessagesInBold = true;
        };

        "com.apple.SoftwareUpdate" = {
          AutomaticCheckEnabled = true;
          # Check for software updates daily, not just once per week
          ScheduleFrequency = 1;
          # Download newly available updates in background
          AutomaticDownload = 1;
          # Install System data files & security updates
          CriticalUpdateInstall = 1;
        };

        "com.apple.symbolichotkeys" = {
          AppleSymbolicHotKeys = {
            # Disable input sources shortcuts
            # Disable '^ + Space' for selecting the previous input source
            "60".enabled = false;
            # "61".enabled = false;
            # -- or --
            "61" = {
              # Set 'Option + Space' for selecting the next input source
              enabled = 1;
              value = {
                parameters = [
                  32
                  49
                  524288
                ];
                type = "standard";
              };
            };

            # Disable Spotlight Shortcuts
            # Disable 'Cmd + Space' for Spotlight Search
            "64".enabled = false;
            # Disable 'Cmd + Alt + Space' for Finder search window
            "65".enabled = false;
          };
        };

        "com.brave.Browser.nightly" = {
          NSUserKeyEquivalents = {
            "Close Tab" = "^w";
            # collides with surfingkeys
            # "Find..." = "^f";
            "New Private Window" = "^$n";
            "New Tab" = "^t";
            "Select Previous Tab" = "^h";
            "Select Next Tab" = "^l";
            "Reload This Page" = "^r";
            "Reopen Closed Tab" = "^$t";
            "Reset zoom" = "^0";
            "Zoom In" = "^=";
            "Zoom Out" = "^-";
          };
        };
      };
    };
    keyboard = {
      enableKeyMapping = true;
      remapCapsLockToControl = true;
    };
  };

  # Mute a startup sound
  # nvram.variables."StartupMute" = "%01";

  security.pam.services.sudo_local.touchIdAuth = true;
  security.sudo.extraConfig = "${username}    ALL = (ALL) NOPASSWD: ALL";
}

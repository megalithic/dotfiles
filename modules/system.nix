{
  config,
  username,
  ...
}:
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

    # DNS servers (Cloudflare and Google)
    dns = [
      "1.1.1.1"
      "8.8.8.8"
    ];

    # Network service names that should be in the list of known network services
    knownNetworkServices = [
      "Wi-Fi"
      "Thunderbolt Ethernet Slot 0"
    ];
  };

  system = {
    primaryUser = "${username}";
    stateVersion = 6;
    startup.chime = false;
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
          {app = "/System/Library/CoreServices/Finder.app";}
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
        "wvous-tl-corner" = null; # Top-left: Mission Control (overview of all spaces)
        "wvous-tr-corner" = null; # Top-right: Desktop (show desktop)
        "wvous-bl-corner" = null; # Bottom-left: Lock Screen (security)
        "wvous-br-corner" = null; # Bottom-right: Quick Note (productivity)
        # "wvous-tl-corner" = 2; # Top-left: Mission Control (overview of all spaces)
        # "wvous-tr-corner" = 4; # Top-right: Desktop (show desktop)
        # "wvous-bl-corner" = 13; # Bottom-left: Lock Screen (security)
        # "wvous-br-corner" = 14; # Bottom-right: Quick Note (productivity)
      };

      finder = {
        AppleShowAllExtensions = true;
        AppleShowAllFiles = true;
        # When performing a search, search the current folder by default
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
        NSAutomaticWindowAnimationsEnabled = false;
        NSWindowShouldDragOnGesture = true;
        NSDocumentSaveNewDocumentsToCloud = false;
        PMPrintingExpandedStateForPrint = true;
        PMPrintingExpandedStateForPrint2 = true;
        NSNavPanelExpandedStateForSaveMode = true;
        NSNavPanelExpandedStateForSaveMode2 = true;
        "com.apple.keyboard.fnState" = false;
        "com.apple.swipescrolldirection" = false;
        # Use scroll gesture with the Ctrl (^) modifier key to
        # zoom, this requires to have "Full disk access" in the
        # program which run nix-darwin command
        # NOTE: doesn't exist on sequoia?
        # universalaccess.closeViewScrollWheelToggle = true;
        "com.apple.trackpad.scaling" = 3.0;
        AppleInterfaceStyleSwitchesAutomatically = false;
        AppleShowScrollBars = "WhenScrolling";
        # ---
        # ludicrous speed:
        # InitialKeyRepeat = 12;
        # KeyRepeat = 1;
        # ---
        # default'ish speed:
        InitialKeyRepeat = 25;
        KeyRepeat = 6;
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
        "com.apple.finder".NewWindowTargetPath = "file:///Users/${username}/";
        NSGlobalDomain = {
          "SLSMenuBarUseBlurredAppearance" = false;
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
        # "com.flexibits.fantastical2.mac" = {
        #   SUAutomaticallyUpdate = false;
        #   SUEnableAutomaticChecks = false;
        # };
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

        # com.apple.messages.text and com.apple.ActivityMonitor disabled —
        # both are sandboxed (see SANDBOXED APP PREFS note below).
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
        # === SANDBOXED APP PREFS DISABLED (macOS Sequoia) ===
        # Sequoia hard-fails `defaults write` to sandboxed apps' containers
        # (~/Library/Containers/<bundle-id>/). Even with FDA on Ghostty,
        # nix-darwin's `launchctl asuser ... sudo defaults write` runs in the
        # launchd GUI context which doesn't inherit Ghostty's TCC grant.
        # Set these manually in each app's Settings/Preferences UI.
        #
        # Disabled domains: com.apple.Safari, com.apple.mail,
        # com.apple.messages.text, com.apple.ActivityMonitor
        # See: https://lapcatsoftware.com/articles/containers.html
        # tell HS where to find its config file
        "org.hammerspoon.Hammerspoon".MJConfigFile = "~/.config/hammerspoon/init.lua";

        # MailMate settings moved to home/common/programs/mailmate/default.nix

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

            # Disable Mission Control "Switch to Desktop N" shortcuts (Ctrl+1-9)
            # These conflict with Hammerspoon bindings for Messages app navigation
            # REF: https://gist.github.com/jimratliff/227088cc936065598bedfd91c360334e
            # IDs 118-126 = Switch to Desktop 1-9 (default: Ctrl+1 through Ctrl+9)
            "118".enabled = false; # Switch to Desktop 1 (Ctrl+1)
            "119".enabled = false; # Switch to Desktop 2 (Ctrl+2)
            "120".enabled = false; # Switch to Desktop 3 (Ctrl+3)
            "121".enabled = false; # Switch to Desktop 4 (Ctrl+4)
            "122".enabled = false; # Switch to Desktop 5 (Ctrl+5)
            "123".enabled = false; # Switch to Desktop 6 (Ctrl+6)
            "124".enabled = false; # Switch to Desktop 7 (Ctrl+7)
            "125".enabled = false; # Switch to Desktop 8 (Ctrl+8)
            "126".enabled = false; # Switch to Desktop 9 (Ctrl+9)
          };
        };

        # NOTE: Browser keybindings moved to home/common/programs/{brave-browser-nightly,helium-browser}/default.nix
        # using the keyEquivalents option in mkChromiumBrowser module
      };
    };
    keyboard = {
      enableKeyMapping = true;
      remapCapsLockToControl = false; # kanata handles caps → esc/ctrl tap-hold
    };
  };

  # Mute a startup sound
  # nvram.variables."StartupMute" = "%01";

  # =============================================================================
  # Text Replacements
  # =============================================================================
  # Use CustomUserPreferences since NSUserDictionaryReplacementItems isn't
  # exposed as a typed option in nix-darwin
  system.defaults.CustomUserPreferences."NSGlobalDomain".NSUserDictionaryReplacementItems = [
    {
      on = 1;
      replace = "@@1";
      "with" = "seth.messer@gmail.com";
    }
    {
      on = 1;
      replace = "@@2";
      "with" = "seth@megalithic.io";
    }
    {
      on = 1;
      replace = "@@3";
      "with" = "seth.messer@strivepharmacy.com";
    }
    {
      on = 1;
      replace = "omw";
      "with" = "On my way!";
    }
  ];

  # =============================================================================
  # Security
  # =============================================================================
  security.pam.services.sudo_local = {
    enable = true;
    touchIdAuth = true;
    reattach = true;
    # Extend here with additional services (e.g., `login`) if we want biometric auth elsewhere.
  };

  security.sudo.extraConfig = "${username}    ALL = (ALL) NOPASSWD: ALL";

  # Apply symbolic hotkey changes immediately (without requiring logout)
  # REF:
  # https://zameermanji.com/blog/2021/6/8/applying-com-apple-symbolichotkeys-changes-instantaneously/
  # https://medium.com/@zmre/nix-darwin-quick-tip-activate-your-preferences-f69942a93236

  # NOTE: postUserActivation was removed; using postActivation with sudo -u instead
  system.activationScripts.postActivation.text = ''
    sudo -u ${username} /System/Library/PrivateFrameworks/SystemAdministration.framework/Resources/activateSettings -u
  '';
}

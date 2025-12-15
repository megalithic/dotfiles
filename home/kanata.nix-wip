{ lib
, config
, pkgs
, ...
}:
with lib;
let
  cfg = config.services.kanata;
in
{
  options.services.kanata = with types; {
    enable = mkEnableOption "Whether or not to enable kanata.";
    configFile = mkOption {
      type = types.str;
      description = "Path to kanata configuration file";
    };
  };

  config = mkIf cfg.enable {
    environment.systemPackages = [
      pkgs.karabiner-driverkit
      pkgs.kanata
    ];

    system.activationScripts.preActivation.text = ''
      ${pkgs.karabiner-driverkit}/bin/install-karabiner-driverkit
    '';

    # Launch daemon for the Virtual HID Device
    launchd.daemons.karabiner-virtualhid = {
      serviceConfig = {
        Label = "org.pqrs.Karabiner-DriverKit-VirtualHIDDevice";
        UserName = "root";
        GroupName = "wheel";
        KeepAlive = {
          SuccessfulExit = false;
          AfterInitialDemand = true;
        };
        RunAtLoad = true;
        StandardOutPath = "/var/log/karabiner-virtualhid.log";
        StandardErrorPath = "/var/log/karabiner-virtualhid-error.log";
        Program = "/Library/Application Support/org.pqrs/Karabiner-DriverKit-VirtualHIDDevice/Applications/Karabiner-VirtualHIDDevice-Daemon.app/Contents/MacOS/Karabiner-VirtualHIDDevice-Daemon";
        WorkingDirectory = "/tmp";
        # Ensure the daemon has access to necessary paths
        EnvironmentVariables = {
          PATH = "/usr/local/bin:/usr/bin:/bin:/usr/sbin:/sbin";
        };
        # Add some safety measures
        ThrottleInterval = 30; # Prevent rapid restarts
        Nice = -20; # Give high priority to the virtual HID device
      };
    };

    # Launch daemon for Kanata
    launchd.daemons.kanata = {
      serviceConfig = {
        Label = "org.nixos.kanata";
        UserName = "root";
        GroupName = "wheel";
        KeepAlive = {
          SuccessfulExit = false;
          AfterInitialDemand = true;
          OtherJobEnabled = {
            "org.pqrs.Karabiner-DriverKit-VirtualHIDDevice" = true;
          };
        };
        RunAtLoad = true;
        StandardOutPath = "/var/log/kanata.log";
        StandardErrorPath = "/var/log/kanata-error.log";
        ProgramArguments = [
          "/bin/bash"
          "-c"
          ''
            # Wait for the virtual HID device to be fully initialized
            sleep 5

            # Check if the virtual HID device is ready
            while [ ! -d "/Library/Application Support/org.pqrs/Karabiner-DriverKit-VirtualHIDDevice" ]; do
              echo "Waiting for Karabiner virtual HID device..."
              sleep 1
            done

            # Additional check to ensure the daemon is running
            while ! pgrep -f "Karabiner-VirtualHIDDevice-Daemon" > /dev/null; do
              echo "Waiting for Karabiner virtual HID daemon to start..."
              sleep 1
            done

            # Start Kanata
            exec ${pkgs.kanata}/bin/kanata --cfg ${cfg.configFile}
          ''
        ];
        WorkingDirectory = "/tmp";
        EnvironmentVariables = {
          PATH = "/usr/local/bin:/usr/bin:/bin:/usr/sbin:/sbin";
        };
        ThrottleInterval = 30;
        Nice = -20;
      };
    };

    # Ensure log files exist with proper permissions
    system.activationScripts.postActivation.text = ''
      # Create log files if they don't exist
      for logfile in /var/log/{kanata,kanata-error,karabiner-virtualhid,karabiner-virtualhid-error}.log; do
        if [ ! -f "$logfile" ]; then
          touch "$logfile"
          chmod 644 "$logfile"
          chown root:wheel "$logfile"
        fi
      done
    '';
  };
}

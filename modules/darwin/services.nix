# Darwin system services (launchd daemons)
#
# This module consolidates system-level launchd daemons that run as root.
# For user-level agents, see: home/common/services.nix
#
# Usage:
#   imports = [ ./darwin/services.nix ];
#
# To add host-specific daemons, add them in hosts/<hostname>.nix:
#   launchd.daemons.my-daemon = { ... };
#
{
  config,
  pkgs,
  lib,
  ...
}: {
  # ─────────────────────────────────────────────────────────────────────────────
  # Nix Store Garbage Collection (System Profiles)
  # ─────────────────────────────────────────────────────────────────────────────
  # Clean system profile generations older than 8 days
  # User profiles are handled by home-manager's nh.clean
  # Runs weekly on Monday at 3am (after user GC at midnight)
  launchd.daemons.nix-gc = {
    serviceConfig = {
      Label = "org.nix.gc";
      ProgramArguments = [
        "/bin/sh"
        "-c"
        "/bin/wait4path /nix/store && /nix/var/nix/profiles/default/bin/nix-collect-garbage --delete-older-than 8d"
      ];
      StartCalendarInterval = [
        {
          Weekday = 1;
          Hour = 3;
          Minute = 0;
        }
      ];
      StandardOutPath = "/var/log/nix-gc.log";
      StandardErrorPath = "/var/log/nix-gc.log";
    };
  };

  # ─────────────────────────────────────────────────────────────────────────────
  # File Descriptor Limits
  # ─────────────────────────────────────────────────────────────────────────────
  # Increase system-wide file descriptor limits for nix builds
  # macOS defaults to 256 which causes "Too many open files" during complex evaluations
  # This is Apple's officially recommended approach (no declarative kernel config exists)
  launchd.daemons.limit-maxfiles = {
    serviceConfig = {
      Label = "limit.maxfiles";
      ProgramArguments = [
        "launchctl"
        "limit"
        "maxfiles"
        "524288" # soft limit
        "524288" # hard limit
      ];
      RunAtLoad = true;
      LaunchOnlyOnce = true;
    };
  };
}

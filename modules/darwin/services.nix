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

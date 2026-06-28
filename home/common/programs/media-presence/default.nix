# media-presence — meeting/AV presence daemon as a user LaunchAgent.
#
# Runs media-presenced at login. It needs no TCC grants: it reads device *state*
# (CoreAudio/CoreMediaIO IsRunningSomewhere — not capture), talks to Helium's
# localhost CDP, and focuses via NSRunningApplication/CDP. No CGWindowList, AX,
# or screencapture, so it never triggers Screen Recording / Automation prompts.
#
# Hammerspoon consumes the Unix socket at ~/.local/state/media-presence/sock.
{
  config,
  pkgs,
  ...
}:
let
  socketPath = "${config.home.homeDirectory}/.local/state/media-presence/sock";
in
{
  home.packages = [ pkgs.media-presenced ];

  launchd.agents.media-presenced = {
    enable = true;
    config = {
      ProgramArguments = [
        "${pkgs.media-presenced}/bin/media-presenced"
        "--socket"
        socketPath
        "--cdp-port"
        "9223"
      ];
      RunAtLoad = true;
      KeepAlive = true;
      StandardOutPath = "${config.home.homeDirectory}/Library/Logs/media-presence/stdout.log";
      StandardErrorPath = "${config.home.homeDirectory}/Library/Logs/media-presence/stderr.log";
    };
  };
}

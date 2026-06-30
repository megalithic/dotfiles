# media-presence — meeting/AV presence daemon as a user LaunchAgent.
#
# Runs the single-file Swift script in ~/.dotfiles/bin/media-presenced at login.
# It needs no TCC grants: it reads device *state* (CoreAudio/CoreMediaIO
# IsRunningSomewhere — not capture), talks to Helium's localhost CDP, and focuses
# via NSRunningApplication/CDP. No CGWindowList, AX, or screencapture, so it never
# triggers Screen Recording / Automation prompts.
#
# Hammerspoon consumes the Unix socket at ~/.local/state/media-presence/sock.
{ config, ... }:
let
  socketPath = "${config.home.homeDirectory}/.local/state/media-presence/sock";
  scriptPath = "${config.lib.mega.dotfilesPath}/bin/media-presenced";
in
{
  launchd.agents.media-presenced = {
    enable = true;
    config = {
      ProgramArguments = [
        scriptPath
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

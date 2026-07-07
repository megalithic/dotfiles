# miccheck — menubar push-to-talk / push-to-mute app (MicDrop-style, local).
#
# Replaces the Hammerspoon miccheck.lua module. Hold cmd+opt for PTT/PTM,
# cmd+opt+p toggles mode. Source: bin/miccheck.swift, compiled to a stable
# binary at ~/.local/bin/miccheckd by bin/miccheck-build (stable path +
# ad-hoc signature keeps the Input Monitoring TCC grant attached).
#
# Hammerspoon controls it over the Unix socket at ~/.local/state/miccheck/sock
# via config/hammerspoon/lib/micctl.lua (set-mode / toggle-mode / get / quit).
{ config, ... }:
let
  scriptPath = "${config.lib.mega.dotfilesPath}/bin/miccheck-launchd";
in
{
  launchd.agents.miccheck = {
    enable = true;
    config = {
      ProgramArguments = [ scriptPath ];
      RunAtLoad = true;
      KeepAlive = true;
      StandardOutPath = "${config.home.homeDirectory}/Library/Logs/miccheck/stdout.log";
      StandardErrorPath = "${config.home.homeDirectory}/Library/Logs/miccheck/stderr.log";
    };
  };
}

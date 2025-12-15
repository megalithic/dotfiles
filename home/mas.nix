{
  inputs,
  config,
  pkgs,
  lib,
  ...
}: let
  masApps = {
    "Xcode" = 497799835;
    # "Keynote" = 409183694;
    # "Fantastical" = 435003921;  # Not available via mas CLI (subscription app with restricted API access)
    # "Pages" = 409201541;
    # "Numbers" = 409203825;
  };

  masInstaller = lib.mega.mkMas {inherit pkgs lib;} masApps;
in {
  home.activation.installMasApps = lib.hm.dag.entryAfter ["writeBoundary"] masInstaller.activationScript;
}

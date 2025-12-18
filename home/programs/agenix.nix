{
  config,
  pkgs,
  lib,
  inputs,
  ...
}: {
  imports = [
    inputs.agenix.homeManagerModules.default
  ];

  age = {
    identityPaths = [
      "${config.home.homeDirectory}/.ssh/id_ed25519"
    ];
    secrets = {
      env-vars.file = "${inputs.self}/secrets/env-vars.age";
      s3cfg.file = "${inputs.self}/secrets/s3cfg.age";
      launchdeck-vpn.file = "${inputs.self}/secrets/launchdeck-vpn.age";
    };
  };

  programs.zsh.initExtra = lib.mkAfter ''
    # Load agenix secrets as environment variables
    if [ -f "${config.age.secrets.env-vars.path}" ]; then
      source "${config.age.secrets.env-vars.path}"
    fi

    # LaunchDeck VPN config path
    export AGENIX_VPN_CONFIG="${config.age.secrets.launchdeck-vpn.path}"
  '';

  programs.fish.interactiveShellInit = lib.mkAfter ''
    # Load agenix secrets as environment variables
    if test -f "${config.age.secrets.env-vars.path}"
      source "${config.age.secrets.env-vars.path}"
    end

    # LaunchDeck VPN config path
    set -gx AGENIX_VPN_CONFIG "${config.age.secrets.launchdeck-vpn.path}"
  '';

  home.packages = [
    inputs.agenix.packages.${pkgs.stdenv.hostPlatform.system}.default
  ];
}

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

  age.secrets = {
    env-vars.file = "${inputs.self}/secrets/env-vars.age";
    s3cfg.file = "${inputs.self}/secrets/s3cfg.age";
  };

  programs.zsh.initExtra = lib.mkAfter ''
    # Load agenix secrets as environment variables
    if [ -f "${config.age.secrets.env-vars.path}" ]; then
      source "${config.age.secrets.env-vars.path}"
    fi
  '';

  programs.fish.interactiveShellInit = lib.mkAfter ''
    # Load agenix secrets as environment variables
    if test -f "${config.age.secrets.env-vars.path}"
      source "${config.age.secrets.env-vars.path}"
    end
  '';

  home.packages = [
    inputs.agenix.packages.${pkgs.stdenv.hostPlatform.system}.default
  ];
}

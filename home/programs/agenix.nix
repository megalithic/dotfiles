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
      work-env-vars.file = "${inputs.self}/secrets/work-env-vars.age";
      s3cfg.file = "${inputs.self}/secrets/s3cfg.age";
    };
  };

  # CRITICAL: Disable RunAtLoad to prevent hang during darwin-rebuild activation.
  # When darwin-rebuild runs as root (via sudo), it loads launch agents in a context
  # where the user's SSH key is inaccessible, causing agenix to fail repeatedly.
  # Secrets are already sourced via shell init (programs.zsh.initExtra / programs.fish.interactiveShellInit).
  # launchd.agents.activate-agenix = {
  #   enable = true;
  #   config = {
  #     RunAtLoad = lib.mkForce false;
  #     KeepAlive = lib.mkForce true;
  #   };
  # };

  programs.zsh.initExtra = lib.mkAfter ''
    # Load agenix secrets as environment variables
    if [ -f "${config.age.secrets.env-vars.path}" ]; then
      source "${config.age.secrets.env-vars.path}"
    fi

    # Load work-specific environment variables
    if [ -f "${config.age.secrets.work-env-vars.path}" ]; then
      source "${config.age.secrets.work-env-vars.path}"
    fi
  '';

  programs.fish.interactiveShellInit = lib.mkAfter ''
    # Load agenix secrets as environment variables
    if test -f "${config.age.secrets.env-vars.path}"
      source "${config.age.secrets.env-vars.path}"
    end

    # Load work-specific environment variables
    if test -f "${config.age.secrets.work-env-vars.path}"
      source "${config.age.secrets.work-env-vars.path}"
    end
  '';

  home.packages = [
    inputs.agenix.packages.${pkgs.stdenv.hostPlatform.system}.default
  ];
}

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
  #
  # Secrets are decrypted on-demand at shell login instead (see shell init below).
  launchd.agents.activate-agenix = {
    enable = true;
    config = {
      RunAtLoad = lib.mkForce false;
      KeepAlive = lib.mkForce false;
    };
  };

  # Decrypt secrets on-demand, then source them as environment variables.
  # The decryption step is needed because RunAtLoad is disabled above.
  programs.zsh.initExtra = lib.mkAfter ''
    # Decrypt secrets if they don't exist yet
    _agenix_secrets_dir="${config.age.secretsDir}"
    if [[ ! -d "$_agenix_secrets_dir" ]] || [[ -z "$(ls -A "$_agenix_secrets_dir" 2>/dev/null)" ]]; then
      _agenix_script=$(echo /nix/store/*-agenix-home-manager-mount-secrets/bin/agenix-home-manager-mount-secrets(N[1]))
      [[ -n "$_agenix_script" && -x "$_agenix_script" ]] && "$_agenix_script" >/dev/null 2>&1
    fi
    unset _agenix_secrets_dir _agenix_script

    # Load agenix secrets as environment variables
    if [ -f "${config.age.secrets.env-vars.path}" ]; then
      source "${config.age.secrets.env-vars.path}"
    fi

    # Load work-specific environment variables
    if [ -f "${config.age.secrets.work-env-vars.path}" ]; then
      source "${config.age.secrets.work-env-vars.path}"
    fi
  '';

  # Use shellInit (not interactiveShellInit) so scripts also get secrets
  programs.fish.shellInit = lib.mkAfter ''
    # Decrypt secrets if they don't exist yet
    set -l agenix_secrets_dir "${config.age.secretsDir}"
    if not test -d "$agenix_secrets_dir"; or test (count (command ls "$agenix_secrets_dir" 2>/dev/null)) -eq 0
      set -l agenix_scripts /nix/store/*-agenix-home-manager-mount-secrets/bin/agenix-home-manager-mount-secrets
      if test (count $agenix_scripts) -gt 0; and test -x "$agenix_scripts[1]"
        $agenix_scripts[1] >/dev/null 2>&1
      end
    end

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

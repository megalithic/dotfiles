{
  config,
  pkgs,
  lib,
  inputs,
  hostname,
  ...
}:
let
  # Per-host secret file, falls back to shared if host-specific doesn't exist
  workEnvVarsFile =
    let hostSpecific = "${inputs.self}/secrets/work-env-vars-${hostname}.age";
    in if builtins.pathExists hostSpecific
       then hostSpecific
       else "${inputs.self}/secrets/work-env-vars.age";
in
{
  imports = [
    inputs.agenix.homeManagerModules.default
  ];

  age = {
    identityPaths = [
      "${config.home.homeDirectory}/.ssh/id_ed25519"
    ];
    secrets = {
      env-vars.file = "${inputs.self}/secrets/env-vars.age";
      work-env-vars.file = workEnvVarsFile;
      s3cfg.file = "${inputs.self}/secrets/s3cfg.age";
    };
  };

  # CRITICAL: Disable RunAtLoad to prevent hang during darwin-rebuild activation.
  # When darwin-rebuild runs as root (via sudo), it loads launch agents in a context
  # where the user's SSH key is inaccessible, causing agenix to fail repeatedly.
  #
  # Secrets are decrypted on-demand at shell login instead (see shell init below).
  # launchd.agents.activate-agenix = {
  #   enable = true;
  #   config = {
  #     RunAtLoad = lib.mkForce true;
  #     KeepAlive = lib.mkForce true;
  #   };
  # };

  # ===========================================================================
  # Launchd Agent Throttling
  # ===========================================================================
  # The agenix home-manager module creates a launchd agent that decrypts secrets.
  #
  # KNOWN ISSUE: If decryption fails (e.g., stale .tmp file from interrupted run),
  # the agent retries indefinitely. ThrottleInterval prevents runaway retries.
  #
  # MANUAL RECOVERY (if secrets stop updating after editing .age files):
  #
  #   1. Check for stuck generation:
  #      ls -la "$(getconf DARWIN_USER_TEMP_DIR)/agenix.d/"
  #
  #   2. Remove the stuck generation (the newer one with .tmp files):
  #      rm -rf "$(getconf DARWIN_USER_TEMP_DIR)/agenix.d/<stuck-generation>"
  #
  #   3. Restart the agent:
  #      launchctl kickstart -k gui/$(id -u)/org.nix-community.home.activate-agenix
  #
  #   4. Verify symlink updated:
  #      ls -la "$(getconf DARWIN_USER_TEMP_DIR)/agenix"
  #
  #   5. Start new shell to pick up secrets:
  #      exec fish
  #
  # ===========================================================================
  launchd.agents.activate-agenix.config = {
    ThrottleInterval = 60; # Prevent runaway retries on decryption failure
  };

  # Decrypt secrets on-demand, then source them as environment variables.
  # The decryption step is needed because RunAtLoad is disabled above.
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

  # Use shellInit (not interactiveShellInit) so scripts also get secrets
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

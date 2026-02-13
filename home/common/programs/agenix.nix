# Agenix secrets for home-manager (standalone)
#
# Secrets are decrypted by a launchd agent on login and stored in:
#   $(getconf DARWIN_USER_TEMP_DIR)/agenix/
#
# To encrypt a new secret:
#   cd ~/.dotfiles/secrets && agenix -e <name>.age
#
# To rekey after adding/removing keys:
#   cd ~/.dotfiles/secrets && agenix -r
#
# Logs: ~/Library/Logs/agenix/{stdout,stderr}
#
# Ref: https://github.com/ryantm/agenix
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
    let
      hostSpecific = "${inputs.self}/secrets/work-env-vars-${hostname}.age";
    in
    if builtins.pathExists hostSpecific
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
      # Decrypt s3cfg directly to ~/.s3cfg where s3cmd expects it
      s3cfg = {
        file = "${inputs.self}/secrets/s3cfg.age";
        path = "${config.home.homeDirectory}/.s3cfg";
      };
    };
  };

  # Source secrets as environment variables in shells
  # (secrets are files - this makes them available as env vars)
  programs.zsh.initExtra = lib.mkAfter ''
    # Load agenix secrets as environment variables
    [ -f "${config.age.secrets.env-vars.path}" ] && source "${config.age.secrets.env-vars.path}"
    [ -f "${config.age.secrets.work-env-vars.path}" ] && source "${config.age.secrets.work-env-vars.path}"
  '';

  programs.fish.interactiveShellInit = lib.mkAfter ''
    # Load agenix secrets as environment variables
    test -f "${config.age.secrets.env-vars.path}" && source "${config.age.secrets.env-vars.path}"
    test -f "${config.age.secrets.work-env-vars.path}" && source "${config.age.secrets.work-env-vars.path}"
  '';

  home.packages = [
    inputs.agenix.packages.${pkgs.stdenv.hostPlatform.system}.default
  ];
}

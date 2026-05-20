# OpNix secrets for home-manager (standalone)
#
# Secrets are declared here and resolved by the OpNix Home Manager module.
#
# The only unmanaged input is the 1Password service account token. It must stay
# out of the Nix store and lives under XDG config:
#   ${XDG_CONFIG_HOME:-$HOME/.config}/opnix/token
#
# Ref: https://github.com/brizzbuzz/opnix
{
  config,
  pkgs,
  lib,
  inputs,
  # hostname,  # re-enable when rxbookpro hostSecrets are restored
  ...
}:
let
  secretsDir = "${config.xdg.configHome}/opnix/secrets";
  tokenFile = "${config.xdg.configHome}/opnix/token";
  commonSecrets = {
    envVars = {
      reference = "op://Crypt/env/notesPlain";
      path = "${secretsDir}/env-vars.sh";
      mode = "0600";
    };

    s3cfg = {
      reference = "op://Crypt/s3cfg/notesPlain";
      path = ".s3cfg";
      mode = "0600";
    };
  };

  # TODO(rxbookpro): re-enable once work-vars item is moved to a known vault.
  # hostSecrets = lib.optionalAttrs (hostname == "rxbookpro") {
  #   workEnvVars = {
  #     reference = "op://Work/rxbookpro-vars/shell-exports";
  #     path = "${secretsDir}/work-env-vars.sh";
  #     mode = "0600";
  #   };
  # };
  hostSecrets = { };
in
{
  programs.onepassword-secrets = {
    enable = true;
    inherit tokenFile;

    secrets = commonSecrets // hostSecrets;
  };

  programs.zsh.initContent = lib.mkAfter ''
    # Load opnix secrets as environment variables
    [ -f "${secretsDir}/env-vars.sh" ] && source "${secretsDir}/env-vars.sh"
    [ -f "${secretsDir}/work-env-vars.sh" ] && source "${secretsDir}/work-env-vars.sh"
  '';

  programs.fish.interactiveShellInit = lib.mkAfter ''
    # Load opnix secrets as environment variables
    test -f "${secretsDir}/env-vars.sh" && source "${secretsDir}/env-vars.sh"
    test -f "${secretsDir}/work-env-vars.sh" && source "${secretsDir}/work-env-vars.sh"
  '';

  home.packages = [
    inputs.opnix.packages.${pkgs.stdenv.hostPlatform.system}.default
  ];

  home.file.".config/opnix/.keep".text = "";
  home.file.".config/opnix/secrets/.keep".text = "";
}

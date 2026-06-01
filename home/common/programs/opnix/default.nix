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
  lib,
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

    appleDeveloperAppleId = {
      reference = "op://Crypt/apple-developer/username";
      path = "${secretsDir}/apple-developer/apple-id";
      mode = "0600";
    };

    appleDeveloperTeamId = {
      reference = "op://Crypt/apple-developer/Section_6qgogrdycnlqc4x7ngqwchlyvi/team id";
      path = "${secretsDir}/apple-developer/team-id";
      mode = "0600";
    };

    appleNotarytoolPassword = {
      reference = "op://Crypt/apple-developer/Section_6qgogrdycnlqc4x7ngqwchlyvi/notarytool app password";
      path = "${secretsDir}/apple-developer/notarytool-password";
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
    [ -f "${secretsDir}/apple-developer/apple-id" ] && export APPLE_ID_EMAIL="$(<"${secretsDir}/apple-developer/apple-id")"
    [ -f "${secretsDir}/apple-developer/team-id" ] && export APPLE_TEAM_ID="$(<"${secretsDir}/apple-developer/team-id")"
    [ -f "${secretsDir}/apple-developer/notarytool-password" ] && export APPLE_NOTARYTOOL_PASSWORD="$(<"${secretsDir}/apple-developer/notarytool-password")"
    [ -f "${secretsDir}/work-env-vars.sh" ] && source "${secretsDir}/work-env-vars.sh"
  '';

  programs.bash.bashrcExtra = lib.mkAfter ''
    # Load opnix secrets as environment variables
    [ -f "${secretsDir}/env-vars.sh" ] && source "${secretsDir}/env-vars.sh"
    [ -f "${secretsDir}/apple-developer/apple-id" ] && export APPLE_ID_EMAIL="$(<"${secretsDir}/apple-developer/apple-id")"
    [ -f "${secretsDir}/apple-developer/team-id" ] && export APPLE_TEAM_ID="$(<"${secretsDir}/apple-developer/team-id")"
    [ -f "${secretsDir}/apple-developer/notarytool-password" ] && export APPLE_NOTARYTOOL_PASSWORD="$(<"${secretsDir}/apple-developer/notarytool-password")"
    [ -f "${secretsDir}/work-env-vars.sh" ] && source "${secretsDir}/work-env-vars.sh"
  '';

  programs.fish.interactiveShellInit = lib.mkAfter ''
    # Load opnix POSIX-style KEY=value secrets as fish environment variables
    function __opnix_source_env_file --argument-names file
      test -f "$file" || return

      while read -l line
        set -l line (string trim -- "$line")
        test -z "$line" && continue
        string match -qr '^#' -- "$line" && continue

        set line (string replace -r '^export[[:space:]]+' "" -- "$line")
        string match -qr '^[A-Za-z_][A-Za-z0-9_]*=' -- "$line" || continue

        set -l parts (string split -m1 = -- "$line")
        set -gx $parts[1] $parts[2]
      end < "$file"
    end

    __opnix_source_env_file "${secretsDir}/env-vars.sh"
    test -f "${secretsDir}/apple-developer/apple-id"; and set -gx APPLE_ID_EMAIL (string collect < "${secretsDir}/apple-developer/apple-id")
    test -f "${secretsDir}/apple-developer/team-id"; and set -gx APPLE_TEAM_ID (string collect < "${secretsDir}/apple-developer/team-id")
    test -f "${secretsDir}/apple-developer/notarytool-password"; and set -gx APPLE_NOTARYTOOL_PASSWORD (string collect < "${secretsDir}/apple-developer/notarytool-password")
    __opnix_source_env_file "${secretsDir}/work-env-vars.sh"
    functions -e __opnix_source_env_file
  '';

  # opnix CLI is installed by the upstream OpNix module itself; adding it here
  # causes a pkgs.buildEnv conflict because it resolves to a different store path.

  home.file.".config/opnix/.keep".text = "";
  home.file.".config/opnix/secrets/.keep".text = "";
}

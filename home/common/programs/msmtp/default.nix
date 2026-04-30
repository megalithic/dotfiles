# msmtp - SMTP send + offline queue (msmtpq)
# Account-specific config lives in home/common/accounts.nix
{
  lib,
  ca-bundle_crt,
  ...
}: {
  programs.msmtp = {
    enable = true;
    # Enable offline queue - use configContent with mkBefore (extraConfig is deprecated)
    configContent = lib.mkBefore ''
      # Global msmtp configuration
      defaults
      auth on
      tls on
      tls_trust_file ${ca-bundle_crt}

      # Log all transactions
      logfile ~/.cache/msmtp/msmtp.log
    '';
  };

  # Create log directory
  home.file.".cache/msmtp/.keep".text = "";
}

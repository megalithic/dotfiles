{ config, pkgs, inputs, ... }:

{
  # Import the base megabookpro config and override specific settings
  imports = [ ./megabookpro.nix ];

  # Hostname-specific overrides for older MacBook Pro
  home.packages = with pkgs; [
    # Add any x86_64-specific packages here if needed
  ];

  # Override any settings specific to this machine
  programs.git.extraConfig = {
    # Inherit all from megabookpro.nix but can override specific settings
    user.signingkey = ""; # Override if different GPG key
  };

  # Environment variables specific to this machine
  home.sessionVariables = {
    # Add any machine-specific environment variables
    MACHINE_TYPE = "oldmbpro";
  };
}
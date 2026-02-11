# megabookpro home-manager configuration
# Imports shared config + adds host-specific overrides
{
  config,
  pkgs,
  lib,
  ...
}: {
  imports = [
    ./common
  ];

  # Host-specific home-manager overrides go here
  # Example: different shell aliases, extra packages, etc.
}

# rxbookpro (work laptop) home-manager configuration
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

  # Work-specific overrides
  # Example: different email config, work tools, etc.
}

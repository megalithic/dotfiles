# megabookpro home-manager configuration
# Imports shared config + adds host-specific overrides
{
  ...
}:
{
  imports = [
    ./common
  ];

  # llama.cpp: ownership flipped to mise (com.megadots.llama-cpp launchd agent
  # + mise/tasks/llama-server-launchd + config/llama-cpp/models.ini),
  # mirroring the same conservative 32GB defaults. The HM module
  # (programs.llamaCppLocal) stays available but disabled here.

  # Host-specific home-manager overrides go here
  # Example: different shell aliases, extra packages, etc.
}

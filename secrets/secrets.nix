# REFS:
# https://github.com/ryantm/agenix?tab=readme-ov-file#using-agenix-with-home-manager
# https://github.com/ryantm/agenix?tab=readme-ov-file#tutorial
# https://github.com/mhanberg/.dotfiles/blob/main/nix/home/secrets.nix
# https://wiki.nixos.org/wiki/Agenix#Tips_and_tricks
#
# Agenix secrets configuration
# Defines which SSH public keys can decrypt which secrets
#
# To encrypt a new secret:
#   agenix -e <secret-name>.age
#
# To rekey all secrets after adding/removing keys:
#   agenix -r
let
  # Your SSH public keys (from 1Password SSH agent)
  # Get with: ssh-add -L
  megaenv = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAICyxphJ0fZhJP6OQeYMsGNQ6E5ZMVc/CQdoYrWYGPDrh megaenv";

  # List of all authorized keys
  allKeys = [megaenv];
in {
  "env-vars.age".publicKeys = allKeys;
  "s3cfg.age".publicKeys = allKeys;

  # "api-keys.age".publicKeys = allKeys;
  # "github-token.age".publicKeys = allKeys;
  # "aws-credentials.age".publicKeys = allKeys;
  # "secret-name.age".publicKeys = allKeys;
}

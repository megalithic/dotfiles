{ config, ... }:
{
  home.file = {
    ".ssh/config".source = config.lib.mega.linkConfig "ssh/config";
    ".ssh/allowed_signers".text =
      "seth@megalithic.io ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAICyxphJ0fZhJP6OQeYMsGNQ6E5ZMVc/CQdoYrWYGPDrh";
  };

  xdg.configFile."1Password/ssh/agent.toml".text = ''
    [[ssh-keys]]
    vault = "Crypt"
    item = "megaenv_ssh_key"
  '';

  programs.ssh = {
    matchBlocks."* \"test -z $SSH_TTY\"".identityAgent =
      "~/Library/Group\ Containers/2BUA8C4S2C.com.1password/t/agent.sock";
  };
}

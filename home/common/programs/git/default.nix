{ pkgs, ... }:
{
  home.file = {
    ".ignore".source = ./tool-ignore;
    ".gitignore".source = ./gitignore;
    ".gitconfig".source = ./gitconfig;
  };

  programs.git = {
    enable = true;
    package = pkgs.gitFull;
    includes = [
      { path = "~/.gitconfig"; }
    ];

    settings.gpg.ssh.program = "/Applications/1Password.app/Contents/MacOS/op-ssh-sign";
    settings.gpg.ssh.allowedSignersFile = "~/.ssh/allowed_signers";
    settings.gpg.format = "ssh";
    settings.user.signingkey = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAICyxphJ0fZhJP6OQeYMsGNQ6E5ZMVc/CQdoYrWYGPDrh";
    settings.commit.gpgSign = true;
  };
}

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

    # 1Password GUI is installed by nix-darwin (programs._1password-gui) into
    # /Applications; its anti-tamper checks require running from /Applications
    # (it quits when run from ~/Applications or the nix store).
    settings.gpg.ssh.program = "/Applications/1Password.app/Contents/MacOS/op-ssh-sign";
    settings.gpg.ssh.allowedSignersFile = "~/.ssh/allowed_signers";
    settings.gpg.format = "ssh";
    settings.user.signingkey = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAICyxphJ0fZhJP6OQeYMsGNQ6E5ZMVc/CQdoYrWYGPDrh";
    settings.commit.gpgSign = true;
  };
}

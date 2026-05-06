{
  config,
  pkgs,
  username,
  hostname,
  ...
}: let
  aliases = import ./aliases.nix;
  # templates = import ./templates.nix;
in {
  programs.jujutsu = {
    enable = true;
    package = pkgs.unstable.jujutsu;
    settings = {
      user = {
        name = "Seth Messer";
        email = "seth@megalithic.io";
      };

      ui = {
        default-command = "log";
        pager = "${pkgs.delta}/bin/delta";
        diff-formatter = ":git";
        # graph.style = "curved";
        # should-sign-off = true;
        show-cryptographic-signatures = true;
      };

      signing = {
        behavior = "own";
        backend = "ssh";
        key = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAICyxphJ0fZhJP6OQeYMsGNQ6E5ZMVc/CQdoYrWYGPDrh";
        backends.ssh = {
          program = "/Applications/1Password.app/Contents/MacOS/op-ssh-sign";
          allowed-signers = "${config.home.homeDirectory}/.ssh/allowed_signers";
        };
      };

      "merge-tools" = {
        difftool = {
          program = "nvim";
          diff-args = [ "-c" "packadd nvim.difftool" "-d" "$left" "$right" ];
        };
      };

      # Auto-update stale workspaces when switching between them
      snapshot.auto-update-stale = true;
      remotes.origin.auto-track-bookmarks = "glob:*";
      colors = {
        commit_id = "magenta";
        change_id = "cyan";
        "working_copy empty" = "green";
        "working_copy placeholder" = "red";
        "working_copy description placeholder" = "yellow";
        "working_copy empty description placeholder" = "green";
        prefix = {
          bold = true;
          fg = "cyan";
        };
        rest = {
          bold = false;
          fg = "bright black";
        };
        "node elided" = "yellow";
        "node working_copy" = "green";
        "node conflict" = "red";
        "node immutable" = "red";
        "node normal" = {bold = false;};
        "node" = {bold = false;};
      };

      templates = {
        draft_commit_description = "builtin_draft_commit_description_with_diff";
      };

      inherit aliases;
      # inherit (templates) revsets revset-aliases template-aliases templates;
    };
  };
}

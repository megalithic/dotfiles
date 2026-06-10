{ lib, ... }:
{
  git-hooks.hooks.typos.enable = lib.mkForce false;

  devenv-base.gitignore.enable = false;
  devenv-base.treefmt = {
    settings.global.excludes = [
      "config/nvim/spell/en.utf-8.add"
      # Vendored third-party source (svkozak/pi-acp) — keep upstream formatting
      "home/common/programs/pi-coding-agent/packages/pi-acp/**"
    ];
    programs = {
      # Comment out or remove formatters you don't want
      # fish_indent.enable = true;
      # nixpkgs-fmt.enable = true;
      # prettier.enable = true;
      # shfmt.enable = true;
      # biome.enable = true;
    };
  };

  tasks = {
    "home:apply" = {
      description = "Apply home-manager configuration";
      # exec = "home-manager switch --flake ./home";
      exec = "just home";
    };
    "system:apply" = {
      description = "Apply nix-darwin configuration";
      # exec = "sudo darwin-rebuild switch --flake ./system";
      exec = "just darwin";
    };
    "nix:update" = {
      description = "Update home and system flake lockfiles, devenv, and manually-pinned packages";
      exec = ''
        # nix flake update --flake ./home
        # nix flake update --flake ./system
        nix flake update --flake ./
        devenv update
        pi -p "Check these two manually-pinned packages for newer versions and update them if newer exists. DO NOT apply any changes (no home-manager switch, no nix-build). DO NOT commit. ONLY update the source files — nothing else.

        1. pi-mcp-adapter (packages/pi-mcp-adapter.nix): check GitHub releases at nicobailon/pi-mcp-adapter for version newer than what's in the nix file. If newer: update version, rev, src hash, and npmDepsHash in packages/pi-mcp-adapter.nix.

        2. pi-web-access (packages/pi-web-access.nix): check GitHub releases at nicobailon/pi-web-access for version newer than what's in the nix file. If newer: update version, rev, src hash, and npmDepsHash in packages/pi-web-access.nix."
      '';
    };
  };
}

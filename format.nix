{ pkgs }:
{
  runtimeInputs = with pkgs; [
    # keep-sorted start
    deadnix
    keep-sorted
    nixfmt-rfc-style
    statix
    stylua
    taplo
    # keep-sorted end

    (writeShellScriptBin "statix-fix" ''
      for file in "$@"; do
        ${lib.getExe statix} fix "$file"
      done
    '')
  ];

  settings = {
    on-unmatched = "info";
    tree-root-file = "flake.nix";

    excludes = [
      "pkgs/ivy-plugins/_sources/*"
    ];

    formatter = {
      # keep-sorted start block=yes newline_separated=yes
      deadnix = {
        command = "deadnix";
        includes = [ "*.nix" ];
      };

      keep-sorted = {
        command = "keep-sorted";
        includes = [ "*" ];
      };

      nixfmt = {
        command = "nixfmt";
        includes = [ "*.nix" ];
      };

      statix = {
        command = "statix-fix";
        includes = [ "*.nix" ];
      };

      stylua = {
        command = "stylua";
        includes = [ "*.lua" ];
      };

      taplo = {
        command = "taplo";
        options = "format";
        includes = [ "*.toml" ];
      };
      # keep-sorted end
    };
  };
}

{
  config,
  pkgs,
  username,
  hostname,
  ...
}: let
  inherit (pkgs.stdenv.hostPlatform) isDarwin;
  
  aliases = import ./aliases.nix { inherit pkgs isDarwin; };
  abbr = import ./abbr.nix;
  functions = import ./functions.nix { inherit isDarwin; };
  plugins = import ./plugins.nix { inherit pkgs; };
  completions = import ./completions.nix;
  keybindings = import ./keybindings.nix;
  theme = import ./theme.nix;
in {
  programs.fish = {
    enable = true;
    
    shellInit = completions;
    
    interactiveShellInit = ''
      ${keybindings}
      ${theme}
    '';
    
    inherit functions;
    shellAliases = aliases;
    shellAbbrs = abbr;
    inherit plugins;
  };
}

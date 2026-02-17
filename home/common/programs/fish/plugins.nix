# Fish shell plugins
{ pkgs }:
[
  {
    name = "autopair";
    inherit (pkgs.fishPlugins.autopair) src;
  }
  {
    name = "nix-env";
    src = pkgs.fetchFromGitHub {
      owner = "lilyball";
      repo = "nix-env.fish";
      rev = "7b65bd228429e852c8fdfa07601159130a818cfa";
      hash = "sha256-RG/0rfhgq6aEKNZ0XwIqOaZ6K5S4+/Y5EEMnIdtfPhk";
    };
  }
  {
    name = "done";
    src = pkgs.fetchFromGitHub {
      owner = "franciscolourenco";
      repo = "done";
      rev = "d6abb267bb3fb7e987a9352bc43dcdb67bac9f06";
      sha256 = "6oeyN9ngXWvps1c5QAUjlyPDQwRWAoxBiVTNmZ4sG8E=";
    };
  }
]

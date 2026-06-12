{ pkgs, ... }:
{
  home.packages = [
    pkgs.tidewave # Tidewave GUI app for web app development
    pkgs.tidewave-cli # Tidewave MCP CLI
  ];
}

{ pkgs, ... }:
# duti — set default applications for document types and URL schemes on macOS.
# Used to re-assert preferred file-type handlers (e.g. PDF) that browsers
# reclaim via LaunchServices on reinstall/registration.
{
  home.packages = [ pkgs.duti ];
}

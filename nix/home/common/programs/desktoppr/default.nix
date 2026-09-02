{
  lib,
  pkgs,
  paths,
  ...
}:
{
  home.activation.setWallpaper = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
    WALLPAPER="${paths.dotfiles}/assets/bokeh_dark.jpg"
    if [ -f "$WALLPAPER" ]; then
      run ${pkgs.desktoppr}/bin/desktoppr "$WALLPAPER"
    fi
  '';
}

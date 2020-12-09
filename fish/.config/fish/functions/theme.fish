function theme -d "toggle kitty theme"
  if test -z "$argv[1]"
    if test "$termTheme" = "light"
      _gruvbox_light
    else
      _gruvbox_dark
    end
  end
  if test "$argv[1]" = "dark"
    _gruvbox_dark
  end
  if test "$argv[1]" = "light"
    _gruvbox_light
  end
  if test "$argv[1]" = "switch"
    if test "$termTheme" = "light"
      _gruvbox_dark
    else
      _gruvbox_light
    end
  end
end

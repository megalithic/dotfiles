# Fish shell aliases
{
  pkgs,
  isDarwin,
}: {
  ls = "${pkgs.eza}/bin/eza --all --group-directories-first --color=always --hyperlink";
  l = "${pkgs.eza}/bin/eza --all --long --color=always --color-scale=all --group-directories-first --sort=type --hyperlink --icons=always --octal-permissions";
  ll = "${pkgs.eza}/bin/eza -lahF --group-directories-first --color=always --icons=always --hyperlink";
  la = "${pkgs.eza}/bin/eza -lahF --group-directories-first --color=always --icons=always --hyperlink";
  tree = "${pkgs.eza}/bin/eza --tree --color=always";

  rm = "${pkgs.darwin.trash}/bin/trash -v";
  q = "exit";
  ",q" = "exit";
  ":q" = "exit";
  ":Q" = "exit";
  ":e" = "nvim";
  mega = "ftm mega";

  copy =
    if isDarwin
    then "pbcopy"
    else "xclip -selection clipboard";
  paste =
    if isDarwin
    then "pbpaste"
    else "xlip -o -selection clipboard";

  cat = "bat";
  "!!" = "eval \\$history[1]";
  clear = "clear && _prompt_move_to_bottom";

  # Inspect $PATH
  pinspect = ''echo "$PATH" | tr ":" "\n"'';
  pathi = ''echo "$PATH" | tr ":" "\n"'';
}

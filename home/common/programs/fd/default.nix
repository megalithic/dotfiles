_: {
  programs.fd = {
    enable = true;
    ignores = [
      ".git"
      ".jj"
      ".direnv"
      "pkg"
      "Library"
      ".Trash"
    ];
  };
}

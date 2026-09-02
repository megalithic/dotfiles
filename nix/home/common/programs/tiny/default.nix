_: {
  programs.tiny = {
    enable = true;
    settings = {
      servers = [
        {
          addr = "irc.libera.chat";
          port = 6697;
          tls = true;
          realname = "Seth";
          nicks = [ "replicant" ];
          join = [
            "#nethack"
            "#nixos"
            "#neovim"
          ];
        }
      ];
      defaults = {
        nicks = [ "replicant" ];
        realname = "Seth";
        join = [ ];
        tls = true;
      };
    };
  };
}

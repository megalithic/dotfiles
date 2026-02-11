{pkgs, ...}: {
  enable = true;
  enableFishIntegration = true;
  enableZshIntegration = true;
  settings = {
    mgr = {
      ratio = [
        1
        3
        4
      ];
      sort_by = "natural";
      sort_dir_first = true;
      show_hidden = false;
      show_symlink = false;
      linemode = "size";
    };
    opener = {
      edit = [
        {
          run = ''nvim "$@"'';
          block = true;
        }
      ];
      # play = [
      #   {
      #     run = ''mpv "$@"'';
      #     orphan = true;
      #     for = "unix";
      #   }
      # ];
      open = [
        {
          run = ''xdg-open "$@"'';
          desc = "open";
        }
      ];
    };
    # open = {
    #   prepend_rules = [
    #     {
    #       name = "*.ts";
    #       use = "edit";
    #     }
    #   ];
    # };
  };

  keymap = {
    input = {
      prepend_keymap = [
        # https://yazi-rs.github.io/docs/tips#close-input-by-esc
        {
          on = ["<Esc>"];
          run = "close";
          desc = "Cancel input";
        }
      ];
    };
    mgr = {
      prepend_keymap = [
        # https://yazi-rs.github.io/docs/tips#dropping-to-shell
        {
          on = ["<C-s>"];
          run = "shell ${pkgs.fish} --block --confirm";
          desc = "Open default shell here";
        }

        # https://yazi-rs.github.io/docs/tips#smart-enter
        # also needs smart-enter plugin, below
        {
          on = ["<Enter>"];
          run = "plugin --sync smart-enter";
          desc = "Enter the child directory, or open the file";
        }

        # {
        #   on = [
        #     "f"
        #     "g"
        #   ];
        #   run = "plugin fg";
        #   desc = "find file by content";
        # }
        # {
        #   on = [
        #     "f"
        #     "f"
        #   ];
        #   run = "plugin fg --args='fzf'";
        #   desc = "find file by file name";
        # }
      ];
    };
  };
  plugins = {
    "smart-enter" = ./plugins/smart-enter;
  };
}

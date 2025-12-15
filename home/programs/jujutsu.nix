{
  config,
  pkgs,
  username,
  hostname,
  ...
}: {
  programs.jujutsu = {
    enable = true;
    settings = {
      user = {
        name = "Seth Messer";
        email = "seth@megalithic.io";
      };
      ui = {
        # paginate = "never";
        default-command = "log";
        pager = "${pkgs.delta}/bin/delta";
        diff-formatter = ":git";
        graph.style = "curved";
        should-sign-off = true;
        show-cryptographic-signatures = true;
      };
      signing = {
        behavior = "own";
        backend = "ssh";
        key = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAICyxphJ0fZhJP6OQeYMsGNQ6E5ZMVc/CQdoYrWYGPDrh";
        backends.ssh = {
          program = "/Applications/1Password.app/Contents/MacOS/op-ssh-sign";
          allowed-signers = "${config.home.homeDirectory}/.ssh/allowed_signers";
        };
      };

      # fix.tools.nixfmt = {
      #   command = [
      #     "${lib.getExe pkgs.nixfmt-rfc-style}"
      #     "--strict"
      #     "--filename=$path"
      #   ];
      #   patterns = [ "glob:'**/*.nix'" ];
      # };

      colors = {
        commit_id = "magenta";
        change_id = "cyan";
        "working_copy empty" = "green";
        "working_copy placeholder" = "red";
        "working_copy description placeholder" = "yellow";
        "working_copy empty description placeholder" = "green";
        prefix = {
          bold = true;
          fg = "cyan";
        };
        rest = {
          bold = false;
          fg = "bright black";
        };
        "node elided" = "yellow";
        "node working_copy" = "green";
        "node conflict" = "red";
        "node immutable" = "red";
        "node normal" = {bold = false;};
        "node" = {bold = false;};
      };
      # git = {
      #   sign-on-push = true;
      #   write-change-id-header = true;
      # };
      aliases = {
        s = ["status"];
        l = ["log"];
        ll = ["log" "-T" "builtin_log_compact_full_description"];
        # ll = [ "log" "-r" ".." ];
        d = ["diff"];
        rb = ["rebase"];
        b = ["bookmark"];
        g = ["git"];
        push = ["git" "push"];
        dv = ["desc"];
        dm = ["desc" "-m"];
        main = ["bookmark" "move" "main" "--to" "@"];
        # tug = [ "bookmark" "move" "--from" "heads(::@- & bookmarks())" "--to" "@-" ];
        # Advances closest bookmark to parent commit
        tug = ["bookmark" "move" "--from" "closest_bookmark(@-)" "--to" "@-"];
      };
      revsets = {
        log = "current_work";
      };
      revset-aliases = {
        "stack()" = "ancestors(reachable(@, mutable()), 2)";
        "stack(x)" = "ancestors(reachable(x, mutable()), 2)";
        "stack(x, n)" = "ancestors(reachable(x, mutable()), n)";
        "current_work" = "trunk()..@ | @..trunk() | trunk() | @:: | fork_point(trunk() | @)";
        "closest_bookmark(to)" = "heads(::to & bookmarks())";
      };
      template-aliases = {
        "format_short_id(id)" = "id.shortest()";
        "abbreviate_timestamp_suffix(s, suffix, abbr)" = ''
          if(
              s.ends_with(suffix),
              s.remove_suffix(suffix) ++ label("timestamp", abbr)
          )
        '';
        "abbreviate_relative_timestamp(s)" = ''
          coalesce(
              abbreviate_timestamp_suffix(s, " millisecond", "ms"),
              abbreviate_timestamp_suffix(s, " second", "s"),
              abbreviate_timestamp_suffix(s, " minute", "m"),
              abbreviate_timestamp_suffix(s, " hour", "h"),
              abbreviate_timestamp_suffix(s, " day", "d"),
              abbreviate_timestamp_suffix(s, " week", "w"),
              abbreviate_timestamp_suffix(s, " month", "mo"),
              abbreviate_timestamp_suffix(s, " year", "y"),
              s
          )
        '';
        "format_timestamp(timestamp)" = ''
          coalesce(
              if(timestamp.after("1 minute ago"), label("timestamp", "<=1m")),
              abbreviate_relative_timestamp(timestamp.ago().remove_suffix(' ago').remove_suffix('s'))
          )
        '';
      };
      templates = {
        log = ''
          if(root,
            format_root_commit(self),
            label(if(current_working_copy, "working_copy"),
              concat(
                separate(" ",
                  pad_end(4, format_short_change_id_with_hidden_and_divergent_info(self)),
                  if(empty, label("empty", "(empty)")),
                  if(description,
                    description.first_line(),
                    label(if(empty, "empty"), description_placeholder),
                  ),
                  bookmarks,
                  tags,
                  working_copies,
                  if(git_head, label("git_head", "HEAD")),
                  if(conflict, label("conflict", "conflict")),
                  if(config("ui.show-cryptographic-signatures").as_boolean(),
                    format_short_cryptographic_signature(signature)),
                  format_timestamp(commit_timestamp(self)),
                ) ++ "\n",
              ),
            )
          )
        '';
        log_node = ''
          label("node",
            coalesce(
              if(!self, label("elided", "~")),
              if(current_working_copy, label("working_copy", "@")),
              if(conflict, label("conflict", "×")),

              if(immutable, label("immutable", "*")),
              label("normal", "·")
            )
          )
        '';
        draft_commit_description = ''
          concat(
            coalesce(description, default_commit_description, "\n"),
            if(
              config("ui.should-sign-off").as_boolean() && !description.contains("Signed-off-by: " ++ author.name()),
              "\nSigned-off-by: " ++ author.name() ++ " <" ++ author.email() ++ ">",
            ),
            surround(
              "\nJJ: This commit contains the following changes:\n", "",
              indent("JJ:     ", diff.stat(72)),
            ),
            "\nJJ: ignore-rest\n",
            diff.git(),
          )
        '';
      };
      # fix.tools.nix-fmt = {
      #   command = [
      #     "nix"
      #     "fmt"
      #   ];
      #   patterns = [ "glob:'**/*.nix'" ];
      # };
    };
  };
}

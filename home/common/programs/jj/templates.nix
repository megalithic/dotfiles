# Jujutsu templates, revsets, and template-aliases
{
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
              pad_end(4, format_short_change_id(change_id)),
              if(empty, label("empty", "(empty)")),
              if(description,
                description.first_line(),
                label(if(empty, "empty"), description_placeholder),
              ),
              bookmarks,
              tags,
              working_copies,
              if(self.contained_in('first_parent(@)'), label("git_head", "HEAD")),
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
}

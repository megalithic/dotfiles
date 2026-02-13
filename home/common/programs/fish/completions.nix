# Fish shell completions (loaded in shellInit)
''
  export PATH="$HOME/.nix-profile/bin:$PATH"
  set -g fish_prompt_pwd_dir_length 20

  # jj bookmark completion helper
  function __fish_jj_bookmarks
    jj bookmark list --template 'if(!remote, name ++ "\n")' 2>/dev/null
  end

  # jj bookmark completions
  complete -c jj -n "__fish_seen_subcommand_from push" -s b -l bookmark -xa "(__fish_jj_bookmarks)" -d "Bookmark"
  complete -c jj -n "__fish_seen_subcommand_from git; and __fish_seen_subcommand_from push" -s b -l bookmark -xa "(__fish_jj_bookmarks)" -d "Bookmark"
  complete -c jj -n "__fish_seen_subcommand_from bookmark; and __fish_seen_subcommand_from delete d forget f set s move m rename r" -xa "(__fish_jj_bookmarks)" -d "Bookmark name"

  # mix task completion helper (project-aware)
  function __fish_mix_tasks
    mix help 2>/dev/null | string match -r '^mix \S+' | string replace 'mix ' ""
  end

  # mix task completions
  complete -c mix -xa "(__fish_mix_tasks)"
''

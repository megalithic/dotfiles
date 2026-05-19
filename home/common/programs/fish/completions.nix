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

  # Git worktree completions
  function __fish_git_pr_branches
    gh pr list --state open --json number,title,author,createdAt,headRefName --limit 50 2>/dev/null | jq -r '.[] | "\(.headRefName)"'
  end

  complete -c git-worktree-cd -f -a '(__git_worktree_names)' -d 'Worktree'
  complete -c git-worktree-new -f -a '(__git_worktree_names)' -d 'Worktree'
  complete -c git-worktree-prune -f -a '(__git_worktree_names)' -d 'Worktree'
  complete -c git-worktree-pr -f -a '(__fish_git_pr_branches)' -d 'PR branch'
''

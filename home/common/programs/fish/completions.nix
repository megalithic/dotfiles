# Fish shell completions (loaded in shellInit)
{ wtBin }:
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

  # Worktrunk smart wrapper completions (local `wt` fish function).
  # Uses the real binary directly to avoid invoking the fish wrapper.
  function __fish_wt_worktrees
    ${wtBin} list --format=json 2>/dev/null | jq -r '.[] | "\(.branch)\t\(.path)"' 2>/dev/null
  end

  # Subcommands (kept visible since upstream fish init is disabled).
  complete -c wt -n __fish_use_subcommand -f -a switch -d 'Switch to a worktree; create if needed'
  complete -c wt -n __fish_use_subcommand -f -a list -d 'List worktrees'
  complete -c wt -n __fish_use_subcommand -f -a remove -d 'Remove a worktree'
  complete -c wt -n __fish_use_subcommand -f -a merge -d 'Merge current branch into target'
  complete -c wt -n __fish_use_subcommand -f -a select -d 'Select a worktree'
  complete -c wt -n __fish_use_subcommand -f -a step -d 'Render hook template step'
  complete -c wt -n __fish_use_subcommand -f -a hook -d 'Manage hooks'
  complete -c wt -n __fish_use_subcommand -f -a config -d 'Manage Worktrunk config/state'

  # Worktree branch names: explicit (`wt switch <TAB>`) and implicit (`wt <TAB>`,
  # including after `-t/--target <value> <TAB>` since no subcommand is seen yet).
  complete -c wt -n '__fish_seen_subcommand_from switch' -f -a '(__fish_wt_worktrees)' -d Worktree
  complete -c wt -n __fish_use_subcommand -f -a '(__fish_wt_worktrees)' -d Worktree

  # Local tmux target option.
  complete -c wt -s t -l target -x -a 'window session' -d 'tmux target'
''

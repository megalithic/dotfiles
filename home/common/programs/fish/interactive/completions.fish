status is-interactive; or return

# jj bookmark completion helper
function __fish_jj_bookmarks
    jj bookmark list --template 'if(!remote, name ++ "\n")' 2>/dev/null
end

complete -c jj -n "__fish_seen_subcommand_from push" -s b -l bookmark -xa "(__fish_jj_bookmarks)" -d "Bookmark"
complete -c jj -n "__fish_seen_subcommand_from git; and __fish_seen_subcommand_from push" -s b -l bookmark -xa "(__fish_jj_bookmarks)" -d "Bookmark"
complete -c jj -n "__fish_seen_subcommand_from bookmark; and __fish_seen_subcommand_from delete d forget f set s move m rename r" -xa "(__fish_jj_bookmarks)" -d "Bookmark name"

# mix task completion helper (project-aware)
function __fish_mix_tasks
    mix help 2>/dev/null | string match -r '^mix \S+' | string replace 'mix ' ""
end

complete -c mix -xa "(__fish_mix_tasks)"

# Worktrunk smart wrapper completions (local `wt` fish function).
function __fish_wt_worktrees
    set -l wt_bin "$WORKTRUNK_BIN"
    test -z "$wt_bin"; and set wt_bin (command -s wt)
    test -z "$wt_bin"; and return 0

    $wt_bin list --format=json 2>/dev/null | jq -r '.[] | "\(.branch)\t\(.path)"' 2>/dev/null
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

# Worktree branch names: explicit (`wt switch <TAB>`) and implicit (`wt <TAB>`).
complete -c wt -n '__fish_seen_subcommand_from switch' -f -a '(__fish_wt_worktrees)' -d Worktree
complete -c wt -n __fish_use_subcommand -f -a '(__fish_wt_worktrees)' -d Worktree

# Local tmux target option.
complete -c wt -s t -l target -x -a 'window session' -d 'tmux target'

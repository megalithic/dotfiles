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
    set -l wt_bin ~/.dotfiles/bin/wt
    test -x "$wt_bin"; or return 0

    $wt_bin list --json 2>/dev/null | jq -r '.items[] | "\(.branch)\t\(.worktree.path // .remote // \"remote\")"' 2>/dev/null
end

# Subcommands (kept visible since upstream fish init is disabled).
complete -c wt -n __fish_use_subcommand -f -a switch -d 'Use the upstream Worktrunk switch command'
complete -c wt -n __fish_use_subcommand -f -a ensure -d 'Ensure setup and canonical session without attaching'
complete -c wt -n __fish_use_subcommand -f -a new -d 'Create and set up a new worktree'
complete -c wt -n __fish_use_subcommand -f -a open -d 'Open the canonical worktree session'
complete -c wt -n __fish_use_subcommand -f -a path -d 'Print the canonical worktree path'
complete -c wt -n __fish_use_subcommand -f -a repair -d 'Repair setup and canonical session'
complete -c wt -n __fish_use_subcommand -f -a prune -d 'Safely remove an integrated worktree'
complete -c wt -n __fish_use_subcommand -f -a list -d 'List worktrees'
complete -c wt -n __fish_use_subcommand -f -a remove -d 'Use the upstream Worktrunk remove command'
complete -c wt -n __fish_use_subcommand -f -a merge -d 'Merge current branch into target'
complete -c wt -n __fish_use_subcommand -f -a select -d 'Select a worktree'
complete -c wt -n __fish_use_subcommand -f -a step -d 'Render hook template step'
complete -c wt -n __fish_use_subcommand -f -a hook -d 'Manage hooks'
complete -c wt -n __fish_use_subcommand -f -a config -d 'Manage Worktrunk config/state'

# Worktree branch names: explicit (`wt switch <TAB>`) and implicit (`wt <TAB>`).
complete -c wt -n '__fish_seen_subcommand_from switch' -f -a '(__fish_wt_worktrees)' -d Worktree
complete -c wt -n __fish_use_subcommand -f -a '(__fish_wt_worktrees)' -d Worktree

# Worktree presentation target: current shell by default, or tmux window/session.
complete -c wt -s t -l target -x -a 'cd window w session s' -d 'presentation target'

# Pi /piview scopes (pview wrapper)
for scope in uncommitted unpushed branch pr ticket worktrees
    complete -c pview -f -a $scope -d "/piview $scope"
end

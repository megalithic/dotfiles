# jj bookmark completion helper
function __fish_jj_bookmarks
    jj bookmark list --template 'if(!remote, name ++ "\n")' 2>/dev/null
end

complete -c jj -n "__fish_seen_subcommand_from push" -s b -l bookmark -xa "(__fish_jj_bookmarks)" -d "Bookmark"
complete -c jj -n "__fish_seen_subcommand_from git; and __fish_seen_subcommand_from push" -s b -l bookmark -xa "(__fish_jj_bookmarks)" -d "Bookmark"
complete -c jj -n "__fish_seen_subcommand_from bookmark; and __fish_seen_subcommand_from delete d forget f set s move m rename r" -xa "(__fish_jj_bookmarks)" -d "Bookmark name"

# mega: start/stop background Ultimate instances (bin/mega)
complete -c mega -f
complete -c mega -n __fish_use_subcommand -a start -d "Start Ultimate for a directory"
complete -c mega -n __fish_use_subcommand -a stop -d "Stop a running Ultimate"
complete -c mega -n __fish_use_subcommand -a ls -d "List running Ultimates"
complete -c mega -n "__fish_seen_subcommand_from start" -xa "(__fish_complete_directories)"
complete -c mega -n "__fish_seen_subcommand_from stop" -xa "(mega ls 2>/dev/null)"

# mix task completion helper (project-aware)
function __fish_mix_tasks
    mix help 2>/dev/null | string match -r '^mix \S+' | string replace 'mix ' ""
end

complete -c mix -xa "(__fish_mix_tasks)"

# Pi /piview scopes (pview wrapper)
for scope in uncommitted unpushed branch pr ticket worktrees
    complete -c pview -f -a $scope -d "/piview $scope"
end

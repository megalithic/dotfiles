function __git_worktree_names
    set -l git_common_dir (git rev-parse --git-common-dir 2>/dev/null)
    test -z "$git_common_dir"; and return

    set -l repo_root (dirname "$git_common_dir")
    set -l worktrees_dir "$repo_root/.worktrees"

    test -d "$worktrees_dir"; or return

    for dir in "$worktrees_dir"/*/
        basename "$dir"
    end
end

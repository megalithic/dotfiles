function git-worktree-prune
    if test (count $argv) -lt 1
        echo "Usage: git-worktree-prune <branch_name>"
        return 1
    end

    set -l branch_name $argv[1]
    set -l repo_root (git rev-parse --show-toplevel 2>/dev/null)
    if test -z "$repo_root"
        echo "Error: Not in a git repository"
        return 1
    end

    set -l worktree_path "$repo_root/.worktrees/$branch_name"

    if not test -d "$worktree_path"
        echo "Error: Could not find worktree for branch $branch_name"
        echo ""
        echo "Available worktrees:"
        git worktree list
        return 1
    end

    echo "Removing worktree: $worktree_path"
    git worktree remove "$worktree_path" --force
    echo "✓ Worktree removed"

    if git show-ref --verify --quiet "refs/heads/$branch_name"
        echo "Deleting branch: $branch_name"
        git branch -D "$branch_name"
        echo "✓ Branch deleted"
    end
end

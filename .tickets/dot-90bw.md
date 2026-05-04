---
id: dot-90bw
status: open
deps: []
links: []
created: 2026-05-04T18:45:00Z
type: feature
priority: 2
assignee: 
parent: 
tags: [pi-skill, jj, conflict-resolution, git-merge, workflow-automation]
---
# pi skill: jj massive conflict resolution with multi-commit history preservation

Create a pi-coding-agent skill that provides vetted scripts and workflows for resolving large merge conflicts across multiple commits in jj/jujutsu repositories, while preserving well-defined commit history (not squashing to a single commit).

## Context

During PR #800 rebase in the rx repo (34 commits → 6 logical groups via squash), we discovered:

1. **jj's conflict format is harder to work with than git's diff3 markers**
   - jj uses diff+snapshot format showing "destination diff vs rebased revision content"
   - Standard git 3-way merge (`git merge-file --diff3`) produces clearer conflict markers with base/ours/theirs sections
   - diff3 format is more intuitive for manual resolution

2. **Conflict resolution across multiple commits is repetitive**
   - Resolving N commits individually means repeating similar merge logic N times
   - Each squashed commit represents 5-12 original commits worth of changes
   - Total effort for 6 commits ≈ effort for 1 mega-commit

3. **Better workflow exists: resolve once, reshape history after**
   - Use jj's history editing strengths (split/diffedit) AFTER conflicts are resolved
   - Separate conflict resolution (hard) from commit organization (easy with jj)
   - Resolve all conflicts once at bookmark tip using 3-way merge
   - Then use `jj split` or `jj diffedit` to carve into logical commits

4. **3-way merge setup that worked well:**
   ```bash
   # Get base (fork point), branch endpoint, and main versions
   jj file show -r 'fork_point(main@origin | branch@origin)' path > base.ex
   jj file show -r 'branch@origin' path > branch.ex  
   jj file show -r 'main@origin' path > main.ex
   
   # Run 3-way merge with diff3 markers
   git merge-file --diff3 branch.ex base.ex main.ex
   # Produces clearer conflict markers than jj's native format
   ```

## What the skill should provide

### 1. Conflict resolution workflow script

A helper command (e.g., `jj-resolve-rebase` or integrated into existing skills) that:

- Detects all conflicted files at current revision
- For each file, automatically generates 3-way merge using git merge-file:
  - Extracts base version from fork point
  - Extracts branch version from original bookmark@origin
  - Extracts main version from rebase destination
  - Runs `git merge-file --diff3` to generate cleaner conflict markers
- Places merged files with conflict markers in working copy
- Provides clear next steps for manual resolution

### 2. Multi-commit history preservation workflow

After conflicts are resolved at the tip, provide guidance/automation for:

- Using `jj split` to interactively carve resolved state into logical commits
- Using `jj diffedit` to selectively move hunks into separate commits
- Suggesting logical groupings based on file paths or git history analysis
- Validating each split commit compiles/tests independently (optional)

### 3. Documentation and best practices

- When to resolve once vs per-commit (decision tree)
- How diff3 markers work vs jj's conflict format
- Examples of good commit groupings for different scenarios
- Recovery paths if things go wrong (`jj op restore`)

## Why

- **Efficiency:** Resolve conflicts once instead of N times across commits
- **Clarity:** diff3 markers are more intuitive than jj's diff+snapshot format
- **Quality:** Better commit history through intentional splitting vs accidental squashing
- **Teachability:** Codifies learnings from real-world complex rebases

## Acceptance Criteria

1. Skill file exists in pi-coding-agent skills directory with proper SKILL.md
2. Core script can detect conflicted files and generate 3-way merged versions with diff3 markers
3. Documentation includes:
   - Decision tree: when to use this vs manual per-commit resolution
   - Step-by-step example from a real rebase scenario
   - Common pitfalls and recovery procedures
4. Workflow supports both "resolve once + split" and "resolve per-group + merge" approaches
5. Script is non-destructive (creates temp files, provides rollback via `jj op restore`)
6. Manual test: Successfully resolve a 10+ commit rebase with 4+ conflicted files using the skill
7. Bonus: Integration with editor (nvim) for launching 3-way merge in split windows

## Reference Materials

- Session context: ~/.local/share/pi/sessions/YYYY-MM-DD/... (rx PR #800 rebase session)
- git merge-file docs: `man git-merge-file`
- jj conflict resolution: https://martinvonz.github.io/jj/latest/working-copy/#resolve-conflicts
- jj history editing: https://martinvonz.github.io/jj/latest/FAQ/#how-do-i-resume-working-on-an-existing-change
- Related skills: task-pipeline, git-worktrees

## Notes

- This skill emerged from attempting to resolve PR #800 in rx repo
- Initial approach (resolve 34 commits individually) was impractical
- Squashing to 6 logical groups helped but still required 6× resolution effort
- "Resolve once, reshape after" proved to be the most efficient strategy
- The hard part is merging conflicting changes; jj makes history editing easy afterward

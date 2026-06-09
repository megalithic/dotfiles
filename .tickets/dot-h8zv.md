---
id: dot-h8zv
status: closed
deps: []
links: []
created: 2026-06-09T15:09:51Z
type: task
priority: 2
assignee: Seth Messer
tags: [ready-for-development, shade-next]
---

# Create shade-next repo skeleton and dev identity

Create new app repo at ~/code/shade-next with minimal Swift/Nix skeleton for shade-next. Establish dev identity now: binary name shade-next, bundle id io.shade.next, and URL scheme shade-next://. Include file hints for expected initial structure such as ~/code/shade-next/Package.swift, ~/code/shade-next/devenv.nix, ~/code/shade-next/Sources/, and any app bundle metadata files. Keep current ~/.dotfiles integration untouched in this ticket.\n\nReference context: ~/.local/share/pi/plans/.dotfiles/shade-next_PLAN.md and ~/.local/share/pi/plans/.dotfiles/shade-next.ticket-context.md.

## Acceptance Criteria

1. ~/code/shade-next exists with a minimal launchable Swift app/package skeleton and Nix/dev environment entry points.\n2. App metadata uses dev identity values: shade-next, io.shade.next, and shade-next://.\n3. A documented build command from ~/code/shade-next succeeds or fails only on a clearly identified missing dependency, not on missing project structure.\n4. No files in ~/.dotfiles are changed by this ticket.\n5. Evidence captured with changed files list and commands run.

---
id: dot-z5k8
status: open
deps: [dot-fvhz]
links: []
created: 2026-06-25T20:12:53Z
type: task
priority: 2
assignee: Seth Messer
tags: [ready-for-development]
---

# Own Worktrunk fish integration in Home Manager

Move fish Worktrunk integration under local Home Manager control while preserving upstream behavior. Disable only upstream fish integration in Worktrunk config, pass a non-recursive Worktrunk binary path into fish functions, and add a local `wt` fish function that vendors upstream directive handling before adding new smart behavior.

File hints: `home/common/programs/worktrunk/default.nix`, `home/common/programs/fish/default.nix`, `home/common/programs/fish/functions.nix`.

## Acceptance Criteria

1. `programs.worktrunk.enableFishIntegration` is disabled while bash and zsh integrations remain enabled.
2. Fish functions can call the real Worktrunk binary without recursively invoking the fish function.
3. Local `wt` fish function preserves `WORKTRUNK_DIRECTIVE_CD_FILE`, `WORKTRUNK_DIRECTIVE_EXEC_FILE`, `WORKTRUNK_SHELL=fish`, cwd changes, exec directive evaluation, and temp-file cleanup.
4. In a fresh fish shell, `wt switch @`, `wt list`, `wt config show`, and `wt hook show` still work.

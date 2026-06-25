---
id: dot-fvhz
status: closed
deps: []
links: []
created: 2026-06-25T20:12:53Z
type: task
priority: 2
assignee: Seth Messer
tags: [ready-for-development]
---

# Verify Worktrunk fish and JSON runtime contract

Verify the current Worktrunk runtime contract before changing Home Manager fish config. Inspect generated fish integration (`wt config shell init fish`), current `~/.config/fish/config.fish` ordering, and local `wt switch` JSON output. Capture notes in the ticket so later implementation preserves Worktrunk directive behavior and knows the `branch`/`path` schema.

File hints: `home/common/programs/worktrunk/default.nix`, `home/common/programs/fish/default.nix`, generated `~/.config/fish/config.fish`, installed Worktrunk fish integration, `~/.local/share/pi/plans/.dotfiles/worktrunk-smart-hooks_PLAN.md`.

## Acceptance Criteria

1. `wt config shell init fish` is inspected and relevant directive-file behavior is noted.
2. `wt switch @ --no-cd --no-hooks --format=json` output is captured and confirms usable `branch` and `path` fields or documents required parser adjustment.
3. Current fish config ordering is inspected without editing generated files directly.
4. If no-arg picker JSON cannot be safely verified non-interactively, the ticket notes exactly how to verify it manually later.

## Notes

**2026-06-25T20:18:41Z**

Verification findings (dot-fvhz). wt 0.56.0 (nixpkgs /nix/store/3fzhv3d2n28a1lcqk099i6clmwvqlxjw-worktrunk-0.56.0).

AC1 — `wt config shell init fish` directive-file behavior:

- Generated fish `wt` function creates two temp files per call: `WORKTRUNK_DIRECTIVE_CD_FILE` (raw path) + `WORKTRUNK_DIRECTIVE_EXEC_FILE` (shell to eval).
- Sets `WORKTRUNK_SHELL=fish` so the binary escapes the exec directive for fish `eval` (fish handles `\` inside '...' differently than POSIX).
- `WORKTRUNK_BIN` env overrides the binary; `--source` runs `cargo run --bin wt` for dev builds.
- After bin runs: cd_file non-empty → `string trim < cd_file` then `cd -- target` (fish builtin read, no cat subprocess, survives removed CWD). exec_file non-empty → `string collect < exec_file` then `eval`.
- Preserves binary exit code; only falls back to cd/exec exit when bin exited 0.
- Local wrapper MUST preserve: two-file directive protocol, WORKTRUNK_SHELL=fish, cd via fish builtin read, eval of exec directive, exit-code propagation.

AC2 — JSON schema `wt switch @ --no-cd --no-hooks --format=json`:

```json
{ "action": "already_at", "branch": "main", "path": "/Users/seth/.dotfiles" }
```

- Usable `branch` + `path` top-level string fields confirmed — no parser adjustment needed.
- `action` enum observed: `already_at` (expect `switched`/`created` too — verify when implementing).
- switch flags confirmed: `--no-cd` (skip cd), `--no-hooks` (skip hooks), `--format json` (structured stdout, built for tool integration). `--no-cd --format=json` is the combo for local target mode owning tmux nav.

AC3 — fish config ordering (inspected, NOT edited):

- `~/.config/fish/config.fish` is HM-generated symlink → /nix/store/.../home-manager-files.
- worktrunk init runs as `<wt> config shell init fish | source` INSIDE the `status is-interactive; and begin` block, AFTER ghostty integration, BEFORE zoxide/starship/mise inits.
- shellInit content (PATH, PLUG_EDITOR, TMUX_SESSION, completions) lands earlier, outside the interactive block.
- Local ownership plan: disable `programs.worktrunk.enableFishIntegration`, emit our own wrapper at equivalent interactive-block position so cd/exec directives still eval in the interactive shell.
- NO `~/.config/fish/functions/wt.fish` exists — HM uses inline `... init fish | source`, not the standalone wrapper file the upstream comment references.

AC4 — completions + no-arg picker:

- Completions NOT installed: `~/.config/fish/completions/wt.fish` and vendor_completions.d/wt.fish both absent. Smart-switch completions (dot-76p7) start from scratch.
- No-arg picker: `wt switch` (branch omitted) opens an INTERACTIVE picker — cannot be captured non-interactively/in JSON here.
  Manual verify later: in interactive fish run `wt switch --format=json` with no branch, confirm whether picker selection still emits `{action,branch,path}` JSON or whether `--format=json` forces non-interactive/errors. Also test `wt switch -t window @` inside vs outside tmux for target-mode behavior.

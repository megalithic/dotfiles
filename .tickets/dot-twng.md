---
id: dot-twng
status: open
deps: []
links: []
created: 2026-06-01T17:16:21Z
type: task
priority: 2
assignee: Seth Messer
tags: [ready-for-development]
---

# Research devenv-owned typos config overrides

Research and propose how this repo should make devenv the sole owner of
`.typos.toml` while keeping word-list updates easy and low-friction. Current
context: `devenv.nix` declares `files.".typos.toml".text`, but the tracked
`.typos.toml` conflicts with that generated file, so devenv reports a conflict
on shell entry.

Explore whether to keep all config in `devenv.nix`, split override data into a
small imported Nix file, use devenv-base options, or follow upstream patterns.
Relevant files: `devenv.nix`, `.typos.toml`, `.gitignore`, `.git/info/exclude`
or git ignore config, and `lat.md/lat.md`.

Research references to compare before choosing an approach:

- <https://github.com/otahontas/nix>
- <https://github.com/otahontas/devenv-base>

Focus especially on how those repos handle typos overrides, generated files,
gitignore behavior, and related repo-local override patterns.

## Acceptance Criteria

1. Research <https://github.com/otahontas/nix> and
   <https://github.com/otahontas/devenv-base> for typos, gitignore,
   generated-file, and override patterns.
2. Document at least two viable approaches for devenv-owned `.typos.toml` in
   this repo, including tradeoffs.
3. Recommend one approach and identify exact files to change.
4. Proposed design preserves easy future updates to accepted words and ignore
   rules.
5. Proposed design removes the `devenv:files` `.typos.toml` conflict.
6. Existing validation commands still pass or any blockers are documented.

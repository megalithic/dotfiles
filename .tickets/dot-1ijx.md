---
id: dot-1ijx
status: open
deps: [dot-rn9o]
links: []
created: 2026-05-30T14:19:51Z
type: chore
priority: 2
assignee: Seth Messer
tags: [ready-for-development]
---

# Remediate Pi npm Dependabot vulnerabilities

GitHub reports 46 open Dependabot alerts on the default branch, all from Pi-related npm lockfiles committed under home/common/programs/pi-coding-agent/. This is not caused by the llama.cpp work, but should be handled after the llama.cpp ticket chain is complete.

Alert distribution captured from gh api repos/megalithic/dotfiles/dependabot/alerts:

- home/common/programs/pi-coding-agent/packages/pi-internet/package-lock.json: 19 alerts (1 critical, 8 high, 9 medium, 1 low)
- home/common/programs/pi-coding-agent/packages/pi-agent-browser/package-lock.json: 18 alerts (1 critical, 8 high, 9 medium)
- home/common/programs/pi-coding-agent/packages/pi-diff-review/package-lock.json: 5 alerts (1 high, 4 medium)
- home/common/programs/pi-coding-agent/packages/pi/package-lock.json: 3 alerts (3 medium)
- home/common/programs/pi-coding-agent/skills/web-browser/scripts/package-lock.json: 1 alert (1 medium)

Affected packages include protobufjs, @protobufjs/utf8, ws, fast-uri, basic-ftp, fast-xml-builder, fast-xml-parser, brace-expansion, ip-address, and @mozilla/readability. Use existing Pi package maintenance flow in home/common/programs/pi-coding-agent/AGENTS.md and justfile update-npm recipes where applicable. Do not remove lockfiles blindly: they are inputs for Nix buildNpmPackage wrappers and web-browser skill scripts. File hints: home/common/programs/pi-coding-agent/packages/*/package.json, home/common/programs/pi-coding-agent/packages/*package-lock\*.json, home/common/programs/pi-coding-agent/skills/web-browser/scripts/package.json, home/common/programs/pi-coding-agent/skills/web-browser/scripts/package-lock.json, home/common/programs/pi-coding-agent/default.nix, home/common/programs/pi-coding-agent/scripts/update-npm-pkg.sh.

## Acceptance Criteria

1. gh api repos/megalithic/dotfiles/dependabot/alerts --paginate shows no open critical/high alerts for Pi npm manifests, or any remaining critical/high alerts are documented as upstream-blocked with package/version reason.
2. package-lock.json files for pi, pi-internet, pi-agent-browser, pi-diff-review, pi-mcp-adapter/pi-subagents vendored locks if implicated, and skills/web-browser/scripts are updated only where needed to patched dependency versions.
3. Nix hashes/npmDepsHash values are updated for any changed buildNpmPackage wrappers.
4. Existing Pi package update flow still works: run the relevant just update-npm <package> command(s) where supported, or document why manual npm lock refresh was needed.
5. devenv shell -- just validate home passes.
6. lat_check passes if lat.md is updated.

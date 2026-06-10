---
id: dot-ycua
status: closed
deps: [dot-sbcv]
links: []
created: 2026-05-11T15:14:53Z
type: feature
priority: 2
assignee: Seth Messer
tags: [ready-for-development]
---

# Update pi-mcp-adapter to v2.6.0

Bump pi-mcp-adapter from v2.5.4 to v2.6.0 in default.nix. v2.6.0 migrated its own deps from @mariozechner/_ to @earendil-works/_, has OAuth fixes (re-register dynamic clients, credential isolation per server URL), and compact tool result rendering.

Steps:

1. Update fetchFromGitHub rev from v2.5.4 to v2.6.0 in default.nix
2. Update src hash (use fake hash first, then let nix tell you the real one)
3. Check if v2.6.0 includes a package-lock.json — if yes, remove the vendored lockfile postPatch; if no, generate a new one from v2.6.0 package.json and update patches/
4. Update npmDepsHash (fake hash → nix build reports real hash)
5. Update comment in default.nix and GITHUB_NPM_PKG_MAP in scripts/update-npm-pkg.sh if lockfile path changes
6. Update AGENT CONTEXT comment at top of default.nix that references v2.5.4

See home/common/programs/pi-coding-agent/default.nix (pi-mcp-adapter block), home/common/programs/pi-coding-agent/patches/, home/common/programs/pi-coding-agent/scripts/update-npm-pkg.sh.

## Acceptance Criteria

1. default.nix references pi-mcp-adapter v2.6.0 with correct rev and hash
2. npmDepsHash matches v2.6.0 transitive deps
3. just validate home builds without error
4. pi starts and /mcp shows tidewave and paper servers connected
5. MCP tools are callable (e.g., mcp({ search: 'logs' }))

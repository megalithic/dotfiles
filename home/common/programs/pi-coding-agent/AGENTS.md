# Pi Coding Agent — Nix-managed configuration

All files here are source-of-truth for `~/.pi/agent/`. Home-manager symlinks
them into place. Run `just home` after changes.

## Directory layout

```
pi-coding-agent/
├── default.nix          # Main nix module — see inline comments for build patterns
├── packages/            # npm packages built via buildNpmPackage
├── extensions/          # Simple .ts extensions (auto-discovered, no npm deps)
├── skills/              # Simple skills (auto-discovered, symlinked)
├── agents/              # Agent .md definitions
├── prompts/             # Prompt templates
├── patches/             # Patches applied to built packages
├── sources/             # Source files (GLOBAL_AGENTS.md)
├── scripts/             # Build/update helpers — see inline comments for PNAME_MAP
├── settings.json        # Merged into ~/.pi/agent/settings.json
├── keybindings.json     # Symlinked directly
├── models.json          # Custom model/provider definitions (symlinked directly)
└── mcp.json             # MCP server config (symlinked directly)
```

## Fetching from GitHub

Use `gh api` to fetch files directly (authenticated, no URL mangling):

```bash
# Single file
gh api repos/{owner}/{repo}/contents/{path} -H 'Accept: application/vnd.github.v3.raw'

# Example
gh api repos/HazAT/pi-config/contents/extensions/execute-command/index.ts \
  -H 'Accept: application/vnd.github.v3.raw' > extensions/execute-command.ts

# List directory contents
gh api repos/{owner}/{repo}/contents/{path} --jq '.[].name'
```

For whole repos or many files, clone and copy what's needed.

## Installing extensions — decision tree

1. Fetch source (URL, repo, etc.)
2. Check `import` statements for npm packages (not relative imports, not pi SDK)
3. **No npm deps** → simple extension → `extensions/` (auto-discovered)
4. **Has npm deps** → nix derivation in `default.nix` (pick a pattern below)

## Build patterns

Four patterns are supported. Pick one based on whether the package has npm
run-time deps and whether it has a public GitHub repo with a usable lockfile.

| Pattern | Builder | Source | When to use |
|---|---|---|---|
| **A. Wrapper** | `buildNpmPackage` | local `packages/<name>/` w/ wrapper `package.json` + lockfile | npm-only release, no public repo, or upstream lockfile broken (current: `pi`, `pi-internet`, `pi-agent-browser`, `pi-diff-review`) |
| **B. fetchFromGitHub + buildNpmPackage** | `buildNpmPackage` | `pkgs.fetchFromGitHub` w/ pinned tag/rev | public repo, has npm deps, upstream provides usable lockfile (or vendor one). Current: `pi-mcp-adapter` (vendored lockfile from previous tag) |
| **C. fetchFromGitHub + stdenvNoCC** | `stdenvNoCC.mkDerivation` | `pkgs.fetchFromGitHub` w/ pinned tag/rev | public repo, **zero** npm deps. Current: `pi-multi-pass` |
| **D. fetchurl + stdenvNoCC** | `stdenvNoCC.mkDerivation` | `pkgs.fetchurl` from npm registry tarball | npm-only release, **zero** npm deps. Current: `pi-synthetic-provider` |

Decision tree:
- No deps + GitHub repo → **C**
- No deps + npm-only → **D**
- Has deps + GitHub repo + lockfile (or vendorable) → **B**
- Has deps + npm-only or upstream lockfile broken → **A**

See `default.nix` AGENT CONTEXT header for complete examples of each pattern,
and `scripts/update-npm-pkg.sh` for the dispatch maps.

## Installing skills — decision tree

1. Fetch source
2. Skill = directory with `SKILL.md` (frontmatter: name, description) +
   optional reference files
3. **No npm deps** → `skills/` (auto-discovered)
4. **Has npm deps** → `packages/` (rare, follow extension npm-deps pattern)

## Updating pi or npm packages

The update script (`scripts/update-npm-pkg.sh`, run via `just update-npm`)
dispatches to one of four functions based on which map a package is in:

| Map | Function | Pattern | Bumps |
|---|---|---|---|
| `PNAME_MAP` | `update_wrapper_package` | A | `package.json` dep version + `npmDepsHash` |
| `GITHUB_NPM_PKG_MAP` | `update_github_npm_package` | B | `version` + `rev` + `hash` (src) + `npmDepsHash` |
| `GITHUB_NO_DEPS_PKG_MAP` | `update_github_no_deps_package` | C | `version` + `rev` + `hash` (src) |
| `FETCHURL_PKG_MAP` | `update_fetchurl_package` | D | `version` + `url` + `hash` |

Usage:
1. (Pattern A only) Edit version in `packages/<name>/package.json`, OR
2. Run `just update-npm <name> [version]` — picks the right dispatcher
3. Run `just update-npm` (no arg) to update all packages
4. For pi itself: check if `patches/` still apply
5. Run `just home`
6. Verify: `pi --version`

### Patches

- `synthetic-fallback-glm-5.1.patch` was **dropped** (obsolete — GLM-5.1,
  Kimi-K2.6, Nemotron all included upstream from `pi-synthetic-provider@1.1.12`).
- `claude-settings-support.patch` is **disabled** pending rewrite against
  `pi-mcp-adapter`'s current `ConfigSourceSpec` architecture (tracked
  separately). It was last authored against v2.4.1 and won't apply cleanly.
- `pi-mcp-adapter-2.6.0-package-lock.json` is a **vendored lockfile** generated
  from upstream v2.6.0 `package.json`. Required because v2.6.0 has no lockfile.
- pi retry patches in `default.nix` `installPhase` (`substituteInPlace` on
  `agent-session.js` for `maxRetries`/`baseDelayMs`) are still active.

## Model scopes (PI_MODEL_SCOPE)

`enabledModelScopes` in `settings.json` maps profile names to model pattern
arrays. The `pinvim` wrapper reads `PI_MODEL_SCOPE` (env var, falls back to
auto-detected profile from tmux session) and passes `--models` to pi.

- `PI_MODEL_SCOPE=rx` → Ctrl-P shows only rx-anthropic models
- `PI_MODEL_SCOPE=mega` → Ctrl-P shows all mega-scoped models
- No scope / unknown scope → falls back to `enabledModels` default list
- Explicit `--models` on command line takes precedence over scope

Implemented in `default.nix` pinvim script (search `MODEL_SCOPE`).
No upstream pi patches needed — uses existing `--models` CLI flag.

## Gotchas

- Don't edit `~/.pi/agent/extensions/` — nix-store symlinks
- Pi uses jiti for TypeScript — extensions run without precompilation
- `pi-review-loop` in `~/.pi/agent/extensions/` is NOT nix-managed (local only)

## Telegram / Pi Bridge

Pi receives Telegram messages via Hammerspoon → Unix socket → `bridge.ts`.
Requires running pi through `pinvim` or `pisock` wrapper.

```
Telegram → Hammerspoon → Unix Socket → pi (bridge.ts) → notify.ts
```

Key files:
- `extensions/bridge.ts` — socket server, receives messages
- `extensions/notify.ts` — suppresses notifications during Telegram conversations
- `config/hammerspoon/lib/interop/pi.lua` — forwards Telegram to socket

When receiving `📱 **Telegram message:**`:
1. Acknowledge immediately via `~/bin/ntfy send -t "pi agent" -m "..." --telegram`
2. Proceed with requested task

Default session: `mega` (configured in `lib/interop/pi.lua`).

### Debugging

```bash
echo $PI_SOCKET        # Should show /tmp/pi-{session}-{window}.sock
ls -la /tmp/pi-*.sock  # Socket exists?
echo '{"type":"telegram","text":"test"}' | nc -U /tmp/pi-{session}.sock
```

| Symptom | Fix |
|---------|-----|
| No socket file | Use `pinvim` or `pisock pi` |
| Socket exists, no messages | Check Hammerspoon console/logs |
| "Bridge listening" not shown | Check `~/.pi/agent/extensions/` |

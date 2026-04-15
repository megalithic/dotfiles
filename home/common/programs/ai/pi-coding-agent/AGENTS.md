# Pi Coding Agent — Nix-managed configuration

All files here are source-of-truth for `~/.pi/agent/`. Home-manager symlinks
them into place. Run `just home` after changes.

## Directory layout

```
pi-coding-agent/
├── default.nix          # Main nix module (builds, auto-discovery, home.file mappings)
├── packages/            # npm packages built via buildNpmPackage
│   ├── pi/              # The pi binary itself
│   ├── pi-mcp-adapter/  # Extension with npm deps
│   ├── pi-internet/     # Extension with npm deps
│   └── ...              # Each has package.json + package-lock.json
├── extensions/          # Simple .ts extensions (auto-discovered, no npm deps)
├── skills/              # Simple skills (auto-discovered, symlinked)
├── agents/              # Agent .md definitions
├── prompts/             # Prompt templates
├── patches/             # Patches applied to built packages
├── sources/             # Source files (GLOBAL_AGENTS.md)
├── scripts/             # Build/update helper scripts
├── settings.json        # Merged into ~/.pi/agent/settings.json
├── keybindings.json     # Symlinked directly
├── models.json          # Symlinked directly
└── mcp.json             # MCP server config
```

## Fetching from GitHub

When user gives a GitHub URL for an extension or skill:

Use `gh api` to fetch files directly (authenticated, no URL mangling):

```bash
# Single file
gh api repos/{owner}/{repo}/contents/{path} -H 'Accept: application/vnd.github.v3.raw'

# Example: save extension
gh api repos/HazAT/pi-config/contents/extensions/execute-command/index.ts \
  -H 'Accept: application/vnd.github.v3.raw' > extensions/execute-command.ts

# List directory contents (to discover files)
gh api repos/{owner}/{repo}/contents/{path} --jq '.[].name'
```

For whole repos or many files, clone and copy what's needed.

After fetching, inspect the source to decide simple vs npm-deps path.

## Installing extensions

### Decision tree

1. **Fetch the extension source** (URL, repo, etc.)
2. **Check for `import` statements** that reference npm packages (not relative
   imports, not pi SDK imports like `@anthropic/...` or `pi-coding-agent`)
3. **If no npm deps** → simple extension → goes in `extensions/`
4. **If has npm deps** → needs buildNpmPackage → goes in `packages/`

### Simple extension (no npm deps)

Most extensions are single `.ts` files that only import from pi's SDK. These are
auto-discovered from `extensions/`.

```bash
# 1. Download to extensions/
curl -o extensions/my-extension.ts <url>

# 2. Verify no external npm imports
grep -E "^import .+ from ['\"]" extensions/my-extension.ts
# OK: imports from pi SDK ("@anthropic/...", relative paths)
# BAD: imports from npm packages ("lodash", "zod", "node-fetch", etc.)

# 3. Rebuild
just home
```

If extension is a directory (multiple files), place whole directory in
`extensions/` — auto-discovery handles both files and directories.

### Extension with npm dependencies

If the extension imports npm packages, it needs `buildNpmPackage` in
`default.nix`.

```bash
# 1. Create package directory
mkdir packages/my-extension
cd packages/my-extension

# 2. Initialize with the extension's npm package
npm init -y
npm install my-extension-package --save

# 3. Add buildNpmPackage block to default.nix (follow existing patterns)
# 4. Add home.file mapping in the xdg.configFile section of default.nix
# 5. Run: just update-npm my-extension  (generates lockfile + nix hash)
# 6. Run: just home
```

**Existing npm-based extensions for reference:** `pi-mcp-adapter`,
`pi-internet`, `pi-multi-pass`, `pi-synthetic-provider`, `pi-agent-browser`

### Signals that an extension needs npm deps

- `import ... from "zod"` (or any non-relative, non-pi-sdk package)
- Has its own `package.json` with `dependencies`
- README mentions `npm install` before use
- Directory structure with `node_modules/`

### Signals it's a simple extension

- Single `.ts` file
- Only imports from pi SDK (`pi.defineExtension`, `pi.tool`, etc.)
- No `package.json`
- README says "copy to extensions directory"

## Updating pi coding agent version

### Check latest version

```bash
npm view @mariozechner/pi-coding-agent version
```

Or check GitHub releases:
https://github.com/nicholasgriffintn/pi-coding-agent/releases

### Update process

1. Edit version in `packages/pi/package.json`:
   ```json
   "dependencies": {
     "@mariozechner/pi-coding-agent": "X.Y.Z"
   }
   ```

2. Run update script (generates new lockfile + computes nix hash):
   ```bash
   just update-npm pi
   ```

3. Check if patches in `patches/` still apply (read patch files, check if
   upstream changed the patched code)

4. Rebuild:
   ```bash
   just home
   ```

5. Verify: `pi --version`

### Updating other npm packages

Same pattern — edit version in `packages/<name>/package.json`, then:

```bash
just update-npm <name>    # one package
just update-npm           # all packages
just home                 # rebuild
```

Available packages: check `packages/` subdirectories or `PNAME_MAP` in
`scripts/update-npm-pkg.sh`.

## Installing skills

### Decision tree

1. **Fetch the skill source** (URL, repo, etc.)
2. **Check structure** — skill = directory with `SKILL.md` (frontmatter: name,
   description, tools) + optional reference files
3. **Check for npm deps** — does it have `package.json` with dependencies?
4. **If no npm deps** → simple skill → goes in `skills/`
5. **If has npm deps** → goes in `skills-with-deps/` (not yet wired up — need
   to add buildNpmPackage + home.file mapping in default.nix)

### Simple skill (no npm deps)

Most skills are a directory with `SKILL.md` + optional reference files. These
are auto-discovered from `skills/`.

```bash
# 1. Create skill directory
mkdir skills/my-skill

# 2. Download SKILL.md (and any reference files)
curl -o skills/my-skill/SKILL.md <url>
curl -o skills/my-skill/references/cheatsheet.md <url>  # if needed

# 3. Verify SKILL.md has frontmatter
head -5 skills/my-skill/SKILL.md
# Should have: ---\nname: ...\ndescription: ...\n---

# 4. Rebuild
just home
```

### Skill with npm dependencies

Rare. If encountered, follow same pattern as npm-based extensions: create a
package in `packages/`, add `buildNpmPackage`, wire up home.file mapping.

## Key nix patterns in default.nix

- **`npmVersion`** — reads version from package.json `dependencies` (single
  source of truth, no version duplication)
- **`npmDepsHash`** — sri hash of npm deps, auto-updated by `update-npm-pkg.sh`
- **Auto-discovery** — extensions/ and skills/ contents are auto-discovered and
  symlinked; no need to manually add home.file entries for simple ones
- **Patches** — applied during `buildNpmPackage` installPhase (check
  `patches/` dir)

## Gotchas

- **Don't edit `~/.pi/agent/extensions/`** — those are nix-store symlinks
- **Pi uses jiti** for TypeScript — extensions run without precompilation
- **`pi-review-loop`** in `~/.pi/agent/extensions/` is NOT nix-managed (local
  only, not symlinked from nix store) — leave it alone
- **After adding a new package to `packages/`**, also add it to `PNAME_MAP` in
  `scripts/update-npm-pkg.sh`

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
4. **Has npm deps** → needs `buildNpmPackage` → `packages/` + wiring in
   `default.nix`

See `default.nix` inline comments for build patterns and `scripts/update-npm-pkg.sh`
for PNAME_MAP.

## Installing skills — decision tree

1. Fetch source
2. Skill = directory with `SKILL.md` (frontmatter: name, description) +
   optional reference files
3. **No npm deps** → `skills/` (auto-discovered)
4. **Has npm deps** → `packages/` (rare, follow extension npm-deps pattern)

## Updating pi or npm packages

1. Edit version in `packages/<name>/package.json`
2. Run `just update-npm <name>` (or no arg for all)
3. For pi itself: check if `patches/` still apply
4. Run `just home`
5. Verify: `pi --version`

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

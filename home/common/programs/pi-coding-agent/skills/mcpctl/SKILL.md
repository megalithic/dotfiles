---
name: mcpctl
description: Manage MCP server configurations — add, remove, list, inspect, troubleshoot. Use when asked to "add mcp server", "remove mcp", "list mcp servers", "mcp status", "configure mcp", "troubleshoot mcp", or any MCP server management task.
---

# mcpctl — MCP server management

Manage MCP server configurations for pi-mcp-adapter. Supports global and project scopes, stdio and HTTP server types.

## Load order

pi-mcp-adapter merges configs in this order (later wins):

1. **Global** — `~/.pi/agent/mcp.json`
2. **Imports** — configs from other tools (vscode, cursor, claude-code, codex, windsurf)
3. **Project** — `.pi/mcp.json` in project root

Project-level entries override global entries with the same name.

## Imports

Project `.pi/mcp.json` can import servers from other tools:

```json
{
  "imports": ["vscode", "cursor", "claude-code"],
  "mcpServers": {
    "my-server": { ... }
  }
}
```

Supported import sources: `vscode`, `cursor`, `claude-code`, `codex`, `windsurf`. Imported servers are merged between global and project configs.

## Scope rules

| Scope | Config file | Managed by | How to edit |
|-------|-------------|------------|-------------|
| **Global** | `~/.pi/agent/mcp.json` | Nix (home-manager) | Edit `~/.dotfiles/home/common/programs/pi-coding-agent/mcp.json`, then `just home` |
| **Project** | `.pi/mcp.json` (project root) | Direct | Write file directly |

**Global is nix-managed.** The file at `~/.pi/agent/mcp.json` is a symlink to the nix store. To change it:

1. Edit the source: `~/.dotfiles/home/common/programs/pi-coding-agent/mcp.json`
2. Run `just home` (or `just rebuild`) to apply
3. Reload pi with `/reload`

**Project is direct.** Write `.pi/mcp.json` in the project root. No rebuild needed — just `/reload`.

## Server types

### Stdio — runs a local command

```json
{
  "mcpServers": {
    "server-name": {
      "command": "npx",
      "args": ["-y", "package-name@latest"],
      "env": { "KEY": "value" },
      "cwd": "/optional/working/dir"
    }
  }
}
```

### HTTP — connects to a URL

```json
{
  "mcpServers": {
    "server-name": {
      "url": "http://localhost:8080/mcp",
      "headers": { "Authorization": "Bearer token" }
    }
  }
}
```

Short form (URL only, type inferred):

```json
{
  "mcpServers": {
    "server-name": {
      "url": "https://example.com/mcp"
    }
  }
}
```

### Config options (all optional)

| Field | Type | Description |
|-------|------|-------------|
| `command` | string | Executable to run (stdio) |
| `args` | string[] | Command arguments (stdio) |
| `env` | object | Environment variables (stdio) |
| `cwd` | string | Working directory (stdio) |
| `url` | string | Server URL (HTTP) |
| `headers` | object | HTTP headers (HTTP) |
| `auth` | `"oauth"` or `"bearer"` | Auth method (HTTP) |
| `bearerToken` | string | Static bearer token |
| `bearerTokenEnv` | string | Env var name for bearer token |
| `lifecycle` | `"lazy"` / `"eager"` / `"keep-alive"` | Connection strategy (default: `lazy`) |
| `idleTimeout` | number | Minutes before idle disconnect |
| `debug` | boolean | Show server stderr |

Lifecycle modes:
- **lazy** (default) — connects on first tool call, disconnects after idle timeout
- **eager** — connects at session start, no auto-disconnect
- **keep-alive** — connects at start, auto-reconnects if dropped

## Operations

### Add

1. Ask scope if not obvious (global for cross-project, project for local)
2. Ask server type if not obvious (stdio or HTTP)
3. Gather config (command/url, args, env, etc.)
4. Read target config file (source file for global, `.pi/mcp.json` for project)
5. Warn if server name already exists — confirm before overwriting
6. Merge new server into existing `mcpServers` object
7. Write updated JSON
8. For global: edit nix source file, inform user `just home` is needed, then `/reload`
9. For project: write directly, then `/reload`
10. Verify: `mcp({ connect: "server-name" })` then `mcp({ server: "server-name" })`

### Remove

1. Determine which scope has the server (check project first, then global)
2. Read the config file
3. Remove the server entry from `mcpServers`
4. Write updated JSON
5. For global: edit nix source, inform user `just home` is needed
6. `/reload` to apply

### List

1. Read global config: `~/.dotfiles/home/common/programs/pi-coding-agent/mcp.json`
2. Read project config: `.pi/mcp.json` in cwd (if exists)
3. Show all servers with:
   - Name
   - Type (stdio/HTTP)
   - Scope (global/project/imported)
   - Connection info (command or URL)
4. Use `mcp({})` to check which are currently connected and list their tools

### Inspect

1. Show full config for the named server
2. Show which scope it comes from
3. Use `mcp({ server: "server-name" })` to list available tools
4. Use `mcp({ connect: "server-name" })` to test connection if not connected

### Troubleshoot

When a server isn't working:

1. Check config syntax — read and validate the JSON
2. Check scope — is it in the right config file?
3. Check connection — `mcp({ connect: "server-name" })`
4. For stdio: verify command exists (`which <command>`), check env vars
5. For HTTP: verify URL is reachable (`curl -s -o /dev/null -w "%{http_code}" <url>`)
6. Check for name conflicts — same name in global and project?
7. Check lifecycle — eager/keep-alive servers should connect at start
8. Report findings with specific fix suggestions

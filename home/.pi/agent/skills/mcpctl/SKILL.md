---
name: mcpctl
description: Manage MCP server configurations for Pi's built-in MCP support — add, remove, list, inspect, troubleshoot. Use when asked to "add mcp server", "remove mcp", "list mcp servers", "mcp status", "configure mcp", "troubleshoot mcp", or any MCP server management task.
---

# mcpctl — MCP server management

Pi connects MCP servers natively; no adapter extension is installed. Full reference: Pi's `docs/mcp.md` (resolve it under the installed `@earendil-works/pi-coding-agent` package).

## Scope rules

| Scope       | Config file                   | How to edit                                                                 |
| ----------- | ----------------------------- | --------------------------------------------------------------------------- |
| **Global**  | `~/.pi/agent/mcp.json`        | Symlink to `~/.dotfiles/home/.pi/agent/mcp.json`; edit the source directly  |
| **Project** | `.pi/mcp.json` (project root) | Write directly; read only once the project is trusted                      |

Project entries replace global entries with the same name. Both files use the `mcpServers` shape shared by other MCP clients.

## Commands

```bash
pi mcp add <name> -- <command> [args...]          # stdio server
pi mcp add <name> --url <url> [--bearer-token-env-var NAME]   # streamable HTTP
pi mcp add -l <name> ...                            # project scope
pi mcp remove <name>
pi mcp list                                         # connects, prints state, tools, errors
pi mcp login <name>                                 # OAuth sign-in
```

In a session: `/mcp` (manager), `/mcp reconnect <name>`, `/mcp login <name>`, `/mcp logout <name>`. Run `/reload` after editing a file.

## Native field names

- HTTP auth: `"headers": { "Authorization": "Bearer ${TOKEN_ENV}" }` (no `auth` / `bearerTokenEnv`).
- Disable without removing: `"enabled": false` (no `disabled`).
- Transport is inferred from `command` (stdio) or `url` (streamable HTTP); `sse` is rejected.
- `exposure`: `codemode` (default), `codemode-deferred`, `deferred`, `direct`, `hidden`; `toolExposure` per tool.

## Tidewave (Elixir projects)

`acp.ts` registers `tidewave` at runtime from `pidewave.url` in the project `.pi/mcp.json` and pings it. Never add `mcpServers.tidewave`; a configured entry shadows the registration. Use `/pidewave` to re-register and ping, or `mise run bootstrap` to regenerate the URL.

## Troubleshoot

1. `pi mcp list` — validates config, connects every enabled server, shows stderr of failed stdio servers.
2. Scope: is the entry in the file you expect? Same name in both files?
3. stdio: `which <command>`; env vars referenced as `${NAME}` must be set in the shell that started Pi.
4. HTTP: `curl -s -o /dev/null -w "%{http_code}" <url>`; 401 without an `Authorization` header means OAuth, run `pi mcp login <name>`.

---
name: sesame
description: Search past Pi coding sessions with Sesame local BM25 search. Use for multi-word session search, tool-call searches, and recent session discovery.
---

# Sesame session search

Sesame indexes Pi session files into SQLite FTS5 and ranks results with BM25.

## When to use

Use `sesame` when you need:

- Multi-word topic search (`"nix infra cleanup"`, `"publish workflow changesets"`)
- Tool-call oriented search (`--tools`, `--tool bash`, `--path package.json`)
- Recent session discovery (`"*"` with filters)

Use `sesame search "*"` to list recent sessions. Use `read` on a result path after you identify the session to inspect.

## CLI

```bash
sesame search "query"
sesame search "query" --json
sesame search "query" --cwd /path/to/project
sesame search "query" --after 7d
sesame search "query" --before 2026-01-01
sesame search "query" --limit 5
sesame search "query" --tools
sesame search "query" --tool bash
sesame search "query" --path package.json
sesame search "query" --exclude <session-id>
```

List recent sessions:

```bash
sesame search "*" --limit 20
sesame search "*" --cwd /path --after 2w --exclude <session-id>
```

Index management:

```bash
sesame index
sesame index --full
sesame status
sesame watch
sesame watch --interval 30
```

## Workflow

1. Run `sesame search "query"`.
2. If results look stale, run `sesame index` or wait for `sesame watch`.
3. Narrow with `--cwd`, `--after`, `--before`, `--tools`, `--tool`, or `--path`.
4. Use `--json` when another tool needs structured output.

## Date filters

- Relative: `7d`, `2w`, `1m`
- Absolute: `YYYY-MM-DD`

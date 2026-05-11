---
id: dot-6r8c
status: open
deps: []
links: [dot-86tz]
created: 2026-05-11T19:19:50Z
type: task
priority: 2
assignee: Seth Messer
parent: dot-0fjk
tags: [ready-for-development]
---
# Support per-repo/session MCP servers, skills, and extensions

Investigate and implement per-repo and/or per-session loading of MCP servers, skills, and extensions. Current architecture: all config lives in global ~/.pi/agent/. Future: projects should be able to define their own MCP servers (.pi/mcp.json), skills, and extensions that load alongside global ones. Related to dot-86tz (project-level MCP config). Needs research into what pi supports natively vs what needs extension/wrapper support.


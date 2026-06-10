---
id: dot-jc7u
status: closed
deps: []
links: []
created: 2026-06-10T13:59:11Z
type: task
priority: 2
assignee: Seth Messer
tags: [ready-for-development]
---

# Update Pi custom footer multi-pass status formatting

Update home/common/programs/pi-coding-agent/extensions/custom-footer.ts and home/common/programs/pi-coding-agent/extensions/multi-sub.ts so model routing status is compact and stable across pool/provider transitions. Current behavior appends multi-pass/caveman/MCP extension statuses into the left footer area, which can hide the right-side model layout. Desired multi-pass output shape: ({sub preset, e.g. alt or mega}){active pool}/{model}/thinking_level. The active pool should be visually emphasized and lighter when the active pool differs from the originally selected/starting pool, so cross-pool transitions are visible at a glance. Keep active model color matching current accent/cyan styling. Darken thinking level and sub preset to reduce visual weight. Never render caveman extension status in custom-footer.ts. MCP server footer output should be reduced to only:  {active}/{total}. The multi-pass related output is what should render at the far right of footer line 2, replacing the existing combination of presets/models/subs/providers/thinking levels currently shown there.

File hints:

- home/common/programs/pi-coding-agent/extensions/custom-footer.ts
- home/common/programs/pi-coding-agent/extensions/multi-sub.ts
- any MCP status extension/source that feeds footerData.getExtensionStatuses()

Verification:

- timeout 30 rg -n "multi-pass|caveman|MCP|mcp|setStatus|getExtensionStatuses" home/common/programs/pi-coding-agent/extensions
- timeout 600 just validate home
- timeout 600 just home

## Acceptance Criteria

1. Custom footer always suppresses caveman extension status; no caveman text appears in rendered footer status output.
2. Multi-pass footer output is always formatted as `({sub preset}){active pool}/{model}/thinking_level`, with missing optional segments handled compactly.
3. Cross-pool transitions are detectable in the footer: active pool styling differs when active pool is not the originally selected/starting pool.
4. Active model keeps current accent/cyan color treatment; thinking level and sub preset use darker/dimmer styling.
5. MCP server related footer output renders only ` {active}/{total}` and no verbose MCP status text.
6. Existing footer layout remains stable during provider/model pool transitions; right-side model information is not pushed out by extension statuses.
7. `timeout 600 just validate home` passes, and `timeout 600 just home` rebuilds successfully.
8. Multi-pass output renders at the far right of footer line 2, replacing the previous presets/models/subs/providers/thinking-level combination in that position.

## Notes

**2026-06-10T15:01:44Z**

Summary: compacted Pi footer multi-pass routing display, suppressed caveman status, reduced MCP footer text, documented behavior, and verified with rg, lat_check, just validate home, and just home.

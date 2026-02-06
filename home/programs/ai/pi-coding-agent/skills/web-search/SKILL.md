---
name: web-search
description: Web search using DuckDuckGo (free, unlimited). Falls back to Brave Search API for content extraction or when ddgr fails.
---

# Web Search

Primary: DuckDuckGo via `ddgr` (free, unlimited, no API key)
Fallback: Brave Search API (for content extraction or when ddgr fails)

## Search (ddgr - primary)

```bash
{baseDir}/search.sh "query"                    # Basic search (5 results)
{baseDir}/search.sh "query" -n 10              # More results (max 25)
{baseDir}/search.sh "query" -t w               # Past week
{baseDir}/search.sh "query" -t m               # Past month
{baseDir}/search.sh "query" -w example.com     # Site-specific search
```

### Options

- `-n <num>` - Number of results (default: 5, max: 25)
- `-t <span>` - Time filter: `d` (day), `w` (week), `m` (month), `y` (year)
- `-w <site>` - Limit to specific site

## Content extraction (brave-search fallback)

When you need the actual page content (not just snippets), use the brave-search skill:

```bash
~/.pi/agent/skills/brave-search/content.js https://example.com/page
```

Or search with content:

```bash
~/.pi/agent/skills/brave-search/search.js "query" --content -n 3
```

## When to use which

| Need | Use |
|------|-----|
| Quick search, facts | `{baseDir}/search.sh` (ddgr) |
| Many searches | `{baseDir}/search.sh` (ddgr) - unlimited |
| Full page content | `brave-search/content.js` |
| Search + read pages | `brave-search/search.js --content` |

## Output format

```
--- Result 1 ---
Title: Page Title
URL: https://example.com/page
Snippet: Description from search results

--- Result 2 ---
...
```

## Rate limits

- **ddgr**: None (scrapes DuckDuckGo directly)
- **brave-search**: 2,000 queries/month free tier

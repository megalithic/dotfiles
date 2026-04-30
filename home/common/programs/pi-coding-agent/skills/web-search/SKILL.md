---
name: web-search
description: Web search using DuckDuckGo (free, unlimited). Falls back to pi-web-access extension for content extraction.
---

# Web Search

Primary: DuckDuckGo via `ddgr` (free, unlimited, no API key)
Content extraction: Use `pi-web-access` extension tools (gemini-search, etc.)

## Search (ddgr)

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

## Content extraction

For full page content (not just snippets), use the `pi-web-access` extension
which provides web search and extraction tools directly in the agent.

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

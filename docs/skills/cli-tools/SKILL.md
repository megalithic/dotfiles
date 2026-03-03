---
name: cli-tools
description: Modern CLI tool usage (fd, rg) for fast file and content searching. Critical for Nix store searches and large codebases. Use when searching files or content, especially in /nix/store.
tools: Bash
---

# Modern CLI Tools (fd, rg)

## Overview

**CRITICAL**: Always use modern, fast CLI tools instead of legacy UNIX commands. This is especially important when searching the Nix store (`/nix/store`), which contains millions of files.

| Legacy | Modern | Speedup | When Legacy Will Fail |
|--------|--------|---------|----------------------|
| `find` | `fd` | 10-100x faster | Timeout on /nix/store |
| `grep` | `rg` | 10-100x faster | Timeout on large dirs |

Both `fd` and `rg` respect `.gitignore` by default and are optimized for large directory trees.

---

## Decision Trees

### "I need to find files"

```
Need to find files?
│
├─▶ Know the filename/pattern?
│   └─▶ fd "pattern"
│       └─▶ fd -e lua (by extension)
│       └─▶ fd -g "*.nix" (glob pattern)
│
├─▶ Know it's in a specific directory?
│   └─▶ fd "pattern" /path/to/dir
│
├─▶ Need to include hidden/gitignored?
│   └─▶ fd -H (hidden) / fd -I (ignored) / fd -HI (both)
│
├─▶ Searching in /nix/store?
│   └─▶ fd "pattern" /nix/store
│       └─▶ CRITICAL: Never use find here!
│
└─▶ Need to run command on results?
    └─▶ fd -x cmd {}     (one at a time)
    └─▶ fd -X cmd {}     (all at once)
```

### "I need to search file contents"

```
Need to search contents?
│
├─▶ Simple pattern search?
│   └─▶ rg "pattern"
│
├─▶ Need specific file types?
│   └─▶ rg "pattern" -t lua
│   └─▶ rg "pattern" -g "*.nix"
│
├─▶ Need context around matches?
│   └─▶ rg "pattern" -C 3 (3 lines before/after)
│   └─▶ rg "pattern" -A 5 (5 lines after)
│   └─▶ rg "pattern" -B 2 (2 lines before)
│
├─▶ Just need filenames?
│   └─▶ rg -l "pattern"
│
├─▶ Need case-insensitive?
│   └─▶ rg -i "pattern"
│
├─▶ Searching in /nix/store?
│   └─▶ rg "pattern" /nix/store
│       └─▶ CRITICAL: Never use grep here!
│
└─▶ Need to replace text?
    └─▶ rg "old" -r "new" --passthru (preview)
    └─▶ Use sed/Edit tool for actual replacement
```

### "Which tool should I use?"

```
What are you trying to do?
│
├─▶ Find files by name/pattern?
│   └─▶ fd
│
├─▶ Search file contents?
│   └─▶ rg
│
├─▶ Find files AND search contents?
│   └─▶ fd -e lua -x rg "pattern"
│   └─▶ fd + rg piped together
│
├─▶ Count/list matches only?
│   └─▶ rg -c (count per file)
│   └─▶ rg -l (list files only)
│
└─▶ Using Claude Code's built-in tools?
    └─▶ Glob tool = like fd (for finding files)
    └─▶ Grep tool = like rg (for searching content)
    └─▶ Prefer built-in tools when available
```

---

## fd (find replacement)

### Quick Reference

```bash
fd "pattern"              # Find files/dirs matching pattern
fd -e lua                 # Find by extension
fd -t f config            # Files only (-t d for directories)
fd -t x                   # Executables only
fd -g "*.nix"             # Glob pattern
fd -H                     # Include hidden files
fd -I                     # Include gitignored files
fd -d 3                   # Max depth 3
fd -E "*.log"             # Exclude pattern
```

### Complete Flag Reference

| Flag | Long Form | Description |
|------|-----------|-------------|
| `-H` | `--hidden` | Include hidden files/directories |
| `-I` | `--no-ignore` | Don't respect .gitignore |
| `-s` | `--case-sensitive` | Case-sensitive search |
| `-i` | `--ignore-case` | Case-insensitive search |
| `-g` | `--glob` | Glob-based search |
| `-F` | `--fixed-strings` | Literal string match |
| `-a` | `--absolute-path` | Show absolute paths |
| `-l` | `--list-details` | Show file details (like ls -l) |
| `-L` | `--follow` | Follow symbolic links |
| `-p` | `--full-path` | Match against full path |
| `-d` | `--max-depth` | Maximum search depth |
| `-t` | `--type` | Filter by type (f/d/l/x/e/s/p) |
| `-e` | `--extension` | Filter by extension |
| `-E` | `--exclude` | Exclude patterns |
| `-x` | `--exec` | Execute command per result |
| `-X` | `--exec-batch` | Execute command with all results |
| `-0` | `--print0` | Null-separated output |
| | `--changed-within` | Modified within timeframe |
| | `--changed-before` | Modified before timeframe |
| | `--size` | Filter by size (+100k, -1m) |
| | `--owner` | Filter by owner |

### Type Filters (-t)

| Type | Description |
|------|-------------|
| `f` | Regular files |
| `d` | Directories |
| `l` | Symbolic links |
| `x` | Executable files |
| `e` | Empty files/directories |
| `s` | Sockets |
| `p` | Named pipes (FIFO) |

### Common Patterns

```bash
# Find by name
fd "config"               # Contains "config"
fd "^config"              # Starts with "config"
fd "\.lua$"               # Ends with .lua (regex)
fd -e lua                 # Same, extension flag

# Find in specific directory
fd -e nix modules/        # .nix files in modules/
fd pattern /path/to/dir   # Search specific directory

# Include hidden/ignored
fd -H "\.env"             # Include hidden files
fd -I node_modules        # Include gitignored files
fd -HI "secret"           # Include both

# Filter by type
fd -t f config            # Files only
fd -t d src               # Directories only
fd -t x                   # Executables only
fd -t l                   # Symlinks only

# Limit depth
fd -d 1                   # Current directory only
fd -d 3 pattern           # Max 3 levels deep

# Filter by time
fd --changed-within 1d    # Modified in last day
fd --changed-within 1h    # Modified in last hour
fd --changed-before 1w    # Modified more than a week ago

# Filter by size
fd --size +1m             # Larger than 1MB
fd --size -100k           # Smaller than 100KB

# Exclude patterns
fd -E "*.log"             # Exclude log files
fd -E ".git" -E "node_modules"  # Exclude multiple
```

### Executing Commands

```bash
# Execute per file (-x)
fd -e lua -x wc -l        # Count lines in each lua file
fd -e jpg -x convert {} {.}.png  # Convert jpg to png

# Execute batch (-X, all at once)
fd -e ts -X prettier -w   # Format all TypeScript files
fd -e lua -X wc -l        # Total line count

# Placeholders
# {}   - Full path
# {/}  - Basename
# {//} - Parent directory
# {.}  - Path without extension
# {/.} - Basename without extension
```

---

## rg (grep replacement)

### Quick Reference

```bash
rg "pattern"              # Search current dir recursively
rg -i "error"             # Case-insensitive
rg -w "app"               # Whole word only
rg -F "exact.string"      # Fixed string (no regex)
rg -t lua "require"       # Search only Lua files
rg -l "TODO"              # List files with matches only
rg -c "TODO"              # Count matches per file
```

### Complete Flag Reference

| Flag | Long Form | Description |
|------|-----------|-------------|
| `-i` | `--ignore-case` | Case-insensitive search |
| `-s` | `--case-sensitive` | Case-sensitive search |
| `-S` | `--smart-case` | Smart case (insensitive if all lowercase) |
| `-w` | `--word-regexp` | Match whole words only |
| `-F` | `--fixed-strings` | Literal string match |
| `-x` | `--line-regexp` | Match entire lines |
| `-v` | `--invert-match` | Invert match |
| `-l` | `--files-with-matches` | Only print file names |
| `-L` | `--files-without-match` | Files without matches |
| `-c` | `--count` | Count matches per file |
| `-o` | `--only-matching` | Print only matching part |
| `-n` | `--line-number` | Show line numbers (default) |
| `-N` | `--no-line-number` | Hide line numbers |
| `-H` | `--with-filename` | Show filenames (default) |
| `-I` | `--no-filename` | Hide filenames |
| `-A` | `--after-context` | Lines after match |
| `-B` | `--before-context` | Lines before match |
| `-C` | `--context` | Lines before and after |
| `-t` | `--type` | Search specific file type |
| `-T` | `--type-not` | Exclude file type |
| `-g` | `--glob` | Include/exclude globs |
| `-r` | `--replace` | Replace matches |
| `-U` | `--multiline` | Enable multiline mode |
| | `--hidden` | Search hidden files |
| | `--no-ignore` | Don't respect .gitignore |
| | `--max-depth` | Maximum directory depth |
| | `--max-count` | Stop after N matches |
| | `--json` | Output as JSON |
| | `--stats` | Show search statistics |

### File Type Filtering

```bash
# Built-in types
rg --type-list            # Show all known types
rg -t lua "pattern"       # Lua files
rg -t nix "pattern"       # Nix files
rg -t py "pattern"        # Python files
rg -t js "pattern"        # JavaScript files
rg -t ts "pattern"        # TypeScript files
rg -t md "pattern"        # Markdown files
rg -t sh "pattern"        # Shell scripts

# Glob patterns
rg "pattern" -g "*.lua"   # Include only .lua
rg "pattern" -g "!*.md"   # Exclude .md files
rg "pattern" -g "!vendor/" # Exclude vendor directory
rg "pattern" -g "src/**/*.ts"  # TypeScript in src/
```

### Context Control

```bash
rg "function" -A 3        # 3 lines after match
rg "function" -B 2        # 2 lines before match
rg "function" -C 2        # 2 lines before and after
rg "error" -C 5           # More context for errors
```

### Output Modes

```bash
# Default: show matches with context
rg "pattern"

# Files only
rg -l "pattern"           # Files with matches
rg -L "pattern"           # Files without matches

# Count
rg -c "pattern"           # Count per file
rg -c "pattern" | awk -F: '{sum+=$2} END {print sum}'  # Total

# Only matching text
rg -o "pattern"           # Just the match
rg -oI "pattern"          # Match only, no filenames

# JSON output
rg --json "pattern"       # For programmatic parsing
```

### Advanced Patterns

```bash
# Multiline matching
rg -U "start.*\nend"      # Match across lines
rg -U "function.*\{[^}]*\}"  # Function bodies

# Regex features
rg "\bword\b"             # Word boundary
rg "foo|bar"              # Alternation
rg "a{2,4}"               # Quantifiers
rg "(?i)case"             # Inline case insensitive
rg "(?:non-capturing)"    # Non-capturing group
rg "look(?=ahead)"        # Lookahead
rg "(?<=look)behind"      # Lookbehind

# Replace (preview)
rg "old" -r "new" --passthru  # Show what would change

# Statistics
rg --stats "pattern"      # Search statistics
```

---

## Integration with Claude Code Tools

### When to Use Built-in Tools vs fd/rg

| Scenario | Use Built-in | Use fd/rg |
|----------|-------------|-----------|
| Finding files in codebase | Glob tool | Complex patterns |
| Searching file contents | Grep tool | /nix/store, complex regex |
| Need execution on results | - | fd -x / fd -X |
| Need JSON output | - | rg --json |
| Multiple operations | - | Piping fd \| rg |

### Glob Tool (like fd)

```bash
# Claude Code's Glob tool
# Good for: simple file finding in codebase

# Equivalent patterns:
# Glob: "**/*.lua"  ≈  fd -e lua
# Glob: "src/**/*.ts"  ≈  fd -e ts src/
```

### Grep Tool (like rg)

```bash
# Claude Code's Grep tool
# Good for: searching content with context

# Equivalent patterns:
# Grep with -C 3  ≈  rg "pattern" -C 3
# Grep output_mode: files_with_matches  ≈  rg -l
```

### When fd/rg is Better

1. **Nix store searches** - Always use fd/rg
2. **Executing commands on results** - fd -x / fd -X
3. **Complex filtering** - Multiple types, exclusions
4. **Performance-critical** - fd/rg are faster
5. **Piped workflows** - fd | xargs rg

---

## Combined Workflows

### Find and Search

```bash
# Find files then search contents
fd -e lua -x rg "require"

# Search specific file types in specific dirs
fd -e nix modules/ -x rg "enable = true"

# Find and process
fd -e json -X jq '.version'
```

### Nix Store Investigations

**CRITICAL**: The Nix store contains millions of files. Legacy tools will timeout.

```bash
# Find where a binary comes from
fd -t x "nvim" /nix/store --max-depth 3

# Find all packages with a specific file
fd "libcurl.so" /nix/store -x dirname | sort -u

# Search derivation files
fd -e drv /nix/store | head -100 | xargs rg "python"

# Find config files
fd "config" /nix/store -t f -d 4 | head -50

# Find package by name pattern
fd "ghostty" /nix/store -d 1 -t d
```

### Code Analysis

```bash
# Find all TODO/FIXME comments
rg "TODO|FIXME" -t lua -t nix

# Find function definitions
rg "^function |^local function " -t lua

# Find all imports/requires
rg "^import |^from |require\("

# Find unused exports
rg "^export " -l | xargs -I {} sh -c 'rg -l "from.*{}" || echo "Unused: {}"'

# Find large files
fd -t f -S +1m

# Find recently modified config
fd -e nix --changed-within 1d
```

---

## Performance Tips

1. **Use fd/rg, not find/grep** - especially for /nix/store
2. **Limit depth** when possible: `fd -d 3` or `rg --max-depth 3`
3. **Filter by type** to reduce search space: `-t lua`, `-g "*.nix"`
4. **Use -l** when you only need filenames, not matches
5. **Exclude large dirs**: `-E node_modules -E .git`
6. **Use --max-count** to stop after N matches
7. **Batch execute** with `-X` instead of `-x` when possible

---

## Common Mistakes

### DON'T (Will timeout on large directories)

```bash
# BAD: Will timeout on /nix/store
find /nix/store -name "*.so"
grep -r "pattern" /nix/store
ls -R /nix/store | grep pattern
```

### DO (Fast even with millions of files)

```bash
# GOOD: Fast even with millions of files
fd -e so /nix/store
rg "pattern" /nix/store
fd "pattern" /nix/store
```

---

## Self-Discovery Patterns

### Finding Help

```bash
# fd help
fd --help
fd --help | grep -i "flag-name"
man fd

# rg help
rg --help
rg --help | grep -i "flag-name"
man rg

# List file types
rg --type-list
rg --type-list | grep lua
```

### Testing Patterns

```bash
# Test fd pattern (dry run)
fd "pattern" --max-results 5

# Test rg pattern (limited)
rg "pattern" --max-count 5

# Count results before processing
fd "pattern" | wc -l
rg -c "pattern" | awk -F: '{sum+=$2} END {print sum}'
```

### Version and Features

```bash
# Check installed version
fd --version
rg --version

# Check available features
rg --pcre2-version  # PCRE2 support
```

---

## Quick Troubleshooting

### "No matches found"

```bash
# Check if pattern is correct
fd "exact" -F         # Try fixed string
rg "exact" -F         # Try fixed string

# Include hidden/ignored
fd -HI "pattern"
rg --hidden --no-ignore "pattern"

# Check file types
rg --type-list | grep yourtype
```

### "Too many results"

```bash
# Limit depth
fd -d 2 "pattern"
rg --max-depth 2 "pattern"

# Limit count
fd --max-results 10
rg --max-count 10

# More specific pattern
fd "^exact$"          # Exact match
rg "\bexact\b"        # Word boundary
```

### "Search is slow"

```bash
# Check if searching /nix/store with wrong tool
# Use fd/rg, NEVER find/grep

# Exclude large directories
fd -E node_modules -E .git
rg -g '!node_modules' -g '!.git'

# Limit depth
fd -d 3
rg --max-depth 3
```

---

## Cheat Sheet

### fd Essentials

```
fd PATTERN              Find files matching pattern
fd -e EXT               Find by extension
fd -t f/d/x             Type: file/dir/executable
fd -H/-I                Hidden/ignored files
fd -d N                 Max depth
fd -E PAT               Exclude pattern
fd -x CMD               Execute per result
fd -X CMD               Execute batch
```

### rg Essentials

```
rg PATTERN              Search contents
rg -i                   Case insensitive
rg -w                   Whole word
rg -F                   Fixed string
rg -t TYPE              File type
rg -g GLOB              Glob filter
rg -l                   Files only
rg -c                   Count matches
rg -A/B/C N             Context lines
```

---
name: cli-tools
description: Modern CLI tool usage (fd, rg) for fast file and content searching. Critical for Nix store searches and large codebases. Use when searching files or content, especially in /nix/store.
tools: Bash
---

# Modern CLI Tools (fd, rg)

## Overview

**CRITICAL**: Always use modern, fast CLI tools instead of legacy UNIX commands. This is especially important when searching the Nix store (`/nix/store`), which contains millions of files.

| Legacy | Modern | Speedup |
|--------|--------|---------|
| `find` | `fd` | 10-100x faster |
| `grep` | `rg` | 10-100x faster |

Both `fd` and `rg` respect `.gitignore` by default and are optimized for large directory trees.

## fd (find replacement)

### Basic Usage

```bash
fd "pattern"              # Find files/dirs matching pattern
fd -e lua                 # Find by extension
fd -t f config            # Files only (-t d for directories)
fd -t x                   # Executables only
```

### Common Patterns

```bash
# Find files by name pattern
fd "\.lua$"               # Regex: files ending in .lua
fd -e lua                 # Same, using extension flag
fd config                 # Files/dirs containing "config"
fd -g "*.nix"             # Glob pattern

# Find in specific directory
fd -e nix modules/        # Find .nix files in modules/
fd pattern /path/to/dir   # Search specific directory

# Include hidden/ignored files
fd -H "\.env"             # Include hidden files
fd -I node_modules        # Include gitignored files
fd -HI "secret"           # Include both

# Nix store searches (CRITICAL - fd is essential here)
fd "ghostty.h" /nix/store           # Fast even with millions of files
fd -e so "libssl" /nix/store        # Find shared libraries
fd -t f "bin/nvim" /nix/store       # Find nvim binaries
```

### Executing Commands on Results

```bash
fd -e lua -x wc -l                  # Run wc -l on each .lua file
fd -e lua -X wc -l                  # Run wc -l once with all files as args
fd -e test.ts -X prettier -w        # Format all test files at once
fd -e nix -x nix-instantiate --parse {}  # Parse each nix file
```

### Useful Flags

| Flag | Purpose |
|------|---------|
| `-H` | Include hidden files |
| `-I` | Include gitignored files |
| `-L` | Follow symlinks |
| `-d N` | Max depth N |
| `-E pat` | Exclude pattern |
| `--changed-within 1d` | Modified in last day |
| `-0` | Null-separated output (for xargs -0) |

## rg (grep replacement)

### Basic Usage

```bash
rg "pattern"              # Search current dir recursively
rg -i "error"             # Case-insensitive
rg -w "app"               # Whole word only (not "application")
rg -F "exact.string"      # Fixed string (no regex)
```

### File Filtering

```bash
rg "import" -t lua        # Search only Lua files
rg "config" -g "*.nix"    # Search with glob pattern
rg "test" -g "!*.md"      # Exclude markdown files
rg "TODO" -g "!vendor/"   # Exclude vendor directory

# Type list
rg --type-list            # Show all known types
rg -t nix "mkOption"      # Search nix files
rg -t lua "require"       # Search lua files
```

### Context and Output

```bash
rg "function" -A 3        # Show 3 lines after match
rg "function" -B 2        # Show 2 lines before match
rg "function" -C 2        # Show 2 lines before and after

rg -l "TODO"              # List files with matches only
rg -c "TODO"              # Count matches per file
rg --json "pattern"       # JSON output for parsing
```

### Advanced Patterns

```bash
# Multiline matching
rg -U "multi\nline"       # Match across lines

# Nix store searches (CRITICAL)
rg "nixpkgs" /nix/store   # Fast full-text search
rg -l "python3" /nix/store/*/bin  # Find packages with python3

# Combined with fd for targeted searches
fd -e nix | xargs rg "mkDerivation"  # Search only nix files
```

### Useful Flags

| Flag | Purpose |
|------|---------|
| `-i` | Case insensitive |
| `-w` | Whole word |
| `-F` | Fixed string (literal) |
| `-v` | Invert match |
| `-l` | Files with matches |
| `-c` | Count matches |
| `-n` | Show line numbers (default) |
| `-N` | Hide line numbers |
| `--no-heading` | No filename headers |
| `-o` | Only matching part |
| `-r` | Replace (with --passthru for preview) |

## Combined Workflows

### Find and Search

```bash
# Find files then search contents
fd -e lua -x rg "require"

# Search specific file types in specific dirs
fd -e nix modules/ -x rg "enable = true"
```

### Nix Store Investigations

```bash
# Find where a binary comes from
fd -t x "nvim" /nix/store --max-depth 3

# Find all packages with a specific file
fd "libcurl.so" /nix/store -x dirname | sort -u

# Search derivation files
fd -e drv /nix/store | head -100 | xargs rg "python"
```

### Code Analysis

```bash
# Find all TODO/FIXME comments
rg "TODO|FIXME" -t lua -t nix

# Find function definitions
rg "^function |^local function " -t lua

# Find all imports/requires
rg "^import |^from |require\(" 
```

## Performance Tips

1. **Use fd/rg, not find/grep** - especially for /nix/store
2. **Limit depth** when possible: `fd -d 3` or `rg --max-depth 3`
3. **Filter by type** to reduce search space: `-t lua`, `-g "*.nix"`
4. **Use -l** when you only need filenames, not matches
5. **Exclude large dirs**: `-E node_modules -E .git`

## Common Mistakes

```bash
# BAD: Will timeout on /nix/store
find /nix/store -name "*.so"
grep -r "pattern" /nix/store

# GOOD: Fast even with millions of files
fd -e so /nix/store
rg "pattern" /nix/store
```

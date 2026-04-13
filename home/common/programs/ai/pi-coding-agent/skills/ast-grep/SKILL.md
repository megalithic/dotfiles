---
name: ast-grep
description: Guide for writing ast-grep rules for structural code search. Use when searching codebases with AST patterns, finding specific code structures, or performing queries beyond simple text search.
---

# ast-grep Code Search

Translate natural language queries into ast-grep rules for structural code matching.

## Workflow

### 1. Write example code matching the target pattern

Save to a temp file for testing.

### 2. Write the rule

Use `pattern` for simple matches, `kind` + `has`/`inside` for complex structures. Always use `stopBy: end` on relational rules.

```yaml
id: async-with-await
language: javascript
rule:
  kind: function_declaration
  has:
    pattern: await $EXPR
    stopBy: end
```

See `references/rule_reference.md` for full rule syntax.

### 3. Test the rule

```bash
# Inline (quick iteration)
echo "async function test() { await fetch(); }" | ast-grep scan --inline-rules "id: test
language: javascript
rule:
  kind: function_declaration
  has:
    pattern: await \$EXPR
    stopBy: end" --stdin

# Rule file (complex rules)
ast-grep scan --rule test_rule.yml test_example.js
```

Debug with `--debug-query=cst` to see the AST structure.

### 4. Search the codebase

```bash
# Simple pattern
ast-grep run --pattern 'console.log($ARG)' --lang javascript .

# Complex rule
ast-grep scan --rule my_rule.yml /path/to/project

# Inline rule
ast-grep scan --inline-rules "..." /path/to/project
```

## Escaping in inline rules

Use `\$VAR` (shell interprets `$`) or wrap in single quotes.

## Key concepts

- **Pattern**: direct code matching (`console.log($ARG)`)
- **Kind + relational**: structural queries (function containing await)
- **Composite**: `all`, `any`, `not` for logical combinations
- **Metavariables**: `$VAR` (named node), `$$VAR` (unnamed node), `$$$` (zero or more nodes)
- **Start simple**: try `pattern` → `kind` → add relational → composite
- **Debug**: `--debug-query=cst` shows actual AST; `--debug-query=pattern` shows how ast-grep interprets your pattern

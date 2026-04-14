# ast-grep Rule Reference

## Rule categories

- **Atomic**: match individual nodes (`pattern`, `kind`, `regex`, `nthChild`, `range`)
- **Relational**: match by position (`inside`, `has`, `precedes`, `follows`)
- **Composite**: logical combinations (`all`, `any`, `not`, `matches`)

A node matches if it satisfies **all** fields in the rule object (implicit AND).

## Atomic rules

### pattern

Match AST node by code pattern. String or object form.

```yaml
pattern: console.log($ARG)
# Object form for ambiguous parsing:
pattern:
  selector: field_definition
  context: class { $F }
  strictness: relaxed  # cst|smart|ast|relaxed|signature
```

### kind

Match by `tree_sitter_node_kind` name.

```yaml
kind: call_expression
```

### regex

Match node's full text with Rust regex. Not a "positive" rule (matches regardless of structural kind).

### nthChild

Match by position among siblings. 1-based, named nodes only.

```yaml
nthChild: 1
# An+B formula:
nthChild: "2n+1"
# Object form:
nthChild:
  position: 3
  reverse: true
  ofRule: { kind: call_expression }
```

### range

Match by character positions (0-based, end exclusive).

```yaml
range:
  start: { line: 0, column: 0 }
  end: { line: 0, column: 10 }
```

## Relational rules

All accept `stopBy` and (for `inside`/`has`) `field` options.

### inside / has

```yaml
inside:
  pattern: class $C { $$$ }
  stopBy: end
has:
  pattern: await $EXPR
  stopBy: end
```

### precedes / follows

Sequential matching. Include `stopBy` but not `field`.

### stopBy

- `"neighbor"` (default): stop at first non-matching node
- `"end"`: search entire subtree
- Rule object: stop when matching node found (inclusive)

### field

Restrict relational match to a specific child field. Only for `inside`/`has`.

**Always use `stopBy: end` when unsure.**

## Composite rules

```yaml
# AND — all must match (guarantees execution order for metavariables)
all:
  - kind: call_expression
  - pattern: console.log($ARG)

# OR — any must match
any:
  - pattern: console.log($$$)
  - pattern: console.warn($$$)

# NOT — negate
not:
  pattern: console.log($ARG)

# Matches — reference a utility rule by id
matches: my-utility-rule-id
```

## Metavariables

| Syntax   | Captures                                     | Example                                                |
| -------- | -------------------------------------------- | ------------------------------------------------------ |
| `$VAR`   | Single named node                            | `console.log($GREETING)`                               |
| `$$VAR`  | Single unnamed node (operators, punctuation) | `$$OP` in binary expression                            |
| `$$$VAR` | Zero or more nodes (non-greedy)              | `console.log($$$)` matches any arg count               |
| `$_VAR`  | Non-capturing (matches different content)    | `$_FUNC($_FUNC)` matches `test(a)` and `testFunc(1+1)` |

**Rules:**

- Valid names: `$META`, `$META_VAR`, `$_`
- Invalid: `$invalid`, `$123`, `$KEBAB-CASE`
- Metavariable text must be the **only** content in its AST node
- Non-working: `obj.on$EVENT`, `"Hello $WORLD"`, `a $OP b`

## Common patterns

```yaml
# Functions containing await
rule:
  kind: function_declaration
  has:
    pattern: await $EXPR
    stopBy: end

# Inside a context
rule:
  pattern: console.log($$$)
  inside:
    kind: method_definition
    stopBy: end

# Async functions without try-catch
rule:
  all:
    - kind: function_declaration
    - has:
        pattern: await $EXPR
        stopBy: end
    - not:
        has:
          pattern: try { $$$ } catch ($E) { $$$ }
          stopBy: end
```

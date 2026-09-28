---
name: git-commit
description: Conventional commit format and guidelines. Use when creating git commits.
---

# Git commit conventions

Always use conventional commits format: `type(optional-scope): description`

## Valid types

- `feat` - new feature
- `fix` - bug fix
- `docs` - documentation changes
- `style` - formatting, missing semicolons, etc (no code change)
- `refactor` - code change that neither fixes a bug nor adds a feature
- `perf` - performance improvement
- `test` - adding or updating tests
- `build` - build system or external dependencies
- `ci` - CI configuration files and scripts
- `chore` - other changes that don't modify src or test files
- `revert` - revert a previous commit

## Examples

```
feat: add dark mode toggle
fix(auth): handle expired tokens correctly
docs: update API documentation
refactor(parser): simplify token handling
test: add integration tests for payment flow
```

## Signing

- Always use `git commit -S` to GPG-sign commits

## Commit message rules

- **Always use single-line commits** - no body, no bullet points, everything in the subject line
- Use imperative mood ("add" not "added", "fix" not "fixed")
- Keep title under 72 characters
- No period at end of title
- No AI attribution (no co-author, no "Generated with Claude")
- Scope is optional but helpful for clarity

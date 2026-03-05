---
description: Simplify code by removing unnecessary complexity
---
Review the code I just wrote with a focus on simplification. Look for:

**DRY violations:**
- Duplicate logic that should be extracted
- Copy-pasted code with minor variations
- Repeated patterns that could be generalized

**Unnecessary complexity:**
- Abstractions that don't pay for themselves
- Wrapper functions that just delegate
- Indirection without clear benefit
- Over-generic solutions for specific problems

**Dead code:**
- Unused functions, variables, parameters
- Commented-out code blocks
- Unreachable branches
- TODO stubs that will never be filled

**Over-engineering:**
- Future-proofing for hypotheticals
- Design patterns applied dogmatically
- Configuration for things that won't change
- Multiple inheritance/composition levels when one suffices

**Guiding principle:** Would a new team member understand this in 30 seconds?

For each issue found:
1. Explain why it adds unnecessary complexity
2. Show the simplified version
3. Apply the fix

If nothing needs simplification, say so and briefly explain what you verified.

$@

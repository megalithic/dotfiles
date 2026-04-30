---
description: Double check / review implementation with fresh eyes
---
Great, now I want you to carefully read over all of the new code you just wrote and other existing code with "fresh eyes," looking super carefully for any obvious bugs, errors, problems, issues, confusion, etc. Also, if you notice any pre-existing issues/bugs those should be addressed.

Question everything: Does each line of code need to exist? Unused parameters, dead code, and unnecessary complexity should be removed, not dressed up with underscore prefixes or comments.

This codebase will outlive you. Every shortcut becomes someone else's burden. Every hack compounds into technical debt that slows the whole team down.

You are not just writing code. You are shaping the future of this project. The patterns you establish will be copied. The corners you cut will be cut again.

Fight entropy. Leave the codebase better than you found it.

You MUST read all relevant code and think deeply (ultrathink!!!) first before you make any edits.

**Response format:**
- If you find ANY issues: fix them, then list what you fixed. Do NOT say "no issues found" - instead end with "Fixed [N] issue(s). Ready for another review."
- If you find ZERO issues: describe what you examined and verified, then conclude with "No issues found."

Do not rush to a verdict. Read all relevant code first, trace through edge cases, and only then decide. I am pushing you to do a genuinely thorough review and not just lazily rubber-stamp it. Make sure you think deeply, then ultrathink some more.

$@
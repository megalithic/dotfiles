---
name: reviewer-simplicity
description: Simplicity, slop and test-quality review of an immutable commit range in the provider portal, read-only
model: openai-codex/gpt-6.1-sol
thinking: high
tools: read, grep, find, ls, bash
system-prompt: append
auto-exit: true
---

Your instructions are shared with Ultimate's reviewer of the same name. Before anything else, read `.ultimate/agents/reviewer-simplicity.md` in the main checkout (`dirname "$(git rev-parse --path-format=absolute --git-common-dir)"`) and follow its body (ignore its YAML frontmatter). If it is missing, answer NEEDS CHANGES with verification blocked and name the missing file. Your final message is the whole deliverable.

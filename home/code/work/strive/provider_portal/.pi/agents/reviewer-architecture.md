---
name: reviewer-architecture
description: Advisory architecture review of an immutable commit range in the provider portal, read-only; never blocks
model: openai-codex/gpt-6.1-sol
thinking: low
tools: read, grep, find, ls, bash
system-prompt: append
auto-exit: true
---

Your instructions are shared with Ultimate's reviewer of the same name. Before anything else, read `.ultimate/agents/reviewer-architecture.md` in the main checkout (`dirname "$(git rev-parse --path-format=absolute --git-common-dir)"`) and follow its body (ignore its YAML frontmatter). If it is missing, say so and stop. Your final message is the whole deliverable.

---
name: reviewer-correctness
addTools: []
---

In these dotfiles, whether it works also means: idempotence of mise tasks and setup scripts (a second `mise run up` changes nothing), both hosts (`megabookpro`, `workbookpro` and their `config.<host>.toml` overlays), and dotfiles links (only Git-tracked files deploy).

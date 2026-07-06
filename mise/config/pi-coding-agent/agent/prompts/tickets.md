---
description: Create tickets from a plan with self-validation
---

Use your task-pipeline skill for the tickets phase.

Slug: $@

If no slug was passed, resolve it per the task-pipeline skill (prefer `$TICKET_ID` or the sole in-progress tk ticket; else scan for orphan `*_PLAN.md` under `~/.local/share/pi/plans/$(basename $PWD)/` — 1 match → use silently; 2+ → list + ask; 0 → tell user to run /plan first).

Read the plan at `~/.local/share/pi/plans/$(basename $PWD)/{slug}_PLAN.md`. Create one ticket per plan step using your ticket-creator skill. Run self-validation on all created tickets. Report what was created and confirm at least one ticket is ready.

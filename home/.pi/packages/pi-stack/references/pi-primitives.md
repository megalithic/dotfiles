# pi primitives for pstack skills

pstack's skills were written for Cursor. This page is the only translation. When a skill names a Cursor primitive, do what the matching row says. Nothing else in the skills overrides it.

## Delegation

| Skill says | Do |
|---|---|
| spawn a `Task`, `subagent_type: generalPurpose` | `subagent({ agent: "general-purpose", task, model })` |
| `subagent_type: poteto-agent` | `subagent({ agent: "poteto-agent", task, model })` |
| `subagent_type: comment-sicko` | `subagent({ agent: "comment-sicko", task })` |
| `readonly: true` | `agent: "pstack-reviewer"` (read-only toolset) |
| `run_in_background: true` | Every `subagent` call is already async. The result arrives as a message that starts your next turn. Never poll, sleep, or tail a file for it. |
| `environment: "cloud"`, cloud agents, cloud-sleeper wake chains | Not available. Run the worker locally in its own worktree (see Worktrees). |
| resume, message, or steer a delegate | `subagent_message({ name, message })` |
| explicit `model` for a role | `model: "provider/id:thinking"` from the role table (Models below). Omit `model` for `inherit-parent` or `auto`. |
| "fast" slugs (`-fast`) | pi has no fast variants. Use the same model at standard speed. |
| "If the `subagent` tool rejects a slug" | It errors with the valid ids. Use the role's default and say so. |

What the parent sends: the brief, exact file paths, the absolute path of `vendor/skills/poteto-mode/SKILL.md` for a `poteto-agent`, and success criteria. What comes back: the delegate's final message, delivered as a steer message with its name. You own the result. Read the diff it produced; do not pass its summary through.

Completion: a playbook step is done when its verification ran against the real artifact and you can point at the output. A delegate saying "done" is not evidence.

Missing capability: if `subagent` is not in your tool list, say so in the reply, do the step yourself in sequence, and label the result "single reviewer, no independent panel".

## Agents shipped by pi-stack

| Agent | Tools | Use |
|---|---|---|
| `general-purpose` | full | implementers, explorers, explainers, investigators, synthesizers |
| `pstack-reviewer` | read-only | interrogate reviewers, arena judges, any `readonly: true` spawn |
| `poteto-agent` | full | code delegates inside a playbook step; reads poteto-mode in full first |
| `comment-sicko` | read-only | the no-comments skill |

Spawn one call per panel seat in the same message, each with a distinct `name` (Reviewer A, Reviewer B) and its own `model`. A panel on one model is not a panel.

## Models

The role table is `~/.pi/agent/pi-stack/models.json`, written by `/setup-pstack`. Its active contents are injected into your system prompt under "pi-stack role table". A role maps to `"provider/id:thinking"` or a list of them (one seat per entry). Upstream default slugs (`claude-opus-5-5-xhigh`, `grok-4.7-xhigh-fast`) mean: the `judgment` and `code` roles from the table. If the table is absent, use the parent model for every role.

## Questions

| Skill says | Do |
|---|---|
| `AskQuestion` | `ask_user_question` (2-4 options, structured). Only for a preference call no experiment can settle. |

## Todo list

"Open a todolist" means the `todo` tool: one `create` per playbook step, verbatim, before task-specific items. A skipped step stays with `skip: <reason>` in its description. `update` to `in_progress` before a step and `completed` when its check passed.

## Sessions and transcripts

| Skill says | Do |
|---|---|
| this conversation's transcript | `$PI_SESSION_FILE` (JSONL). Search it with `vcc_recall`. |
| the user's chat history, other sessions | the `sessions` MCP (searchable past sessions for this cwd) |
| `~/.cursor/projects/*/agent-transcripts` | `~/.pi/agent/sessions/` grouped by cwd slug. Never read another project's slug. |

## Loops and long runs

`/loop <prompt>` means the user's `/loop` command when present (a re-arming prompt). `/goal` style long runs use the `goal` extension when present (`create_goal`, `get_goal`). If neither exists, say so and drive the task from the todo list in one session.

## Review and verification tools

| Skill says | Do |
|---|---|
| `/deslop`, `deslop` skill (cursor-team-kit) | not shipped. Run the `no-comments` skill for code and the `unslop` skill for prose. |
| `control-ui`, `control-cli` (cursor-team-kit) | not shipped. Use the project's verification skill if one exists (`verify-*`), else the `web-browser` or `chrome-cdp` skill for UIs and `interactive_shell` for CLIs. Phoenix apps: the Tidewave MCP when present. |
| Bugbot, "the agentic security review" | PR review bots. Use whatever bot the repo has (GitHub review comments via `gh`). None is a blocker. |
| Origin CLI | not installed. Take every `gh` fallback the skill offers. |
| `create-skill` (Cursor built-in) | pi's skill format: a directory with `SKILL.md` (frontmatter `name`, `description`), under `.pi/skills/` or `~/.pi/agent/skills/`. See the authoring-a-skill playbook. |
| `/babysit` built-in | none in pi; the Babysit playbook is the only one. |
| plan mode, `CreatePlan` | none in pi. Write the plan as a todo list plus a short artifact (`artifact` tool) when the user wants to read it. |

Calibrated judgments: when a skill asks you to dedupe findings, score candidates against a rubric, or decide whether two reviewers raised the same issue, use `typesafe_evaluate` (Jev) when it is in your tool list. One state, one question per item per dimension. Report its probabilities as its judgment, not yours.

Guards: pi-warden runs beside you. A held command means the operator must approve; a "done without a check" steer means run the check. Do not route around either.

## Worktrees

Parallel workers get their own worktree. Use the `wt` tool when the repo has it (`wt ensure <name> --json`), never raw `git worktree`. Delete with `wt prune`, never `rm -rf`.

## Skills

Invoke a skill as `/skill:<name>`. Read a bundled skill by path: `vendor/skills/<name>/SKILL.md` under the pi-stack package root, the directory that holds the poteto-mode path in your system prompt. Principle leaves are `vendor/skills/principle-<title>/SKILL.md`.
